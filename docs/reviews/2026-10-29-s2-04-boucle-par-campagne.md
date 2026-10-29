# S2-04 · WF1 — la boucle campagne par campagne : correctif écrit, prouvé en rouge puis en vert (2026-10-29)

> **Correction du [ticket S2-04](../sprint-02.md)**, critères 2 à 5, sur la mesure d'ouverture du
> [2026-10-29](2026-10-29-mesure-s2-04-lot-de-campagnes.md) et la décision **`D-019`** (boucle au
> `batchSize: 1`). Ce que cette revue apporte en plus de la décision : **le banc a prouvé que
> `batchSize: 1` seul ne suffit pas** — la campagne suivante du lot reste sans collecte ni clôture tant
> que le seau interne des couples n'accepte pas une nouvelle arrivée. Le correctif livré porte donc
> **deux paramètres**, et il est passé du **rouge** (défaut reproduit malgré le correctif partiel) **au
> vert** (trois scénarios, base réelle rendue 0/0/0 chaque fois).

## 1. Le correctif livré — deux paramètres, zéro logique réécrite

`git diff` de `n8n/workflows/wf1-collecte.json` : **deux blocs `parameters`, rien d'autre** (aucun
`jsCode`, aucun nœud créé ou supprimé) :

| Nœud | Paramètre | Avant | Après | Pourquoi |
|---|---|---|---|---|
| « Pour chaque campagne (S1-02) » | `batchSize` | 10 | **1** | **Un passage = une campagne = un run** (`D-019`) : la préparation (`runOnceForAllItems`) et les trois clôtures (`.first()`) deviennent exactes telles quelles |
| « Pour chaque couple (S2-03) » | `options.reset` | *(absent)* | **`={{ $json.couple === true }}`** | le seau interne du nœud doit **repousser le reset** pour le passage courant au moment où la campagne **suivante** ouvre le sien |

L'expression discriminate par la **donnée**, jamais par un index : les items frais de la préparation
portent le marqueur `couple === true` (lu tel quel par le bloc *If* « Des couples à collecter ? »),
les rendus de la boucle portent le marqueur `reste === true` (lu par « Reste-t-il un couple ? »). Le
`reset` évalué **vrai** sur un couple neuf rouvre le nœud comme un nouveau lot ; évalué **faux** sur
les rendus de la boucle, le seau interne continue de porter les couples **du même passage**.

### L'écart, écrit (le périmètre du ticket le prévoyait)

Le ticket interdit de toucher « la collecte par page de `S2-03` **sauf si la mesure l'exige — alors
écrit au ticket** ». C'est le cas, et c'est pourquoi il est écrit **deux fois** :

- le mécanisme a d'abord été **lu dans le code de n8n** (`DynamicSplitAndBatchNode`) : une fois le
  seau interne épuisé (`nodeContext.items` vide), une arrivée nouvelle prolonge le nœud en
  « terminé » sauf si `options.reset` est évalué vrai, qui reprend l'entrée comme un nouveau lot ;
- puis le banc l'a **prouvé en rouge** (§ 2) : `batchSize: 1` **sans** le `reset` reproduce **le défaut
  exact du ticket** — la seconde campagne reste `running`, jamais clôturée.

La décision **`D-019`** écrivait « la préparation et les clôtures exactes
**sans modification** » : le banc la corrige — exact pour la préparation et les clôtures, **insuffisant
pour l'aval du passage** — et cette rectification est écrite dans `D-019` même (addendum du même jour).

## 2. Le rouge — le défaut reproduit malgré le `batchSize: 1` (2026-10-29)

Le banc rejoué avec le **seul premier paramètre** (`batchSize: 1`, `options` du nœud S2-03 remis à
`{}`), scénario `donnees` (A en échec provoqué `43.21A × 99`, B à résultats réels `41.20A × 48` —
sondée `HTTP 200`, `total_results = 37`) :

| Ligne `runs` | Campagne | Statut | `started_at` | `finished_at` | `items_processed` |
|---|---|---|---|---|---|
| `1c335593` | A | **`error`** (message nommé, § 3) | 10:41:06.553853 | 10:41:30.203 | 0 |
| `e47030ba` | B | **`running`** | 10:41:30.790459 | **NULL** | 0 |

- `companies` écrites : **0** — la campagne B (37 résultats réels à la sonde) n'a **rien** collecté ;
- **Aucune** clôture pour B : le passage de B n'a jamais ouvert le seau des couples — l'erreur de A
  consomme le tour **rédigé pour le passage courant**, et l'arrivée de B sur un nœud déjà épuisé ne
  rouvre rien **sans `reset`** ;
- **c'est le défaut du ticket, inchangé** : l'invariant « un passage = une campagne » ne tient que si
  le seau interne des couples **accepte l'arrivée nouvelle**. Le `batchSize: 1` règle l'amont du lot,
  pas le tampon interne de la boucle S2-03.

