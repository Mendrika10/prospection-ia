# Daily asynchrone

Trois lignes par jour, en haut du fichier (le plus récent d'abord). Alimenté par l'agent
**Orchestrateur** ; le PO en prend connaissance. Rien d'oral qui ne finisse ici ou dans un ticket.

Format :
```
## AAAA-MM-JJ (jour) — Sprint N
- Fait : …
- Prévu : …
- Bloqué : …   ← un blocage sans ticket de levée n'est pas un blocage, c'est un vœu
```

---

## 2026-10-26 (lundi) — S1-04 : la preuve faite a révélé que WF1 ne collectait rien

- **Fait** : `S1-04` **réellement clos**. La PR #32 avait fusionné les réglages de politesse et un
  harnais de test embarqué dans le workflow, mais sa preuve restait « à faire pour la DoD
  complète ». Preuve faite sur instance n8n jetable (conteneurs jetables, n8n 2.43.5) contre le
  projet Supabase réel — et elle a mis au jour **trois défauts réels** : (1) `Filtrage et
  compteurs` rattachait les pages à leur couple via `pairedItem.sourceOverwrite`, **champ que n8n
  ne remplit jamais** → *tout* échec réseau (endpoint inexistant, timeout 10 s) ressortait en
  **`success`, 0 élément** : un plantage silencieux, exactement ce que le ticket interdit ; (2) la
  logique `echecs_collecte` vivait dans un nœud **orphelin** (aucun entrant depuis S1-03) → « un
  couple en panne ⇒ `partial` » était du code mort ; (3) le harnais de test embarqué (4 nœuds)
  était **cassé** (`onError` dans `parameters`, en-têtes User-Agent dans `options`) et sa sortie
  ne menait nulle part — retiré, la preuve étant une exécution sur copie (pratique S1-02/S1-06).
  **Corrigé** : rattachement sur `pairedItem.item`, échecs de collecte comptés par la conciliation
  réellement branchée, `runs.error` porteur du message, `waitBetweenTries` aligné à 5 000 ms.
  **Mesuré** : User-Agent `Prospection-ia/1.0 (n8n WF1 collecte)` **observé sur le fil**, écart
  **948 ms** entre deux appels, retry ×3 (503 puis 200) → `success`, 2 couples dont un en panne →
  `partial` avec message exploitable, endpoint faux → `error` + `ENOTFOUND`, réponse vide
  (`2A` × `05.10Z`, département **valide**) → `success` 0 écrit, collecte réelle 2 couples →
  `success`, `items_processed = 2`, 2 lignes `companies` écrites. Base rendue à 0/0/0 après chaque
  scénario.
- **Fusion** : PR #36 fusionnée en squash `3945450`, CI de `main` **verte** (run 40325270121).
- **Limitation, non bloquante** : la collecte sur l'**API publique** n'a pas pu être rejouée en
  `success`. `recherche-entreprises.api.gouv.fr` résout trois adresses et **deux ne répondent
  jamais** depuis ce réseau (`.76` → 200 en 2,0 s ; `.77` → timeout 15,0 s ; `.78` → timeout
  12,7 s). Selon l'adresse tirée, l'appel dépasse le timeout de 10 s imposé par le ticket — et le
  run le dit (`error` + message) au lieu de le taire, ce qui est le comportement voulu.
- **Sprint review + rétrospective** (dues le 23/10, tenues le 26/10) : métriques relevées — vélocité
  **8** tickets (croissante), lead time médian **0,1 h** (1 outlier à 89 h, `S1-02`), **1 échec de CI
  sur 91 runs (1,1 %)**, **0 PR refusée**, et surtout **1 bug critique échappé** : WF1 ne collectait
  rien tout en annonçant `success`. **1 à garder** : la preuve d'exécution réelle avant `fait` ·
  **1 à arrêter** : clore un ticket dont la preuve est « à faire » · **1 à essayer** : une exécution de
  bout en bout de WF1 avant de clore tout ticket touchant la chaîne de collecte.
  Détail : [`reviews/2026-10-26-sprint-1-review.md`](reviews/2026-10-26-sprint-1-review.md).
- **Fait (suite)** : rétrospective versée dans `AGENTS.md` §10 (**5 pièges mesurés**, réponse à la
  question 3 du §6) et §5/§6 de `docs/sprint-01.md` relevés (PR #38 fusionnée en squash `0ab43a9`).
- **Prévu** : rattraper la **revue en contexte neuf** de `S1-04` (écart assumé, écrit au ticket) ;
  trancher avec le PO si le timeout de 10 s reste tenable face à cette API.
- **Bloqué** : rien.

---

## 2026-10-22 (jeudi) — S1-04 fait : politesse de crawl et robustesse, PR #32 fusionnée

- **Fait** : `S1-04` exécuté — User-Agent corrigé (sorti de `options`, silencieusement non émis, vers racine `sendHeaders`/`headerParameters`), `waitBetweenBatches: 1000` sur Split in Batches, `retryOnFail ×3` sur Collecte API (délai fixe 5 s, plafond n8n), `onError: continueRegularOutput` (Continue on Fail), tests intégrés : endpoint faux (département `XX` → `partial`) + département vide (`99` → `success`), verdict via Code node `Verdict tests S1-04`. PR #32 fusionnée en squash `be89bf9`, CI de `main` **verte** (run 39784921649 : sql, secrets, node). Sprint 1 : **tous les tickets de développement sont ✅ fait**.
- **Prévu** : Sprint Review (démo de ce qui tourne réellement) + Rétrospective (1 à garder, 1 à arrêter, 1 à essayer → mise à jour `AGENTS.md` §10).
- **Bloqué** : rien (S0-06 Telegram/PageSpeed verrou humain, non bloquant pour le sprint).

## 2026-10-20 (mardi) — S1-03 fait : upsert `companies` par SIREN, preuve complète, PR #30
fusionnée

- **Fait** : `S1-03` exécuté sur instruction du propriétaire (ordre D-006 levé avec `S1-06`) :
  la chaîne d'écriture d'ADR 0007 est en place dans `n8n/workflows/wf1-collecte.json` (Code « Lot
  des entreprises » → HTTP « Upsert des entreprises » `POST ?on_conflict=siren` + Prefer
  `merge-duplicates` → passe de propriété PATCH `campaign_id=is.null` → 2 conciliations) et
  **vérifiée en conditions réelles** sur l'instance n8n jetable avec le projet réel : requête
  émise **observée** par une copie d'écho du nœud (URL, Prefer, 2 en-têtes d'auth via
  `supabaseApi`, payload 6 lignes sans `campaign_id` ni colonnes enrichies) ; deux passages de la
  même campagne : 0 duplication, SIREN existant mis à jour, marque manuelle re-attribuée sur une
  ligne recréée, `campaign_id` et colonnes enrichies jamais déplacés (D-009) ; dédoublonnage
  intra-lot testé sur le Code node réel (lot de 3 dont 1 doublon → 2, premier gagne, D-010).
  Base verte après nettoyage (comptes avant/après identiques). **Arbitrages PO écrits** : D-009
  (payload sans `campaign_id`) et D-010 (premier gagne). Découvertes consignées dans
  `sprint-01.md` : 401 sans les **deux** en-têtes (`supabaseApi` seul credential qui les porte),
  `in.("…","…")` PGRST100, `sendHeaders` en paramètres de **racine** du nœud HTTP v3
  (implication : User-Agent à re-vérifier en `S1-04`).
- **Fusion** : PR #30 fusionnée en squash `e6e2c14` sur instruction explicite du propriétaire
  (CI de la PR verte, run 39433897410) ; re-revue demandée sur la PR (reviewer attribué, points
  listés en commentaire) — même écart de relecture assumé que `S1-06`, consigné dans
  `sprint-01.md`.
- **Prévu** : `S1-04` (politesse de crawl — y compris le User-Agent, cf. découverte
  `sendHeaders` en paramètres de racine), puis `S1-05` re-review et validation PO.
- **Bloqué** : rien (crash intermittent de Node sous Windows à la sortie du harnais — jamais
  sur les preuves elles-mêmes, verdict toujours imprimé).

## 2026-10-20 (mardi) — S1-06 fait : WF5 en place, preuves create/update sans doublon, ordre D-006 levé

- **Fait** : WF5 (`n8n/workflows/wf5-erreurs.json`) écrit puis **vérifié en conditions réelles** sur
  une instance n8n jetable : deux copies de WF1 reliées par `settings.errorWorkflow`, activées
  (mode « trigger », exclu par le code n8n pour « manual » — `execution-lifecycle-hooks.js`, l. 516-520).
  Cas A (échec avant ouverture) → WF5 **crée** la ligne `runs` en `error` ; cas B (échec après
  ouverture, collecte sabote au nœud clôture) → WF5 **clôt la ligne `running`** en `error`
  (exactement la ligne ouverte, `finished_at` posé). Pas de boucle : 1 exécution WF5 par échec,
  0 ligne figée. Nettoyage complet (comptes avant/après identiques). **PR #28 : re-revue demandée
  (reviewer attribué, points listés en commentaire), fusion en squash `2969c3d` sur instruction
  explicite, CI de `main` verte (run 39390859370) ; l'écart « l'agent ne valide pas son propre
  travail » est consigné dans `sprint-01.md` (pas de review signée d'un tiers).**
- **Découvertes consignées dans `sprint-01.md`** : le filtre WF5 doit matcher la **clé du contrat
  `runs`** (`wf1-collecte`, constante posée par WF1) et non le nom n8n de l'exécution — le run
  orphelin restait sinon figé ; le mode « manual » ne déclenche jamais l'error workflow ; WF5 doit
  être **activé** ; et le verrou de versions n8n (PATCH persiste le JSON mais les exécutions
  chargeaient l'ancienne version) impose l'archivage + suppression + réimport à neuf.
- **Ordre D-006 levé** : `S1-03` (upsert, déjà préparé ce matin) devient exécutable.
- **Bloqué** : rien (crash intermittent de Node sous Windows à la sortie du harnais — jamais sur les
  preuves elles-mêmes, verdict toujours imprimé).

## 2026-10-20 (mardi) — S1-02 fusionné : PR #25, corrections de revue prouvées, CI de `main` verte

- **Fait** : la PR #25 (`S1-02` — WF1 collecte réelle) est passée par sa DoD complète :
  relue en contexte neuf deux fois (les 4 points importants signalés puis corrigés puis re-vérifiés),
  corrections **prouvées en exécution réelle** sur instance n8n jetable (commit 458fecc : conciliation des écritures,
  statut `partial` sur le cas doublons, plafond de pagination, contrat `siren` ;
  10 tests de simulation + 3 mutations), fusionnée en **squash `76ae1eb`**, CI de `main` **verte**
  (run 39376121986). `sprint-01.md` : S1-02 passe à ✅ fait (cette PR).
- **Prévu** : `S1-03` (upsert `on conflict (siren)`) — à cadrer sur la base de la découverte « le nœud
  Supabase poste un lot en un seul POST atomique » (`AGENTS.md` §10), et `S1-04` (politesse de
  crawl, `Retry` ×3 sur le nœud HTTP).
- **Bloqué** : rien.

## 2026-10-16 (vendredi) — S1-02 : WF1 collecte réellement, 3 090 entreprises écrites puis nettoyées

- **Fait** : `S1-02` vérifié en conditions réelles sur une instance n8n **jetable** (conteneur local
  `wf1-s102`, arrêté et nettoyé après capture des preuves) : 3 campagnes de test (NAF 43.21A ×
  départements 44 et 974, dont une avec `effectif_min=50`). Résultats dans la base : 1 648 + 1 441 + 1
  entreprises écrites, `runs.details` exacts (D-002), pagination native 74/61 pages selon la campagne,
  règle du siège appliquée (ADR 0005), `companies.raw` à 29 clés. Un tick horaire à vide aussi capturé
  (run `campaign_id NULL`, 0 items).
- **Corrigé au passage (mesuré, pas supposé)** : (1) `tranche_effectif_salarie` **vide** = HTTP 422,
  le paramètre est désormais **omis** quand `effectif_min` est nul (« nul = aucun filtre ») ;
  (2) le Code node n8n (JsTaskRunner) refuse `fetch`/`node:http` — la collecte passe par un nœud
  HTTP Request natif avec pagination intégrée ; (3) le Code node **exige** un `name` par entreprise
  (`companies.name` est NOT NULL : sinon l'insertion échouait pour tout le lot).
- **Nettoyage** : toutes les données de test (`companies`, `runs`, `campaigns`) supprimées, conteneur
  jetable arrêté, scripts `.tmp-*` supprimés. Les doublons de SIREN (campagnes qui se recouvrent)
  sont le travail explicite de `S1-03` (upsert `on conflict (siren)`).
- **Prévu** : revue de la PR puis `S1-03`.
- **Bloqué** : rien.

## 2026-10-16 (vendredi) — S1-05 : relecture PR #1 en contexte neuf — un bloquant trouvé, corrigé, rebasé

- **Demandé** : relire la PR #1 (`S1-05` — garde-fou du format des codes NAF) en contexte neuf
  (rôle Reviewer §7), pendant que la CI de la PR #22 tournait.
- **Prouvé en arène** (Postgres 16, séquence exacte du job CI `sql`) : rouge sans la migration
  (exit 3, bon message), les 5 fichiers de test verts sur la même base, mutabilité du test prouvée
  (regex affaibli → le test échoue avec le bon message). Deux essais de mutation intermédiaires ont
  produit des résultats neutres — défauts de mon harnais, jamais de la PR ; aucun verdict ne repose
  dessus. Consigné car « passer pour la mauvaise raison » s'applique aussi à un relecteur.
- **Trouvé, bloquant** : la migration `20261015000002` fait un `alter table … add constraint` **nu**,
  donc non réapplicable — or le `ci.yml` devenu effectif au merge rejoue **toutes** les migrations sur
  une base peuplée (règle du dépôt §4) : seconde passe = `constraint "campaigns_naf_codes_format"
  already exists` (42710), reproduit en arène. Le vert actuel de la PR ne couvre pas ce pipeline :
  le `ci.yml` de **sa branche** est antérieur à l'étape « Réappliquer ».
- **Corrigé, prouvé, poussé** (`fix(sql):`, +18/−3, commit `1db1c74`) : l'alter enveloppé dans
  `do $ if not exists # Daily asynchrone

Trois lignes par jour, en haut du fichier (le plus récent d'abord). Alimenté par l'agent
**Orchestrateur** ; le PO en prend connaissance. Rien d'oral qui ne finisse ici ou dans un ticket.

Format :
```
## AAAA-MM-JJ (jour) — Sprint N
- Fait : …
- Prévu : …
- Bloqué : …   ← un blocage sans ticket de levée n'est pas un blocage, c'est un vœu
```
---


## 2026-10-16 (vendredi) — S1-01 : relecture PR #22 par un Reviewer neuf, finding corrigé et prouvé

- **Demandé** : relire la PR #22 en contexte neuf (rôle Reviewer §7) et corriger ce qu'elle trouve.
- **Trouvé** : un finding **important** reconnu comme valide après vérification — §4 « Reprise
  automatique (retry ×3) sur erreur réseau » était absent : aucun des trois nœuds Supabase de WF1 ne portait `Retry on Fail ×3`.
  Deux faux positifs de mon validateur, rejetés après vérification des sources n8n
  installées : `version` est un **tableau** chez `scheduleTrigger`, et le walker ne descendait pas dans
  `options[].values` des fixedCollection.
- **Corrigé** (`n8n/workflows/wf1-collecte.json`, +13/−4) : `retryOnFail ×3` + `waitBetweenTries 5 s`
  (plafond n8n ; délai **fixe**) sur la **lecture** et les **deux clôtures** `runs`. L'**insert** reste
  sans retry **par choix** : reprendre un insert qui a peut-être déjà écrit créerait deux lignes `runs`
  pour une exécution (interdit). Note mise à jour dans l'artéfact.
- **Prouvé, pas supposé** : validateur (contre les descriptions de nœuds **installées**) vert ; les deux
  chemins exécutés sur les harnais → nominal : `success` en 3 s (insert 1,6 s / lecture 0,45 s / clôture
  0,86 s) ; erreur = ligne passée en `error` + `finished_at` + message. Lignes **réelles** confirmées
  dans Supabase (`runs` : `3a4b7d19…` success, `625a6fd1…` error). Une ligne harnais orpheline
  `running` (`623ff168…` du 15/10 12:44, tuée pendant la vérification) reste à nettoyer :
  elle ne vient ni de l'artéfact ni du chemin corrigé.
- **Deux pièges supplémentaires, à porter en AGENTS.md §10** : copier une base SQLite **vive** y compris
  son WAL peut figer la copie (SQLite attend indéfiniment à l'ouverture ; il faut `VACUUM INTO` pour une copie
  consistante) ; et tuer le serveur pendant la lecture fige la ligne `runs` en
  `running` pour toujours — plus rien ne la fermera.

## 2026-10-15 (jeudi, soir) — S1-01 : WF1 existe, journalise son passage, et c'est prouvé sur le vrai projet

- **Demandé** : `S1-01` — squelette de WF1 (cadence fixe, campagnes dues, log `runs`), `S0-04` levé.
  Écriture **autorisée** : `n8n/workflows/` uniquement.
- **Fait** : `n8n/workflows/wf1-collecte.json` — 9 nœuds, 3 notes explicatives, déclencheur **horaire**
  (propriété du nœud, seule cadence possible : ADR 0006), lecture de la vue `campaigns_due` avec
  `returnAll: true`, création d'une ligne `runs` en `running` au démarrage puis clôture en `success`
  (ou `error` + message) avec `finished_at`, et `items_processed = 0` — **D-002** : cette colonne compte
  les lignes **écrites**, et le squelette n'écrit aucune donnée métier. Credential référencé **par nom**
  (`Supabase service_role (WF1)`), aucun secret dans le fichier.
- **Prouvé, pas supposé** : l'artéfact commité importé dans une instance n8n **jetable** (copie de la base,
  volume dédié) rend des nœuds/connexions/réglages **identiques** à ce que la base stocke ; la trace
  d'exécution montre `running` → `success` et ne renvoie **que** la campagne `active = true` (une campagne
  inactive créée pour le test n'apparaît sur aucune sortie) ; et le vrai projet contient la ligne
  `wf1-collecte | success | fini=true | items=0`. Les 2 campagnes de test et les 4 lignes des harnais ont
  été supprimées après vérification : il ne reste que la ligne de l'artéfact.
- **Comment exécuter sans toucher l'instance de l'équipe** : `n8n execute` ne sait démarrer que les
  sous-workflows (il exige un *Execute Workflow Trigger*) ; la route réelle est
  `POST /rest/workflows/:id/run` (celle de l'UI), avec `triggerToStartFrom`. Le harnais tourne dans un
  conteneur jetable sur une copie de la base, avec un compte propriétaire de test — les données, elles,
  partent bien vers le **vrai** projet Supabase (c'est là qu'est la preuve).
- **Trois pièges n8n 2.x mesurés** (deux à porter en `AGENTS.md` §10) : `N8N_USER_FOLDER=/home/node/.n8n`
  fait lire `.n8n/.n8n` — une base neuve et **vide**, donc un login « mauvais mot de passe » inexplicable ;
  `import:workflow` **désactive toujours** le workflow importé ; et **activer = publier** (une bascule de
  `active` en base ne planifie rien : `Processed 0 published workflows`).
- **Limite assumée** : le message stocké dans `runs.error` est le repli de l'expression — la forme d'un item
  de sortie d'erreur n'étant pas celle attendue en 2.43.5, à reprendre avec les vrais échecs de `S1-02`.
- **Bloqué** : rien. `S1-02` peut enchaîner (il branche la collecte sur le nœud d'itération laissé en place).

---
## 2026-10-15 (jeudi, nuit) — le contrôle d'idempotence regarde aussi le **schéma**, et une **référence** retient les objets perdus

- **Demandé** : détecter aussi les objets de schéma perdus par une migration (colonnes, index,
  contraintes, policies RLS). Le contrôle ne comparait que des **données** : supprimer une policy, un
  index, un `grant` ou `security_invoker` ne change **aucune ligne**, donc il ne voyait rien.
- **Fait** : `.github/sql/schema-fingerprint.sql` — 175 objets de `public` (colonnes avec type/not
  null/défaut, contraintes, index, déclencheurs, RLS activée/forcée, policies, privilèges **réels**
  de `anon`/`authenticated`/`service_role`, options de vue, fonctions, séquences, extensions,
  privilèges par défaut) ; et `.github/sql/schema-baseline.txt`, la référence committée. Le job `sql`
  fait désormais **trois** comparaisons : données avant/après, schéma avant/après, et « aucun objet de
  la référence n'a disparu ».
- **La troisième était nécessaire, et je l'ai mesurée avant de l'écrire** : une destruction **rejouée à
  l'identique** est invisible aux comparaisons avant/après — `drop index … if exists` détruit dans les
  deux passes. Démontré, quatre mutations que **rien d'autre** ne voit : index du dashboard détruit
  (`DONNEES=OK SCHEMA=OK` mais `REFERENCE=OBJET_PERDU`), **RLS désactivée sur `leads`** (aucun test ne
  la couvre, aucune ligne ne change), défaut de colonne `created_at` retiré, contrainte `CHECK`
  supprimée. Symétriquement, les quatre cas précédents (données) restent détectés : `truncate`,
  `update` destructeur, `delete`, et la migration non idempotente qui échoue à la réapplication.
- **Deux pièges de conception traités** : `pg_proc.provolatile` et `pg_default_acl.defaclobjtype` sont
  de type `"char"`, où `||` est ambigu (erreur SQL silencieusement avalée par ma redirection → 0 objet
  mesuré : sans le contrôle « 175 lignes », j'aurais livré une empreinte vide) ; et la version
  d'extension est **exclue** de l'empreinte, car elle change avec l'image Postgres, pas avec nos
  migrations.
- **Propriété vérifiée** : la référence est **reproduisible** (régénérée sur une base neuve → identique)
  et **indépendante des données** (régénérée après seed + tests + témoins → identique), ce qui autorise
  la comparaison sur la base peuplée. Retrait **volontairement** non signalé : la référence ne bloque
  que les disparitions — une migration additive ne demande aucune régénération.
- **Un piège dans mon propre harnais, encore une fois** : un fichier de mutation laissé dans
  `supabase/migrations/` par une série interrompue a fait échouer le cas **nominal**. Le contrôle était
  juste ; c'est mon banc d'essai qui mentait. Rejoué sur une base propre :
  `TESTS=OK DONNEES=OK SCHEMA=OK REFERENCE=OK`.
- **Le premier passage CI a échoué, et c'était une vraie leçon** : la référence contenait
  `schema|public|…|proprietaire=postgres`, alors qu'une base **vierge** — celle de la CI — fait appartenir
  `public` à `pg_database_owner` (Postgres 15+). Le propriétaire du schéma ne vient **pas** de nos
  migrations : le mesurer, c'était mesurer **l'environnement**, et le contrôle échouait pour une raison
  qui n'a rien à voir avec une migration. Ligne retirée, référence régénérée sur une base **vierge**, et
  vérifié : base vierge et base dont le schéma a été recréé à la main rendent la **même** empreinte
  (`ENVIRONNEMENT_SANS_EFFET=OK`). Aurait échoué silencieusement en local — la CI l'a attrapé.
- **Règle écrite dans `AGENTS.md` §4** : aucun objet de la référence ne doit disparaître ; une suppression
  voulue régénère la référence dans la **même** PR.
- **Bloqué** : `S0-04` — inchangé.

## 2026-10-15 (jeudi, nuit) — le garde-fou d'idempotence était **aveugle sur quatre des six tables**

- **Le défaut, mesuré avant d'être corrigé** : le contrôle ajouté juste avant réappliquait les migrations
  **juste après le seed**, quand `companies`, `analyses`, `leads` et `blocklist` sont **vides**. Or sur une
  table vide, une migration destructrice ne change **rien** à l'empreinte : elle passe inaperçue.
  Les deux cas, exécutés : `delete from public.blocklist` **sans** données témoins →
  `VERDICT=OK_SANS_CHANGEMENT` (la destruction est laissée passer) ; **avec** témoins →
  `VERDICT=DONNEES_MODIFIEES` (`blocklist 1 → 0`). **Une empreinte ne prouve que ce qu'il y a à perdre.**
- **Fait** : `.github/sql/witness-data.sql` — une ligne témoin par table, données manifestement fausses
  (le dépôt est public, `D-004`), idempotent. Et **réordonnancement** du job `sql` : migrations → seed →
  **tests** → données témoins → **réapplication + empreinte avant/après**.
- **Pourquoi la réapplication vient maintenant après les tests** : `rls.sql` compte des lignes **exactes**
  (« 1 lead ») et insère des SIREN fixes. Peupler la base avant lui rendrait ses assertions fausses, et
  je refuse d'affaiblir un test pour faire passer mon propre contrôle. Avant, la réapplication était après
  le seed et avant les tests ; les tests, eux, ne sont pas touchés.
- **Cinq cas rejoués localement sur un Postgres 16.15** (l'image de la CI), dans l'ordre exact de la CI :
  **1** nominal → `OK_SANS_CHANGEMENT` · **2** `create table` sans garde → `ECHEC_A_LA_REAPPLICATION`
  (`relation "mut_a" already exists`) · **3** `truncate runs` → `DONNEES_MODIFIEES` (`runs 3 → 0`) ·
  **4** `update campaigns` (nombre de lignes **inchangé**) → `DONNEES_MODIFIEES` · **5/6** le cas `blocklist`
  ci-dessus. Tables mesurées avant la réapplication : `analyses 2, blocklist 1, campaigns 2, companies 2,
  leads 2, runs 3` — **six sur six non vides**, ce qui était l'objectif.
- **Règle transmise à `AGENTS.md` §4** : toute nouvelle table de données doit être déclarée **à la fois**
  dans `.github/sql/db-fingerprint.sql` et dans `.github/sql/witness-data.sql` — sinon elle n'est couverte
  par aucun contrôle et la CI restera verte **à tort**.
- **Bloqué** : `S0-04` — inchangé.

## 2026-10-15 (jeudi, nuit) — `S0-04` **levé** : les migrations sont vérifiées sur le **vrai** projet Supabase

- **Fait** : accès base obtenu. Le chemin s'est trouvé par mesure : l'hôte direct
  (`db.<ref>.supabase.co`) n'est résolu qu'en **IPv6**, et le pooler **session (5432)** est
  **injoignable** depuis ce réseau ; c'est le pooler **transaction (6543)** qui répond.
  `supabase db push --db-url` a appliqué les **3 migrations**, historique distant `…0001, …0003, …0004`.
- **Fait — les 4 suites passent SUR LE VRAI PROJET**, `code 0` chacune, assertions lues dans la sortie :
  `rls.sql` (`TOUS LES TESTS RLS PASSENT`), `runs_details.sql` (6 assertions), `campaigns_due.sql`
  (10, dont le contrôle discriminant « `anon`, même avec le droit sur la vue, ne lit rien »),
  `anon_privileges.sql` (7 objets inspectés, aucun privilège `anon`). État mesuré : 6 tables, la vue,
  **RLS sur les 6**, 10 policies, `runs.details`, `security_invoker=true` lu dans `pg_class`.
- **Fait — les vérifications à la main**, celles que la DoD demande explicitement : `anon` reçoit
  **401 `permission denied`** sur les 6 tables **et** la vue, **alors que 4 lignes de données
  existaient** (sinon le contrôle ne prouverait rien) ; `service_role` **écrit** (HTTP 201, ligne
  ensuite supprimée) — le chemin n8n est prouvé, pas supposé. `.env` complet : la clé transmise comme
  `service_role` était en réalité la clé **`anon`** ; la vraie a été récupérée par l'API et ses claims
  vérifiés (`role=service_role`, bon projet), sans jamais l'afficher.
- **Fait — l'empreinte du vrai projet comparée à notre référence** (`.github/sql/schema-baseline.txt`) :
  **aucun objet manquant**. Trois lignes `privilege_defaut` diffèrent seulement par leur **texte**
  (l'entrée propriétaire `postgres=` existe côté plateforme, absente côté CI) alors que l'**effet** est
  identique — les `anon=arwdDxtm` y sont. C'est la limite connue de la référence, mesurée pour de vrai.
- **Deux écarts consignés, et arbitrés par le propriétaire plutôt que tus** : la région est
  **`eu-west-1`** (Irlande) et non `eu-west-3` — l'intention du critère est respectée, sa lettre non ;
  et la relecture de `S1-08`/`S1-09` est une revue **adversariale non indépendante**, donc l'exigence
  du dépôt « un agent ne valide jamais son propre travail » n'est **pas** satisfaite à la lettre. Les
  deux tickets passent à `fait` avec l'écart **écrit dans le ticket**, pas abandonné en silence. Leurs
  constats restent ouverts et sont, eux, mesurés.
- **Nettoyage** : résidu de `rls.sql` (4 lignes) et ligne de vérification REST supprimés — toutes les
  tables du projet sont revenues à **0**.
- **Prévu** : `S1-01` et `S1-02` — le verrou est levé, leur DoD est désormais vérifiable directement.
- **Bloqué** : rien. `S0-05` (board) et `S0-06` (bot Telegram) restent ouverts, sans impact sur le sprint.

## 2026-10-15 (jeudi, nuit) — la CI devient **fidèle à la plateforme** sur les privilèges par défaut

- **Fait** : `.github/sql/roles.sql` reproduit enfin ce qu'un vrai projet Supabase porte déjà dans
  `pg_default_acl` — `ALL` pour `anon`, `authenticated` et `service_role` sur les tables, fonctions et
  séquences de `public`. Conséquence reproduite : **tout objet neuf de `public` naît lisible et
  inscriptible par `anon`**, vue comprise.
- **Fait** : `supabase/tests/anon_privileges.sql` — le contrôle « `anon` ne détient aucun privilège sur
  les objets de `public` », écrit sur le **catalogue** et non sur six noms connus, donc il couvre
  l'objet que le prochain sprint ajoutera. Quatre contrôles, dont deux **positifs** : l'inventaire doit
  voir des objets (sinon le test refuse de conclure au lieu de passer à vide), et `authenticated` /
  `service_role` doivent lire les 7 objets attendus (sinon le contrôle principal serait tautologique).
- **Trois mutations prouvent qu'il mord** : une table neuve sans `revoke` → **exit 3** avec les sept
  privilèges nommés ; la même plus une vue neuve → **exit 3** sur les deux objets ; `revoke` explicite →
  **exit 0** (l'échec n'était donc pas fortuit) ; et sur une base **vide**, le test **refuse de
  conclure** (`inventaire suspect : 0 objet`) au lieu de passer sans rien prouver.
- **La référence a dû être régénérée, et c'est instructif** : le delta n'est pas d'une ligne mais de
  **14** — 1 ligne `privilege_defaut` dont le **texte change** (migration 1 et `roles.sql` écrivent dans
  le **même** enregistrement `pg_default_acl`) et **13 ajouts**. Ces 13 disent quelque chose de réel :
  les privilèges par défaut de la plateforme élargissent aussi ceux d'`authenticated` —
  `insert`/`update`/`delete` sur `analyses`, `runs`, `companies` et la vue `campaigns_due`, qu'aucun
  `revoke` ne restreint. C'est filtré par la RLS (le contrôle 4 de `rls.sql` passe désormais **par elle**,
  comme sur le vrai projet, et non plus par un refus de privilège) — mais c'est désormais **visible**.
- **Vérifié** : les quatre suites sortent en **code 0** sur une base neuve (ordre alphabétique :
  `anon_privileges` · `campaigns_due` · `rls` · `runs_details`), empreintes **données** et **schéma**
  avant/après réapplication **identiques**, et la comparaison à la nouvelle référence ne signale
  **aucun** objet disparu. Règle ajoutée dans `AGENTS.md` §4.
- **Prévu** : l'application des migrations sur le projet réel (toujours en attente du mot de passe base).
- **Bloqué** : `S0-04` — inchangé.

## 2026-10-15 (jeudi, nuit) — accès au **vrai** projet Supabase : lecture acquise, écriture bloquée ; revue de `S1-08`/`S1-09`

- **Fait** : le projet réel `rexnoeixlkedvdhzeoqk` est enfin **interrogé pour de vrai** — pas
  supposé. Constaté par API : projet **vierge** (0 table, 0 vue, 0 schéma `supabase*`), rôles
  `anon`/`authenticated`/`service_role` présents, `pgcrypto`/`uuid-ossp`/`pg_stat_statements`
  installés, PostgreSQL **17.11**, PostgREST répond (`404 PGRST205` sur `leads`, table inexistante).
  `.env` écrit et **vérifié non suivi** (`git check-ignore` → `.gitignore:2:.env`, `git status` vide).
- **Bloqué, et diagnostiqué plutôt que contourné** : le jeton Management API fourni est en
  **lecture seule** — `current_user = supabase_read_only_user`, `transaction_read_only = on`,
  **même avec `read_only:false`** (`create schema` → `ERROR 25006`). Les tests ne sont pas seulement
  bloqués par le DDL : ils **insèrent** des lignes. Donc rien n'a été appliqué, rien n'a été coché :
  `S0-04` reste ouvert et `S1-08`/`S1-09` restent `en review`. Il faut le **mot de passe de la base**
  (chemin `supabase link` + `db push`) pour aller plus loin.
- **Fait (2e condition de la DoD, elle ne dépend pas des identifiants)** : relecture **adversariale**
  de `S1-08`/`S1-09` → [`reviews/2026-10-15-s1-08-s1-09.md`](reviews/2026-10-15-s1-08-s1-09.md).
  Trois constats, chacun **mesuré** sur un Postgres jetable : (1) un run en **`error`** bloque sa
  campagne aussi longtemps qu'un run en cours — 24 h par défaut, sans qu'aucun test ne l'exerce ni
  que l'ADR 0006 l'arbitre ; (2) `runs.items_processed` est **nullable**, donc le « sens unique » de
  D-002 n'est pas tenu par la base ; (3) `prochain_run` est `NULL` pour une campagne **due** jamais
  exécutée. Contrôles conformes au passage : `security_invoker` lu dans le catalogue, `anon` sans
  aucun privilège, et l'index partiel **réellement utilisé** (`Index Only Scan`, 3,7 ms sur 100 005 runs).
- **Deux pièges nommés** : la clé `service_role` transmise est **identique à la clé `anon`** (même
  empreinte, claims `role=anon`) — `.env` la laisse vide plutôt que d'écrire un faux secret ; et le
  jeton d'accès a transité en clair dans la conversation, donc **à révoquer** (stocké hors dépôt,
  jamais dans un fichier suivi).
- **Fait (et c'est le premier constat qui ne pouvait venir que du vrai projet)** : le **pré-vol** de
  l'environnement → [`reviews/2026-10-15-pre-vol-environnement-supabase.md`](reviews/2026-10-15-pre-vol-environnement-supabase.md).
  Sur un projet Supabase, **tout objet neuf de `public` reçoit `ALL` pour `anon`** (relevé dans
  `pg_default_acl`) ; la CI, partie d'un Postgres nu, **ne reproduit pas** ces privilèges par défaut.
  Mesuré en A/B (mêmes migrations, deux bases) : une table neuve sans `revoke` ni RLS est **lisible et
  inscriptible par `anon`** côté plateforme, **invisible** côté CI. Nos deux migrations sont **hors de
  cause** (elles révoquent explicitement : `anon` = 0 privilège sur les 6 tables et sur la vue) — mais
  un oubli futur serait **vert en CI et ouvert sur le vrai projet**. Correction proposée, à décider en
  ticket : reproduire les privilèges par défaut dans `roles.sql` + un test de catalogue « aucun objet
  de `public` n'est lisible par `anon` ». Au passage, deux pièges d'environnement sont **écartés** :
  `service_role` a bien `bypassrls=t` et `postgres` peut endosser les trois rôles, donc les
  `set local role` des tests tiendront sur le vrai projet.
- **Prévu** : `supabase link` + `db push` + les trois suites sur le vrai projet dès que le mot de
  passe est fourni ; puis `S0-04` coché et `S1-08`/`S1-09` passés à `fait` — **si et seulement si**
  les sorties sont vertes.
- **Bloqué** : `S0-04` — inchangé, et désormais c'est précisément l'**écriture** qui manque.

## 2026-10-15 (jeudi, nuit) — la CI réapplique les migrations sur une base **déjà peuplée**

- **Fait** : le job `sql` applique désormais les migrations **deux fois** — la seconde **après le
  seed**, donc sur une base **peuplée**, qui est le cas réel d'un projet Supabase en service recevant
  une migration — et compare une **empreinte avant/après** : nombre de lignes **et contenu**
  ([`.github/sql/db-fingerprint.sql`](../.github/sql/db-fingerprint.sql)). L'exit code seul ne suffit
  pas : `truncate` sort en **code 0** en détruisant les données.
- **Trois mutations prouvent que le contrôle mord** : migration **non idempotente** (`create table`
  sans garde) → échec de la réapplication (`relation "mut_a" already exists`) ; `truncate public.runs`
  → **données modifiées détectées** (`runs 1 → 0`) ; `update campaigns set name = …` → **détecté alors
  que le nombre de lignes ne bouge pas**. C'est ce dernier cas qui justifie l'empreinte de **contenu**
  plutôt qu'un simple comptage.
- **Un défaut dans mon propre harnais, corrigé** : ma première mutation « non idempotente » était
  créée **après** la première passe, donc elle créait la table pour la première fois et passait —
  elle ne testait rien. Une migration non idempotente doit exister **dès la passe 1**.
- **Conséquence écrite dans `AGENTS.md` §4** : une migration doit être **réapplicable sans perte ni
  duplication**. C'est désormais une règle que la CI fait respecter, pas une préférence.
- **Deux pièges traités au passage** : `core.autocrlf=true` sur ce poste Windows pouvait livrer un
  shebang en CRLF (« bad interpreter » en CI) → `.gitattributes` force `*.sh` en `eol=lf`, vérifié sur
  le blob **indexé** ; et le contrôle est ajouté **à l'étape existante** du job `sql`, donc le nom du
  statut requis par la protection de branche **ne change pas**.
- **Bloqué** : rien de nouveau — `S0-04` reste le verrou du sprint.

## 2026-10-15 (jeudi, nuit) — `S1-08` et `S1-09` implémentés en SQL, et vérifiés localement

- **Fait** : les deux tickets atteignables **sans Supabase** sont implémentés, chacun dans sa branche,
  sa PR et sa CI — `S1-08` **#12**, `S1-09` **#13**, toutes deux fusionnées. Méthode respectée :
  **test écrit d'abord** (rouge réel local : `column "details" … does not exist`, puis
  `column "interval_minutes" … does not exist`), migration ensuite, vert local sur un **Postgres 16.15**
  isolé, puis CI. **23 assertions** lues dans le log du job `sql`, pas au statut.
- **S1-08** : `runs.details` sépare *récupérées / écartées / écrites* (`D-002`) ; `items_processed`
  reçoit un sens unique, documenté par `comment on column` — document dont le test **vérifie l'existence**.
- **S1-09** : `RF-03` était **impossible** à implémenter, pas seulement difficile (le déclencheur n8n
  n'évalue ses valeurs qu'à la publication ; rien n'enregistrait le dernier passage).
  **`ADR 0006`** tranche — cadence fixe, intervalle explicite par campagne, runs rattachés à leur
  campagne, vue `campaigns_due` qui écrit la règle une seule fois.
- **Un défaut trouvé dans mon propre test, par un test de mutation** : ma première vérification
  « `anon` ne lit rien sur la vue » **passait pour la mauvaise raison** — `anon` n'a aucun privilège
  sur la vue, donc le refus arrivait même en retirant `security_invoker`. Démonstration : la mutation
  rendait `EXIT=0` alors que la protection avait disparu. Le test **ouvre donc la vue à `anon`** avant
  de vérifier qu'il n'en obtient rien — seul scénario discriminant, qui échoue bien (`EXIT=3`) quand la
  protection saute. Un contrôle **positif** a été ajouté : `service_role` (WF1) et `authenticated`
  doivent pouvoir lire la vue, sinon les `grant` n'étaient couverts par rien.
- **Prévu** : `S1-01`/`S1-02` dès que `S0-04` est levé ; relecture de la PR #1.
- **Bloqué** : `S0-04` — inchangé, et c'est lui qui empêche `S1-08` et `S1-09` d'être **`fait`** :
  la DoD exige une vérification sur l'environnement cible. Ils sont donc `en review`.

## 2026-10-15 (jeudi, nuit) — le planning relu par un agent Reviewer, et ses conséquences

- **Fait** : revue du planning et de **D-006/D-007** →
  [`reviews/2026-10-15-planning-sprint-1.md`](reviews/2026-10-15-planning-sprint-1.md). Elle a été
  faite en **re-dérivant chaque affirmation depuis une source primaire** — schéma SQL, **API appelée
  pour de vrai**, documentation n8n officielle — et non en relisant la prose de son auteur.
  **1 constat bloquant, 4 importants, 3 mineurs**, tous corrigés ici.
- **Bloquant corrigé** : `S1-02` exigeait d'écrire dans `runs.details` **sans déclarer la dépendance
  `S1-08`** qui crée la colonne → dépendance ajoutée (la DoR n'était pas satisfaite sur son 4e critère).
- **Ce que la revue a apporté de neuf**, que personne n'avait mesuré : le **vocabulaire d'effectif est
  prouvé** (les 15 tranches INSEE acceptées, 9 valeurs hors vocabulaire refusées en HTTP 400) et l'API
  accepte une **liste** de bandes (`52,53` → 263 = 172 + 91). Donc `D-007` a atteint **son propre
  déclencheur de révision** → **`D-008`** : le filtre d'effectif devient **obligatoire**. Et comme
  `campaigns.effectif_min` est un entier face à une API qui ne filtre que par bandes, la règle d'union
  est désormais **écrite dans le ticket** (sur-ensemble assumé, jamais un sous-ensemble silencieux).
- **Corrigé aussi** : l'état « Prêt sous condition », **inventé** par le planning et absent de la
  méthode (DoR binaire), supprimé — les 5 tickets concernés sont **Prêt**, leurs dépendances sont
  déclarées ; le motif de rejet du test de `S1-04` (« impossible depuis `S1-05` ») **conditionné**, la
  contrainte n'étant pas encore sur `main` ; le motif trop fort à `S1-08` (« ne peut pas échouer » →
  « ne prouve rien sur l'exploitabilité ») ; la revendication n8n **sourcée** par la documentation
  officielle ; et le verdict « Déjà fait » de `S1-05` ramené à « **Déjà implémenté, en review** ».
- **Prévu** : trancher la décision d'architecture de `S1-09`, puis `S1-09` et `S1-08` — atteignables
  **sans Supabase**.
- **Bloqué** : `S0-04`, inchangé. Et un point qui ne se corrige pas : **cette revue n'est pas
  indépendante** — auteur et relecteur sont la même session. C'est écrit dans le rapport, et ça reste
  vrai : la valeur tient à la méthode (sources primaires), pas au regard neuf.

## 2026-10-15 (jeudi, nuit) — Sprint Planning tenu par l'agent Product Owner

- **Fait** : planning du Sprint 1. **8 tickets soumis** → 6 retenus tels quels, **1 refusé** (`S1-07`),
  **1 créé** (`S1-09`) : **7 à faire**, plus `S1-05` déjà fait. La validation
  de la Definition of Ready a révélé **quatre défauts réels** — c'est là que le planning a servi :
  `S1-01` demandait l'impossible (« un cron par campagne lu à l'exécution » : n8n ne sait pas le faire,
  et rien n'enregistre le dernier passage d'une campagne) → nouveau prérequis **S1-09** ; `S1-02`
  déguisait une tâche en critère d'acceptation ; `S1-04` demandait un test **devenu impossible depuis
  `S1-05`** (la base refuse d'enregistrer la campagne invalide que le test utilisait) ; `S1-08` avait un
  critère qui **ne pouvait pas échouer**. Les **4 lignes du Sprint 0** restées ouvertes ont leur sort
  écrit dans le planning (3 verrous ou reports assumés, 1 case qui se ferme au premier run réel) :
  « pas dans ce sprint » n'est pas « oublié ». Deux décisions écrites (D-006, D-007).
- **Conformité au brief, contrôlée** : les **8 décisions** ont les 7 rubriques du §8, une date, un
  statut et au moins 3 options écartées. Trois défauts du **brief lui-même** corrigés : le §2 annonçait
  « cinq » verrous humains pour **quatre** listés (reliquat d'une correction antérieure, incomplète) ;
  le §6 confiait au PO la mémoire `AGENTS.md` §10 que le §9 lui interdisait d'écrire ; le gabarit du §8
  réclamait un libellé « statut » absent des 8 titres.
- **Écart de périmètre, déclaré** : la session a corrigé des compteurs faux dans le §10 de
  `methode-equipe-agents.md`, que le §9 ne listait pas comme modifiable. Résolution : ce **seul tableau
  d'inventaire** entre dans le périmètre d'écriture du PO, sans droit de toucher aux règles.
  **À confirmer ou à annuler par l'humain** — je ne m'accorde pas moi-même une permission.
- **Refusé** : `S1-07` (documentation d'exploitation) sort du sprint — on documenterait une procédure
  qui n'a **jamais tourné**, elle serait réécrite au premier incident. Retour conditionné à la première
  collecte réelle.
- **Prévu** : `S1-09` et `S1-08` (atteignables **sans Supabase**), puis `S1-01`/`S1-02` dès que
  l'humain lève `S0-04`. La relecture de la PR #1 ne dépend que d'un agent.
- **Bloqué** : `S0-04` reste **le** verrou du sprint, et c'est écrit plutôt que contourné. Reste aussi
  la décision d'architecture qui conditionne `S1-09` (agent, ~20 min).

## 2026-10-15 (jeudi, nuit) — le Product Owner devient un agent, et il a déjà décidé

- **Fait** : le rôle de Product Owner passe à un **agent** (décision D-000), avec un brief senior
  15+ ans : [`product-owner.md`](prompts/product-owner.md) — autorité, quatre verrous humains,
  méthode d'arbitrage, métriques et anti-métriques, 7 anti-patrons, format de décision obligatoire.
  Puis le PO agent a **exercé** le rôle au lieu de rester une étiquette : 5 décisions produit
  (**D-001 à D-005**, auxquelles s'ajoute D-000 pour la gouvernance) écrites dans
  [`product-decisions.md`](product-decisions.md), dont trois qui changent le sprint :
  protocole de calibrage **chiffré** (D-001), sens unique donné à `runs.items_processed` (D-002 →
  nouveau ticket **S1-08**), et observabilité **remontée avant l'upsert** avec une portée réduite
  pour ne plus dépendre de Telegram (D-003).
- **Prévu** : revue de la PR #1 (`S1-05`), puis `S1-01` dès que `S0-04` est débloqué.
- **Bloqué** : `S0-04` (clés + migrations) et le board — **actions humaines**, désormais nommées
  comme telles partout, avec la raison : un agent n'a ni les clés ni le scope `gh`.

## 2026-10-15 (jeudi, fin de journée) — `main` est protégée, et c'est vérifié

- **Fait** : décision PO appliquée — dépôt passé **public** pour obtenir le verrou (GitHub Pro étant
  contraire à la contrainte « 0 € »). Protection de `main` configurée puis **testée par une vraie
  tentative de push direct**, rejetée par GitHub (`GH006 … 3 of 3 required status checks are
  expected`), avec contrôle du hash de `origin/main` avant/après. Scan de **tout l'historique**
  relancé après le passage en public : aucun secret. Trois pièges ajoutés à la mémoire d'équipe
  (`AGENTS.md` §10), dont un que j'ai moi-même rencontré ce soir.
- **Prévu** : revue de la PR #1 puis son merge (premier passage complet du cycle ticket → PR → CI →
  merge) ; application des 2 migrations Supabase par le PO ; board Projects.
- **Bloqué** : board Projects (scope `project` absent du jeton `gh`) ; `.env` Supabase non rempli.

## 2026-10-15 (jeudi, après-midi) — S0-05 lancé sur autorisation du PO

- **Fait** : dépôt **privé** créé — <https://github.com/Mendrika10/prospection-ia>. `main` et la branche
  `feat/s1-05-garde-fou-naf` poussées, **PR #1** ouverte. La CI a tourné **sur GitHub** pour la première
  fois : 3 jobs verts (`sql` 24 s, `secrets` 5 s, `node` 8 s), 12 assertions exécutées et vérifiées
  **dans le log du job `sql`**, pas seulement au statut. Le job `node` a bien émis son `notice`
  d'auto-désactivation. Le rejeu local était donc fidèle.
- **Prévu** : décision PO sur la protection de branche, création du board, puis S0-04 (`.env` +
  migrations Supabase) et la revue de la PR #1.
- **Bloqué** : deux points, tous deux vérifiés par l'API (pas supposés) :
  1. **Protection de branche impossible** — `PUT /branches/main/protection` **et** `POST /rulesets`
     renvoient 403 « Upgrade to GitHub Pro or make this repository public » sur un dépôt privé en
     offre gratuite. Décision PO requise (rester privé / rendre public / payer).
  2. **Board Projects** — le jeton `gh` n'a pas le scope `project`. Déblocage :
     `gh auth refresh -s project,read:project`, ou création manuelle dans l'UI.

## 2026-10-15 (jeudi) — Sprint 1 démarré par anticipation

- **Fait** : `S1-05` implémenté et **vérifié rouge → vert** sur la branche `feat/s1-05-garde-fou-naf`.
  Le test a d'abord échoué (`EXIT=3`, le code NAF compact passait), puis les 5 cas sont passés
  après la migration. Job CI `sql` rejoué localement de bout en bout sur une base neuve :
  **7 assertions RLS + 5 assertions schéma, exit 0**, et contrôle de comptage confirmant que les
  tests ne se polluent pas. `ADR 0005` accepté par le PO.
- **Prévu** : `S0-04` (projet Supabase) et `S0-05` (dépôt GitHub + board) — actions PO, elles
  bloquent la suite. Puis `S1-01` (squelette WF1), qui dépend de `S0-04` pour être vérifié.
- **Bloqué** : `S1-05` reste **en review** tant que le dépôt GitHub n'existe pas : sans dépôt, pas
  de PR, donc pas de revue par un agent tiers — et la Definition of Done l'exige. Un ticket
  implémenté mais non revu n'est pas « fait ».

## 2026-10-15 (jeudi) — Sprint 0

- **Fait** : Sprint 0 livré — arborescence, `AGENTS.md`, `.env.example`, `docker-compose` n8n,
  CI (jobs `sql` / `secrets`, job `node` auto-désactivé et signalé), modèles de ticket et de PR.
  Schéma initial + RLS + `supabase/tests/rls.sql` : 7 assertions vertes sur un Postgres 16 neuf
  (dont « anon ne lit rien », critère d'acceptation v1). Contrat de l'API Recherche d'entreprises
  vérifié pour de vrai : 4 pièges documentés dans `AGENTS.md` §10.
- **Prévu** : S0-04 (projet Supabase), S0-05 (dépôt GitHub + board), validation d'ADR 0005.
- **Bloqué** : rien de bloqué techniquement. Trois actions **PO** conditionnent le Sprint 1 :
  le compte Supabase (`S0-04`), le dépôt GitHub (`S0-05`) et la décision `ADR 0005`.

## Décisions : qui décide, et où c'est écrit

Les décisions **produit** sont prises par l'agent Product Owner et vivent dans
[`product-decisions.md`](product-decisions.md). Seuls les quatre verrous du §2 de son brief remontent
à l'humain — identifiants, argent, action hors du dépôt, suppression de données.

| Décision | Qui décide | Où c'est écrit | Statut |
|---|---|---|---|
| Le Product Owner est un agent | Propriétaire humain | `product-decisions.md` D-000 | ✅ en vigueur |
| Ciblage local : filtrer sur le siège | Agent PO | [ADR 0005](adr/0005-ciblage-des-entreprises-locales.md) | ✅ accepté |
| Protocole de calibrage et arrêt de la grille de scoring | Agent PO | `product-decisions.md` **D-001** | ✅ en vigueur, déclenchement à 100 analyses |
| `runs.items_processed` = lignes écrites ; compteurs dans `runs.details` | Agent PO | `product-decisions.md` **D-002** → ticket **S1-08** | ✅ en vigueur |
| Observabilité avant l'upsert, sans attendre Telegram | Agent PO | `product-decisions.md` **D-003** | ✅ en vigueur |
| Dépôt public : aucune donnée d'entreprise n'y entre | Agent PO | `product-decisions.md` **D-004** | ✅ en vigueur — **révision fin S1** |
| Le board Projects ne bloque aucune décision | Agent PO | `product-decisions.md` **D-005** | ✅ en vigueur |
| Périmètre, ordre et règle d'exécution du Sprint 1 | Agent PO | `product-decisions.md` **D-006** | ✅ en vigueur — refus de `S1-07`, création de `S1-09` |
| Filtre d'effectif **conditionnel**, écart tracé | Agent PO | `product-decisions.md` **D-007** → tracé par `S1-08` | ✅ en vigueur |
| Scope `project` du jeton `gh` | **Humain** | ticket `S0-05` | ⬜ non bloquant |
| `.env` Supabase + application des 2 migrations | **Humain** | ticket `S0-04` | ⛔ **bloquant** pour tout le sprint 1 |
| Vercel Hobby (usage non commercial, risque R4) | ADR à écrire | PO | avant S7, mais à ne pas oublier | ⬜ |
| Nom de domaine / réputation d'envoi (v2) | hors périmètre v1 | PO | plus tard | ⬜ |
