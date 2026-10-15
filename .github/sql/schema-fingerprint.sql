-- =============================================================================
-- Empreinte de SCHÉMA — les objets de `public`, par opposition aux DONNÉES
-- (.github/sql/db-fingerprint.sql). Les deux sont comparées avant/après la
-- réapplication des migrations par le job CI `sql`.
--
-- POURQUOI LES DEUX : une migration peut détruire un objet **sans toucher une seule
-- ligne**. Supprimer une policy RLS, un index, un `grant`, une contrainte, un défaut
-- de colonne ou l'option `security_invoker` d'une vue ne change AUCUNE ligne : la
-- comparaison de données reste verte et la régression passe. C'est la même leçon que
-- les tables vides (voir .github/sql/witness-data.sql) : une empreinte ne prouve que
-- ce qu'elle regarde.
--
-- CE QUI EST MESURÉ (schéma `public`, plus les extensions) :
--   * colonne          : nom, type, not null, défaut
--   * contrainte       : nom + définition (clé étrangère, check, unique, primary key)
--   * index            : nom + définition (prédicat partiel et ordre compris)
--   * declencheur      : nom + définition (dont la fonction appelée)
--   * rls              : RLS activée / forcée, table par table
--   * policy           : nom, commande, rôles, using, with check
--   * privilege        : ce que anon / authenticated / service_role peuvent RÉELLEMENT
--                        faire — mesuré par `has_table_privilege`, donc privilèges
--                        hérités et ceux accordés à PUBLIC compris
--   * vue              : options (`security_invoker` !), colonnes mesurées ci-dessus
--   * fonction         : security definer ou invoker, langage, volatilité, md5 du corps
--   * schema / sequence / extension / privilege_defaut
--
-- UTILISÉ DE DEUX FAÇONS, et les deux sont nécessaires (voir le job `sql`) :
--   1. avant/après la réapplication → ce qui a été modifié PAR la réapplication ;
--   2. comparé à `.github/sql/schema-baseline.txt` → ce qui a DISPARU, y compris par une
--      migration qui détruit inconditionnellement (un `drop index` rejoué à l'identique
--      ne se voit dans aucune comparaison avant/après : mesuré, il passait).
--
-- NON mesuré, volontairement : les privilèges PAR COLONNE (`attacl`), les tables hors
-- du schéma `public`, et la SÉMANTIQUE d'une migration idempotente mais fausse — ce
-- fichier compare des états, il ne relit pas le code.
--
-- L'ordre total (`order by` sur les quatre colonnes) est indispensable : sans tri, la
-- comparaison deviendrait un tirage au sort. Déterminisme vérifié en rejouant ce
-- fichier deux fois de suite sur la même base : sortie identique.
--
-- Usage : psql -v ON_ERROR_STOP=1 -q -tA -f .github/sql/schema-fingerprint.sql
-- =============================================================================

select 'colonne' as type, c.relname as objet, a.attname as nom,
       format_type(a.atttypid, a.atttypmod)
         || case when a.attnotnull then ' not null' else '' end
         || coalesce(' default ' || pg_get_expr(d.adbin, d.adrelid), '') as detail
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  join pg_attribute a on a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
  left join pg_attrdef d on d.adrelid = c.oid and d.adnum = a.attnum
 where n.nspname = 'public' and c.relkind in ('r', 'p', 'v', 'm')
union all
select 'contrainte', c.relname, con.conname, pg_get_constraintdef(con.oid)
  from pg_constraint con
  join pg_class c on c.oid = con.conrelid
  join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public'
union all
select 'index', c.relname, i.relname, pg_get_indexdef(x.indexrelid)
  from pg_index x
  join pg_class i on i.oid = x.indexrelid
  join pg_class c on c.oid = x.indrelid
  join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public'
union all
select 'declencheur', c.relname, t.tgname, pg_get_triggerdef(t.oid)
  from pg_trigger t
  join pg_class c on c.oid = t.tgrelid
  join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public' and not t.tgisinternal
union all
select 'rls', c.relname, '-',
       'activee=' || c.relrowsecurity || ' forcee=' || c.relforcerowsecurity
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public' and c.relkind in ('r', 'p')
union all
select 'policy', p.tablename, p.policyname,
       p.cmd
         || ' roles=' || coalesce(
              array_to_string(array(select unnest(p.roles::text[]) order by 1), ','), '-')
         || ' using=' || coalesce(p.qual, '-')
         || ' withcheck=' || coalesce(p.with_check, '-')
  from pg_policies p
 where p.schemaname = 'public'
union all
select 'privilege', c.relname, r.rolname, g.priv
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  cross join (values ('anon'), ('authenticated'), ('service_role')) as r(rolname)
  cross join (values ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE')) as g(priv)
 where n.nspname = 'public'
   and c.relkind in ('r', 'p', 'v', 'm')
   and has_table_privilege(r.rolname, c.oid, g.priv)
union all
select 'vue', c.relname, 'options', coalesce(array_to_string(c.reloptions, ','), '-')
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public' and c.relkind in ('v', 'm')
union all
select 'fonction', p.proname, pg_get_function_identity_arguments(p.oid),
       case when p.prosecdef then 'security definer' else 'security invoker' end
         || ' langue=' || l.lanname
         || ' volatilite=' || p.provolatile::text
         || ' corps_md5=' || md5(p.prosrc)
  from pg_proc p
  join pg_language l on l.oid = p.prolang
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
union all
select 'schema', n.nspname, '-', 'proprietaire=' || pg_get_userbyid(n.nspowner)
  from pg_namespace n
 where n.nspname = 'public'
union all
select 'sequence', c.relname, '-', 'proprietaire=' || pg_get_userbyid(c.relowner)
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public' and c.relkind = 'S'
union all
-- Version d'extension NON mesurée : elle change avec l'image Postgres, pas avec nos
-- migrations. Ce qui doit être détecté, c'est une extension qui DISPARAÎT.
select 'extension', e.extname, '-', '-'
  from pg_extension e
union all
select 'privilege_defaut', coalesce(n.nspname, '-'), coalesce(r.rolname, 'PUBLIC'),
       coalesce(d.defaclobjtype::text, '-') || ' ' || array_to_string(d.defaclacl::text[], ',')
  from pg_default_acl d
  left join pg_namespace n on n.oid = d.defaclnamespace
  left join pg_roles r on r.oid = d.defaclrole
order by 1, 2, 3, 4;
