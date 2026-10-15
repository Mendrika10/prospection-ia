-- =============================================================================
-- Tests : `campaigns_due` — campagne par campagne, due ou non (S1-09, ADR 0006)
--
-- LA RÈGLE TESTÉE, recopiée ici en clair (critère du ticket : l'agent Automation
-- ne doit rien avoir à réinterpréter) :
--
--     une campagne est due si :
--         active = true
--     ET  ( aucun run n'a jamais démarré pour elle
--           OU  now() >= dernier_started_at + interval_minutes × 1 minute )
--
--     où dernier_started_at = max(runs.started_at) pour cette campagne,
--     TOUS STATUTS CONFONDUS (un run en cours bloque donc sa campagne).
--
-- Critères d'acceptation du ticket :
--   * une campagne JAMAIS exécutée est due (premier passage toujours autorisé)
--   * une campagne exécutée RÉCEMMENT n'est pas due
--   * une campagne DÉSACTIVÉE reste hors jeu, même due par le temps
--   * la comparaison d'échéance est écrite en clair (ci-dessus)
--   * le fichier ne laisse aucune ligne derrière lui (`begin; … rollback;`)
--
-- Deux tests supplémentaires, dont un piège qui a été trouvé en écrivant ce fichier :
--
--   * La vue est en `security_invoker = true`. Sans cet attribut, une vue s'exécute avec les
--     droits de son PROPRIÉTAIRE et CONTOURNE la RLS : `anon` lirait les campagnes, ce qui
--     casserait le critère d'acceptation v1 « un accès anonyme ne lit aucune donnée ».
--
--     ⚠️ Vérifier « anon ne lit rien » NE SUFFIT PAS ici : la vue ne lui accorde aucun privilège,
--     donc le refus arrive même avec des sémantiques défaillantes — le test passerait pour la
--     mauvaise raison. C'est ce que le contrôle de mutation a montré (voir le rapport de PR).
--     Le test accorde donc explicitement à `anon` le droit de LIRE LA VUE avant de vérifier qu'il
--     n'obtient quand même AUCUNE donnée : c'est le pire cas, et le seul qui soit discriminant.
--
-- Exécution : psql -v ON_ERROR_STOP=1 -f supabase/tests/campaigns_due.sql
-- =============================================================================
\set ON_ERROR_STOP on

begin;

do $$
declare
  v_jamais    uuid;
  v_recente   uuid;
  v_ancienne  uuid;
  v_inactive  uuid;
  v_en_cours  uuid;
  v_n         int;
  v_dernier   timestamptz;
  v_prochain  timestamptz;
