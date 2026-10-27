# Défaut B — le rattachement des pages par la donnée (S2-02)

> Objet : le ticket **`S2-02`** (« rattacher chaque page au bon couple, sans index implicite »). Ce
> document instruit **pourquoi** le rattachement de `S1-04` ne pouvait pas tenir, ce qui peut
> réellement porter la clé d'un couple, et ce que la preuve a pu mesurer — y compris ce qui l'a
> **bloquée**. Décision associée : **`D-017`**.
> Date : **2026-10-27**. Complète
> [`2026-10-26-execution-reelle-wf1-api-publique.md`](2026-10-26-execution-reelle-wf1-api-publique.md)
> § « Défaut B », qui reste le relevé où le défaut a été vu pour la première fois.

## 1. Le défaut, reproduit de zéro

Banc jetable : un **stub local** qui répond, dans chaque page, le couple **réellement demandé**
(`echo_demande`) — la seule source de vérité de l'appartenance — et deux mini-workflows contenant
**le nœud HTTP de WF1 copié tel quel** (mêmes paramètres, même pagination, même `timeout 10 s`, même
`retryOnFail ×3`), seule l'URL change. Couples servis : `43.21A|974` sur **3 pages** (50 résultats),
`41.20A|15` sur **1 page** (10).

Deux lectures, **la même exécution** :

| Item | Ce que `$input.all()` donne au Code node suivant | Ce que le nœud a **rangé** (`$('collecte').all()`) | Page réelle |
|---|---|---|---|
| 0 | `pairedItem.item = 0` | `0` | page 1 du couple 1 |
| 1 | `pairedItem.item = 1` | `0` | page 2 du couple 1 |
| 2 | `pairedItem.item = 2` | `0` | page 3 du couple 1 |
| 3 | `pairedItem.item = 3` | `1` | page 1 du couple 2 |

