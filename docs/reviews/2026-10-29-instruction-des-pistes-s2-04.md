# S2-04 · Instruction des trois pistes sur les chiffres de la mesure, et trancher (2026-10-29)

> Suite de [la mesure du mécanisme](2026-10-29-mesure-s2-04-lot-de-campagnes.md), même journée. Le
> ticket exige qu'« une piste n'entre [dans le ticket] qu'avec la mesure qui la justifie » :
> l'instruction ci-dessous applique **chaque piste aux chiffres de la mesure et au code exact** de WF1.
> **Aucune correction n'est écrite ici** — le trancher porte sur la **stratégie de correction** ; la
> correction elle-même et ses preuves (critères 2 à 5) restent à implémenter et à mesurer.

## 1. La faille exacte, pointée par la mesure (code à l'appui)

Trois passages du code, relevés le même jour que la mesure :

1. **« Pour chaque campagne (S1-02) »** — `splitInBatches`, **`batchSize: 10`**,
   `waitBetweenBatches: 1 000`. Le lot entier traversé **en bloc, en un seul passage** (sortie loop
   `main#1` → « Run démarré ») ; les clôtures reviennent à l'**input** du loop ; la sortie `done`
   (`main#0`) **n'est pas branchée** (le workflow se termine).
2. **« Préparation de collecte (S1-02) »** — Code node en **`runOnceForAllItems`**, bâti sur
   `$('Pour chaque campagne (S1-02)').first().json` et `$('Run démarré (campagne)').first().json` :
   **un seul item de préparation est produit pour toute l'exécution**, celui de la **première**
   campagne du lot. Couples, collecte, compteurs, écriture : tout l'aval n'a jamais vu que la campagne
   **A**.
3. **Les trois clôtures** — `id = eq {{ $json.run_id ?? $('Run démarré (campagne)').first().json.id }}`.

Liais avec les chiffres de la [mesure](2026-10-29-mesure-s2-04-lot-de-campagnes.md) : la campagne **B**
a bien **obtenu** sa ligne `runs` (« Run démarré » reçoit les items du lot) — mais elle n'a reçu
**ni couple, ni collecte, ni clôture** (`items_processed = 0`, ligne restée `running`). La faille est
**structurelle** : le passage en bloc ne donne l'aval qu'à **une seule** campagne ; les clôtures `.first()`
n'en sont que la pointe visible. Corriger l'adressage seul (renvoyer le bon `run_id` à la clôture de B)
ne clôturerait **rien** : l'aval de B — couples, collecte, écriture — **n'existe pas** dans le passage.

## 2. Instruction des trois pistes

### Piste (a) — une boucle par campagne : du lot, un passage par campagne (retenue)

**Changement exact** : `batchSize: 10` → **`batchSize: 1`** sur « Pour chaque campagne (S1-02) ».
**Un seul paramètre**, aucune ligne de code modifiée, aucune structure de workflow changée.

- **Invariant établi par le changement** : **un passage = une campagne = un run**. La boucle
  `splitInBatches` émet déjà **un item de campagne par passage** et attend le retour de la branche
  (les clôtures reviennent à son input) : à `batchSize: 1`, tout l'aval du passage — « Run démarré »,
  « Préparation de collecte », la collecte, les clôtures — ne voit **qu'une seule campagne à la fois**.
- **« Préparation de collecte » devient exacte sans modification** : son `runOnceForAllItems` avec un
  seul item est propre, ses `.first()` visent la campagne et le run **du passage courant**.
- **Les trois clôtures deviennent correctes sans modification** : chaque passage porte **un seul**
  `runs` — le fallback `.first()` vise nécessairement le run courant, jamais celui d'une autre
  campagne.
- **Le POST multi-rows disparaît de lui-même** : « Run démarré » ne reçoit qu'un item par passage
  (une seule ligne `runs` par requête) — la mesure a rendu le POST multi-rows visible par les
  `started_at` **identiques à la microseconde** (trois fois sur trois), qui brouillent l'ordre de
  création des lignes.
- **L'aval de collecte n'est pas touché** : la boucle couple par couple de `S2-03` (pages, `retry-after`
  plancher, cadence horodatée) et le rattachement par la donnée de `S2-02` sont **inchangés** — ils
  opèrent à l'intérieur du passage courant, sur les couples de **cette** campagne.
- **Politesse** : `waitBetweenBatches: 1 000` garde **au moins 1 s** entre deux campagnes consécutives,
  en plus de la garde horodatée de 1 s entre requêtes (`S1-04`/`S2-03`) — la file de campagnes
  sérialise la collecte, elle télécommande la pression de l'API.
