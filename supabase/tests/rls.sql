-- =============================================================================
-- Tests RLS et privilèges — critères d'acceptation v1 (§11)
--   * "RLS activée : un accès anonyme ne lit aucune donnée"
--   * n8n (service_role) écrit sans blocage, le dashboard (authenticated) suit le pipeline
--
-- Exécution (le script se termine en erreur si un test échoue) :
--   supabase start && psql "$(supabase status -o env | grep DB_URL | cut -d= -f2- | tr -d '\"')" -f supabase/tests/rls.sql
--   ou via docker : docker exec -i <pg> psql -U postgres -v ON_ERROR_STOP=1 -f - < supabase/tests/rls.sql
--
-- Prérequis : rôles anon / authenticated / service_role présents (fournis par Supabase).
-- =============================================================================
\set ON_ERROR_STOP on

do $$
declare
  v_leads int;
  v_status public.lead_status;
  v_updated timestamptz;
begin
  ---------------------------------------------------------------------------
  -- Écriture préalable en service_role (jouée par n8n en production)
  ---------------------------------------------------------------------------
  set local role service_role;
  insert into public.companies (siren, name, website)
    values ('000000001', 'Test SARL', 'http://exemple.fr');
  insert into public.analyses (siren, http_status, https, has_viewport, psi_mobile_score)
    values ('000000001', 200, false, false, 35);
  insert into public.leads (siren, score, reasons)
    values ('000000001', 7, '["Pas de version mobile"]'::jsonb);
  insert into public.runs (workflow, status, items_processed)
    values ('test', 'success', 1);
  raise notice 'OK  service_role écrit dans companies / analyses / leads / runs';
  reset role;

  ---------------------------------------------------------------------------
  -- 1. anon ne lit AUCUNE donnée
  ---------------------------------------------------------------------------
  begin
    set local role anon;
    select count(*) into v_leads from public.leads;
    raise exception 'ECHEC  anon a pu lire % ligne(s) de leads', v_leads;
  exception
    when insufficient_privilege then
      raise notice 'OK  anon ne peut pas lire leads (permission denied)';
  end;

  begin
    set local role anon;
    select count(*) into v_leads from public.companies;
    raise exception 'ECHEC  anon a pu lire % ligne(s) de companies', v_leads;
  exception
    when insufficient_privilege then
      raise notice 'OK  anon ne peut pas lire companies (permission denied)';
  end;

  ---------------------------------------------------------------------------
  -- 2. authenticated lit le pipeline
  ---------------------------------------------------------------------------
  set local role authenticated;
  select count(*) into v_leads from public.leads;
  if v_leads <> 1 then
    raise exception 'ECHEC  authenticated devrait lire 1 lead, lu %', v_leads;
  end if;
  raise notice 'OK  authenticated lit les leads (% ligne)', v_leads;

  ---------------------------------------------------------------------------
  -- 3. authenticated suit le pipeline : changement de statut (RF-18)
  ---------------------------------------------------------------------------
  update public.leads set status = 'contacte' where siren = '000000001';
  select status into v_status from public.leads where siren = '000000001';
  if v_status <> 'contacte' then
    raise exception 'ECHEC  statut non mis à jour (%)', v_status;
  end if;
  raise notice 'OK  authenticated met à jour le statut d''un lead';

  -- 3bis. saisie manuelle du site / email (RF-07) + trigger updated_at.
  -- On force une date passée : si le trigger est actif, il la réécrit avec now().
  update public.companies
     set website = 'https://exemple.fr',
         website_source = 'manual',
         updated_at = now() - interval '1 day'
   where siren = '000000001';
  select updated_at into v_updated from public.companies where siren = '000000001';
  if v_updated is null or v_updated < now() - interval '1 minute' then
    raise exception 'ECHEC  trigger updated_at inactif sur companies (%)', v_updated;
  end if;
  raise notice 'OK  authenticated corrige une fiche entreprise + trigger updated_at';

  ---------------------------------------------------------------------------
  -- 4. authenticated ne peut PAS écrire dans runs (réservé à n8n)
  ---------------------------------------------------------------------------
  begin
    set local role authenticated;
    insert into public.runs (workflow) values ('hack');
    raise exception 'ECHEC  authenticated a pu écrire dans runs';
  exception
    when insufficient_privilege then
      raise notice 'OK  authenticated ne peut pas écrire dans runs';
  end;

  reset role;
  raise notice '=== TOUS LES TESTS RLS PASSENT ===';
end
$$;
