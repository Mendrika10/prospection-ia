# Confirmation indépendante du critère 7 — `S2-03` (2026-10-28)

> Objet : la **relecture en contexte neuf** (critère 7) avait été faite **dans la même session** que
> l'implémentation ([verdict](2026-10-28-revue-pr-s2-03.md)), ce qui laisse la confirmation par une
> **session indépendante** due — la preuve reposant sur une mesure de banc, certes rejouable, mais
> dont personne d'autre n'avait rejoué ni le banc ni les assertions. Comme pour `S2-02`, cette
> confirmation a été confiée à une **session séparée** (processus distinct, aucun accès à
> l'historique ni à l'auteur), isolée sur un **dossier fermé**. Sa sortie brute a été relue ; ce
> document la consigne. Le verbatim intégral vivait dans le dossier jetable
> (`.tmp-s203-conf/verdict-brut.log`, `.tmp-s203-conf/reviewer-tests.mjs`), nettoyé après consignation.

## 1. Le protocole (identique à celui de `S2-02`)

La session indépendante n'a reçu **que** le dossier, **sans le verdict** de la relecture interne —
ni les revues de mesure, ni `D-018` :

- `ticket-s203.md` — le ticket tel qu'ouvert, critères d'acceptation compris ;
- `description-pr.md` — la description de la PR fournie par l'auteur ;
- `diff-wf1.patch` — le diff du code livré ;
- `wf1-collecte.json` — le workflow livré en entier ;
- à côté : le banc et le stub (`.tmp-s203-banc.mjs`, `.tmp-s203-stub.mjs`) présentés comme
  **des outils à relire, pas des documents à croire** (docker + image n8n disponibles).

Objectifs demandés : (1) vérifier le code livré contre **chaque** critère, sur le diff et le JSON,
pas sur l'intention ; (2) écrire et lancer **ses propres** cas de test, sans réutiliser les
assertions de l'auteur ; (3) rendre un verdict classé bloquant / important / mineur / hors
périmètre ; (4) écrire ce qu'elle n'a pas pu vérifier.

## 2. Ce que la session a fait, de son côté

- **Relecture complète** du ticket, de la description, du diff et du workflow livré — notamment le
  code **en clair** des nœuds nouveaux (`Accumuler la page`, `Rythme de la requête`, `Pages
  collectées`, `Mémoriser le couple`) et du `Filtrage` (inchangé par cette PR), extraits du JSON
  et non du diff.
- **Rejeu du banc réel** (stub + image n8n, scénarios A/B/C/D) — chiffres au § 3, identiques à ceux
  publiés.
- **92 tests écrits par elle-même**, **tous verts**, avec l'honnêteté du banc demandée : une
  **première passe** de 31 assertions comptait **un échec**, dont la cause était **l'attente du
  test**, pas le code — le test attendait le plancher nu de 5 000 ms quand aucun `retry-after` n'est
  fourni, alors que le code applique plancher **+ marge** de 1 000 ms (la marge de réveil anticipé
  de `Wait`, documentée). L'assertion a été corrigée **du côté du test**, jamais du côté du code.

| Suite (92 assertions au total) | Couverture |
|---|---|
| 1 — `Accumuler la page` | 33 tests : page pleine / partielle, `429/408/500/502/503`, refus métier `400/403/404`, `retry-after` numérique / date HTTP / invalide / vide / `0` / `1` / `> 60 s`, budget épuisé, isolation entre exécutions |
| 2 — Isolation de l'état statique | 2 tests : deux `$execution.id` simultanés ne se polluent pas |
| 3 — `Pages collectées` | 5 tests : le couple abandonné **ne fuit pas ses pages tronquées**, mix succès + erreur, nettoyage de l'état global |
| 4 — `Rythme de la requête` | 5 tests : cadence 1 s tenue, échéance API prioritaire, tolérance 1 ms |
| 5 — Structure du workflow | 47 tests : HTTP (pagination / batching / `retryOnFail` retirés, `fullResponse` + `neverError` ajoutés), nœuds S2-03 présents, `batchSize = 1`, `Wait` dynamique, IDs uniques, **cibles de connexions valides, routage complet de la boucle, aucun nœud orphelin** |

## 3. Le banc rejoué par la session (numéros identiques à ceux publiés)

| Scénario (stub, journal du serveur) | Requêtes | Reprises (écarts) | Pages conservées |
|---|---|---|---|
| Témoin, aucun refus | **5** | — | 5 → 120 lignes, aucun doublon |
| Page 3 refusée 25 s, `retry-after: 7` | **8** | **8,05 / 8,04 / 8,05 s** | 5 → 120 lignes |
| Refus définitif, `retry-after: 4` | **7** (2 servies, 5 refus) | **5,05 / 5,06 / 5,05 / 5,05 s** | 0, couple `error` **nommé** |
| Deux couples du même NAF | **10** | — | 10 → 240 lignes |

Écarts entre pages suivantes relevés entre **1,04 s et 1,16 s** — **aucun écart inférieur à 1 s**.

## 4. Vérification des critères d'acceptation (tableau du relecteur indépendant)

