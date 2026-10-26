# Journal des décisions produit

Décisions du **Product Owner** (agent — voir [`prompts/product-owner.md`](prompts/product-owner.md)).
Une décision non écrite ici n'existe pas. Format imposé par le §8 du brief :
décision · pourquoi · options écartées · preuves · conséquence · **ce qui me ferait changer d'avis** · qui exécute.

> Ce journal ne remplace pas les ADR : un **ADR** tranche une question *technique* (comment), une
> **décision produit** tranche une question de *valeur, de priorité ou de périmètre* (quoi, quand, combien).
> Les deux se répondent, aucun ne se substitue à l'autre.

---

## D-000 — Le rôle de Product Owner est tenu par un agent · 2026-10-15 · en vigueur

**Décision** : les décisions produit (priorités, périmètre, seuils, risques, validation des ADR,
ordre des tickets) sont prises par un **agent Product Owner**, et non par le propriétaire du projet.
Seuls les quatre verrous du §2 du brief remontent à l'humain, parce qu'un agent n'en a
techniquement pas les moyens (identifiants, argent, action hors du dépôt).

**Pourquoi** : le propriétaire veut déléguer l'arbitrage produit, pas seulement l'exécution. Journal
à l'appui, les décisions produit peuvent être prises et tracées par un agent, à une condition : qu'il
écrive, motive, et indique ce qui le ferait changer d'avis.

