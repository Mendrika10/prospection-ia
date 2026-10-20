# ADR 0007 — WF1 écrit les entreprises par upsert PostgREST (`on_conflict=siren`), pas par une fonction SQL

**Statut** : accepté · **Date** : 2026-10-20 · **Décideurs** : Architecte (celle-ci) · arbitrage PO dans
[D-009](../product-decisions.md) · implémentation : `S1-03`

## Contexte

`S1-02` (PR #25) a révélé par preuve réelle que le nœud Supabase de n8n poste le lot **en un seul
POST atomique** et qu'avec l'`insert` simple : **tout** doublon SIREN fait échouer le lot au
complet, un lot mixte (nouveaux + existants) échoue au complet, et l'échec ressort comme **UN**
item d'erreur. Le code du nœud dans l'image n8n en place (vérifié le 2026-10-20, extraction
`docker create` + `docker cp`) n'expose que `create/delete/get/getAll/update` — `grep -icE
'upsert|on_conflict|merge-duplicates'` → **0** : l'upsert est *impossible par le nœud*. Or RF-05
exige « alimente `companies` sans doublon » : relancer une collecte de campagne ne doit ni
dupliquer, ni échouer, ni écraser les champs enrichis (`website`, `email`, `phone`, `website_source`).

## Décision

WF1 écrit les entreprises en **un seul POST PostgREST par lot** (`S1-02` l'a déjà prouvé : un POST
dans un seul appel réseau), contre `POST {SUPABASE_URL}/rest/v1/companies?on_conflict=siren` avec
l'en-tête `Prefer: resolution=merge-duplicates` — la sémantique PostgreSQL « ON CONFLICT DO UPDATE »
native du stock :

1. **Le nœud est un `httpRequest`**, pas le nœud Supabase. La clé de `service_role` est portée par le
   **credential n8n déjà en place** (`supabaseApi` : host + service_role) référencé dans le JSON
   exporté par `id`/`name` uniquement — aucune clé dans le dépôt (règle « aucun secret dans le
   versionné »). **Mesure d'authentification (2026-10-20, projet réel)** : la passerelle PostgREST
   du projet exige **les deux en-têtes** — `Authorization: Bearer …` seul renvoie 401 « No API key
   found in request », `apikey` seul renvoie 401 « permission denied for role anon » — c'est le
   type **prédéfini `supabaseApi`** du nœud HTTP qui porte les deux depuis le même secret (vérifié
   dans le code n8n en place, `SupabaseApi.credentials.js` l. 28-33). Le rallongement
   « httpHeaderAuth » unique imaginé au départ est **impossible** à faire poser ces deux en-têtes.
2. **Un item = un lot** construit et **dédupliqué par SIREN dans un Code node** (sans réseau —
   AGENTS.md §10 : le JsTaskRunner n'a ni `fetch` ni `node:http`), **avant** tout POST. La garde
   PostgREST « ON CONFLICT DO UPDATE command cannot affect row a second time » ne doit jamais être
   touchée : deux fois la même clé dans un seul POST est une erreur évitable en amont, pas une
   erreur à gérer en aval. Arbitrage PO : le **premier** item gagne (D-010).
3. **Le payload d'upsert ne porte pas `campaign_id`** (D-009) : la ligne garde la campagne qui l'a
   créée ; il ne porte jamais les colonnes enrichies (`website`, `email`, `phone`, `website_source`) :
   elles ne sont **pas envoyées**, plutôt que « envoyées puis écrasées par `null` ».
   **Précision de conséquence (2026-10-20)** : omettre la colonne du payload fait que une ligne
   toute nouvelle serait écrite **sans propriétaire** (PostgREST n'insère que les colonnes envoyées).
   L'attribution du propriétaire passe donc par une **passe distincte**, après le POST : un
   `PATCH /rest/v1/companies?campaign_id=is.null&siren=in.(...)` (limité aux SIREN du lot), qui
   n'attribue **que** les lignes fraîches — un re-passage ne déplace jamais le propriétaire d'une
   ligne déjà attribuée. C'est un complément, pas une exception : le payload d'upsert reste sans
   `campaign_id`, et la passe ne touche aucun autre champ.
4. Les écritures en échec suivent la **sémantique D-002/§5** : un échec de lot ressort comme UN item
   en échec (le lot est atomique : rien n'est écrit), la conciliation compte les lignes *réellement*
   écrites et le run passe en `partial`.

## Options écartées

- **`update` puis `create` en cascade (tout par le nœud Supabase)** : deux requêtes, un run *course*
  possible entre deux ticks de campagne, pas d'atomicité du lot — un dédoublonnage imparfait entre
  les deux passes.
- **Fonction SQL `on conflict` appelée par RPC (`supabase.rpc`)** : fiable, mais elle met du SQL
  applicatif dans le nœud (périmètre Backend dans un ticket Automation), sort le chemin d'écriture
  du reste du workflow et fait de la migration une dépendance du workflow.
- **Faire l'upsert dans le Code node** : impossible — le JsTaskRunner n'a ni `fetch` ni `node:http`
  (AGENTS.md §10, mesuré le 2026-10-16).

## Conséquences / coût

- Le POST du lot passe par un **credential d'en-tête** : sur les instances n8n déployées, il faut
  créer le credential une fois (le JSON exporté le référence par `id`/`name`) — c'est le même
  réflexe que le credential Supabase de WF1 aujourd'hui.
- La réponse du POST est le **lot renvoyé** (`Prefer: return=representation`) pour compter les
  lignes réellement écrites — un seul serveur de vérité sur le compte, pas une recréation
  logicielle.
- Le POST est atomique : **rien** n'est écrit d'un lot si un POST échoue. Un échec de lot à moitié
  écrit n'existe plus. La conciliation S1-02 reste vraie.
- Le critère « les colonnes enrichies ne sont plus jamais envoyées » est vérifiable dans le JSON
  exporté (et non plus seulement dans une exécution) — un contenu du payload est audit statique.

## Ce qui changerait l'avis

Une future version du nœud Supabase n8n qui exposerait l'option `on_conflict`/`merge-duplicates`
rendrait l'HTTP Request inutile pour l'écriture en lot : on rebrancherait alors le nœud natif —
l'ADR se casse sur cette construction, pas sur le besoin.
