# S2-04 · WF1 — un lot de campagnes n'est pas traité campagne par campagne : la mesure du mécanisme (2026-10-29)

> **Mesure d'ouverture** du [ticket S2-04](../sprint-02.md), critère 1 (*« le mécanisme est mesuré avant
> toute correction »*). Défaut constaté **trois fois séparément** (26/10 via `S2-01`, 28/10 pendant la
> preuve de `S2-03`, confirmé par la relecture indépendante). Aucune stratégie de correction n'est
> retenue ici — c'est la mesure qui la désignera.

## 1. L'exécution que la mesure reproduit

Deux campagnes actives, **dues dans le même tick** — créées par un **seul POST REST** (intervalle 1 440 min,
comme la cadence par défaut), lot de
**deux items** remis à WF1. Base Supabase **réelle** ; instance n8n **jetable** (volume docker,
`docker.n8n.io/n8nio/n8n:latest`, `N8N_USER_FOLDER=/data/n8n`, `N8N_ENCRYPTION_KEY` du `.env` jamais
affichée) ; copie de `wf1-collecte.json` importée avec **une seule déviation, écrite** : le Schedule
Trigger remplacé par un Manual Trigger du **même nom, même id, même position** (piège `AGENTS.md`
§10 : un déclencheur CRON refuse `n8n execute`). `wf1-collecte.json` de production **inchangé**.

Deux scénarios :

| Scénario | Campagne A | Campagne B | Ce qu'il sourdit |
|---|---|---|---|
| **zero** | `05.10Z × 2A` | `05.10Z × 973` | les deux sondues à `total_results = 0` (API publique) : aucune écriture, aucune erreur API |
| **echec** | `43.21A × 99` (département invalide, banc `S2-03`) | `05.10Z × 2A` | l'échec **provoqué** de A, et le sort de B |

Chaque exécution : jauge avant (`campaigns / companies / runs = 0 / 0 / 0` — le harnais refuse de
démarrer autrement) → création des deux campagnes → exécution de la copie WF1 → relève de base →
**nettoyage** (runs puis campagnes, comptes relevés **0 / 0 / 0** après chaque mesure).

## 2. Les relevés — trois reproductions, un seul motif

| Scénario | lignes `runs` créées | `started_at` | Campagne A | Campagne B |
|---|---|---|---|---|
| zero (1re) | **2** | **identiques à la microseconde** — `2026-10-29T08:40:25.338184+00:00` ×2 | `success`, `finished_at` 08:40:26.749, `items_processed = 0` | **`running`**, `finished_at` NULL, `items_processed = 0` |
| echec | **2** | **identiques à la microseconde** — `2026-10-29T08:42:52.790766+00:00` ×2 | **`error`**, `finished_at` 08:43:05.438, `items_processed = 0` | **`running`**, `finished_at` NULL, `items_processed = 0` |
| zero (reprise pour la trace) | **2** | **identiques à la microseconde** — `2026-10-29T08:44:39.424098+00:00` ×2 | `success`, 08:44:40.853, `items_processed = 0` | **`running`**, `finished_at` NULL |

