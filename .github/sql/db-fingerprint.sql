-- =============================================================================
-- Empreinte de la base : pour chaque table, le NOMBRE de lignes et une empreinte de
-- CONTENU (md5 des lignes triées).
--
-- Pourquoi le contenu et pas seulement le nombre de lignes : `truncate` change le
-- nombre, mais `update companies set email = null` ne le change pas et détruit quand
-- même de la donnée. La CI compare cette empreinte AVANT et APRÈS la réapplication des
-- migrations (.github/workflows/ci.yml) : c'est la comparaison qui prouve quelque chose,
-- pas l'exit code de `psql`.
--
-- `order by x::text` rend l'agrégat déterministe : sans tri, md5 change d'un appel à
-- l'autre et la comparaison deviendrait un tirage au sort.
--
-- La liste des tables est VOLONTAIREMENT figée (les six tables de données du produit) :
-- une migration qui AJOUTE une table est légitime et ne doit pas faire échouer la
-- comparaison — ce sont les données DÉJÀ LÀ qui ne doivent pas bouger. Ajouter une table
-- ici quand elle devient une table de données du produit est donc un geste conscient,
-- pas un automatisme (`pg_tables` rendrait toute migration additive suspecte).
--
-- Si une table a été supprimée par une migration, cette requête échoue (relation
-- inexistante) et la CI s'arrête : c'est voulu, c'est un signal lisible.
--
-- Usage : psql -v ON_ERROR_STOP=1 -q -tA -f .github/sql/db-fingerprint.sql
-- =============================================================================

select 'analyses' as objet, count(*) as lignes,
       coalesce(md5(string_agg(x::text, '|' order by x::text)), '-') as empreinte
  from public.analyses x
union all
select 'blocklist', count(*), coalesce(md5(string_agg(x::text, '|' order by x::text)), '-')
  from public.blocklist x
union all
select 'campaigns', count(*), coalesce(md5(string_agg(x::text, '|' order by x::text)), '-')
  from public.campaigns x
union all
select 'companies', count(*), coalesce(md5(string_agg(x::text, '|' order by x::text)), '-')
  from public.companies x
union all
select 'leads', count(*), coalesce(md5(string_agg(x::text, '|' order by x::text)), '-')
  from public.leads x
union all
select 'runs', count(*), coalesce(md5(string_agg(x::text, '|' order by x::text)), '-')
  from public.runs x
order by 1;