| # | Critère | Statut | Preuve du relecteur |
|---|---|---|---|
| 1 | Mécanisme mesuré avant toute correction | ✅ | Journaux du banc : le réessai relance l'item **entier** depuis la page 1, `retry-after` non lu — conformes à la mesure du 2026-10-27 |
| 2 | Un `429` isolé ou une rafale ne fait plus perdre le couple | ✅ | Scénario B : 3 reprises, 5 pages conservées, 120 lignes ; la stratégie retenue est écrite dans le code |
| 3 | `retry-after` est un plancher | ✅ | Code `Math.max(demandée + marge, 5 000)` ; tests : `0` → 5 000 ms, `7` → 8 000 ms ; banc : ~8,05 s, **pas** 7,00 |
| 4 | Politesse de crawl non dégradée | ✅ | Diff : `User-Agent` / `timeout` inchangés, plafond de 100 pages conservé en code ; écarts page suivante ≥ 1,04 s |
| 5 | Pire cas honnête | ✅ | Scénario C : `error`, message nommant `43.21A|05`, 0 ligne écrite, pas de succès muet |
| 6 | Preuve de bout en bout (API + base réelles) | ⚠️ **non rejouable dans son dossier** | Ni l'API publique ni la base n'y sont accessibles ; les chiffres réels du run (`22` lignes / `error` nommé / base `0/0/0`) restent sur la foi des fiches du dossier |
| 7 | Relecture + confirmation indépendante | ✅ | *la présente session EST la confirmation demandée* |

## 5. Constats du relecteur indépendant, classés

**Bloquant — aucun.**

**Importants (3)** :

1. **Critère 6 non rejouable dans son environnement isolé** (ni API publique ni base réelle) : les
   chiffres de bout en bout tiennent sur la foi des pièces du dossier. *Note du consignateur : ce
   critère a été vérifié **en base réelle** par la relecture interne, qui a l'accès à
   l'environnement (base relevée `0 / 0 / 0` avant et après, échec provoqué sur département
   invalide) et le pire cas a été prouvé **sur stub et sur l'API réelle** — les deux chemins se
   recouvrent.*
2. **Défaut pré-existant confirmé** : deux campagnes dues dans le même tick laissent une ligne
   `runs` en `running` (« Préparation de collecte » lit toujours `.first()` sur les nœuds amont).
   Pas introduit par `S2-03`, pas corrigé par lui — **ticket dédié requis** (déjà annoncé à la
   relecture interne).
3. **État global non nettoyé si le conteneur meurt pendant la boucle** : le `delete` de « Pages
   collectées » protège le cas nominal, pas le crash ; l'état orphelin resterait en mémoire du
   workflow jusqu'au redémarrage de n8n. Constat mesuré et juste, **hors périmètre du ticket**.

**Mineurs (3)** :

4. `Réessai après refus ?` : les **deux** branches de l'IF pointent vers `Rythme de la requête`,
   donc un `etape` inattendu serait silencieusement traité comme un réessai ; un `throw` sur valeur
   inconnue serait plus sûr. *Note du consignateur, vérifiée sur le JSON livré : la branche **false
   est le chemin normal** (`etape === 'page'` poursuit la même boucle), l'IF est **redondant**, pas
   mort ; le constat opérationnel tient tel quel.*
5. La note sticky **S1-04** décrit encore les réglages retirés du nœud HTTP (`requestInterval`,
   `Retry on Fail ×3`, `waitBetweenTries = 5 000`) — la note S2-03 documente le changement,
   l'ancienne n'est pas mise à jour et peut tromper un lecteur futur.
6. `tranche_effectif_salarie` pourrait être envoyé comme **la chaîne `"undefined"`** si aucune bande
   n'est appliquée — comportement **antérieur** à la PR (le diff ne change que l'échappement des
   guillemets), à tracer hors ticket. *Note : la correction « paramètre omis quand `effectif_min`
   est nul » date de `S1-02` ; la forme de l'expression mérite une vérification dédiée.*

**Hors périmètre (1)** : le banc tourne sur l'image `n8n:latest` plutôt que `2.43.5` — si `latest`
pointe un jour ailleurs, les comportements mesurés (`Wait`, `fullResponse`, `neverError`) pourraient
diverger.

## 6. Verdict de la session indépendante

**`VERDICT: approuvé sous réserves`** — **aucun bloquant** ; 1 important (le critère 6 non rejouable
dans son dossier), 2 importants **hors ticket** (défaut pré-existant des deux campagnes du même
tick, état orphelin en cas de crash), 3 mineurs, 1 hors périmètre — **aucune réserve ne porte sur
les critères 2 à 5 du ticket**. Son résumé : *« Le code livré répond à l'objectif du ticket :
remplacer la pagination native (qui jetait les pages acquises en cas de `429`) par une boucle maison
page par page, avec reprise après `retry-after + 1 s`, plancher de 5 s, plafond de 60 s, et abandon
nommé au pire cas. Les 92 tests unitaires que j'ai écrits passent. Les 4 scénarios du banc réel
produisent les résultats annoncés. La structure du workflow est cohérente. »*

**Son point d'honnêteté, répété** : le critère 6 n'a pas pu être rejoué dans son environnement — si
bien que la chaîne complète est : le relecteur **interne** a vérifié le critère 6 **en base réelle**
(base rendue `0 / 0 / 0`), le relecteur **indépendant** n'y a pas accès mais confirme les critères
1 à 5 par ses propres tests et son rejeu du banc. **Aucune session n'a validé ses propres
assertions seule.**

---

**Critère 7 — STATUT FINAL : ✓ SATISFAIT** (le 2026-10-28). La relecture interne avait dit ce qui
serait demandé à la session indépendante — (a) rejouer le banc et comparer les écarts, (b) chercher
un chemin où `Attendre encore ?` ne revérifie pas l'échéance, (c) vérifier que le couple abandonné
ne peut pas écrire de lignes partielles, (d) confirmer que le défaut des deux campagnes est
antérieur — : **(a)** fait (§ 3, écarts identiques), **(c)** fait (suite 3, 5 assertions), **(d)**
fait (§ 5.2 confirmé) ; **(b)** couvert par la suite 4 (cadence et échéance prioritaire testées par
la session elle-même). Les réserves hors ticket sont consignées et attendent leur ticket dédié.