## 3. Le vert — trois scénarios sur le fichier délivré (correctif complet, 2026-10-29)

Chaque scénario : jauge **0 / 0 / 0** avant, exécution réelle de la copie WF1 (instance n8n jetable,
seule déviation écrite : le déclencheur manuel, même nom/id/position), relève de base, **nettoyage
companies puis runs puis campagnes**, jauge **0 / 0 / 0** après.

### Scénario zero — deux campagnes sondées à 0 (`05.10Z × 2A`, `05.10Z × 973`)

| Ligne `runs` | Campagne | Statut | `started_at` | `finished_at` | `items` | détails |
|---|---|---|---|---|---|---|
| `ba5195a1` | A | **`success`** | 10:35:35.523721 | 10:35:49.47 | 0 | `{"ecartees":0,"recuperees":0}` |
| `322eca9d` | B | **`success`** | 10:35:49.309484 | 10:36:07.579 | 0 | `{"ecartees":0,"recuperees":0}` |

Deux passages **séquentiels** (`started_at` distincts — B suit A d'une seconde, `waitBetweenBatches`
l'espacant), **aucune** ligne `running`, `campaigns_due` vide, base rendue 0/0/0.

### Scénario echec — A en échec provoqué, B à 0 résultat

| Ligne `runs` | Campagne | Statut | `started_at` | `finished_at` | `items` | message |
|---|---|---|---|---|---|---|
| `9ad0ff66` | A | **`error`** | 10:36:52.41805 | 10:37:15.689 | 0 | `1 couple(s) en echec — 43.21A\|99 : HTTP 400 — refus définitif de l'API à la page 1 : HTTP 400 — Au moins un paramètre \`d…` |
| `003fd3e6` | B | **`success`** | 10:37:16.171465 | 10:37:23.391 | 0 | — |

L'**échec nommé de A ne fait pas tomber B** : ce sont deux passages, et B est créée, exécutée et
clôturée (message de A : le couple de sa campagne — `43.21A\|99`, la seule qu'elle porte — et le refus
de l'API). Base rendue 0/0/0.

### Scénario donnees — échec provoqué de A + B à résultats réels (`41.20A × 48`, `total_results = 37`)

| Ligne `runs` | Campagne | Statut | `started_at` | `finished_at` | `items` | détails |
|---|---|---|---|---|---|---|
| `01484912` (vert final) | A | **`error`** | 10:42:39.473908 | 10:42:51.861 | 0 | message nommé (`43.21A\|99`) |
| `6fb70ecd` (vert final) | B | **`success`** | 10:42:52.621772 | 10:42:56.646 | **20** | `{"ecartees":2,"recuperees":22}` |

- **`companies` écrites : 20, toutes rattachées à B** (relevé par la banc : aucun `campaign_id` de A,
  aucun orphelin) — le rattachement par la donnée de `S2-02` tient à travers la boucle : chaque
  passage écrit **dans sa propre campagne** ;
- les 37 résultats de la sonde → 22 récupérées / 2 écartées (les mêmes règles de filtrage du
  couple, **intactes**), 20 sièges uniques écrits ;
- base rendue **0 / 0 / 0**.

### Le compte complet des exécutions, dans l'ordre vécu

| # | Heure | Fichier du workflow | Scénario | Verdict |
|---|---|---|---|---|
| 1 | 10:34 | **délivré** (les deux paramètres) | donnees | **vert** — B `success`, 20 `companies` en B, 0/0/0 |
| 2 | 10:35 | délivré | zero | **vert** — les deux `success`, 0/0/0 |
| 3 | 10:36 | délivré | echec | **vert** — A `error` nommé, B `success`, 0/0/0 |
| 4 | 10:41 | **rouge** (`options` du nœud S2-03 mis à `{}`) | donnees | **rouge** — B `running` à jamais, **0** ligne `companies` |
| 5 | 10:42 | délivré (**restauré à l'identique**, diff revérifié) | donnees | **vert** — le tableau ci-dessus, retenu comme preuve principale |

Quatre exécutions vertes sur le fichier délivré, un rouge sur sa seule variante — le § 5 le
reformule précisément.

## 4. Les critères 2 à 5, un à un

| Critère | Verdict | Les chiffres |
|---|---|---|
| **2 — chaque campagne due du tick a sa ligne `runs`, créée puis clôturée** | ✅ | **trois verts** × 2 campagnes = 6 lignes, **toutes** clôturées (`success` ou `error` nommé), **aucune** `running`, les deux campagnes collectées quand elles avaient des couples |
| **3 — l'échec d'une campagne ne fait pas tomber l'autre** | ✅ | `echec` et `donnees` : A en `error` nommé (`finished_at` renseigné, message qui nomme son couple) → B créée, collectée, clôturée ; pas de « succès » muet (l'`error` de A est un message exploitable), pas de run orphelin |
| **4 — aucune régression de ce qui est prouvé** | ✅ | `git diff` : **2 blocs de paramètres, rien d'autre** — aucun `jsCode`, la politesse du crawl intacte (`waitBetweenBatches: 1000` entre campagnes **en plus** de la garde horodatée de la requête, `timeout` 10 s, UA, retry-after plancher de `S2-03` non touchés), le rattachement par la donnée de `S2-02` non touché (la clause `reset` de son nœud de boucle ne change **pas** sa sémantique intra-passage — les chiffres du `donnees` vert le prouvent : 22 pages récupérées sur 2 pages, écartées comptées, 20 lignes tous rattachées à B) |
| **5 — preuve de bout en bout sur deux campagnes, `companies` rattachées à **leur** campagne, base rendue à son état d'avant** | ✅ scénario `donnees` | deux campagnes dues créées par **un seul POST**, 20 lignes `companies` **toutes rattachées à B**, `campaigns_due` vidé, relevés avant **0/0/0** et après **0/0/0** chaque fois |

Reste **ouvert** (critère 6) : la relecture par un **Reviewer en contexte neuf** et la confirmation
par une session **indépendante**, comme les deux tickets précédents.

## 5. Le cycle de preuve, en toute honnêteté

1. **10:34 — vert** (`donnees`, correctif des deux paramètres en place) : 2 runs, B `success`
   `items_processed = 20`, 20 `companies` en B, base 0/0/0.
2. **10:41 — rouge** (colonne `reset` neutralisée, scénario `donnees`) : B `running`, jamais
   clôturée, **0** ligne `companies` — **défaut du ticket reproduit** (`§ 2`). *
3. **10:42 — vert final** (fichier délivré **restauré à l'identique**, diff revérifié) : le
   `donnees` du § 3, retenu comme preuve principale.

Le rouge ne prouve pas un bug **introduit** : il prouve que le **premier paramètre seul ne
suffisait pas** — la nécessité du `reset` est **prouvée par son absence**.

## 6. Rejouer la preuve

- **Pré-requis** : `.env` (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `N8N_ENCRYPTION_KEY`) ; docker ;
  **base vierge** (le banc refuse de démarrer sinon).
- **Le banc** : `.tmp-s204-banc.mjs`, **jetable selon la convention du dépôt** (non consigné) —
  reconstruit d'après le protocole de [la mesure](2026-10-29-mesure-s2-04-lot-de-campagnes.md), et
  étendu le 29/10 : **trois scénarios** (`zero`, `echec`, `donnees`), **sondage des couples à l'API
  publique avec reprise 429** (plancher 5 s, 6 essais — le refus intermittent de débit est mesuré),
  contrat de sonde par scénario (200 total 0 / 400 / 200 total > 0) vérifié **avant** le banc,
  volumes docker jetables (`s204-n8n-<scénario>`) supprimés après chaque passage, copie de WF1 avec
  **Manual Trigger** (même nom/id/position), credentials réimportés (`serviceRole`), lignes `runs`,
  `campaigns_due` et `companies` relevées avec le rattachement de campagne, **nettoyage
  companies → runs → campagnes** (les clés étrangères rendaient le seul cap runs/campagnes insuffisant
  une fois le `companies` peuplé — écart de la **mesure** d'ouverture, corrigé ici) et jauge finale
  0/0/0. Secrets jamais affichés, jamais écrits hors du dossier temporaire supprimé en fin de course.
- **Commandes** : `node .tmp-s204-banc.mjs zero` · `node .tmp-s204-banc.mjs echec` ·
  `node .tmp-s204-banc.mjs donnees` (traces de n8n : `.tmp-s204-banc-logs/run-<scénario>.log`).
- **Pour rejouer le rouge** : mettre `options: {}` sur « Pour chaque couple (S2-03) », jouer
  `donnees`, **restaurer** le fichier délivré avant tout autre usage ; le vert est à
  **re-confirmer** sur le fichier restauré (§ 5) — jamais le rouge laissé en place.
- **Pitfalls rencontrés** (espérés déjà connus, confirmés) : `-v` Windows exige un chemin `d:/…` en
  slash ; le volume doit appartenir à uid 1000 (`--user 0 … chown -R 1000:1000`) ; `N8N_USER_FOLDER=/data/n8n`
  indispensable ; `list:workflow` rend des **ids nanoid** — pas des UUID ; un `429` de l'API publique
  peut toucher la **sonde** sans aucun lien avec le workflow (l'espacement 1,1 s et la reprise 5 s
  l'ont traversé deux fois sur quatre scénarios).
