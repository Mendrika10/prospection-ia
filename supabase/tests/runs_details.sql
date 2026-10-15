-- =============================================================================
-- Tests : runs.details — distinguer récupérées / écartées / écrites (S1-08, D-002)
--
-- Critères d'acceptation du ticket :
--   * `runs.items_processed` garde un sens UNIQUE : lignes ÉCRITES en base
--   * `runs.details` porte au minimum `recuperees` et `ecartees` (entiers),
--     documentés par un `comment on column` : la colonne doit s'expliquer seule
--   * les trois compteurs se lisent SÉPARÉMENT sur un même run, avec des valeurs
--     DIFFÉRENTES (sinon la séparation ne prouve rien)
--   * le fichier ne laisse aucune ligne derrière lui (`begin; … rollback;`)
--
-- Ce que ce test refuse d'être : il ne vérifie PAS que « c'est du JSONB ». Le type
-- de colonne le garantit déjà, donc un tel test ne pourrait pas échouer — défaut
-- relevé par la revue du 2026-10-15. Il lit les compteurs et calcule la métrique
-- qui les justifie (le taux de rejet).
--
-- Exécution : psql -v ON_ERROR_STOP=1 -f supabase/tests/runs_details.sql
-- =============================================================================
\set ON_ERROR_STOP on

begin;

do $$
declare
  v_run_id     uuid;
  v_ecrites    int;
  v_recuperees int;
  v_ecartees   int;
  v_taux_rejet numeric;
  v_comment    text;
begin
  ---------------------------------------------------------------------------
  -- Écriture d'un run représentatif : 30 entreprises récupérées, 18 écartées
  -- par la règle de ciblage (ADR 0005), 12 réellement écrites en base.
  ---------------------------------------------------------------------------
  insert into public.runs (workflow, status, items_processed, details)
  values ('wf1-collecte', 'success', 12,
          '{"recuperees": 30, "ecartees": 18}'::jsonb)
  returning id, items_processed into v_run_id, v_ecrites;

  ---------------------------------------------------------------------------
  -- 1. Les trois compteurs se lisent séparément, sur le MÊME run
  ---------------------------------------------------------------------------
  select items_processed,
         (details ->> 'recuperees')::int,
         (details ->> 'ecartees')::int
    into v_ecrites, v_recuperees, v_ecartees
    from public.runs
   where id = v_run_id;

  if v_ecrites is null or v_recuperees is null or v_ecartees is null then
    raise exception 'ECHEC  un des trois compteurs est illisible (ecrites=%, recuperees=%, ecartees=%)',
      v_ecrites, v_recuperees, v_ecartees;
  end if;
  raise notice 'OK  les trois compteurs se lisent séparément : écrites=% récupérées=% écartées=%',
    v_ecrites, v_recuperees, v_ecartees;

  if (v_ecrites, v_recuperees, v_ecartees) <> (12, 30, 18) then
    raise exception 'ECHEC  valeurs inattendues : attendu (12, 30, 18), lu (%, %, %)',
      v_ecrites, v_recuperees, v_ecartees;
  end if;

  ---------------------------------------------------------------------------
  -- 2. Les trois valeurs sont DIFFÉRENTES
  --    Si elles étaient égales, la séparation des compteurs ne serait pas
  --    démontrée : le test passerait sans que rien ne soit distingué.
  ---------------------------------------------------------------------------
  if v_ecrites = v_recuperees or v_ecrites = v_ecartees or v_recuperees = v_ecartees then
    raise exception 'ECHEC  les trois compteurs ne sont pas distincts (%, %, %) : la séparation n''est pas démontrée',
      v_ecrites, v_recuperees, v_ecartees;
  end if;
  raise notice 'OK  les trois compteurs sont distincts (12 / 30 / 18)';

  ---------------------------------------------------------------------------
  -- 3. La métrique qui justifie ces compteurs est calculable : le taux de rejet
  --    (seuil d'alerte du brief PO §5 : > 60 % = campagne trop large)
  ---------------------------------------------------------------------------
  select round(100.0 * v_ecartees / (v_recuperees + v_ecartees), 1) into v_taux_rejet;
  if v_taux_rejet <> 37.5 then
    raise exception 'ECHEC  taux de rejet calculé % au lieu de 37.5', v_taux_rejet;
  end if;
  raise notice 'OK  taux de rejet calculable : % %% (18 écartées sur 48 vues)', v_taux_rejet;

  ---------------------------------------------------------------------------
  -- 4. Items_processed et details->>'ecartees' ne mesurent PAS la même chose
  --    (c'est toute la décision D-002 : un seul sens par colonne)
  ---------------------------------------------------------------------------
  if v_ecrites = (select (details ->> 'ecartees')::int from public.runs where id = v_run_id) then
    raise exception 'ECHEC  items_processed confondu avec le compteur d''écartées';
  end if;
  raise notice 'OK  items_processed (écrites) ne double pas le compteur d''écartées';

  ---------------------------------------------------------------------------
  -- 5. Les colonnes s'expliquent toutes seules (`comment on column`)
  --    Critère du ticket : sans ce fichier, un agent doit comprendre le sens.
  ---------------------------------------------------------------------------
  select col_description('public.runs'::regclass, attnum) into v_comment
    from pg_attribute
   where attrelid = 'public.runs'::regclass and attname = 'details';

  if v_comment is null or v_comment not like '%recuperees%' or v_comment not like '%ecartees%' then
    raise exception 'ECHEC  la colonne details n''est pas documentée (comment on column) : %', v_comment;
  end if;
  raise notice 'OK  runs.details documenté par comment on column';

  select col_description('public.runs'::regclass, attnum) into v_comment
    from pg_attribute
   where attrelid = 'public.runs'::regclass and attname = 'items_processed';

  if v_comment is null then
    raise exception 'ECHEC  la colonne items_processed n''est pas documentée (sens unique, D-002)';
  end if;
  raise notice 'OK  runs.items_processed documenté par comment on column';

  raise notice '=== TESTS runs.details : PASSENT ===';
end
$$;

-- Aucune ligne ne survit : le run de test disparaît avec la transaction.
rollback;
