-- =============================================================================
-- Données témoins — une ligne par table de données, insérée AVANT la réapplication
-- des migrations (étape « Réappliquer les migrations » du job CI `sql`).
--
-- POURQUOI CE FICHIER EXISTE : après le seed, quatre des six tables sont VIDES
-- (`companies`, `analyses`, `leads`, `blocklist`). Une migration destructive sur
-- `companies` — `delete from public.companies`, par exemple — ne changerait alors
-- l'empreinte de RIEN, et passerait inaperçue. Une empreinte ne prouve que ce qu'il
-- y a à perdre : il faut donc peupler les six tables avant de comparer.
--
-- ⚠️ Données manifestement fausses, et c'est volontaire : le dépôt est **public**, donc
-- aucune donnée d'entreprise réelle ne peut y entrer (décision D-004). Les SIREN
-- « 9… » sont réservés ici pour être reconnaissables en cas de fuite dans un log.
--
-- Idempotent (`on conflict do nothing`) : rejouable sans erreur ni doublon.
-- Les dépendances sont respectées : `companies` avant `analyses` et `leads` (clé étrangère).
--
-- Usage : psql -v ON_ERROR_STOP=1 -q -f .github/sql/witness-data.sql
-- =============================================================================

-- 1. campaigns
insert into public.campaigns (id, name, naf_codes, departements, villes, effectif_min,
                              score_threshold, interval_minutes, active)
values ('00000000-0000-4000-8000-0000000000ff', 'TEMOIN (CI) — ne pas collecter',
        array['99.99Z'], array['000'], array['Témoin'], null, 7, 1440, false)
on conflict (id) do nothing;

-- 2. companies
insert into public.companies (siren, name, naf, address, city, postal_code, effectif,
                              website, website_source, campaign_id, raw)
values ('999999991', 'TEMOIN SARL (CI)', '99.99Z', '1 rue du Test', 'Témoinville', '00000',
        '00', null, 'introuvable',
        '00000000-0000-4000-8000-0000000000ff', '{"temoin": true}'::jsonb)
on conflict (siren) do nothing;

-- 3. analyses
insert into public.analyses (siren, http_status, https, has_viewport, copyright_year,
                             tech_hints, psi_mobile_score)
values ('999999991', 200, false, false, 2010, array['témoin'], 35)
on conflict do nothing;

-- 4. leads
insert into public.leads (siren, score, reasons, status, notes)
values ('999999991', 8, '["TEMOIN (CI)"]'::jsonb, 'nouveau', 'ligne témoin du job sql')
on conflict (siren) do nothing;

-- 5. runs
insert into public.runs (id, workflow, status, items_processed, details, campaign_id)
values ('00000000-0000-4000-8000-0000000000fe', 'TEMOIN (CI)', 'success', 1,
        '{"recuperees": 1, "ecartees": 0}'::jsonb,
        '00000000-0000-4000-8000-0000000000ff')
on conflict (id) do nothing;

-- 6. blocklist
insert into public.blocklist (siren, email, reason)
values ('999999991', 'temoin-ci@exemple.invalid', 'ligne témoin du job sql');
