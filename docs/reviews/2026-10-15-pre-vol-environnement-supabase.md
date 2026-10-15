# Pré-vol — environnement du projet Supabase réel (`rexnoeixlkedvdhzeoqk`)

> Rôle : **Reviewer** (`prompts/roles.md` §7) · Date : 2026-10-15 · Objet : ce que le projet réel
> porte **avant** sa première migration — et ce que la CI, elle, ne peut pas voir.
>
> Ce document n'est **pas** la vérification demandée par `S0-04` : celle-ci exige d'appliquer les
> migrations et de rejouer les tests **sur le projet**, et l'écriture est bloquée (voir les limites).
> C'est le **pré-vol** — et il a trouvé un écart réel entre la CI et la plateforme.

## Pourquoi ce document existe

`S0-04` demande de vérifier les migrations sur le vrai projet. Le jeton fourni est **en lecture
seule** (prouvé : `current_user = supabase_read_only_user`, `transaction_read_only = on`, **même avec
`read_only:false`** ; `create schema` → `ERROR 25006`), donc rien n'a été appliqué. La **lecture**,
elle, est acquise — et c'est elle qui a produit le constat ci-dessous.

## Relevé sur le vrai projet (lecture seule, API Management)

| Mesure | Valeur |
|---|---|
| Objets | **0 table**, **0 vue**, **aucun** schéma `supabase*` → projet **vierge** |
| Version | PostgreSQL **17.11** |
| Extensions | `pgcrypto`, `uuid-ossp`, `pg_stat_statements` |
| Fonctions d'auth | `auth.uid`, `auth.jwt`, `auth.role` présentes |
| `anon` / `authenticated` | `bypassrls=f`, `super=f`, `login=f`, `inherit=t` |
| `service_role` | **`bypassrls=t`** — l'hypothèse de `.github/sql/roles.sql` est **exacte** |
| Adhésions | `postgres` est membre de `anon`, `authenticated` **et** `service_role` |
| `public` — ACL | `USAGE` pour **PUBLIC**, `postgres`, `anon`, `authenticated`, `service_role` |
| `public` — **privilèges par défaut** | `arwdDxtm` (**ALL**) accordé à `anon`, `authenticated`, `service_role` sur les **tables** (`r`), **fonctions** (`f`) et **séquences** (`S`) — posé par `postgres` **et** par `supabase_admin` |
| `security_invoker` (PG ≥ 15) | disponible |
| Jeton fourni | `transaction_read_only = on` → lecture seule |

Deux pièges d'environnement classiques sont donc **écartés**, et c'est une bonne nouvelle : les
`set local role` des tests (`rls.sql`, `campaigns_due.sql`) fonctionneront sur le vrai projet, et
`service_role` y contourne bien la RLS comme le suppose la CI.

## Le constat : la CI ne reproduit pas les privilèges par défaut de la plateforme

Sur un projet Supabase, **tout objet neuf créé dans `public` reçoit `ALL` pour `anon`,
`authenticated` et `service_role`** — c'est ce que dit `pg_default_acl`, relevé ci-dessus. La CI,
elle, part d'un Postgres nu où `.github/sql/roles.sql` crée les rôles **sans** ces privilèges par
défaut.

Mesuré en A/B, deux bases, **mêmes migrations** (Postgres 16.15 jetable) : à gauche une base qui
reproduit la plateforme, à droite une base qui reproduit la CI. On y ajoute ensuite les objets d'une
migration **future** — une table et une vue neuves, **sans `revoke` explicite et sans RLS**, le cas
« on a oublié » :

| Objet | Base « comme le vrai projet » | Base « comme la CI » |
|---|---|---|
| Table neuve — `anon` **lit** | **`t`** | `f` |
| Table neuve — `anon` **écrit** | **`t`** | `f` |
| Vue neuve (`security_invoker`) — `anon` lit | **`t`** | `f` |
| Les 6 tables livrées — `anon` | `0` privilège | `0` privilège |
| Vue `campaigns_due` — `anon` | `f` | `f` |

Lecture du tableau : **nos deux migrations sont hors de cause** — elles révoquent explicitement
(`revoke all on all tables … from anon`, `revoke all on public.campaigns_due from anon`), et l'état
livré est identique dans les deux bases. Le problème est ailleurs : *un oubli futur serait vert en CI
et ouvert sur le vrai projet*. Le critère d'acceptation v1 « un accès anonyme ne lit aucune donnée »
reposerait alors sur **un seul** mécanisme (la RLS) là où la plateforme en laisse deux, et la CI ne
pourrait pas le dire.

## Correction proposée — une décision, pas un correctif d'office

1. **`.github/sql/roles.sql` reproduit les privilèges par défaut de Supabase** (`alter default
   privileges … grant all on tables/functions/sequences to anon, authenticated, service_role`). La
   CI verrait alors ce que la plateforme voit. Effet attendu : **aucun** changement d'état final,
   puisque les migrations existantes révoquent explicitement — l'empreinte de schéma devrait rester
   identique, ce qu'un run CI confirmerait ou infirmerait.
2. **Un test de catalogue** : « aucun objet de `public` n'est lisible par `anon` », écrit pour
   parcourir *tous* les objets et non les six connus. Il passerait aujourd'hui, et attraperait
   l'oubli de demain — en CI **et** sur le vrai projet.

Je ne l'ai **pas** implémenté : cela touche le modèle de la CI et le jeu de tests, donc la preuve qui
porte `S1-08`/`S1-09` en review. C'est un **ticket à décider**, pas une retouche à glisser dans une
PR de revue. Cette revue instruit, elle ne décrète pas.

## Limites

- **La vérification de `S0-04` n'est pas faite** : aucune migration appliquée, aucune suite lancée sur
  le vrai projet. `S0-04` reste ouvert, `S1-08` et `S1-09` restent `en review`.
- Relevé **non indépendant** : même session que l'auteur des livrables.
- L'A/B est fait sur **16.15**, le relevé sur **17.11**. Le mécanisme des privilèges par défaut ne
  change pas entre ces versions, mais l'A/B n'a pas été rejoué sur 17.11.
- Aucune mesure du comportement **en charge** sur le vrai projet (aucune donnée n'y existe).
