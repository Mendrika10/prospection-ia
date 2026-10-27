# Un item paginé refusé au milieu : n8n reprend-il la page, ou relance-t-il tout ? (critère 1 de `S2-03`)

> Objet : **critère 1 du ticket [`S2-03`](../sprint-02.md)** — « le mécanisme est **mesuré avant
> toute correction** : un `429` injecté au milieu d'une pagination et la trace de ce que n8n fait des
> pages déjà reçues — d'où il reprend, et ce qu'il jette ».
> Date : **2026-10-27**. Complète les deux revues de `S2-02`
> ([mesure](2026-10-27-rattachement-des-pages-par-la-donnee.md) § 3 et [revue de PR](2026-10-27-revue-pr-53.md) § 4),
> qui avaient levé le constat **sans l'isoler**.

## 1. Montage — et la seule déviation, écrite

- **Stub local** (`node:http`, dans le conteneur) qui sert **5 pages** de 25, 25, 25, 25 et 20 résultats
  (total 120) et **journalise chaque requête** reçue : numéro de page, statut, horodatage à la
  milliseconde. C'est le journal qui répond — pas une déduction.
- **Le nœud « Collecte API (S1-02) » est copié tel quel** depuis l'export livré
  (`n8n/workflows/wf1-collecte.json`) : mêmes `queryParameters`, même pagination
  (`$pageCount + 1`, `requestInterval: 1000`, `completeExpression` sur `results.length < 25`,
  `maxRequests: 100`), mêmes `retryOnFail: true` / `maxTries: 3` / `waitBetweenTries: 5000`,
  même `timeout: 10000`, même `batchSize: 1`.
- **Une seule déviation, et elle est écrite** : son `url` pointe sur le stub (`http://127.0.0.1:8080/search`)
  au lieu de l'API publique — **aucune requête ne sort**. Rien d'autre n'est touché.