- **Périmètre** : le nœud « Pour chaque campagne » est **dans le périmètre du ticket** (nœuds amont de
  `campaigns_due` jusqu'à la préparation, et les clôtures). Le paramètre `batchSize` n'écrit ni
  schéma, ni SQL, ni CI, ni boucle de collecte.
- **Ce que la correction devra prouver** (critères 2 à 5) : sur l'exécution réelle des **deux
  campagnes** dues dans le même tick, chaque campagne a **sa** ligne `runs` créée **puis clôturée**
  (`success` / `error` nommé) ; l'**échec provoqué** de l'une ne fait pas tomber l'autre ; la base
  rendue **0 / 0 / 0** ; `git diff` prouvant que `S2-03` et `S2-02` sont intacts.
- **Risques notés, à constater à la correction** : (i) un échec du **POST « Run démarré »** d'un
  passage coupe la boucle (aucun `onError` réglé sur ce nœud) — hors de la mesure d'ouverture, à
  constater au banc ; (ii) la sortie `done` du loop restant **non branchée**, la fin du lot est déjà
  la fin du workflow : rien à changer.

### Piste (b) — un sous-workflow par campagne : isolation par exécution (écartée)

- **Changement exact** : un **second fichier** de workflow (préparation + collecte + clôture pour une
  campagne), appelé par « Execute Workflow » dans le workflow parent par campagne du tick.
- **Hors du périmètre du ticket** : le périmètre verrouillé est « les nœuds **amont** de
  `wf1-collecte.json` (de `campaigns_due` jusqu'à la préparation, et les **clôtures** de `runs`) » —
  un sous-workflow exige un second fichier de workflow, une **restructuration complète** plutôt qu'une
  correction de point de faille.
- **Aucun gain sur l'invariant** : la mesure a démontré que l'aval est bâti **par campagne** —
  un sous-workflow ne la rend pas plus locale : le parent l'appelle déjà, par campagne ou par couple ;
  il ne change **rien** sur la faille du passage (il n'en **remplace** pas la boucle).
- **Le coût de preuve augmente** : la preuve de bout en bout (critère 5) passe par **N exécutions**
  (le parent + N sous-workflows) ; la **session indépendante** à rejouer n'a plus un workflow mais
  **deux** fichiers à rejouer ; le parent doit gérer l'échec de l'« Execute Workflow » — un
  sous-workflow interrompu après son POST « running » laisse **exactement** le run orphelin que la
  mesure a condamné (`running` non clôturé).
- **Le seul bénéfice théorique** de la piste (b) — l'état de collecte `S2-03` **par exécution**, indexé
  par `$execution.id` — existe déjà et n'entremêle **jamais** deux campagnes sous la piste (a) :
  un passage = une campagne.

### Piste (c) — un run par élément du lot : les campagnes au même passage (écartée dans ce format)

- **Changement exact** : garder `batchSize: 10`, rendre « Préparation de collecte » `runOnceForEachItem`
  (ou produit N items), résoudre le run **par `campaign_id`** (mapping sur
  `$('Run démarré (campagne)').all()`), et porter la collecte **multi-campagnes** dans le même passage.
- **Le coût que les chiffres de la mesure rendent visible** : les **compteurs de filtrage** (agrégat
  actuel) sont **mélangés** entre campagnes ; le **lot des entreprises** posté à `companies` mêlerait
  **N campagnes** en un seul POST ; la conciliation du lot et la clôture de campagne deviennent
  multi-campagnes — **tout le pipeline aval** devrait être retravaillé, alors que la mesure a démontré
  qu'il fonctionne **par campagne et par page**.
- **L'échec d'une campagne ne fait pas tomber l'autre** (critère 3) devient **plus difficile** à
  prouver : une erreur d'item peut tomber la branche du passage entier ; sous la piste (a), elle est
  donnée **par construction** (un passage = un run, erreur d'une campagne restant dans son passage).
- **La condition du ticket** — « un run par élément du lot **si la mesure le montre** » — **n'est pas
  remplie** : la mesure montre un problème que `batchSize: 1` résout au **moindre coût** ; les lignes
  par élément **existent déjà** (les deux lignes `runs` sont créées), ce qui manque est **l'aval**,
  pas la création.

## 3. Trancher

**La mesure tranchante** : sur les chiffres relevés le 29/10, **une seule piste** respecte à la fois
l'invariant recherché (« chaque campagne a sa ligne, créée puis clôturée »), le périmètre verrouillé
du ticket et le coût de correction minimal :

| Piste | Changement exact | Étendue | Périmètre | Verdict | Verdict du trancher |
|---|---|---|---|---|---|
| **(a) Boucle** | « Pour chaque campagne » : `batchSize: 10` → **1** | **1 paramètre**, **0 ligne de code** | dans le périmètre | invariant **un passage = une campagne = un run** | **✅ retenue** |
| (b) Sous-workflow | second workflow + « Execute Workflow » | restructuration complète | **hors périmètre** (2e fichier) | ne corrige pas la faille, coût de preuve supérieur | ❌ écartée |
| (c) Run par élément | préparation multi-items + aval multi-campagnes retravaillé | **tout le pipeline aval** | à la lisière (compteurs, upsert, conciliation) | condition du ticket **non remplie** | ❌ écartée |

**Conséquence immédiate** : ouverture de la décision **`D-019`** dans
[`product-decisions.md`](../product-decisions.md) (stratégie tranchée sur la mesure, comme `D-018` sur
le banc de `S2-03`). **Prochaine étape du ticket** : implémenter `batchSize: 1`, puis **prouver les
critères 2 à 5** par le même banc que la mesure d'ouverture — `batchSize`, la preuve de bout en bout
sur **deux campagnes réelles** dues dans le même tick, avec l'**échec provoqué** de l'une et les
relevés `runs` l'relative : **avant WF2**.
