-- =============================================================================
-- Garde-fou : format des codes NAF des campagnes
-- Cf. ticket S1-05 · ADR 0005 · AGENTS.md §10 (pièges connus)
-- =============================================================================
-- Pourquoi cette migration existe :
--   L'API Recherche d'entreprises attend un code APE au format POINTÉ (« 43.21A »)
--   et rejette le format INSEE compact (« 4321A ») en HTTP 400. Pire : un nom de
--   paramètre inconnu étant ignoré silencieusement, une campagne mal saisie pouvait
--   remonter des résultats NON filtrés sans aucune erreur visible.
--   Le premier jet de supabase/seed.sql contenait ce format compact : la contrainte
--   ci-dessous rend l'erreur impossible à réintroduire, au niveau de la base.
--
-- Portée volontairement limitée aux codes NAF : le format des départements et des
-- villes relève d'un autre ticket.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Une fonction IMMUTABLE est nécessaire : un CHECK ne peut pas contenir de
-- sous-requête, mais il peut appeler une fonction immutable.
-- Elle ne dépend que de son argument (aucune lecture de table).
-- -----------------------------------------------------------------------------
create or replace function public.naf_codes_valides(codes text[])
returns boolean
language sql
immutable
as $$
  select coalesce(
    bool_and(coalesce(c ~ '^[0-9]{2}\.[0-9]{2}[A-Z]$', false)),
    true  -- tableau vide : campagne en cours de configuration, autorisée
  )
  from unnest(codes) as c;
$$;

comment on function public.naf_codes_valides(text[]) is
  'Vrai si tous les codes sont des codes APE pointés (43.21A). Tableau vide accepté.';

-- -----------------------------------------------------------------------------
-- Contrainte. Elle valide aussi les lignes déjà présentes : si une base
-- contient encore un code au format compact, cette migration échoue — c'est
-- voulu, il faut corriger la donnée plutôt que masquer le problème.
--
-- RÉAPPLICABLE (règle du dépôt, AGENTS.md §4) : le job CI rejoue TOUTES les
-- migrations sur une base peuplée, et l'empreinte de schéma avant/après doit
-- rester identique. Sans garde, la seconde passe échoue — mesuré en arène
-- Postgres 16 : « constraint campaigns_naf_codes_format already exists » (42710).
-- -----------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'campaigns_naf_codes_format'
      and conrelid = 'public.campaigns'::regclass
  ) then
    alter table public.campaigns
      add constraint campaigns_naf_codes_format
      check (public.naf_codes_valides(naf_codes));
  end if;
end
$$;

comment on column public.campaigns.naf_codes is
  'Codes APE au format pointé (ex. 43.21A, 43.99C). Le format compact (4321A) est rejeté en HTTP 400 par l''API Recherche d''entreprises.';

-- -----------------------------------------------------------------------------
-- Rappel (n8n écrit avec la clé service_role) : les privilèges sont déjà accordés
-- par la migration initiale, rien à ajouter ici.
-- -----------------------------------------------------------------------------
