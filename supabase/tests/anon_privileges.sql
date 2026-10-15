-- =============================================================================
-- Tests : `anon` ne détient AUCUN privilège sur les objets de `public`
--
-- LE CONTRÔLE, EN UNE PHRASE : sur un projet Supabase, tout objet neuf de `public`
-- naît avec `ALL` pour `anon` (relevé dans `pg_default_acl` le 2026-10-15, et reproduit
-- par .github/sql/roles.sql depuis). Le critère d'acceptation v1 « un accès anonyme ne
-- lit aucune donnée » repose donc sur DEUX mécanismes — la RLS et le `revoke` — et ce
-- fichier tient le second. La RLS, elle, est tenue par rls.sql.
--
-- POURQUOI UN INVENTAIRE DU CATALOGUE, ET NON SIX NOMS EN DUR : `rls.sql` vérifie les
-- six tables du produit, nommées une à une. Une table AJOUTÉE demain ne serait couverte
-- par rien — et l'écart est mesuré : sur une base « comme la CI » (sans les privilèges
-- par défaut de la plateforme) le problème n'existe même pas. Ce fichier parcourt donc
-- le catalogue, pour que l'oubli de demain soit rouge le jour où il est commis.
--
-- CE QU'IL NE COUVRE PAS, ET POURQUOI — un test doit dire ce qu'il laisse passer :
--   * les FONCTIONS : PostgreSQL accorde EXECUTE à PUBLIC par défaut, donc `anon` peut
--     exécuter `public.set_updated_at()` — sur la plateforme comme ici. C'est un défaut
--     de la plateforme, pas un oubli de migration ; le révoquer changerait l'exécution
--     des déclencheurs, ce qui est une décision, donc une migration nouvelle. Documenté
--     et mesuré plutôt que masqué.
--   * les privilèges PAR COLONNE (`attacl`) : aucun n'existe aujourd'hui.
--   * le SCHÉMA lui-même : `anon` a bien `USAGE` sur `public` (migration 1, et c'est
--     nécessaire à PostgREST) — ce n'est pas une donnée.
--
-- Exécution : psql -v ON_ERROR_STOP=1 -f supabase/tests/anon_privileges.sql
-- Sur le vrai projet : même commande avec la chaîne de connexion — c'est un contrôle de
-- catalogue, il ne dépend d'aucune donnée et n'écrit rien.
-- =============================================================================
\set ON_ERROR_STOP on

begin;

do $$
declare
  v_objets  int;
  v_fautifs text;
  v_lus     int;
begin
  ---------------------------------------------------------------------------
  -- 1. Contrôle POSITIF : l'inventaire voit bien des objets.
  --    Un parcours qui ne trouve rien passe sans rien prouver — piège déjà rencontré
  --    deux fois dans ce dépôt (une empreinte sur table vide ne prouve rien ; un test
  --    qui refusait pour la mauvaise raison non plus). On refuse de conclure à l'aveugle.
  ---------------------------------------------------------------------------
  select count(*) into v_objets
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relkind in ('r', 'p', 'v', 'm', 'f', 'S');

  if v_objets < 7 then
    raise exception 'ECHEC  inventaire suspect : % objet(s) dans public, attendu au moins 7 (6 tables + la vue campaigns_due) — le test serait aveugle', v_objets;
  end if;
  raise notice 'OK  inventaire : % objets de public inspectes', v_objets;

  ---------------------------------------------------------------------------
  -- 2. LA PROPRIÉTÉ : aucun privilège de `anon`, sur aucune table ni vue.
  --    SEPT privilèges, pas seulement SELECT : `anon` naît avec `arwdDxtm`, donc le
  --    droit d'écrire, de supprimer ou de tronquer serait tout aussi grave — et
  --    l'empreinte de schéma ne mesure, elle, que les quatre privilèges courants.
  ---------------------------------------------------------------------------
  select string_agg(format('%s(%s)=%s', c.relname, c.relkind, g.priv), ', ' order by c.relname, g.priv)
    into v_fautifs
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    cross join (values ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
                       ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')) as g(priv)
   where n.nspname = 'public'
     and c.relkind in ('r', 'p', 'v', 'm', 'f')
     and has_table_privilege('anon', c.oid, g.priv);

  if v_fautifs is not null then
    raise exception 'ECHEC  anon detient des privileges : % — une migration a cree un objet de public sans le revoquer (voir .github/sql/roles.sql et AGENTS.md section 4)', v_fautifs;
  end if;
  raise notice 'OK  anon ne detient aucun privilege sur les tables et vues de public';

  ---------------------------------------------------------------------------
  -- 3. Les SÉQUENCES : `has_table_privilege` ne les couvre pas, et une séquence
  --    lisible laisse deviner les volumes. Aucune n'existe aujourd'hui (les clés sont
  --    des uuid) : le contrôle est donc écrit pour le jour où il y en aura une.
  ---------------------------------------------------------------------------
  select string_agg(format('%s=%s', c.relname, g.priv), ', ' order by c.relname, g.priv)
    into v_fautifs
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    cross join (values ('SELECT'), ('UPDATE'), ('USAGE')) as g(priv)
   where n.nspname = 'public'
     and c.relkind = 'S'
     and has_sequence_privilege('anon', c.oid, g.priv);

  if v_fautifs is not null then
    raise exception 'ECHEC  anon detient des privileges sur une sequence : %', v_fautifs;
  end if;
  raise notice 'OK  anon ne detient aucun privilege sur les sequences de public';

  ---------------------------------------------------------------------------
  -- 4. Contrôles POSITIFS inverses : les rôles légitimes, eux, lisent.
  --    Sans eux, un `has_table_privilege` qui répondrait « false » à tout le monde
  --    passerait le contrôle 2 sans rien démontrer — le test serait tautologique.
  ---------------------------------------------------------------------------
  select count(*) into v_lus
    from (values ('campaigns'), ('companies'), ('analyses'), ('leads'),
                 ('runs'), ('blocklist'), ('campaigns_due')) as t(nom)
   where has_table_privilege('authenticated', 'public.' || t.nom, 'SELECT');

  if v_lus <> 7 then
    raise exception 'ECHEC  authenticated ne lit que % objet(s) sur 7 : le controle 2 ne prouve rien dans ces conditions', v_lus;
  end if;

  select count(*) into v_lus
    from (values ('campaigns'), ('companies'), ('analyses'), ('leads'),
                 ('runs'), ('blocklist'), ('campaigns_due')) as t(nom)
   where has_table_privilege('service_role', 'public.' || t.nom, 'SELECT');

  if v_lus <> 7 then
    raise exception 'ECHEC  service_role ne lit que % objet(s) sur 7 (WF1 serait bloquee)', v_lus;
  end if;
  raise notice 'OK  authenticated et service_role lisent les 7 objets attendus (controle 2 non tautologique)';

  raise notice '=== TESTS anon_privileges : PASSENT ===';
end
$$;

-- Lecture seule, mais on garde la forme des autres tests : rien ne survit.
rollback;
