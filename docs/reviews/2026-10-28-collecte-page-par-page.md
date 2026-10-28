# La collecte, page par page : ce que la mesure impose, et ce qu'elle prouve (critères 2 à 6 de `S2-03`)

> Objet : les **critères 2 à 6 du ticket [`S2-03`](../sprint-02.md)** — le couple multi-pages survit à un
> refus, le `retry-after` est un plancher, la politesse ne baisse pas, le pire cas reste honnête, et la
> preuve est faite de bout en bout. Suite du
> [critère 1](2026-10-27-reprise-d-une-pagination-refusee.md) : le mécanisme du réessai d'item y était
> **mesuré** (relance de l'item entier depuis la page 1, pages acquises jetées).
> Date : **2026-10-28**.

## 1. Ce que la première mesure fermait — et pourquoi elle ne laissait qu'une voie

Le critère 1 avait établi trois choses, et chacune retire une option :

| Constat mesuré (2026-10-27) | Conséquence |
|---|---|
| Le réessai relance l'**item entier** depuis la page 1 | « reprendre à la page en échec » est impossible avec ce nœud |
| L'échec définitif **jette** les pages acquises | « sortir en `partial` avec ses pages » est impossible aussi |
| Le délai est **fixe** (5 s) et `retry-after` n'est pas lu | la seule patience réglable est le **nombre** de tentatives |

Reste la troisième voie du ticket — *réessayer en respectant `retry-after`*. La mesure de banc ci-dessous
(§ 2), puis la **lecture du code de n8n** (§ 3), montrent qu'elle ne peut pas être un réglage :
`waitBetweenTries` est **plafonné à 5 000 ms** dans `n8n-core`
(`Math.min(5000, Math.max(0, node.waitBetweenTries ?? 1000))`, image 2.43.5). Allonger l'attente est donc
impossible ; allonger la patience signifie **multiplier les tentatives**, chacune repayant la profondeur
du refus — c'est-à-dire **augmenter la pression sur une API qui vient de refuser**, ce que le critère 4
interdit.

## 2. Banc A/B : le même refus, l'ancien réglage et le « plus patient »

**Montage** : stub local (`node:http`) qui sert 5 pages (25/25/25/25/20 → 120 résultats) et refuse la
**page 3** (`429`, `retry-after: 4`) tant qu'une fenêtre n'est pas écoulée ; conteneur n8n jetable
(2.43.5) ; le nœud « Collecte API (S1-02) » **copié tel quel** depuis l'export livré — seules ses
`maxTries` / `waitBetweenTries` changent, et son `url` (seule déviation, écrite). Le journal du stub
horodate chaque requête.

| Variante (même fenêtre de refus : 25 s) | Requêtes reçues | Pages servies et **conservées** | Issue |
|---|---|---|---|
| **Ancien réglage** — `maxTries 3`, `waitBetweenTries 5 000` | **9** (pages 1-2 payées 3 fois + 3 refus) | **0** — l'item d'erreur remplace tout | `error`, couple perdu |
| **« plus patient »** — `maxTries 5`, `waitBetweenTries 15 000` | **14** | **5** (`1,2,3,4,5`, sans doublon) | `success` — mais réglage inopérant, voir § 3 |
| **« plus patient », fenêtre fermée pour de bon** | **15** (5 × pages 1-2 + 5 refus) | **0** | `error`, couple perdu |

Deux enseignements, et le second est le décisif :

1. La patience **fonctionne** quand la fenêtre est courte : 5 tentatives couvrent 33 s et récupèrent les
   5 pages là où 3 tentatives (18 s) échouaient.
2. Mais le délai observé reste **6,03 s**, y compris avec `waitBetweenTries = 15 000` : le réglage est
   **silencieusement plafonné**. Et quand la fenêtre ne se rouvre pas, la variante patiente paie **15
   requêtes pour zéro page** — **plus** de pression que l'ancien réglage pour le même résultat nul.

**Conclusion du banc** : « patience par le nombre de tentatives » est un **amplificateur**, pas une
correction. Il ne satisfait pas le critère 4 (pression) et ne satisfait le critère 2 que par chance
(fenêtre courte). La voie qui reste est un **changement de structure** : faire de la **page** l'unité de
collecte.

## 3. Pourquoi la page, et pas « le couple avec plus de patience » : le code, pas l'opinion

| Ce que la lecture du code de l'image `latest` (2.43.5) établit | Où |
|---|---|
| `waitBetweenTries` est **borné à 5 000 ms** — la valeur configurée au-delà est ignorée sans message | `n8n-core/dist/execution-engine/workflow-execute.js:955` (`Math.min(5000, …)`) |
| Le nœud `Wait` n'accepte **pas** l'unité `milliseconds` (unités : `seconds`, `minutes`, `hours`, `days`) | `n8n-nodes-base/.../Wait.node.js` (`validateWaitUnit`) — erreur levée **à l'exécution** |
| Le minuteur du nœud `Wait` peut rendre la main **avant** l'échéance demandée | mesuré, § 4 |
| Un `429` **n'arrive pas** avec ses en-têtes quand le nœud HTTP est en `continueRegularOutput` : l'item d'erreur porte `{message, name, code, status}` | mesuré, § 4 |

Ces quatre points dessinent la correction : elle ne peut pas tenir dans un réglage. Il faut **une
requête par item**, un **réessai de la seule page en échec**, un **délai lu dans `retry-after`** et une
**cadence vérifiée sur l'horloge**, pas sur un minuteur.

## 4. La correction, mesurée sur le même banc (stub, n8n jetable)

Le nœud HTTP ne pagine plus : `page = {{ $json.page }}`, une requête par item, `retryOnFail` **retiré**,
et la réponse demandée **complète** (`fullResponse`) avec `neverError` — c'est ce qui rend un `429`
**lisible** (`statusCode` + `headers`), là où l'item d'erreur ne portait aucun en-tête. Autour de lui, une
boucle « un couple à la fois, une page à la fois » (`Pour chaque couple`, `Accumuler la page`,
`Couple collecté ?`, `Réessai après refus ?`, `Rythme de la requête`, `Attendre encore ?`,
`Attente de cadence`, `Mémoriser le couple`, `Reste-t-il un couple ?`, `Pages collectées`), et **tout
l'aval de WF1 inchangé** — le filtrage reçoit exactement la forme d'avant (un item par page, dans l'ordre
des couples).

**Scénarios, journal du serveur à l'appui** (les nœuds de collecte sont ceux de l'export livré ; seuls
l'`url` et l'amont de campagne sont remplacés par un banc) :

