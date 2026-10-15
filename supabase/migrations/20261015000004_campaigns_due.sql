-- =============================================================================
-- Prospection IA — Migration 4 : cadence des campagnes et campagnes dues
-- Ticket S1-09 · décision d'architecture ADR 0006 · RF-03, cahier des charges §7.1 et §7.2
-- =============================================================================
-- Pourquoi cette migration : RF-03 (« planifier la fréquence d'exécution par campagne »)
-- n'était pas implémentable en l'état, pour deux raisons vérifiées le 2026-10-15 :
--   * le déclencheur n8n est une propriété du nœud, et ses valeurs ne sont évaluées qu'à la
--     PUBLICATION du workflow (documentation officielle) : aucun cron par ligne n'est lisible
--     au moment de l'exécution ;
--   * rien n'enregistrait le dernier passage d'une campagne, donc aucune campagne ne pouvait
--     être « due » ou non.
--
-- ADR 0006 tranche en trois règles :
--   1. le déclencheur reste à cadence fixe (il empêche aussi la mise en pause du Supabase
--      gratuit après une semaine d'inactivité) ;
--   2. la fréquence par campagne devient un INTERVALLE explicite (`interval_minutes`) ; la
--      colonne `cron` reste au schéma mais devient purement descriptive ;
--   3. le dernier passage devient lisible via `runs.campaign_id`, et la vue `campaigns_due`
--      expose les campagnes à traiter.
--
-- La règle d'échéance est écrite ICI, une seule fois, et recopiée en clair dans
-- supabase/tests/campaigns_due.sql pour que l'agent Automation n'ait rien à réinterpréter :
--     active = true  ET  ( aucun run  OU  now() >= dernier_started_at + interval_minutes )
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 1. Fréquence par campagne : un intervalle, pas un cron à interpréter
--    Défaut 1440 min = 24 h, identique à la cadence du cron par défaut ('0 6 * * *') :
--    aucune campagne existante ne change de comportement à l'application de la migration.
-- -----------------------------------------------------------------------------
alter table public.campaigns add column if not exists interval_minutes int not null default 1440;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.campaigns'::regclass
       and conname  = 'campaigns_interval_minutes_positif'
  ) then
    alter table public.campaigns
      add constraint campaigns_interval_minutes_positif check (interval_minutes > 0);
  end if;
end
$$;

comment on column public.campaigns.interval_minutes is
  'Fréquence voulue de collecte pour cette campagne, en minutes (ADR 0006). C''est LA valeur qui décide si une campagne est due : voir la vue public.campaigns_due. Défaut 1440 = 24 h.';

comment on column public.campaigns.cron is
  'DESCRIPTIF uniquement (ADR 0006) : lisible par un humain, JAMAIS interprété à l''exécution. Le déclencheur n8n a une cadence fixe et ne peut pas lire un cron par ligne — ses valeurs ne sont évaluées qu''à la publication du workflow. La fréquence réelle est interval_minutes.';

-- -----------------------------------------------------------------------------
-- 2. Rattacher un run à sa campagne : sans cela, aucune campagne n'a de « dernier passage »
-- -----------------------------------------------------------------------------
alter table public.runs add column if not exists campaign_id uuid;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.runs'::regclass
       and conname  = 'runs_campaign_id_fkey'
  ) then
    alter table public.runs
      add constraint runs_campaign_id_fkey
      foreign key (campaign_id) references public.campaigns(id) on delete set null;
  end if;
end
$$;

comment on column public.runs.campaign_id is
  'Campagne à l''origine de ce run (ADR 0006). NULL pour un run sans campagne (WF5 erreurs, exécution à vide). `on delete set null` : supprimer une campagne ne doit ni détruire son historique d''exécution, ni être bloqué par lui.';

-- Index de la seule lecture réelle : « quand cette campagne a-t-elle tourné pour la dernière fois ? »
-- Partiel : les runs sans campagne (WF5) ne sont jamais cherchés par campagne.
create index if not exists runs_campaign_started_idx
  on public.runs (campaign_id, started_at desc)
  where campaign_id is not null;

-- -----------------------------------------------------------------------------
-- 3. La vue qui répond à la question, avec la règle écrite une seule fois
--
--    `security_invoker = true` est INDISPENSABLE : par défaut, une vue s'exécute avec les
--    droits de son propriétaire et CONTOURNE la RLS des tables qu'elle lit. Sans cet attribut,
--    `anon` — qui n'a ni privilège ni policy — lirait les campagnes : régression directe du
--    critère d'acceptation v1 « un accès anonyme ne lit aucune donnée ». Le test le vérifie.
--
--    `dernier_run` prend le dernier run DÉMARRÉ, tous statuts confondus : un run en cours
--    empêche donc la relance de sa campagne par le tick suivant (conséquence assumée, ADR 0006).
-- -----------------------------------------------------------------------------
create or replace view public.campaigns_due
with (security_invoker = true) as
select
  c.id,
  c.name,
  c.naf_codes,
  c.departements,
  c.villes,
  c.effectif_min,
  c.score_threshold,
  c.cron,
  c.interval_minutes,
  c.active,
  c.created_at,
  c.updated_at,
  d.dernier_run,
  d.dernier_run + make_interval(mins => c.interval_minutes) as prochain_run
from public.campaigns c
left join lateral (
  select max(r.started_at) as dernier_run
    from public.runs r
   where r.campaign_id = c.id
) d on true
where c.active
  and (
    d.dernier_run is null
    or now() >= d.dernier_run + make_interval(mins => c.interval_minutes)
  );

comment on view public.campaigns_due is
  'Campagnes à collecter maintenant (ADR 0006, ticket S1-09). Règle : active = true ET (aucun run, ou now() >= dernier run DÉMARRÉ + interval_minutes). dernier_run = max(runs.started_at), tous statuts confondus : un run en cours empêche la relance. Lue par WF1 (service_role) ; anon n''y a aucun accès.';

-- La vue est un objet distinct : ni `grant ... on all tables`, ni `alter default privileges
-- on tables` de la migration 1 ne la couvrent. Sans ces deux lignes, WF1 lirait
-- « permission denied » et la vue serait inutilisable.
grant select on public.campaigns_due to authenticated, service_role;
revoke all on public.campaigns_due from anon;

notify pgrst, 'reload schema';