- Conteneur **jetable**, **n8n 2.43.5**, workflow minimal autour du nœud (déclencheur exécutable par le
  CLI + un item d'entrée).
- Quatre scénarios : **témoin** (aucune panne), **`429` sur la page 3 une fois**, **`429` sur la page 3
  à chaque fois**, et un **contrôle** (même chose avec `500`) pour voir si le comportement tient au
  statut ou au mécanisme.

## 2. Ce que le serveur a réellement reçu (verbatim)

**Témoin** — rien à signaler, et c'est ce qui valide la cadence :

```
page=1 → 200 (25)   page=2 → 200 (25)   page=3 → 200 (25)   page=4 → 200 (25)   page=5 → 200 (20)
```

**`429` sur la page 3, une fois** — la question posée :

```
13:27:37.397  page=1 → 200 (25 résultats servis, total 120)
13:27:38.434  page=2 → 200 (25 résultats servis, total 120)
13:27:39.448  page=3 → 429 (refus n°1, mode once)
13:27:45.481  page=1 → 200 (25 résultats servis, total 120)     ← 6,03 s plus tard : PAGE 1
13:27:46.493  page=2 → 200 (25 résultats servis, total 120)
13:27:47.548  page=3 → 200 (25 résultats servis, total 120)
13:27:48.566  page=4 → 200 (25 résultats servis, total 120)
13:27:49.587  page=5 → 200 (20 résultats servis, total 120)
```

**`429` sur la page 3, à chaque fois** — trois tentatives, et ce qui reste :

```
13:28:00.170  page=1 → 200 …   13:28:01.205  page=2 → 200 …   13:28:02.214  page=3 → 429 (refus n°1)
13:28:08.243  page=1 → 200 …   13:28:09.252  page=2 → 200 …   13:28:10.260  page=3 → 429 (refus n°2)
13:28:16.276  page=1 → 200 …   13:28:17.284  page=2 → 200 …   13:28:18.294  page=3 → 429 (refus n°3)
```

**Contrôle `500`** — exactement la même forme (pages 1 et 2, puis la 3 refusée, trois fois).

## 3. Ce que le nœud HTTP a émis

| Scénario | Items émis | Pages émises | Statut du nœud | Temps | Requêtes reçues par le serveur |
|---|---|---|---|---|---|
| Témoin | **5** | `1, 2, 3, 4, 5` | `success` | 4,24 s | **5** (aucune en double) |
| `429` une fois | **5** | `1, 2, 3, 4, 5` — **sans doublon** | `success` | 12,33 s | **7** (pages 1-2 payées deux fois) |
| `429` toujours | **1** | — *(l'item d'erreur)* | `success` (avec erreur) | 19,27 s | **9** (3 × pages 1-2 + 3 refus) |
| `500` toujours | **1** | — *(l'item d'erreur)* | `success` (avec erreur) | 19,35 s | **9** | 

L'erreur émise porte ce que l'API a dit — en-têtes compris :

```
{"statusCode":429,"error":"{\"message\":\"Too Many Requests.\"}","isAxiosError":true,
 "response":{"headers":{"retry-after":"4","server":"nginx","annuaire-entreprises-instance-number":"02"…}}}
```

## 4. Ce que la mesure établit (et qui n'était, jusqu'ici, qu'une lecture plausible)

1. **`retryOnFail` relance l'item ENTIER, pagination comprise, depuis `page = 1`.** Le refus tombe page
   3 ; 6,03 s plus tard, la **page 1** est redemandée. **Il n'y a pas de reprise à la page en échec** :
   la question du ticket est tranchée, et la réponse est celle des deux revues — mais **mesurée**, avec
   le journal du serveur, et non plus déduite d'un temps total.
2. **Le délai entre deux tentatives est de 6,03 s**, soit `waitBetweenTries` (5 000 ms) + ~1 s. Il est
   **fixe** : le `retry-after: 4` que l'API annonce n'est **pas lu** (ici il se trouve que 5 s > 4 s,
   mais par coïncidence de réglage, pas par lecture de l'en-tête).
3. **Le travail déjà fait est payé deux fois, et son coût croît avec la profondeur du refus** : un refus
   page 3 fait refaire 2 requêtes ; un refus page 20 en ferait refaire 19 — **à chaque tentative**.
   Sur une API qui **refuse pour cause de débit**, relancer la pagination entière **ajoute** de la
   pression : c'est un amplificateur, mesuré (9 requêtes pour 3 refus).
4. **Le comportement ne dépend pas du statut** (`429` et `500` donnent la même forme) : c'est le
   mécanisme de réessai de l'item, pas un traitement du `429`.
5. **Quand la panne est définitive, les pages déjà obtenues sont perdues** : le nœud émet **un seul
   item**, l'item d'erreur — **pas** les pages 1 et 2 servies trois fois. Six requêtes servies, zéro
   page conservée. C'est le « défaut de rendement » du ticket, désormais chiffré.
6. **Quand la panne est passagère, il n'y a AUCUN doublon de page** : l'item réussi émet `1, 2, 3, 4, 5`,
   pas `1, 2, 1, 2, 3, 4, 5`. **Le rattachement de `S2-02` n'est donc pas mis en danger par le
   réessai** — la règle stricte de segmentation (une page `page = 1` ouvre un segment) reste valable,
   et une collecte qui réussit après un refus produit exactement une série complète. C'était la crainte
   la plus sérieuse de cette mesure ; elle est levée.

## 5. Ce que cela change pour `S2-03` — sans choisir à sa place

Le ticket posait **trois stratégies possibles**. La mesure en ferme une et en précise deux :

- **« reprendre à la page en échec »** — **impossible avec ce nœud** : il n'expose aucun point de reprise,
  et le réessai repart de la page 1. Cette voie exigerait de sortir la pagination du nœud HTTP
  (piste (b) ou (d) du ticket), pas de la régler.
- **« réessayer en respectant `retry-after` »** — **déjà partiellement le cas** (5 s > 4 s), mais par un
  réglage **statique** qui ignore l'en-tête. Améliorer ne coûte rien en politesse ; ça ne rend pas la
  collecte plus résiliente, ça ne fait que changer le délai.
- **« sortir en `partial` avec les pages acquises »** — **impossible dans la structure actuelle** : au
  moment de l'échec définitif, le nœud **jette** les pages acquises et n'émet que l'erreur. Il faudrait
  que la collecte soit découpée en unités qui **réussissent séparément** (pages ou lots de pages), ce
  que le nœud paginé ne fait pas.

**Conséquence honnête** : la correction la moins chère (augmenter `maxTries`, ajuster le délai) **ne
supprime pas** le défaut — elle en réduit la fréquence et **aggrave** le gaspillage quand elle échoue
(3 tentatives × profondeur). Toute solution qui garde ce qui a été obtenu passe par un **changement de
structure** de la collecte. Le choix entre ces voies est le travail restant de `S2-03` : il n'est pas
tranché ici, et cette mesure existe pour qu'il se tranche sur des chiffres.

## 6. Ce que cette mesure n'établit pas

- Le comportement **sur l'API réelle** : le stub n'imite ni la latence, ni la variabilité de la fenêtre
  de débit, ni le fait qu'un `429` réel arrive souvent **en rafale** (la fenêtre partagée). Le
  mécanisme mesuré est celui du nœud ; la **fréquence** des refus reste celle du service.
- Le coût exact d'une rafale : ici le refus est toujours sur la **même** page. Un refus à des pages
  variables produirait plus de requêtes gaspillées, pas moins.
- Aucune mesure n'a été prise sur un couple **multi-pages réel** : ce n'était pas l'objet de ce
  critère, et la fenêtre de l'API ne l'a pas permis le 27/10 (voir les deux revues de `S2-02`).