| Scénario | Requêtes reçues | Écarts entre deux requêtes de la **même** page | Écarts de page à page | Pages conservées | Issue |
|---|---|---|---|---|---|
| **A — aucun refus** | **5** | — | **1,21 / 1,04 / 1,05 / 1,05 s** | 5 → **120 lignes** | `success`, 0 doublon |
| **B — page 3 refusée 25 s, `retry-after: 7`** | **8** (5 pages + 3 refus) | **8,05 / 8,05 / 8,14 s** | 1,15 / 1,07 / 1,06 / 1,04 s | 5 → **120 lignes** | `success`, 0 doublon |
| **C — page 3 refusée pour de bon, `retry-after: 4`** | **7** (2 pages + 5 refus) | **5,13 / 5,05 / 5,07 / 5,04 s** | 1,12 / 1,08 s | 0 | `error` **nommé** : `43.21A\|05 : HTTP 429 — 5 tentative(s) sur la page 3 … couple abandonné` |
| **D — deux couples du même NAF** | **10** (5 + 5 pages) | — | **1,05 à 1,12 s** (8 écarts) | 10 → **240 lignes** | `success`, 0 échec de rattachement |

Ce que ces quatre lignes établissent, une par une :

1. **Le refus ne coûte plus que la page en échec** : 8 requêtes pour 5 pages avec 3 refus, contre **9
   pour 0 page** à l'ancien réglage dans la même fenêtre de 25 s — **moins de pression ET le couple
   sauvé**.
2. **`retry-after` est réellement lu** : la même page est redemandée **8,05 s** après un
   `retry-after: 7`, **5,13 s** après un `retry-after: 4` — dans les deux cas **au-delà** de ce que
   l'API demande. Le plancher est observé, pas déduit.
3. **Le pire cas est honnête** : budget épuisé → `error`, message qui nomme le couple **et** la page,
   **aucune** ligne écrite, et les autres couples continuent (le filtrage de `S1-04`/`S2-02` n'a pas
   bougé).
4. **Deux couples du même NAF restent séparés** : 10 pages, 240 lignes, **aucune incohérence de
   rattachement** — la collecte par page ne rouvre pas le défaut B de `S2-02`.
5. **La cadence tient** : **aucun** écart inférieur à 1,04 s sur les quatre scénarios.

