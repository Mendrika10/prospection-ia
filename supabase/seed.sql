-- =============================================================================
-- Seed de développement (local uniquement, jamais en prod)
-- Usage : supabase db reset  (ou psql -f supabase/seed.sql)
-- =============================================================================

-- Campagne d'exemple, DÉSACTIVÉE par défaut : l'activer explicitement pour
-- déclencher WF1 (évite de lancer une collecte involontaire).
--
-- ⚠️ Format des codes NAF : APE **pointé** (43.21A), pas le format INSEE compact
-- (4321A). L'API Recherche d'entreprises rejette le format compact en HTTP 400
-- (vérifié le 2026-10-15) — voir AGENTS.md §10.
insert into public.campaigns (name, naf_codes, departements, villes, effectif_min, score_threshold, cron, active)
values (
  'Exemple - artisans du bâtiment 974',
  array['43.99C', '43.21A'],
  array['974'],
  '{}',
  1,
  7,
  '0 6 * * *',
  false
)
on conflict do nothing;

-- Trace d'exécution de test, utile pour vérifier la page /runs avant la mise en route de n8n
insert into public.runs (workflow, started_at, finished_at, status, items_processed)
values ('seed', now(), now(), 'success', 0);