**Options écartées** : *Product Owner humain seul* (c'est ce que le propriétaire refuse) ·
*agent PO avec droit de veto humain sur tout* (revient à ne rien déléguer ; le propriétaire n'a plus
qu'un rôle de validation, et chaque décision attend) · *pas de rôle PO du tout* (l'ordre des tickets
se décide alors au fil des sessions, c'est-à-dire au hasard).

**Preuves utilisées** : aucune mesure — décision de gouvernance du propriétaire, assumée comme telle.

**Conséquence / coût** : la qualité du produit dépend maintenant de la qualité de ce brief et du
respect du format de décision. Risque assumé : un agent PO péremptoire qui « décide » sans preuve.
Contre-mesure : le §4 impose de nommer l'hypothèse non testée, et le §8 impose de citer la preuve.

**Ce qui me ferait changer d'avis** : deux décisions consécutives invalidées par les faits
(révision humaine), ou trois sprints où le PO agent se contente d'entériner sans jamais refuser un ticket.

**Qui exécute** : propriétaire humain (acté) · suivi par l'Orchestrateur.

---

## D-001 — Protocole de calibrage et critères d'arrêt de la grille de scoring · 2026-10-15 · en vigueur

**Décision** : la grille ne se retouche plus à l'intuition. Après **100 analyses réelles**, on mesure
deux taux sur un échantillon de **30 analyses lues à la main** : faux positifs (site jugé correct alors
que le score dépasse le seuil) et faux négatifs. Les seuils :

| Faux positifs mesurés | Décision automatique |
|---|---|
| **> 30 %** | **Arrêt de la collecte** et recalibrage obligatoire avant toute nouvelle analyse |
| 10 à 30 % | Ajustement des pondérations, la collecte continue |
| < 10 % | On peut **baisser** le seuil pour élargir le volume — la précision est acquise |

**Pourquoi** : ADR 0004 annonçait « recalculer après 50-100 résultats » sans dire qui mesure quoi ni
quand s'arrêter. Un protocole sans seuil ne se déclenche jamais. Le risque R5 (faux positifs) est
précisément ce qui détruirait la confiance dans l'outil.

**Options écartées** : *calibrer en continu* (le calibrage infini, anti-patron §7.1 : on ne saura
jamais si un changement de poids a amélioré quoi que ce soit) · *mesurer sur 500 analyses* (trop tard :
500 leads faux gaspillent des semaines de prospection) · *faire relire par l'agent qui a codé la
grille* (il validera ses propres pondérations).

**Preuves utilisées** : aucune encore — 0 analyse réelle en base. **Hypothèse assumée** : les
pondérations d'ADR 0004 produiront entre 10 % et 40 % de faux positifs. C'est une hypothèse, pas
un fait, et c'est écrit comme telle.

**Conséquence / coût** : une relecture manuelle de 30 fiches, prévue au sprint S3, non compressible.
Coût immédiat : rien. Bénéfice : la première mesure qui rend le seuil défendable.

**Ce qui me ferait changer d'avis** : si l'échantillon de 30 est trop petit pour être concluant
(intervalle de confiance trop large), on monte à 50 — mais on ne baisse jamais sous 30.

**Qui exécute** : rôle Backend/Data pour l'extraction de l'échantillon (S3) ; lecture et décision : PO.

---

## D-002 — `runs.items_processed` compte les lignes **écrites** · 2026-10-15 · en vigueur

**Décision** : `runs.items_processed` = nombre de lignes **effectivement écrites** en base.
Les deux autres compteurs devenus obligatoires par ADR 0005 — entreprises **récupérées** de l'API et
entreprises **écartées** par la règle de ciblage — vont dans un champ **distinct** `runs.details`
(JSONB). Aucune information de calibrage ne disparaît dans un champ qui sert déjà à autre chose.

**Pourquoi** : un compteur unique qui change de sens au fil des sprints rend toute comparaison
historique impossible — on ne saurait plus si « 240 » veut dire « 240 intéressantes » ou
« 240 lignes touchées ». Or D-001 a besoin de comparer des volumes entre campagnes pour détecter un
découpage trop large (taux de rejet > 60 %).

**Options écartées** : *tout mettre dans `items_processed`* (champ à sens variable, donc inutile) ·
*tout mettre dans `error`* (détourner un champ destiné aux messages d'échec : impossible à agréger) ·
*ne compter que les écritures et jeter le reste* (le taux de rejet est la seule métrique qui dit si
une campagne cible trop large — sans lui, pas de calibrage possible).

**Preuves utilisées** : conséquence explicite d'ADR 0005 (« les métriques par run doivent distinguer
récupérées / écartées / écrites »), qui était restée sans propriétaire.

**Conséquence / coût** : une migration SQL est nécessaire (ajout de `runs.details`) → **ticket S1-08**.
Les lignes de `runs` déjà écrites gardent un `details` vide : sans gravité, ce sont des exécutions de test.

**Ce qui me ferait changer d'avis** : si le champ `details` reste vide en production pendant deux
sprints consécutifs, c'est qu'il ne sert à rien — je le supprimerai plutôt que de le laisser mentir
sur la qualité de l'instrumentation.

**Qui exécute** : rôle Backend/Data (S1-08 pour le schéma), rôle Automation (WF1).

---

## D-003 — L'observabilité entre dans le sprint **avant** l'upsert, et n'attend pas Telegram · 2026-10-15 · en vigueur

**Décision** : `S1-06` (WF5, workflow d'erreurs) passe **avant** `S1-03` (upsert `companies`), et sa
version retenue est sa **portée minimale** : trace en base (`runs.status = 'error'` + message dans
`runs.error`) dès qu'un workflow échoue. La notification Telegram devient un *plus*, elle n'est
**plus bloquante** : elle attend `S0-06` sans retenir le ticket.

Nouvel ordre de passage du Sprint 1 : `S1-01` → `S1-02` → **`S1-06`** → `S1-03` → `S1-04` → `S1-08` → `S1-07`.

**Pourquoi** : le coût du délai de l'observabilité est élevé. WF1 va tourner la nuit sans personne ;
sans trace d'erreur, un échec se découvre des jours plus tard et on ne saura pas *quand* il a
commencé. Ajouter des écritures (S1-03, S1-04) avant de pouvoir voir les échecs, c'est augmenter le
volume de choses qui peuvent échouer en silence.

Deuxième raison, décisive : coupler la sécurité à un compte externe (`S0-06`, action humaine non
faite) reporterait la brique **pour une raison qui n'a rien à voir avec sa valeur**. La trace en base
suffit à diagnostiquer ; Telegram ajoute du confort, pas de la capacité.

**Options écartées** : *garder l'ordre initial* (l'upsert d'abord : on écrit davantage avant de
pouvoir détecter les pannes) · *S1-06 complet exigeant Telegram* (le ticket resterait bloqué sur une
action humaine, sans que le blocage soit justifié) · *attendre le déploiement sur VPS (S7)* (l'échec
silencieux sera un problème dès le premier run, pas au sprint 7).

**Preuves utilisées** : AGENTS.md §5 impose déjà « une ligne dans `runs` par exécution » — la règle
était écrite mais aucun ticket ne la rendait vraie pour les *échecs*. Risque R7 du cahier des charges.

**Conséquence / coût** : `S1-06` change de périmètre (à reporter dans son ticket) et la notification
Telegram est reportée. Le propriétaire humain garde `S0-06` à faire, mais plus rien ne l'attend.

**Ce qui me ferait changer d'avis** : si `S0-06` est fait avant le début de `S1-06`, on fait la
version complète d'un coup — la décision porte sur l'ordre, pas sur le mépris de la notification.

**Qui exécute** : rôle Automation (S1-06) ; mise à jour du sprint : PO.

---

## D-004 — Dépôt public : aucune donnée d'entreprise ne peut y entrer · 2026-10-15 · en vigueur

**Décision** : le dépôt reste **public** — c'est la seule façon d'obtenir la protection de branche
sans payer (GitHub la refuse en privé/gratuit, vérifié). Contrepartie acceptée et **opposable** :
aucune donnée d'entreprise, aucun secret, aucun export contenant un identifiant n'entre dans le dépôt.
Les échantillons de test utilisent des SIREN fictifs, jamais des extraits du registre réel.

**Pourquoi** : le verrou de branche protège la seule boucle de qualité existante (CI + relecture).
Y renoncer pour garder le dépôt privé échangerait une garantie de qualité contre une confidentialité
que le contenu actuel ne justifie pas encore : il n'y a ni donnée client, ni secret, ni algorithme
propriétaire (la grille de scoring est un raisonnement commercial, pas un secret industriel).

**Options écartées** : *rester privé sans protection* (un merge rouge devient possible ; la règle
« CI verte obligatoire » n'est plus qu'une intention) · *GitHub Pro* (~4 $/mois, contraire à la
contrainte « 0 € » — non négociable en v1) · *passer privé plus tard, quand il y aura des données*
(c'est le bon moment pour cette question, pas maintenant : le passage public est immédiat, l'inverse
demande une décision explicite — d'où ce point de révision).

**Preuves utilisées** : `PUT /branches/main/protection` et `POST /rulesets` renvoient 403 en privé
gratuit ; après passage en public, protection appliquée **et testée** (push direct refusé par GitHub,
`GH006 … 3 of 3 required status checks are expected`). Scan de tout l'historique : 0 secret.

**Conséquence / coût** : le cahier des charges, la méthode d'équipe et la grille de scoring sont
publics. Un concurrent peut lire la stratégie. Assumé : la valeur est dans l'exécution et le volume
de leads qualifiés, pas dans la confidentialité de la grille.

**Ce qui me ferait changer d'avis** : dès qu'une donnée d'entreprise réelle entre dans le pipeline
(fin S1, dès WF1 en production) ou dès qu'un premier message de prospection est envoyé, je réévalue —
le dépôt repasse privé et je renonce au verrou technique, ou je paie. Point de révision : **fin du sprint S1**.

**Qui exécute** : rôle DevOps (état actuel) · surveillance : PO, à chaque revue de sprint.

---

## D-005 — Le tableau de sprint versionné reste la source de vérité ; le board ne bloque rien · 2026-10-15 · en vigueur

**Décision** : `docs/sprint-01.md` est **la** source de vérité des tickets, statuts et limites WIP.
Le tableau GitHub Projects est une **commodité d'affichage**, pas un prérequis. Aucune décision du
sprint n'attend sa création, et son absence n'est pas un blocage du sprint.

**Pourquoi** : le board n'apporte rien que le fichier ne contienne déjà (les 5 colonnes et la limite
WIP de 2 y sont écrites). Il ajoute de la visibilité, ce qui a de la valeur plus tard, quand plusieurs
personnes ou plusieurs agents travailleront en parallèle — pas maintenant, où il y a un humain et des
sessions successives. Or il coûte une action humaine (le jeton `gh` n'a pas le scope `project`) : le
faire attendre pour un sujet d'affichage serait disproportionné.

**Options écartées** : *bloquer le sprint jusqu'à la création du board* (un outil d'affichage ne
bloque pas un sprint) · *abandonner le board* (il sera utile dès que le WIP augmentera ; on ne jette
pas un outil gratuit) · *suivre les statuts dans les issues GitHub à la place* (les tickets sont déjà
rédigés et versionnés ; les dupliquer créerait deux sources de vérité qui divergeront).

**Preuves utilisées** : le refus de l'API (`missing required scopes [project read:project]`) —
c'est un coût humain réel, pas une difficulté technique.

**Conséquence / coût** : le suivi reste dans Git, en lecture seule sur GitHub. Quand le board sera
créé, il faudra y recopier tout le backlog — travail mécanique, à faire une fois, sans valeur ajoutée.
(Le nombre n'est volontairement pas écrit ici : un compteur figé dans une instruction vivante devient
faux au ticket suivant — défaut trouvé au planning du 2026-10-15.)
Assumé, parce que le report est gratuit et l'attente ne l'est pas.

**Ce qui me ferait changer d'avis** : dès qu'un deuxième agent travaille en parallèle sur le même
sprint, la lecture d'un fichier partagé ne suffit plus à éviter les collisions — le board devient
nécessaire et je le remets en tête de sprint.

**Qui exécute** : propriétaire humain (scope `gh`, quand il veut) · surveillance : PO.

---

## D-006 — Périmètre, ordre et règle d'exécution du Sprint 1 · 2026-10-15 · en vigueur

**Décision** : le Sprint 1 retient **7 tickets** (`S1-01`, `S1-02`, `S1-03`, `S1-04`, `S1-06`,
`S1-08`, `S1-09`) plus `S1-05` déjà fait. Il **refuse `S1-07`** et **crée `S1-09`** en prérequis.
Ordre : `S1-09` → `S1-08` → `S1-01` → `S1-02` → `S1-06` → `S1-03` → `S1-04`.
Règle d'exécution : développement contre un **Postgres local** (celui de la CI), Definition of Done
**vérifiée sur Supabase** avant tout `fait`.

**Pourquoi** : la validation de la Definition of Ready a montré que deux tickets n'étaient pas
implémentables tels qu'écrits (`S1-01` demandait un cron par campagne lu à l'exécution, impossible
dans n8n et sans trace du dernier passage). Un sprint qui démarre sur un ticket impossible produit du
retravail, pas de la valeur. Et le sprint n'est **pas** limité par la capacité (7 tickets ≤ cible de 8)
mais par un **verrou humain** (`S0-04`) : je préfère l'écrire et réordonner pour rendre faire ce qui
est faisable dès maintenant, plutôt que de présenter un sprint qui ne peut pas finir.

**Options écartées** :

- *Garder les 9 tickets tels quels* : `S1-01` non implémentable, la découverte du problème aurait eu
  lieu en cours d'implémentation, au prix d'une demi-journée et d'un ticket à réécrire.
- *Ne rien lancer avant que `S0-04` soit levé* : deux tickets (`S1-08`, `S1-09`) peuvent atteindre
  leur DoD **complète** dès maintenant, sans identifiant ni accès Supabase. Attendre serait du temps perdu
  pour préserver une illusion d'ordre.
- *Refuser `S1-04` (politesse de crawl) plutôt que `S1-07`* : la politesse de crawl est un **contrat
  avec une API publique** dès le premier appel (risques R2/R6), pas du confort. Le coût du délai de
  `S1-04` est élevé ; celui de `S1-07` est quasi nul avant la première collecte réelle.
- *Descendre la limite WIP à 1 pour compenser* : la contrainte est le verrou humain, pas la
  concurrence entre agents. Abaisser le WIP n'aurait rien débloqué et aurait allongé le délai.

**Preuves utilisées** : les quatre constats du planning, chacun vérifiable dans `docs/sprint-01.md` §3 —
`S1-01` (aucune trace du dernier passage de campagne dans le schéma), `S1-02` (le contrat de l'API
n'offre pas de confirmation du vocabulaire d'effectif : `tranche_effectif_salarie=53` renvoie
HTTP 200 avec 0 résultat, ce n'est **pas** une preuve que le code est valide), `S1-04` (la contrainte
ajoutée par `S1-05` empêche d'enregistrer la campagne invalide que le test demandait), `S1-08` (un
critère que le type de colonne rend infalsifiable).

**Conséquence / coût** : le backlog du sprint reste au-dessus de la cible tant que `S0-04` n'est pas
levé ; la documentation d'exploitation arrivera **après** la première collecte réelle, pas avant.
`S1-09` introduit une dépendance d'Architecte sur le chemin critique : elle doit être tranchée vite,
sinon elle devient le nouveau goulot.

**Ce qui me ferait changer d'avis** : si `S0-04` n'est pas levé au bout de **3 jours** (plus de la
moitié du sprint), je réordonne pour terminer `S1-09` + `S1-08` + `S1-01` et je déplace `S1-03` et
`S1-04` au Sprint 2 — je préfère trois tickets finis et vérifiés à cinq tickets à moitié faits.

**Qui exécute** : Orchestrateur (ordre et WIP) · rôles Backend/Data, Automation, Architecte ·
**humain** pour `S0-04`.

---

## D-007 — Le filtre d'effectif est conditionnel, et son absence est tracée · 2026-10-15 · **révisée par D-008** (déclencheur atteint le 2026-10-15)

**Décision** : le filtre `tranche_effectif_salarie` n'est appliqué à une collecte **que si** son code
est confirmé par une requête qui le prouve. Sinon la campagne est collectée **sans** ce filtre, et
l'écart est tracé dans `runs.details` (le champ créé par `S1-08`).

**Pourquoi** : RF-01 prévoit de cibler par tranche d'effectif, mais le vocabulaire de codes accepté par
l'API n'était traité nulle part dans le sprint. Or on sait déjà, pour l'avoir vérifié, que cette API
**ignore silencieusement** un paramètre inconnu : un filtre mal employé ne provoque pas d'erreur, il
rend des résultats non filtrés — le pire des cas, parce qu'il ressemble à un succès.

**Options écartées** :

- *Bloquer `S1-02` jusqu'à confirmation* : un détail de filtre ne doit pas retenir le cœur métier
  (appel d'API, pagination, règle de ciblage) qui, lui, est prêt.
- *Ignorer `effectif_min` sans rien dire* : contraire à « vérifier, ne pas croire », et le jour où
  quelqu'un croira filtrer par effectif, il ne filtrera rien sans le savoir.
- *Retirer `effectif_min` du modèle* : RF-01 le demande explicitement ; on ne supprime pas une
  exigence parce qu'un paramètre d'API est mal documenté.

**Preuves utilisées** : contrat réel de l'API vérifié le 2026-10-15 (le filtre d'activité s'appelle
`activite_principale` et non `code_naf` ; format NAF pointé obligatoire ; `per_page` ≤ 25 ;
`departement` filtre sur les établissements). Aucune preuve en revanche que `tranche_effectif_salarie`
accepte le code observé : la requête a renvoyé 0 résultat, ce qui ne distingue pas « code invalide »
de « aucune entreprise correspondante ».

**Conséquence / coût** : les campagnes existantes (`effectif_min = 1`) ne sont pas affectées. Une
campagne exigeant un effectif réel peut donc collecter **plus large que demandé** — c'est assumé et
visible, ce qui vaut mieux qu'un filtre supposé actif. À surveiller : le nombre de collectes où le
filtre n'a pas pu être appliqué.

**Ce qui me ferait changer d'avis** : dès qu'une requête prouve le vocabulaire (elle renvoie les
codes attendus **et seulement eux**, sur deux codes distincts), je rends le filtre obligatoire pour
les campagnes qui déclarent un `effectif_min`.

**Qui exécute** : Architecte (consigner le vocabulaire retenu) · Automation (`S1-02`).

---

## D-008 — Le filtre d'effectif devient obligatoire, et il s'exprime en **bandes** · 2026-10-15 · en vigueur

**Décision** : le filtre `tranche_effectif_salarie` n'est plus conditionnel. Il est appliqué **dès
qu'une campagne déclare un effectif minimum**. Le vocabulaire est **figé** aux 15 tranches d'effectif
salarié de l'unité légale (`00 01 02 03 11 12 21 22 31 32 41 42 51 52 53`). L'API ne filtrant que par
**bandes** et acceptant une **liste**, `campaigns.effectif_min` est traduit en **union de bandes** :
la bande qui contient la valeur demandée, **puis toutes les bandes supérieures**, en **une seule**
requête. Les bandes réellement appliquées sont écrites dans `runs.details`.

**Pourquoi** : `D-007` s'était engagé à rendre le filtre obligatoire « dès qu'une requête prouve le
vocabulaire ». La preuve est apportée le 2026-10-15 (revue du planning, API appelée) : les 15 codes
sont acceptés avec résultats, et 9 valeurs hors vocabulaire — dont `50` et `54`, syntaxiquement
valides — sont refusées en **HTTP 400**. La crainte qui justifiait la conditionnalité (un filtre faux
qui passe **silencieusement**) tombe pour un code prouvé : un code faux produit une **erreur visible**.
Le seul cas resté dangereux est le **nom** de paramètre mal orthographié, ignoré en silence — d'où
l'exigence de vérifier le nom exact, déjà inscrite à `S1-02`. Objectif servi : RF-01 (cibler par
tranche d'effectif). Règle d'arbitrage : (valeur × certitude) / effort — effort d'une requête,
certitude **mesurée**, valeur portée par une exigence explicite.

**Options écartées** :

- *Rester conditionnel (statu quo de `D-007`)* : le déclencheur est atteint ; garder un filtre « au cas
  où » ferait porter aux données une imprécision qu'on sait désormais mesurer.
- *Ajouter une colonne `effectif_tranche` et retirer `effectif_min`* : migration et changement de modèle
  pour rien, alors que « au moins N salariés » reste l'expression naturelle du besoin (RF-01).
- *Filtrer sur la seule bande contenant `effectif_min`* : **faux** — « au moins 60 salariés » traduit en
  bande `21` (50-99) **exclurait** les entreprises de 100 salariés et plus, qui satisfont l'exigence.
  C'est un sous-ensemble, donc un faux négatif **silencieux** : exactement le défaut que `D-007`
  cherchait à éviter.
- *Post-filtrer sur l'effectif exact* : impossible, l'API ne renvoie que la **bande**, jamais l'effectif.

**Preuves utilisées** (API appelée le 2026-10-15, tous NAF confondus, sorties reproduisibles) :
```
acceptés : 00 01 02 03 11 12 21 22 31 32 41 42 51 52 53   (HTTP 200, résultats > 0)
refusés  : 13 23 33 43 50 54 55 99 A1 ZZ                  (HTTP 400)
tranche_effectif_salarie=52,53                            -> 263 = 172 + 91   (union)
tranche_effectif_salarie=52&tranche_effectif_salarie=53   ->  91              (le dernier gagne)
```
Les 15 codes acceptés sont les tranches INSEE (`00` = 0 salarié … `53` = 10 000 et plus), corroborées
par l'INSEE et par `etalab/sirene_as_api`. Le « 0 résultat » observé sur `43.21A` × `53` était une
**intersection** NAF × effectif, pas une preuve d'invalidité : `53` seul renvoie 91 entreprises.

**Conséquence / coût** : le filtre est un **sur-ensemble assumé**. Pour `effectif_min = 60`, on accepte
aussi des entreprises de 50 à 59 salariés ; l'écart maximal est la **largeur de la bande contenant la
valeur demandée**. **Changement de comportement à déclarer** : les campagnes existantes
(`effectif_min = 1`) excluront désormais les unités à **0 salarié** (bande `00`) — moins de volume,
meilleurs leads. À surveiller : le volume par campagne après application, et le taux de rejet
(> 60 % = campagne trop large, brief §5).

**Ce qui me ferait changer d'avis** : une chute de plus de **50 %** du volume collecté d'une campagne
existante après application du filtre, ou une campagne dont `effectif_min` rend la bande contenante
manifestement trop large (demander 200 salariés et recevoir des entreprises de 100). Dans ce cas, la
campagne déclarera ses **bandes** explicitement, au lieu d'un entier.

**Qui exécute** : Automation (`S1-02`) · Backend/Data (`S1-08`, pour la trace des bandes appliquées).
**Origine** : revue [`reviews/2026-10-15-planning-sprint-1.md`](reviews/2026-10-15-planning-sprint-1.md),
constat n° 4.

---

## D-009 — Au re-passage d'une campagne, `campaign_id` n'est **pas** re-piqué · 2026-10-20 · en vigueur

**Décision** : le payload d'upsert de `S1-03` ne porte **jamais** la colonne `campaign_id`. La ligne
`companies` garde la campagne qui l'a créée pour la première fois ; un re-passage de collecte
(éventuellement déclenché par une autre campagne) met à jour les données métier sans réattribuer
la propriété.

**Pourquoi** : ce que WF2/WF3 auront trouvé et rattaché ne doit jamais être déplacé par une
re-collecte. Repiquer `campaign_id` n'ajoute par ailleurs rien au dédoublonnage : une ligne est
unique par SIREN, et sa « campagne » ne sert qu'à savoir qui l'a découverte. Le re-passage a un
seul objectif : rafraîchir les données réelles du registre public.

**Options écartées** :

- *Inclure `campaign_id` dans le payload* (la ligne « suit sa dernière collecte ») : la campagne
  qui a découvert l'entreprise perd la trace de cette découverte dès qu'une re-collecte passe, et
  les compteurs par campagne (runs, D-002) ne se réconcilient plus avec le contenu de `companies`.
- *Envoyer un `null` explicite* : écraser une valeur réelle avec un `null` est du silence destructeur.

**Preuves utilisées** : la preuve `S1-03` — au premier passage, les lignes nouvelles reçoivent leur
`campaign_id` par une **passe de propriété distincte** (PATCH PostgREST restreint aux SIREN du lot
*et* à `campaign_id IS NULL` — cf. ADR 0007, la passe n'attribue que les lignes fraîches) ; au
re-passage d'une campagne de test, le `campaign_id` des lignes existantes reste inchangé ; les
colonnes enrichies (`website`, `email`, `phone`, `website_source`) sont, elles, **jamais envoyées**
(plus fort que « pas écrasées ») — contrat vérifié dans le contenu du payload émis (AGENTS.md §10 :
un lot = un seul POST atomique).

**Conséquence / coût** : la ligne `companies` reste propriété de sa campagne de découverte ; au
re-passage, son `campaign_id` ne bouge pas, même si la re-collecte vient d'une autre campagne.

**Ce qui me ferait changer d'avis** : si l'exploitation a un jour besoin de savoir quand une ligne
a été vue en collecte pour la dernière fois (par quelle campagne), cela demande une colonne dédiée
(ex. `last_collected_at`) — pas un déplacement du `campaign_id`.

**Qui exécute** : Automation (`S1-03`, le payload d'upsert) · le propriétaire (l'arbitrage écrit ici).

---

## D-010 — Dans un lot de collecte, un SIREN en double a son **premier** item qui gagne · 2026-10-20 · en vigueur

**Décision** : le lot construit par le Code node de `S1-03` garde, pour un même SIREN deux fois
(couple multi-départements), les données de son **première** occurrence (ordre du flux), et
rejette les occurrences suivantes, comptées avant l'écriture.

**Pourquoi** : le payload d'un lot est **unique par SIREN** sans dépendre de l'ordre du POST (garde
PostgREST : « ON CONFLICT DO UPDATE command cannot affect row a second time »). Le « premier
gagne » est vérifiable sans supposer l'ordre interne d'un POST atomique : une collecte produit les
entreprises dans l'ordre de lecture du registre, la première occurrence est identifiable sans
ambiguïté au moment du Code node.

**Options écartées** :

- *Le dernier gagne* : il fait dépendre la valeur retenue de l'ordre d'arrivée des données de
  collecte, et suppose de relire la base pour comprendre « pourquoi celui-là a gagné », là où le
  premier gagne est posé une fois pour toutes dans le Code node.
- *Fusionner les données des deux occurrences (par colonne, coalesce)* : il crée un comportement
  inexpliqué pour l'exploitation (un mélange non demandé des deux collectes), sur un cas de
  volume marginal.

**Preuves utilisées** : la preuve de `S1-03` — un lot contenant deux fois le même SIREN (avec des
données différentes) est écrit une fois, avec les données du **premier** item ; les doublons sont
rejetés **avant** l'écriture et comptés (détails, jamais perdus) ; la garde PostgREST
(« cannot affect row a second time ») n'est jamais touchée.

**Conséquence / coût** : le lot est unique par SIREN — un lot mélangé (un SIREN nouveau + un SIREN
existant) écrit les nouveaux et met à jour les existants en un seul POST, et un re-passage de
campagne ne change le nombre de lignes de ni le contenu envoyé ni la campagne propriétaire.

**Ce qui me ferait changer d'avis** : si la collecte peut qualifier la fraîcheur relative des deux
occurrences du même SIREN dans un même lot (ex. une date de mise à jour du registre par ligne),
« le dernier gagne » pourra reprendre l'arbitrage — sur preuve, et par une révision de D-010.

**Qui exécute** : Automation (`S1-03`, le Code node de dédoublonnage) · le propriétaire (l'arbitrage écrit ici).

---

## D-011 — Le « vérifié » de la Definition of Done, pour la chaîne de collecte, est une exécution de bout en bout · 2026-10-26 · en vigueur

**Décision** : pour tout ticket dont le livrable touche la chaîne de collecte de WF1 (un nœud, une
arête, un contrat de données, un réglage de robustesse), la ligne « Déployé et vérifié sur
l'environnement cible » de la Definition of Done (§2.4 de la méthode) signifie : **une exécution de
WF1 de bout en bout** — 1 campagne due, 1 couple (code NAF × département), ≤ 25 éléments attendus —
avec **la ligne `runs` lue en base** comme preuve, et **au moins un scénario d'échec provoqué** si le
ticket touche la robustesse. La preuve se fait sur une instance n8n **jetable**, avec une **copie**
du workflow exporté (pratique de `S1-02`, `S1-03`, `S1-06`). Le statut de l'UI n8n seul n'est **pas**
une preuve recevable ; la ligne `runs` (statut, `items_processed`, `details`, `error`) l'est.

**Pourquoi** : cela sert l'objectif du cahier des charges « une chaîne qui collecte réellement » et
la métrique étoile polaire (leads livrés par semaine au-dessus du seuil) — c'est la seule qui prouve
la chaîne de bout en bout. La CI ne peut pas l'exercer : elle ne teste que le SQL, et le job `node`
s'annonce ignoré. Le trou est **démontré**, pas supposé : `S1-02`, `S1-03` et `S1-04` ont chacun
passé leur CI et leur preuve locale, et la chaîne entière n'avait **jamais** tourné d'un bout à
l'autre — trois défauts l'ont traversée (rattachement des couples faux, conciliation restée
orpheline, harnais de test cassé), dont un **critique** qui a vécu 6 jours sur `main` derrière une
CI verte et deux tickets marqués `fait`.

**Règle d'arbitrage utilisée** : `(valeur × certitude) / effort`, ajustée du **coût du délai**.
Valeur : la chaîne de collecte est la brique qui débloque WF2 et WF3, donc elle passe avant sa
valeur propre. Certitude : totale — la mesure a déjà eu lieu et a trouvé les trois défauts. Effort :
~30 min par ticket concerné. Coût du délai : un défaut de collecte invisible « réussit » pendant
plusieurs jours ; c'est le coût le plus élevé du sprint 1, mesuré.

**Options écartées** :

- *S'en remettre à la CI* : elle ne teste que le SQL, et le défaut critique a vécu 6 jours derrière
  une CI verte (mesuré). La règle ne fermerait pas le trou qu'elle prétend fermer.
- *Écrire l'exigence au cas par cas dans le ticket* : c'est exactement l'état qui a échoué —
  l'exigence était écrite dans `S1-04`, et le ticket a été fusionné avec la mention
  « *(à faire pour la DoD complète)* ». Une règle qui varie selon le ticket n'est pas une règle.
- *Bloquer les tickets de collecte jusqu'à ce qu'une CI sache exercer n8n* : coût prohibitif et sans
  rapport avec l'objectif du sprint — la mesure manuelle coûte 30 min, une CI n8n est un chantier.
  À réévaluer (cf. ci-dessous), pas à attendre.
- *Se contenter d'un test à blanc sans écriture en base* : il ne prouve ni l'upsert, ni les
  compteurs, ni la clôture de campagne — c'est-à-dire pas la chaîne.

**Preuves utilisées** : preuve d'exécution du 2026-10-26 (instance n8n jetable, projet Supabase
réel) — User-Agent observé sur le fil, écart **948 ms** entre deux appels, retry ×3 (503, 503, 200 →
`success`), 2 couples dont un en panne → `partial` avec message exploitable, endpoint faux →
`status = error` + `ENOTFOUND`, réponse vide (département valide) → `success` 0 écrit, collecte
réelle 2 couples → `success`, `items_processed = 2`, **2 lignes `companies` réellement écrites** ;
base rendue à 0/0/0 après chaque scénario.

**Conséquence / coût** : ~30 min par ticket touchant la chaîne de collecte. Un `fait` sans cette
preuve vaut un `🟦` : le ticket repasse en review. La preuve vit dans la section du ticket (sortie de
commande et extrait de la ligne `runs`), pas seulement dans la description de la PR.

**Ce qui me ferait changer d'avis** : un job de CI capable d'importer un workflow dans un n8n
conteneurisé et de l'exercer de bout en bout — le coût manuel tomberait à zéro ; ou deux sprints
consécutifs où ce garde-fou ne trouve rien alors qu'un défaut de collecte est découvert par une
autre voie (il serait alors mal placé, non inutile).

**Qui exécute** : Automation (produit la preuve et l'écrit dans le ticket) · Orchestrateur (refuse
la clôture sans elle) · le PO (l'arbitrage écrit ici). Inscrire la règle dans la liste de la DoD
(`methode-equipe-agents.md` §2.4) sort du périmètre d'édition de ce rôle : à porter par le
propriétaire du dépôt.

**Origine** : revue [`reviews/2026-10-26-sprint-1-review.md`](reviews/2026-10-26-sprint-1-review.md)
§5, décision n° 1.

---

## D-012 — Le timeout de collecte reste à 10 s ; la rotation d'adresses se mesure avant d'être décidée · 2026-10-26 · en vigueur

**Décision** : le nœud de collecte garde `timeout = 10 s` et `retryOnFail = ×3` (délai **fixe**
5 000 ms — plafond de n8n). On ne l'allonge pas, et on n'ajoute **aucun** réessai d'adresse tant que
la rotation d'adresses n'a pas été **mesurée**. Un échec de collecte reste `status = error` avec un
message exploitable : jamais un « succès » muet.

**Pourquoi** : cela sert le critère d'acceptation v1 « un échec de collecte doit se voir » et le
garde-fou « aucun plantage silencieux ». Allonger un délai ne traite pas la cause : mesuré le
2026-10-26, `recherche-entreprises.api.gouv.fr` résout **trois** adresses — `.76` → HTTP 200 en 2,0 s,
`.77` → délai dépassé après **15,0 s**, `.78` → délai dépassé après **12,7 s** — et aucun client ne
réessaie une autre adresse après un échec de connexion. **Hypothèse non testée, nommée comme telle** :
cette panne est propre au réseau d'où la mesure a été faite ; elle n'a pas été reproduite depuis
l'hôte d'exécution réel.

**Règle d'arbitrage utilisée** : le garde-fou de **vérité d'état** passe avant le confort de run.
Un timeout plus long **masque** une panne (« le run était juste lent »), un timeout infini laisse la
ligne `runs` en `running` — l'observabilité ment dans les deux cas. Le coût d'un faux `error` est
nul : il est visible et lisible dans `runs.error`.

**Options écartées** :

- *Passer à 30 s ou 60 s* : ne corrigerait rien **dans la mesure disponible** — les deux adresses
  muettes ne répondent ni à 12,7 s ni à 15,0 s ; un délai plus long produit le même `error`, plus
  tard, et rend un vrai ralentissement invisible. Coût : un run bloqué plus longtemps par page.
- *Retirer le timeout* : la ligne `runs` resterait `running` indéfiniment — le plantage silencieux
  sous une autre forme, exactement ce que `S1-04` interdit.
- *Forcer un réessai sur une autre adresse tout de suite* : piste plausible mais **non mesurée** —
  rien ne dit qu'un réessai n8n re-résout le DNS au lieu de réutiliser l'adresse en échec, ni qu'il
  tomberait sur `.76`. Décider là-dessus serait une opinion confiante ; c'est un ticket de mesure.
- *Contourner l'API publique par un miroir ou un cache* : introduit une dépendance et un coût
  récurrent, contre le garde-fou « coût récurrent = 0 € », pour un défaut non prouvé côté API.

**Preuves utilisées** : les trois mesures d'adresses du 2026-10-26 (une seule joignable sur trois) ;
la preuve d'exécution `S1-04` — hôte inexistant → `status = error`, `getaddrinfo ENOTFOUND …`, et le
run le **dit** au lieu de sortir en `success` avec 0 élément.

**Conséquence / coût** : une part des runs de collecte sortira en `error` alors que le code est
correct. C'est un signal d'environnement, pas un défaut — et cela ne se corrige **jamais** en
affaiblissant le timeout. Point de surveillance : le taux de runs `error` sur l'API publique, à
relever au sprint 2.

**Ce qui me ferait changer d'avis** : une mesure montrant qu'un réessai atteint une autre adresse
(on l'ajoute alors, timeout inchangé) ; ou **3 adresses sur 3 joignables** depuis l'hôte d'exécution
réel — la cause serait locale, et cette décision serait révisée sur cette mesure.

**Qui exécute** : Automation (configuration du nœud HTTP : `timeout 10 s`, `retryOnFail ×3`, délai
fixe 5 000 ms) · Orchestrateur (ticket de mesure de la rotation d'adresses au sprint 2) · le PO
(l'arbitrage écrit ici).

**Origine** : revue [`reviews/2026-10-26-sprint-1-review.md`](reviews/2026-10-26-sprint-1-review.md)
§5, décision n° 2.

---

## D-013 — `S1-07` reste refusé, et sa condition de retour devient vérifiable · 2026-10-26 · en vigueur

**Décision** : `S1-07` (documentation d'exploitation de WF1) reste **refusé** du sprint 1. Sa
condition de retour cesse d'être « dès 1 collecte réelle » — formulation trop floue pour être
contrôlée — et devient : le ticket passe en `Prêt` **dès qu'une exécution de WF1 a réellement appelé
`recherche-entreprises.api.gouv.fr` et écrit au moins une ligne `companies`**, la preuve étant la
ligne `runs` **et** le SIREN présent en base. Une exécution contre un hôte d'écho, même concluante,
ne remplit **pas** la condition.

**Pourquoi** : cela sert la valeur même de la documentation d'exploitation, qui est de diagnostiquer
un incident. Une procédure écrite pour une chaîne qui n'a jamais réussi contre l'API réelle décrit un
état qui n'existe pas, et sera réécrite au premier incident. La condition de retour du planning du
2026-10-15 n'était pas vérifiable : c'est ce flou qui a laissé planer le doute après la collecte du
2026-10-26 — réussie, mais **contre un hôte d'écho local**, seule l'URL de collecte étant substituée.

**Règle d'arbitrage utilisée** : `(valeur × certitude) / effort`. Valeur : réelle mais **non
débloquante** (l'exploitation est encore à 0 campagne, 0 entreprise). Certitude : nulle tant que
l'API publique n'a pas répondu en `success`. Effort : petit. Donc **oui** au ticket, **pas
maintenant** — et il remonte à la première occasion, sans rouvrir de débat.

**Options écartées** :

- *Tenir la collecte contre l'écho pour « réelle »* : vide la condition de son sens. La doc
  affirmerait « WF1 collecte » alors que WF1 n'a jamais rien collecté à la source ; le premier
  incident révélerait l'écart.
- *Écrire la doc maintenant, limitation inscrite dedans* : la limitation n'est pas stable (elle est
  peut-être réseau — cf. D-012). Documenter une procédure dont on ne sait pas si elle est bonne
  produit une fausse assurance d'exploitation.
- *Reformuler la condition en « dès 1 exécution de bout en bout »* : c'est le garde-fou de **D-011**,
  qui sert la clôture des tickets de code ; il ne dit rien de la joignabilité de l'API publique, qui
  est précisément ce que `S1-07` doit documenter.
- *Faire porter la doc par le ticket de mesure de D-012* : mélange deux livrables (une mesure, une
  procédure) — si la mesure échoue, la doc meurt avec elle.

**Preuves utilisées** : preuve du 2026-10-26 — la collecte de bout en bout a tourné **contre un écho
local** (seule l'URL de collecte substituée), 2 lignes `companies` écrites, base rendue à 0/0/0
après ; la collecte sur l'API publique n'a **pas** été rejouée en `success` (cf. D-012). Statut réel
du ticket au 2026-10-26 : `⬜`, en-tête aligné sur le tableau du §2 du sprint.

**Conséquence / coût** : le sprint 1 se termine avec **un ticket refusé, assumé et daté** — un refus,
pas un oubli. Tant qu'il n'est pas rouvert, un incident WF1 se diagnostique par la lecture de `runs`
en base et de l'UI n8n : les deux chemins existent déjà, ils ne sont simplement pas écrits pour
l'exploitation.

**Ce qui me ferait changer d'avis** : la première collecte réussissant sur l'API publique — la
condition se remplit d'elle-même ; ou l'ouverture de `WF2`/`WF3` avant elle, auquel cas la doc
d'exploitation de WF1 devient nécessaire **avec la limitation écrite dedans**, plutôt que d'attendre.

**Qui exécute** : Orchestrateur (maintien du refus, remise en `Prêt` sur la preuve décrite) ·
Documentation (`S1-07`) · le PO (l'arbitrage écrit ici).

**Origine** : revue [`reviews/2026-10-26-sprint-1-review.md`](reviews/2026-10-26-sprint-1-review.md)
§5, décision n° 3.

