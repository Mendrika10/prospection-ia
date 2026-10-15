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

-- L'utilisateur de connexion doit pouvoir endosser ces rôles pour les tests
-- (équivalent du rôle « postgres » administrateur de Supabase).
grant anon to current_user;
grant authenticated to current_user;
grant service_role to current_user;