**La campagne B n'est jamais clôturée, dans aucun scénario.** Même quand A échoue en `error` nommé
(l'exécution n8n elle-même passe en `success` — l'échec de A **ne fait pas tomber** l'exécution), la
ligne de B reste `running`.

## 3. Le « pourquoi » — la trace de clôture ne connaît qu'un seul run

Les traces d'exécution (§ 6) montrent, **dans les deux scénarios** :

- la sortie de la boucle (`Pour chaque campagne (S1-02)`, `batchSize = 10`) emet **les deux items** vers
  la branche de clôture : `Run démarré (campagne)` a bien créé **deux** lignes `runs` (les relevés) ;
- mais la proposition de clôture n'emporte qu'**un seul** id de run, celui de la **première** campagne du
  lot — l'expansion dans les sorties de clôture donne **un seul id** dans les deux traces :
  `d5c169be…` (zero, run de A) et `d23835f7…` (echec, run de A). C'est le code du workflow :
  `id = eq {{ $json.run_id ?? $('Run démarré (campagne)').first().json.id }}` — sans `run_id` explicite,
  **`.first()` désigne toujours le run de la première campagne**, quelle que soit l'item clôturée ;
- l'item de B passe par la branche de clôture **sans jamais être adressé** : sa ligne survit en
  `running` pour toujours.

**Le lot n'est pas traité campagne par campagne : une seule ligne de run porte les clôtures.** Les deux
items arrivent dans la branche de clôture, mais chaque clôture adresse **le même run** — celui de la
première campagne du lot. L'autre ligne n'a jamais de correspondance.

## 4. L'effet en aval — `campaigns_due` compte la ligne fauvée

Après chaque exécution, la vue [`campaigns_due`](../../supabase/migrations/20261015000004_campaigns_due.sql)
renvoie **0 campagnes dues** : `dernier_run = max(runs.started_at)` **tous statuts confondus**
(commentaire de la vue : *« un run en cours empêche la relance … conséquence assumée, ADR 0006 »*).

- Campagne **A** : ledit « dernier passage » est cohérent — elle vient de tourner.
- Campagne **B** : le `dernier_run` est **la ligne elle-même restée `running`** — qu'elle n'a
  **jamais eu** comme exécution valable. Résultat : **24 h au moins sans collecte** (son
  `interval_minutes` = 1 440), la ligne fautive n'étant clôturée **jamais** : la campagne est
  **affamée**.

## 5. Ce que la mesure établit (et ce qu'elle n'établit pas)

**Établi** : le défaut est attribuable au **traitement du lot en une seule exécution de `runs`** dans
WF1 — un lot de N campagnes dues crée **N** lignes `runs` (deux identiques `started_at`) et **une seule**
est clôturée ; l'échec d'une campagne **ne change pas** le sort des autres ; `campaigns_due` raye la
campagne B de tous les prochains ticks ; les trois reproductions sont **distinctes** (2 scénarios ×
2 moments, plus la trace à l'appui, base chaque fois **0 / 0 / 0** avant et après).

**Non établi ici** : les pistes de correction (boucle par campagne, sous‑workflow par campagne, un run
par élément du lot) — **aucune n'est retenue à ce stade**, à instruire sur ces chiffres, comme le
demande `D-016` ; ni ce que devient la ligne `running` dans le temps (elle est jugée orpheline par le
code — personne ne la clôture jamais).

## 6. Rejouer la mesure

- **Pré-requis** : `.env` (clés `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `N8N_ENCRYPTION_KEY`) ;
  docker ; **base vierge** (le harnais refuse de démarrer sinon).
- **Le harnais** : `.tmp-s204-mesure.mjs`, **jetable selon la convention du dépôt** (non consigné) —
  son protocole est intégralement décrit ici : (1) jauge avant 0/0/0 ; (2) couples **sondués à l'API
  publique** (User-Agent n8n WF1, 1,1 s entre sondes) — scénario `zero`, ou échec provoqué `43.21A×99`
  + sonde B — scénario `echec` ; (3) création des **deux** campagnes en un POST ; (4) volume docker +
  copie de WF1 avec **Manual Trigger** (même nom/id/position), credential `Supabase service_role (WF1)`
réimporté (host + `serviceRole`) ; (5) `n8n import:credentials` puis `import:workflow` puis
`n8n execute --id=<id du workflow>` — les traces d'exécution (`run-zero.log`, `run-echec.log`) sont
écrites au dossier d'import ; (6)
  relève `runs` (id, `started_at`, `finished_at`, `status`, `items_processed`, campagnes rattachées),
  `campaigns_due` ; (7) nettoyage : DELETE `runs` puis `campaigns` des deux campagnes, comptes 0/0/0.
- **Commandes** : `node .tmp-s204-mesure.mjs` (scénario zero) · `node .tmp-s204-mesure.mjs echec`
  (échec provoqué). Le `n8n list:workflow` de cette version de l'image renvoie des **ids nanoid**
  (`4MEfhzNApVq1seJZ|WF1 - Collecte`), pas des UUIDs — adapter le reconnaisseur d'id.
- **Pitfalls rencontrés et documentés** : `-v` Windows exige un chemin `d:/…` en slash ; le volume
  doit appartenir à uid 1000 de l'image (**`docker run --user 0 … chown -R 1000:1000 /data/n8n`** avant
  tout usage, sinon `EACCES mkdir '/data/n8n/.n8n'`) ; `N8N_USER_FOLDER=/data/n8n` indispensable sinon
  les migrations repartent de zéro à chaque commande.