**Pourquoi la cadence est une garde horodatée et pas un `Wait`** : mesuré d'abord avec un simple nœud
`Wait` de 1 s, deux écarts sont descendus à **0,85 s et 0,52 s** — le minuteur du nœud rendait la main
**avant** l'échéance (474 ms pour 1 000 demandés, sur un autre passage). Une garantie « 1 req/s » ne peut
donc pas être publiée sur ce minuteur : `Rythme de la requête` recalcule l'attente depuis
l'**horodatage de la dernière requête**, `Attendre encore ?` revérifie après chaque réveil, et l'attente
d'un refus est une **échéance** (`retry-after + 1 s`) relue à chaque tour — une durée réappliquée à
chaque tour bouclait (mesuré, corrigé). Résultat : les huit écarts de page de D sont entre 1,05 et 1,12 s.

## 5. Preuve de bout en bout (`D-011` / `D-015`), sur l'API réelle et la base réelle

Deux exécutions réelles de WF1 sur le fichier **livré**, sur des couples réels, avec la ligne `runs`
**lue en base** après coup. Base relevée avant : `campaigns 0 / companies 0 / runs 0`.

| Preuve | Couple | `runs.status` | `runs.items_processed` | `runs.details` | Lignes écrites |
|---|---|---|---|---|---|
| **A — couple multi-pages** | `43.21A × 05` (36 résultats, **2 pages**) | **`success`** | **22** | `{recuperees: 36, ecartees: 14}` | **22** entreprises |
| **B — échec provoqué** | `43.21A × 99` (département invalide → `400`) | **`error`** | **0** | `{recuperees: 0, ecartees: 0}` | **0** |

Le message de B, verbatim : `1 couple(s) en echec — 43.21A|99 : HTTP 400 — refus définitif de l'API à la
page 1 : HTTP 400 — Au moins un paramètre « departement » est non valide…`. Il **nomme le couple** et
**cite l'API**.

La preuve A est **superposable** à celle de `S2-02` (même couple, mêmes 36 résultats, mêmes 22 lignes
retenues, mêmes 14 écartées) : la collecte a changé de structure **sans changer de résultat**.

**Base rendue à son état d'avant** : après nettoyage des lignes créées, `campaigns 0 / companies 0 /
runs 0` — identique au relevé d'entrée.

## 6. Politesse de crawl : le `git diff` des réglages

| Réglage de `S1-04` | Avant | Après | Verdict |
|---|---|---|---|
| Cadence entre requêtes | `requestInterval: 1000` (dans le nœud paginé) | **garde horodatée avant CHAQUE requête** (`Rythme de la requête` → `Attendre encore ?` → `Attente de cadence`) | **identique** en valeur ; **mesurée** et non supposée |
| `User-Agent` | `Prospection-ia/1.0 (n8n WF1 collecte)` | inchangé | identique |
| Plafond de pagination | `maxRequests: 100` | `MAX_PAGES = 100` dans `Accumuler la page` | **identique** |
| `timeout` | 10 000 ms | inchangé | identique |
| Réessai | `retryOnFail ×3` **sur l'item paginé** | retiré ; 5 essais **par page**, à `retry-after + 1 s` | **pression divisée par la profondeur du refus** |

Le seul réglage qui **disparaît** est `requestInterval`, et c'est parce que la pagination native
disparaît : la cadence est désormais tenue par une garde explicite, **plus stricte** que le minuteur
qu'elle remplace (aucun écart < 1,04 s mesuré, contre 0,52 s avec un simple `Wait`). **Aucun réglage ne
rend la collecte plus agressive** : 5 requêtes en succès, comme avant.

## 7. Ce que cette mesure n'établit pas

- **La fréquence réelle des refus** : le stub décide quand refuser ; l'API décide de son côté, et sa
  fenêtre est **partagée sur l'IP de sortie**. Ce qui est prouvé, c'est ce que WF1 fait **d'un** refus.
- **Les rafales longues** : `ATTENTE_MAX_MS = 60 s` et 5 essais par page sont des **choix**, écrits dans
  le code et ici. Au-delà, le couple est abandonné **nommé** — c'est un renoncement assumé, pas la preuve
  qu'il est optimal.
- **Le très gros couple** (`43.21A × 974`, 61 pages) : toujours non prouvé, pour la même raison qu'en
  `S2-02` (fenêtre de débit). La structure, elle, ne dépend pas du volume.
- **La stabilité de l'horloge du poste de mesure** : sur un passage, des `executionTime` **négatifs** et
  des réveils de `Wait` très en avance ont été observés dans le même run (Docker Desktop). Ces
  observations ne changent pas la correction (la garde horodatée est justement là pour ne pas dépendre
  d'un minuteur), mais elles ne sont **pas** attribuées : la cadence est re-mesurée à chaque banc, et le
  chiffre publié est celui du dernier banc complet.