begin
  ---------------------------------------------------------------------------
  -- 5 campagnes, une par cas de la règle
  ---------------------------------------------------------------------------
  insert into public.campaigns (name, naf_codes, departements, interval_minutes, active)
  values ('test jamais executee', array['43.21A'], array['974'], 1440, true)
  returning id into v_jamais;

  insert into public.campaigns (name, naf_codes, departements, interval_minutes, active)
  values ('test executee il y a 1 min', array['43.21A'], array['974'], 1440, true)
  returning id into v_recente;

  insert into public.campaigns (name, naf_codes, departements, interval_minutes, active)
  values ('test executee il y a 3 jours', array['43.21A'], array['974'], 1440, true)
  returning id into v_ancienne;

  insert into public.campaigns (name, naf_codes, departements, interval_minutes, active)
  values ('test desactivee mais due', array['43.21A'], array['974'], 1440, false)
  returning id into v_inactive;

  insert into public.campaigns (name, naf_codes, departements, interval_minutes, active)
  values ('test run en cours', array['43.21A'], array['974'], 1440, true)
  returning id into v_en_cours;

  -- Historique : un run par campagne concernée
  insert into public.runs (workflow, status, campaign_id, started_at) values
    ('wf1-collecte', 'success', v_recente,  now() - interval '1 minute'),
    ('wf1-collecte', 'success', v_ancienne, now() - interval '3 days'),
    ('wf1-collecte', 'success', v_inactive, now() - interval '5 days'),
    ('wf1-collecte', 'running', v_en_cours, now() - interval '2 minutes');

  ---------------------------------------------------------------------------
  -- 1. Jamais exécutée -> DUE (premier passage toujours autorisé)
  ---------------------------------------------------------------------------
  select count(*) into v_n from public.campaigns_due where id = v_jamais;
  if v_n <> 1 then
    raise exception 'ECHEC  une campagne jamais exécutée devrait être due (% ligne dans la vue)', v_n;
  end if;
  raise notice 'OK  campagne jamais exécutée = due (premier passage autorisé)';

  ---------------------------------------------------------------------------
  -- 2. Exécutée il y a 1 minute, intervalle 1440 min -> PAS due
  ---------------------------------------------------------------------------
  select count(*) into v_n from public.campaigns_due where id = v_recente;
  if v_n <> 0 then
    raise exception 'ECHEC  une campagne exécutée il y a 1 min (intervalle 1440) ne devrait PAS être due';
  end if;
  raise notice 'OK  campagne exécutée récemment = pas due';

  ---------------------------------------------------------------------------
  -- 3. Exécutée il y a 3 jours, intervalle 1440 min -> DUE
  ---------------------------------------------------------------------------
  select count(*) into v_n from public.campaigns_due where id = v_ancienne;
  if v_n <> 1 then
    raise exception 'ECHEC  une campagne exécutée il y a 3 jours (intervalle 1440) devrait être due';
  end if;
  raise notice 'OK  campagne exécutée il y a plus d''un intervalle = due';

  ---------------------------------------------------------------------------
  -- 4. L'échéance est calculée, pas devinée : prochain_run = dernier_run + intervalle
  ---------------------------------------------------------------------------
  select dernier_run, prochain_run into v_dernier, v_prochain
    from public.campaigns_due where id = v_ancienne;
  if v_prochain <> v_dernier + (1440 * interval '1 minute') then
    raise exception 'ECHEC  prochain_run (%) <> dernier_run (%) + 1440 min', v_prochain, v_dernier;
  end if;
  raise notice 'OK  prochain_run = dernier_run + intervalle (1440 min)';

  ---------------------------------------------------------------------------
  -- 5. Désactivée mais due par le temps -> HORS JEU
  ---------------------------------------------------------------------------
  select count(*) into v_n from public.campaigns_due where id = v_inactive;
  if v_n <> 0 then
    raise exception 'ECHEC  une campagne désactivée ne doit jamais être due, même par le temps';
  end if;
  raise notice 'OK  campagne désactivée = hors jeu, même due par le temps';

  ---------------------------------------------------------------------------
  -- 6. Run EN COURS -> bloque sa campagne (ADR 0006 : tous statuts confondus)
  ---------------------------------------------------------------------------
  select count(*) into v_n from public.campaigns_due where id = v_en_cours;
  if v_n <> 0 then
    raise exception 'ECHEC  un run en cours devrait bloquer sa campagne';
  end if;
  raise notice 'OK  un run en cours bloque sa campagne (pas de relance par le tick suivant)';

  ---------------------------------------------------------------------------
  -- 7. Le compte global : 2 dues sur 5. Cette assertion attrape une vue qui
  --    renverrait TOUT (filtre `active` oublié) ou RIEN (comparaison inversée),
  --    deux défauts que les contrôles « ligne par ligne » ci-dessus ne verraient pas.
  ---------------------------------------------------------------------------
  select count(*) into v_n from public.campaigns_due where id in (v_jamais, v_recente, v_ancienne, v_inactive, v_en_cours);
  if v_n <> 2 then
    raise exception 'ECHEC  attendu 2 campagnes dues sur 5, obtenu %', v_n;
  end if;
  raise notice 'OK  2 campagnes dues sur 5 (ni tout, ni rien)';

  ---------------------------------------------------------------------------
  -- 8. Contrôle POSITIF : les rôles qui DOIVENT lire la vue y arrivent
  --    `grant select ... to service_role` est indispensable à WF1 : sans lui, la vue
  --    serait inutilisable — et les contrôles 1 à 7 ci-dessus, exécutés en superutilisateur,
  --    ne le verraient pas.
  ---------------------------------------------------------------------------
  set local role service_role;
  select count(*) into v_n
    from public.campaigns_due
   where id in (v_jamais, v_recente, v_ancienne, v_inactive, v_en_cours);
  reset role;
  if v_n <> 2 then
    raise exception 'ECHEC  service_role (WF1) devrait lire 2 campagnes dues, lu %', v_n;
  end if;
  raise notice 'OK  service_role (WF1) lit campaigns_due (% campagnes dues sur 5)', v_n;

  set local role authenticated;
  select count(*) into v_n from public.campaigns_due where id = v_jamais;
  reset role;
  if v_n <> 1 then
    raise exception 'ECHEC  authenticated devrait lire la vue (dashboard), lu %', v_n;
  end if;
  raise notice 'OK  authenticated lit campaigns_due (dashboard)';

  ---------------------------------------------------------------------------
  -- 9. Contrôle NÉGATIF discriminant : anon reçoit le droit de lire la VUE, et ne doit
  --    toujours rien obtenir. Si la vue perdait `security_invoker`, elle s'exécuterait
  --    avec les droits de son propriétaire et cette requête renverrait des lignes.
  ---------------------------------------------------------------------------
  grant select on public.campaigns_due to anon;
  begin
    set local role anon;
    select count(*) into v_n from public.campaigns_due;
    raise exception 'ECHEC  anon a lu % campagne(s) : la vue contourne la RLS (security_invoker absent ?)', v_n;
  exception
    when insufficient_privilege then
      raise notice 'OK  anon, même avec le droit sur la vue, ne lit rien (security_invoker vrai)';
  end;
  reset role;
  revoke select on public.campaigns_due from anon;

  raise notice '=== TESTS campaigns_due : PASSENT ===';
end
$$;

-- Aucune campagne ni aucun run de test ne survit.
rollback;