**Le nœud range l'index de l'item d'ENTRÉE ; ce que le nœud suivant LIT est l'index de SORTIE.**
C'est écrit dans le code de l'image, et c'est cohérent avec la mesure : `pairedItem: { item: itemIndex }`
où `itemIndex` est l'index de la boucle `for (let itemIndex = 0; itemIndex < items.length; itemIndex++)`
de `n8n-nodes-base/dist/nodes/HttpRequest/V3/HttpRequestV3.node.js` (branche JSON et branche d'erreur).
Le nœud n'est donc pas fautif : **l'appartenance traverse le nœud, puis est réécrite** pour un nœud
qui rend plus d'items qu'il n'en reçoit.

Conséquence pour le rattachement de `S1-04` (« `pairedItem.item` **est** l'index du couple ») : il ne
tient que si **chaque couple tient sur une page**. Au-delà — et c'est le cas normal — la page 2 du
couple 1 est lue comme le couple 2 (`41.20A|15`), la page 3 est hors bornes, et la page 1 du couple 2
aussi : la collecte est **abandonnée** (« *N page(s) sans couple rattachable* »), exactement ce que le
run 3 du 26/10 avait produit (60 pages). Le défaut est donc **bloquant**, pas cosmétique : une
campagne multi-pages ne peut pas être collectée.

## 2. Ce qui NE PEUT PAS porter la clé — deux voies fermées, mesurées

Le ticket demande que « la clé soit portée par la donnée ». La première question est donc : *le nœud
HTTP peut-il la transporter ?* **Non**, et c'est mesuré deux fois :

1. **`options.response.response.outputPropertyName`** (le seul champ de sortie du nœud) **n'existe
   que pour les réponses `text` et `file`** — la branche JSON ne le lit pas — **et il est lu une
   seule fois, sur l'item 0** : `getNodeParameter('options.response.response.outputPropertyName', 0,
   'data')`. Mesuré : renseigné par expression (`'cle_' + naf + '_' + departement'`), les items
   ressortent avec les clés de l'API (`results`, `total_results`, …) — aucune clé injectée, et une
   clé unique pour tous les couples de toute façon.
2. **L'API n'écho pas la requête.** Clés de premier niveau mesurées : `results`, `total_results`,
   `page`, `per_page`, `total_pages`. Rien du couple demandé.

Et **le couple n'est pas lisible dans la réponse** non plus : `matching_etablissements` (l'établissement
qui a fait entrer l'entreprise dans les résultats) **n'a pas de champ `departement`** — mesuré sur la
page 1 de `43.21A × 974` : les 25 résultats ont un `matching_etablissements`, **aucun** n'expose de
`departement` (le `code_postal` est là, mais en tirer un département est faux pour la Corse et
l'outre-mer, et absent quand l'entreprise a été retenue sur son siège). Seul le **siège** porte un
`departement` — et c'est précisément ce que la règle d'ADR 0005 rejette comme preuve d'appartenance,
puisque le filtre de l'API porte sur les **établissements**.

**Conséquence, et c'est le cœur de la décision** : pour deux couples qui partagent un code NAF
(`43.21A × 974` et `43.21A × 15`), **aucune donnée d'une page ne dit à quel couple elle appartient**.
Ce qui les sépare est **structurel** : une page `page = 1` ouvre une nouvelle série, et les séries
suivent **l'ordre des couples** de « Préparation de collecte ».

## 3. La mesure que `D-016` demandait — et qui explique l'échec de la preuve

Les six exécutions de WF1 lancées pour la preuve ont **toutes** échoué, en `error`, avec la signature
déjà connue :

```json
{"status":"error","items_processed":0,
 "error":"1 couple(s) en echec — 43.21A|974 : timeout of 10000ms exceeded — ECONNABORTED",
 "details":{"recuperees":0,"ecartees":0,"bandes_appliquees":[]}}
```

40,1 s = **3 × 10 s + 2 × 5 s** (trois tentatives, deux attentes de 5 s) : la collecte n'a reçu
**aucune page**. Le relevé simultané — celui que `D-016` a écrit comme condition de sa propre
révision — donne la cause :

| Instrument (même conteneur, même minute) | Ce qu'il voit |
|---|---|
| Nœud HTTP de WF1 copié tel quel | `{"statusCode":429,"error":"Too Many Requests."}` — en-têtes de l'API : `server: nginx`, `retry-after: 4`, `annuaire-entreprises-instance-number: 02` |
| Trace réseau `NODE_DEBUG=net` du code de n8n | `connect: autodetecting` → **`37.59.183.76` connectée** (l'adresse vivante) : le repli fonctionne |
| Sonde **nue** (`fetch`), toutes les 2 s, **pendant** l'exécution | `200, 429, 200, 200, 200, 200, 429, 429, 429, 200` — **le même mur, en alternance** |

Donc : **l'API `recherche-entreprises` limite le débit par IP**, le refus est sec (`429`,
`retry-after: 4`) et **partagé** — la sonde nue, qui ne doit rien à n8n, se fait refuser au même
moment et sur le même réseau. Mesures de cadence (mêmes conditions, IP de sortie la même) :

| Espacement demandé | Requêtes servies |
|---|---|
| 1 s | **3 à 6 sur 10** |
| 5 s | **6 sur 10** |
| 10 s | **4 sur 10** |

D'où trois conséquences directes :

1. **Ce n'est pas une question de cadence** : espacer ne suffit pas, la fenêtre est consommée
   **ailleurs** sur la même IP de sortie. Le 2026-10-26, un conteneur avait collecté **60 pages**
   à 1 page/s : la marge existe, elle est **partagée** et **variable**.
2. **Un seul `429` perd tout un couple** : `retryOnFail ×3` relance la pagination **depuis la page 1**
   (il ne reprend pas où il s'est arrêté), donc un refus au milieu d'une collecte de 61 pages coûte
   trois tentatives complètes et se termine en `error`. **Constat nouveau, à instruire à part** : la
   collecte ne survit pas à un `429` — c'est une robustesse à décider, pas un défaut de rattachement.
3. **Les six échecs sont honnêtes** : `status = error`, `items_processed = 0`, message exploitable,
   **rien d'écrit**. Le garde-fou anti-silence de `S1-04` tient sous panne réelle — c'est la seule
   bonne nouvelle de cette série, et elle méritait d'être dite.

## 4. Deux hypothèses écartées par la mesure (et un piège de méthode rejoué)

- **« Le conteneur est limité, l'hôte non »** : mesuré séparément, cela semblait vrai (l'hôte servait
  des `200`, le conteneur des `429`). Mesuré **simultanément**, sur les **trois** chemins — conteneur
  en réseau pont, conteneur en `--network host`, hôte Windows — les trois rendent **le même mélange**
  `200/429`. Les deux premières mesures n'étaient pas prises dans la même fenêtre : c'est **le piège
  exact** que `D-016` a consigné, rejoué par celui qui l'avait écrit.
- **« Un proxy d'environnement ferait échouer n8n et pas un `fetch` »** : l'environnement du conteneur
  a été lu — **aucune** variable `*_PROXY`, et `fetch` (undici) ne les lit pas de toute façon. Faux.
- **« Une adresse serait limitée et pas les autres »** : en épinglant chaque adresse séparément,
  `.77` et `.78` restent **muettes au niveau TCP** (~10,5 s, `TypeError`) et **`.76` rend des `429`
  elle aussi**. La limite est côté service, pas côté adresse.

## 5. Ce que le correctif fait (et ce qu'il vérifie)

Le rattachement se fait **sur la donnée de chaque page**, dans « Filtrage et compteurs » :

- une page `page = 1` (ou un item en erreur) **ouvre un segment** ; un segment se ferme sur une
  **dernière page partielle** (`< 25` résultats) ou sur une erreur ;
- le segment *k* est attribué au couple *k* de « Préparation de collecte » ;
- et **tout écart est une erreur**, jamais une attribution silencieuse :
  nombre de segments ≠ nombre de couples, page hors séquence (`page` ≠ position), `total_results`
  qui varie dans un même couple, somme des résultats servis ≠ `total_results` annoncé, segment qui ne
  se ferme pas (le plafond de pagination de `S1-04`, conservé), ou `activite_principale` différent du
  NAF du couple (l'anti-silence, conservé).

Vérifié hors réseau, avec `$input` et `$` simulés, sur **onze scénarios et 30 assertions** (exit 0) —
dont **six échecs provoqués** : pages de deux couples interverties (NAF différents) → refus et message
anti-silence ; pages hors séquence ; **collecte tronquée** (segment jamais fermé) ; panne réseau sur un
couple avec l'autre collecté (→ `partial`, 10 lignes écrites, message nommant le couple fautif) ;
collecte commençant à la page 2 ; deux couples pour un seul segment. Et trois cas nominaux : un couple
multi-pages + un autre (compteurs et écriture attendus), **deux couples de même NAF** (61 pages de
`43.21A × 974` + 8 pages de `43.21A × 15` → `recuperees = 1 711` = 1 515 + 196, 1 711 lignes), et le
cas du § 6.5.

Le code testé est **celui du fichier livré** (`n8n/workflows/wf1-collecte.json`), pas un brouillon : le
test porte sur l'artefact qui part en PR. Et il est comparé au code de `S1-04` **pris dans git**
(`git show d156e99:n8n/workflows/wf1-collecte.json`) — c'est ce qui rend le critère 3 **rouge → vert**
au lieu d'être une affirmation.

## 6. La preuve de bout en bout — ce qui a pu être établi, et ce qui est resté bloqué

**Montage** : conteneur jetable (`docker.n8n.io/n8nio/n8n:latest`, **n8n 2.43.5**), workflow =
**l'export versionné copié**, avec **un seul ajout** : un déclencheur exécutable par le CLI (le
déclencheur horaire ne l'est pas). Le credential Supabase est assemblé **en mémoire** et écrit dans le
conteneur par `docker exec -i` — aucun secret sur le disque du dépôt. Les campagnes sont **réelles**,
créées dans le projet du produit ; les totaux annoncés par l'API sont relevés **dans la même fenêtre**
que l'exécution ; chaque scénario est contrôlé **par requête** sur les lignes écrites ; la base est
relevée **avant** (le harnais refuse de démarrer si elle n'est pas à `0 / 0 / 0`) et **rendue à son
état d'avant** après (relevé en fin de séance : `0 / 0 / 0`).

**Aucune déviation de cadence pour les trois scénarios** : A, B et C ont tourné avec le
`requestInterval` **livré** (1 000 ms). Le harnais sait espacer les pages (`INTERVALLE`), mais seules
les tentatives de la référence (§ 6.4) en ont eu besoin — et elles sont **toutes** en échec : l'écart
n'a donc jamais servi à faire passer une preuve.

**Limite de lecture, dite** : la sortie du CLI (`n8n execute`) dépasse 1 Mo sur ces campagnes et n'a
pas pu être reparsée automatiquement pour A et B. L'évidence de ces deux scénarios est donc la **ligne
`runs` lue en base** et les **contrôles par requête**, pas une relecture nœud par nœud du JSON
d'exécution.

### 6.1 Scénario A — un couple multi-pages, collecté en entier

Campagne `43.21A × 05` (`effectif_min = 3`) : l'API annonce, **dans la même fenêtre**, **36 résultats
sur 2 pages**.

| Ce qui est lu | Résultat |
|---|---|
| `runs.status` / `runs.error` | **`success`** / **`null`** |
| `runs.items_processed` | **22** (lignes écrites — D-002) |
| `runs.details` | `{recuperees: 36, ecartees: 14, bandes_appliquees: [13 bandes]}` |
| Cohérence | **22 + 14 = 36** — exactement le total annoncé par l'API |
| Lignes `companies` rattachées | **22** · sièges **tous** en `05` · **0 hors zone** · **0 sans siège** |
| Exécution | **23,0 s** à la cadence livrée |

Sous le défaut, ce couple était **abandonné à sa page 2** : le code de `S1-04` rejoué sur les mêmes
données rend `echec de collecte WF1 : 2 page(s) sans couple rattachable (pairedItem perdu) — collecte
interrompue` (§ 6.5), et rien n'est écrit. Ce tableau est donc le même cas, mesuré à l'envers.

### 6.2 Scénario B — deux couples qui partagent le code NAF `43.21A` (`05` et `70`)

Chaque couple tient sur **2 pages** (l'API annonce 36 résultats en `05` et 33 en `70`, même fenêtre).

| Ce qui est lu | Résultat |
|---|---|
| `runs.status` / `runs.error` | **`success`** / **`null`** |
| `runs.items_processed` | **42** |
| `runs.details` | `{recuperees: 69, ecartees: 27}` |
| Cohérence | **69 = 36 + 33** (les deux couples en entier) et **42 + 27 = 69** |
| Répartition par requête | lignes à siège `05` : **22** · lignes à siège `70` : **20** · **0 hors zone** · **0 sans siège** |
| Établissements appariés **par ligne** | **42 lignes** en portent · appariés en `05` : **44** · en `70` : **43** — **aucune** ligne d'un couple ne porte d'établissement de l'autre |
| Exécution | **42,3 s** à la cadence livrée |

C'est le critère 2 du ticket, et il est mesuré **par requête** : le département lu dans chaque ligne est
celui de son couple, y compris quand les deux couples partagent le code NAF — le cas où le défaut
était **silencieux**.

### 6.3 Scénario C — l'échec provoqué reste un échec, nommé

`43.21A × 99` : l'API refuse ce département.

| Ce qui est lu | Résultat |
|---|---|
| `runs.status` | **`error`** (jamais `success`) |
| `runs.items_processed` | **0** |
| Lignes écrites | **0** |

Le message du run, verbatim (tronqué par le plafond de 900 caractères du nœud) :

```json
{"status":"error","items_processed":0,
 "error":"1 couple(s) en echec — 43.21A|99 : HTTP 400 — {\"erreur\":\"Au moins un paramètre `departement` est non valide. Les valeurs valides : ['01', '02', …",
 "details":{"ecartees":0,"recuperees":0,"bandes_appliquees":[]}}
```

Un premier essai de ce scénario avait rendu un `timeout of 10000ms exceeded` : c'était la **panne de
débit** (§ 3), pas le refus. La réponse au département invalide a alors été mesurée **depuis le chemin
d'exécution** (conteneur, `departement=99` → **HTTP 400** avec le message de l'API), puis le scénario a
été relancé : c'est l'exécution citée ci-dessus, et c'est le message de l'API qui s'y lit. Écrire le
premier essai au lieu du second aurait attribué au rattachement un échec de débit.

### 6.4 Ce qui est resté bloqué — la référence `43.21A × 974` (1 515 résultats, 61 pages)

Le critère 1 du ticket **nomme ce couple**, et il n'a **pas pu** être collecté : **six tentatives**,
de la cadence livrée à **4 s entre les pages**, toutes terminées en `error` — la dernière refusée après
**cinq pages** (`HTTP 429`, `retry-after: 4`). La cause est celle du § 3 et elle est mesurée **en
simultané** : la limite de débit est côté service et **partagée sur l'IP de sortie**. Le 26/10, un
conteneur avait servi 60 pages à 1 page/s — la marge existe, elle est variable et elle ne
m'appartient pas.

**Ce que la preuve met à la place du couple nommé** : les **plus petits couples réellement
multi-pages** que la fenêtre admet — `43.21A × 05` (36 → 2 pages) et `43.21A × 70` (33 → 2 pages),
avec le filtre d'effectif de `D-008` à `effectif_min = 3`. Ce seuil n'est pas un confort : mesuré,
`effectif_min = 10` **aplatit ces couples à une seule page** (preuve inutilisable) — 3 **réduit le
volume sans aplatir**.

**Ce que cela vérifie, et ce que cela ne vérifie pas** : la **substance** du critère 1 est établie —
un couple **multi-pages** collecté **en entier** (`recuperees` = total annoncé par l'API, `items_processed
+ ecartees = recuperees`, `error = null`), et le défaut B tombe dès la **page 2**, donc la preuve
l'exerce. Le **volume** (1 515 sur 61 pages) ne l'est pas, et ce n'est pas le code qui l'empêche :
l'API n'offre aujourd'hui ni la fenêtre ni le débit. L'écart est **assumé et écrit** au ticket, comme
l'a été l'exception inverse de `S2-01` (`D-016`) — décision **`D-017`**.

### 6.5 Critère 3 — la clé n'est plus un index : rouge → vert, hors réseau

Mêmes pages, **cinq dispositions de `pairedItem`** (index de sortie `0,1,2,3` — celle que n8n fait
lire ; index d'entrée `0,0,0,1` — celle que n8n range ; constant `7` ; hors bornes `999` ; absent) :

| Disposition | Code de `S1-04` | Code livré |
|---|---|---|
| `0,1,2,3` (ce que n8n fait lire) | **erreur** : `2 page(s) sans couple rattachable` | 60 lignes · `recuperees = 60` |
| `0,0,0,1` (ce que n8n range) | 60 lignes · `recuperees = 60` | 60 lignes · `recuperees = 60` |
| constant `7` | **erreur** : `4 page(s) sans couple rattachable` | 60 lignes · `recuperees = 60` |
| hors bornes `999` | **erreur** : `4 page(s) sans couple rattachable` | 60 lignes · `recuperees = 60` |
| absent | **erreur** : `4 page(s) sans couple rattachable` | 60 lignes · `recuperees = 60` |

Deux choses sont donc établies, et pas seulement affirmées : le résultat **ne dépend plus** de l'index
(une seule sortie pour les cinq dispositions), et il **en dépendait** avant — c'est bien la lecture de
`pairedItem` qui portait l'attribution, et elle est la seule chose qui a changé. Une assertion porte en
outre sur le **code livré** : hors commentaires, il ne contient plus le mot `pairedItem` (le commentaire
du nœud l'explique, et c'est volontaire : le prochain lecteur doit savoir **pourquoi** il n'est pas lu).

## 7. Conséquence pour le ticket

- **Critère 1** ✅ sur sa substance (couple multi-pages collecté en entier, compteurs réconciliés), **avec
  l'écart de volume du § 6.4 assumé par `D-017`** ; **critère 2** ✅ mesuré par requête sur deux couples
  de même NAF (§ 6.2) ; **critère 3** ✅ rouge → vert (§ 6.5) ; **critère 4** ✅ le plafond de pagination
  reste une erreur (11 scénarios hors réseau, dont la collecte tronquée), et **critère 5** — la relecture
  par un Reviewer **en contexte neuf** — reste **à faire** : c'est la revue de la PR, et c'est
  précisément l'écart qui avait laissé passer le défaut critique de `S1-04`.
- **Ce que le ticket n'a pas couvert, et qui est plus gros que lui** : un **seul** `429` fait échouer
  tout un couple (le `retryOnFail ×3` relance la **pagination entière**, pas la page en échec). C'est
  une question de **robustesse de la collecte**, pas de rattachement — elle est consignée ici et dans
  `AGENTS.md` §10, et c'est le planning qui l'instruit (`D-017` le dit).

