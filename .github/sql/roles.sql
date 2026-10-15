-- =============================================================================
-- Rôles que Supabase fournit déjà, et que Postgres « nu » n'a pas.
--
-- Utilité : rejouer les migrations et supabase/tests/rls.sql sur une image
-- postgres officielle (CI, machine de dev sans projet Supabase).
-- Sur un vrai projet Supabase, ce fichier ne sert PAS et n'est pas une migration :
-- il ne doit donc pas être placé dans supabase/migrations/.
-- =============================================================================

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    execute 'create role anon nologin noinherit';
  end if;

  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    execute 'create role authenticated nologin noinherit';
  end if;

  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    execute 'create role service_role nologin noinherit';
  end if;
end
$$;

-- Dans Supabase, service_role porte BYPASSRLS : c'est ce qui permet à n8n d'écrire
-- en contournant la RLS. On reproduit l'attribut pour que les tests soient fidèles.
alter role service_role bypassrls;

-- -----------------------------------------------------------------------------
-- Privilèges PAR DÉFAUT de la plateforme — mesurés sur un vrai projet, pas supposés.
--
-- Sur un projet Supabase, `pg_default_acl` porte « ALL pour anon, authenticated et
-- service_role » sur les tables, fonctions et séquences de `public` (relevé le
-- 2026-10-15 : `arwdDxtm` pour les trois rôles, posé par `postgres` ET par
-- `supabase_admin`). Conséquence : TOUT objet neuf de `public` naît lisible et
-- inscriptible par `anon` — vue comprise.
--
-- Sans cette reproduction, la CI mentait par omission, et c'était mesurable : une table
-- et une vue neuves, sans `revoke` ni RLS, étaient lisibles par `anon` sur une base
-- « comme Supabase » et INVISIBLES sur une base « comme la CI ». Nos migrations révoquent
-- explicitement, donc l'état livré est sain dans les deux cas — mais un oubli FUTUR aurait
-- été vert en CI et ouvert en production. Détail et A/B :
-- docs/reviews/2026-10-15-pre-vol-environnement-supabase.md.
--
-- L'EFFET est reproduit, pas la ligne : `supabase_admin` n'existe pas ici, et
-- `pg_default_acl` ne range qu'une entrée par (rôle, schéma, type d'objet) — celle que la
-- migration 1 complète de ses propres `grant`. C'est pourquoi
-- `.github/sql/schema-baseline.txt` est régénéré dans la même PR que ce bloc.
--
-- Corollaire, et c'est tout l'intérêt : sur cette base comme sur la plateforme, une
-- migration qui crée un objet de `public` doit RÉVOQUER `anon` explicitement, et
-- `supabase/tests/anon_privileges.sql` le vérifie objet par objet.
-- -----------------------------------------------------------------------------
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;

-- L'utilisateur de connexion doit pouvoir endosser ces rôles pour les tests
-- (équivalent du rôle « postgres » administrateur de Supabase).
grant anon to current_user;
grant authenticated to current_user;
grant service_role to current_user;
