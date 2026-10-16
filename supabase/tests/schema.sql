-- =============================================================================
-- Tests de SCHÉMA : contraintes, formats (le test frère rls.sql couvre la sécurité)
--
-- Pourquoi ce fichier existe : le premier jet de supabase/seed.sql utilisait le
-- format NAF compact (« 4321A »). L'API Recherche d'entreprises le rejette en
-- HTTP 400, et le bug n'a été découvert qu'en interrogeant réellement l'API.
-- La contrainte testée ici rend cette erreur impossible à réintroduire.
--
-- Exécution (sortie en code ≠ 0 si un test échoue) :
--   psql -v ON_ERROR_STOP=1 -f supabase/tests/schema.sql
--
-- ⚠️ La CI joue supabase/tests/*.sql dans l'ordre alphabétique sur la MÊME base :
--    ce fichier ne doit laisser aucune ligne derrière lui d'où le begin/rollback.
-- =============================================================================
\set ON_ERROR_STOP on

begin;

-- -----------------------------------------------------------------------------
-- Cas 1 — un code NAF au format APE pointé doit être accepté.
-- Placé en premier volontairement : il prouve que le rôle `authenticated` a bien
-- le droit d'écrire. Sans lui, les tests négatifs suivants passeraient pour la
-- mauvaise raison (permission refusée au lieu de contrainte violée).
-- -----------------------------------------------------------------------------
do $$
begin
  set local role authenticated;
  insert into public.campaigns (name, naf_codes, departements)
  values ('Test format valide', array['43.21A', '43.99C'], array['974']);
  raise notice 'OK  code NAF pointé (43.21A, 43.99C) accepté';
end
$$;

-- -----------------------------------------------------------------------------
-- Cas 2 — format INSEE compact « 4321A » : c'est le bug d'origine, doit échouer.
-- -----------------------------------------------------------------------------
do $$
begin
  set local role authenticated;
  begin
    insert into public.campaigns (name, naf_codes) values ('Test format compact', array['4321A']);
    raise exception 'ECHEC  le code NAF compact 4321A a été accepté (l''API le rejette en HTTP 400)';
  exception
    when check_violation then
      raise notice 'OK  code NAF compact (4321A) refusé';
    when insufficient_privilege then
      raise exception 'ECHEC  test non concluant : permission refusée, pas une violation de contrainte';
  end;
end
$$;

-- -----------------------------------------------------------------------------
-- Cas 3 — une campagne en cours de configuration (tableau vide) doit rester possible.
-- -----------------------------------------------------------------------------
do $$
begin
  set local role authenticated;
  insert into public.campaigns (name, naf_codes) values ('Test campagne non ciblée', '{}');
  raise notice 'OK  tableau de codes vide accepté (campagne en cours de configuration)';
end
$$;

-- -----------------------------------------------------------------------------
-- Cas 4 — minuscule refusée (l'API attend une majuscule stricte).
-- -----------------------------------------------------------------------------
do $$
begin
  set local role authenticated;
  begin
    insert into public.campaigns (name, naf_codes) values ('Test minuscule', array['43.21a']);
    raise exception 'ECHEC  le code NAF en minuscules (43.21a) a été accepté';
  exception
    when check_violation then
      raise notice 'OK  code NAF en minuscules (43.21a) refusé';
    when insufficient_privilege then
      raise exception 'ECHEC  test non concluant : permission refusée, pas une violation de contrainte';
  end;
end
$$;

-- -----------------------------------------------------------------------------
-- Cas 5 — code tronqué refusé.
-- -----------------------------------------------------------------------------
do $$
begin
  set local role authenticated;
  begin
    insert into public.campaigns (name, naf_codes) values ('Test tronqué', array['43.2A']);
    raise exception 'ECHEC  le code NAF tronqué (43.2A) a été accepté';
  exception
    when check_violation then
      raise notice 'OK  code NAF tronqué (43.2A) refusé';
    when insufficient_privilege then
      raise exception 'ECHEC  test non concluant : permission refusée, pas une violation de contrainte';
  end;
end
$$;

-- Nettoyage : aucune ligne ne doit subsister (les autres tests comptent les lignes).
rollback;

\echo '=== TESTS DE SCHEMA : PASSENT ==='
