-- =============================================================================
-- Prospection IA — Migration initiale
-- Réf. cahier des charges §7.1 (modèle de données) et §9 (RGPD / blocklist)
-- Sprint S1
-- =============================================================================
-- Rôles concernés :
--   * service_role (n8n)  : contourne la RLS, écrit dans companies/analyses/leads/runs
--   * authenticated (moi) : lit tout, écrit leads/campaigns/blocklist via le dashboard
--   * anon                : aucun policy => aucun accès (critère d'acceptation v1)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Trigger utilitaire : maintient updated_at
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- campaigns — ciblage (RF-01 à RF-03)
-- -----------------------------------------------------------------------------
create table if not exists public.campaigns (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,
  naf_codes        text[] not null default '{}',
  departements     text[] default '{}',
  villes           text[] default '{}',
  effectif_min     int,
  score_threshold  int not null default 7 check (score_threshold between 0 and 10),
  cron             text default '0 6 * * *',
  active           boolean not null default true,
  created_at       timestamptz default now(),
  updated_at       timestamptz default now()
);

-- -----------------------------------------------------------------------------
-- companies — entreprises issues du registre public (RF-04 à RF-07)
-- -----------------------------------------------------------------------------
create table if not exists public.companies (
  siren           text primary key,
  name            text not null,
  naf             text,
  address         text,
  city            text,
  postal_code     text,
  effectif        text,
  website         text,
  email           text,
  phone           text,
  website_source  text check (website_source in ('places', 'osm', 'manual', 'introuvable')),
  campaign_id     uuid references public.campaigns(id) on delete set null,
  raw             jsonb,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

-- -----------------------------------------------------------------------------
-- analyses — analyses techniques historisées (RF-08 à RF-11)
-- -----------------------------------------------------------------------------
create table if not exists public.analyses (
  id              uuid primary key default gen_random_uuid(),
  siren           text not null references public.companies(siren) on delete cascade,
  analyzed_at     timestamptz default now(),
  http_status     int,
  https           boolean,
  has_viewport    boolean,
  copyright_year  int,
  tech_hints      text[],
  psi_mobile_score int check (psi_mobile_score between 0 and 100),
  error           text
);

-- -----------------------------------------------------------------------------
-- leads — suivi commercial (RF-15 à RF-18)
-- -----------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'lead_status') then
    create type public.lead_status as enum
      ('nouveau', 'a_contacter', 'contacte', 'repondu', 'gagne', 'perdu', 'ignore');
  end if;
end
$$;

create table if not exists public.leads (
  siren         text primary key references public.companies(siren) on delete cascade,
  score         int not null check (score between 0 and 10),
  reasons       jsonb not null default '[]',
  status        public.lead_status not null default 'nouveau',
  notified_at   timestamptz,
  contacted_at  timestamptz,
  notes         text,
  updated_at    timestamptz default now()
);

-- -----------------------------------------------------------------------------
-- runs — observabilité des exécutions n8n (RF-19)
-- -----------------------------------------------------------------------------
create table if not exists public.runs (
  id               uuid primary key default gen_random_uuid(),
  workflow         text not null,
  started_at       timestamptz default now(),
  finished_at      timestamptz,
  status           text check (status in ('running', 'success', 'partial', 'error')),
  items_processed  int default 0,
  error            text
);

-- -----------------------------------------------------------------------------
-- blocklist — liste d'opposition RGPD (§9)
-- -----------------------------------------------------------------------------
create table if not exists public.blocklist (
  id          uuid primary key default gen_random_uuid(),
  siren       text,
  email       text,
  reason      text,
  created_at  timestamptz default now(),
  constraint blocklist_siren_or_email check (siren is not null or email is not null)
);

create unique index if not exists blocklist_siren_key on public.blocklist (siren) where siren is not null;
create unique index if not exists blocklist_email_key on public.blocklist (lower(email)) where email is not null;

-- -----------------------------------------------------------------------------
-- Index — dashboard < 2 s pour 10 000 leads (§4) + sélections des workflows
-- -----------------------------------------------------------------------------
create index if not exists leads_score_status_idx      on public.leads (score desc, status);
create index if not exists leads_notified_idx          on public.leads (notified_at) where notified_at is null;
create index if not exists companies_naf_idx           on public.companies (naf);
create index if not exists companies_city_idx          on public.companies (city);
create index if not exists companies_no_website_idx    on public.companies (campaign_id) where website is null;
create index if not exists analyses_siren_date_idx     on public.analyses (siren, analyzed_at desc);
create index if not exists runs_workflow_started_idx   on public.runs (workflow, started_at desc);

-- -----------------------------------------------------------------------------
-- Triggers updated_at
-- -----------------------------------------------------------------------------
drop trigger if exists companies_set_updated_at on public.companies;
create trigger companies_set_updated_at
  before update on public.companies
  for each row execute function public.set_updated_at();

drop trigger if exists campaigns_set_updated_at on public.campaigns;
create trigger campaigns_set_updated_at
  before update on public.campaigns
  for each row execute function public.set_updated_at();

drop trigger if exists leads_set_updated_at on public.leads;
create trigger leads_set_updated_at
  before update on public.leads
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Row Level Security (§4, §7.1)
-- Aucune policy pour `anon` => accès anonyme refusé.
-- -----------------------------------------------------------------------------
alter table public.campaigns  enable row level security;
alter table public.companies  enable row level security;
alter table public.analyses   enable row level security;
alter table public.leads      enable row level security;
alter table public.runs       enable row level security;
alter table public.blocklist  enable row level security;

-- Lecture : utilisateur authentifié uniquement
drop policy if exists "read_campaigns" on public.campaigns;
create policy "read_campaigns" on public.campaigns
  for select to authenticated using (true);

drop policy if exists "read_companies" on public.companies;
create policy "read_companies" on public.companies
  for select to authenticated using (true);

drop policy if exists "read_analyses" on public.analyses;
create policy "read_analyses" on public.analyses
  for select to authenticated using (true);

drop policy if exists "read_leads" on public.leads;
create policy "read_leads" on public.leads
  for select to authenticated using (true);

drop policy if exists "read_runs" on public.runs;
create policy "read_runs" on public.runs
  for select to authenticated using (true);

drop policy if exists "read_blocklist" on public.blocklist;
create policy "read_blocklist" on public.blocklist
  for select to authenticated using (true);

-- Écriture : campagnes (CRUD dashboard, RF-01..03)
drop policy if exists "write_campaigns" on public.campaigns;
create policy "write_campaigns" on public.campaigns
  for all to authenticated using (true) with check (true);

-- Écriture : pipeline commercial (statuts, notes, RF-18)
drop policy if exists "update_leads" on public.leads;
create policy "update_leads" on public.leads
  for update to authenticated using (true) with check (true);

-- Écriture : liste d'opposition (§9)
drop policy if exists "write_blocklist" on public.blocklist;
create policy "write_blocklist" on public.blocklist
  for all to authenticated using (true) with check (true);

-- Écriture : corrections manuelles de fiche entreprise (site/email saisis à la main, RF-07)
drop policy if exists "update_companies" on public.companies;
create policy "update_companies" on public.companies
  for update to authenticated using (true) with check (true);

-- Grants explicites (les policies ci-dessus restent le filtre réel)
grant usage on schema public to anon, authenticated, service_role;

grant select on all tables in schema public to authenticated;
grant insert, update, delete on public.campaigns, public.leads, public.blocklist to authenticated;
grant update on public.companies to authenticated;

-- n8n écrit avec la clé service_role : privilèges complets sur les tables (la RLS est
-- contournée, la clé ne doit donc jamais quitter les credentials n8n)
grant all on all tables in schema public to service_role;

-- Les prochaines tables créées dans public héritent de ces droits
alter default privileges in schema public grant all on tables to service_role;
alter default privileges in schema public grant select on tables to authenticated;

grant usage on schema public to anon;
revoke all on all tables in schema public from anon;

-- -----------------------------------------------------------------------------
-- Types exposés à PostgREST (dashboard)
-- -----------------------------------------------------------------------------
notify pgrst, 'reload schema';
