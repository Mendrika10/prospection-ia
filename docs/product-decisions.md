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
(`methode-equipe-agents.md` §2.4) sortait du périmètre d'édition de ce rôle : **fait le 2026-10-26
sur instruction du propriétaire du dépôt** — la ligne « Déployé et vérifié sur l'environnement
cible » y porte désormais la règle, sans qu'une autre décision soit nécessaire. Même exigence portée
sur les deux gabarits de clôture (`.github/ISSUE_TEMPLATE/ticket.md`,
`.github/PULL_REQUEST_TEMPLATE.md`), qui listaient leur propre DoD sans cette ligne : une règle que
l'agent qui ferme le ticket ne lit pas n'est pas encore appliquée.

**Consigné** : PR **#43** fusionnée en squash `afd196b`, CI de `main` **verte** (run 40333027573).

**Origine** : revue [`reviews/2026-10-26-sprint-1-review.md`](reviews/2026-10-26-sprint-1-review.md)
§5, décision n° 1.

---

## D-012 — Le timeout de collecte reste à 10 s ; la rotation d'adresses se mesure avant d'être décidée · 2026-10-26 · **révisée par D-014** (mesure faite le 2026-10-26)

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

---

## D-014 — La panne d'adresses de l'API est réelle mais absorbée par le client : le timeout reste à 10 s · 2026-10-26 · **révisée par D-015** (l'exécution réelle montre que le nœud HTTP de n8n, lui, ne bascule pas)

**Décision** : trois choses, et la première est que **rien ne change** dans les réglages.

1. Le nœud de collecte garde `timeout = 10 s` et `retryOnFail ×3` (délai fixe 5 000 ms) et
   **aucune rotation d'adresses n'est ajoutée** : la mesure du 2026-10-26 montre que le client
   **bascule tout seul** sur l'adresse vivante quand la première ne répond pas.
2. Le **ticket de mesure** annoncé par `D-012` est **clos par cette mesure** : il n'y a pas de
   rotation à ajouter, donc rien à ouvrir au sprint 2 sur ce sujet.
3. La **prédiction** de `D-012` (« une part des runs sortira en `error` ») est **corrigée** : elle ne
   se vérifie pas. Ce qui reste — et devient le point de surveillance — est un risque de nature
   différente : l'API n'est joignable que par **une adresse vivante sur trois**, et la bascule du
   client **masque** cette dépendance.

**Pourquoi** : cela sert le critère d'acceptation v1 « un échec de collecte doit se voir », sans
renier la règle de vérité d'état de `D-012` — on ne rallonge toujours pas un délai pour faire
disparaître un échec. Mais une décision dont la conséquence prédite est démentie par sa **propre
mesure** doit être révisée par écrit : sinon le prochain lecteur croira que WF1 échoue une fois sur
deux et « corrigera » un timeout qui n'a rien à se reprocher. La mesure n'a pas changé le **réglage**
(`D-012` reste appliquée telle quelle) : elle a changé le **motif** et le **risque**. C'est ce que
cette décision consigne.

**Règle d'arbitrage utilisée** : la même que `D-012` — la **vérité d'état** avant le confort de run —
mais appliquée à l'envers : ici la mesure dit que l'état réel est **meilleur** que craint, donc l'effort
justifié est **nul** (aucun réglage) et le seul livrable utile est le risque nouvellement identifié.
Coût du délai : une prédiction fausse laissée dans le journal coûterait une « correction » inutile au
premier run lent.

**Options écartées** :

- *Ajouter une rotation d'adresses dans WF1* : inutile — le repli existe déjà et a été mesuré 8 fois
  sur 8, sur l'hôte comme dans le conteneur — et hors de portée du Code node (sans réseau,
  `AGENTS.md` §10). La faire dans le nœud HTTP voudrait dire viser une IP figée en quittant le nom,
  c'est-à-dire transformer la panne de `.76` en panne **définitive**.
- *Allonger le timeout* : les adresses mortes ne répondent à **aucun** délai (6 essais sur 6 en
  timeout à 12 s, et 15,0 s mesuré la veille, sans SYN-ACK) — cela ne changerait rien sinon la durée
  d'un échec.
- *Retirer `retryOnFail ×3`* : le retry reste utile là où il a été mesuré utile (503 → 200, `S1-04`),
  son coût est nul et il ne peut pas nuire ici.
- *Ne pas réviser `D-012` et laisser sa prédiction fausse* : c'est exactement l'écart entre la doc et
  la réalité que le sprint 1 a payé une fois (`S1-04`).

**Preuves utilisées** : mesure du 2026-10-26 — protocole, sorties brutes des deux relevés et limites
in [`reviews/2026-10-26-mesure-rotation-api.md`](reviews/2026-10-26-mesure-rotation-api.md). En bref :
`.77` et `.78` muettes au niveau **TCP** (SYN sans réponse, 6/6 en timeout à 12 s), `.76` à 199–209 ms
au TCP et 263–656 ms en HTTP ; **8 appels sur 8 réussis** par le nom, sur l'hôte **et** dans le
conteneur n8n, tous joints sur `.76` ; le résolveur renvoyait une adresse **muette** en premier (`.78`
puis `.77`, 5 fois sur 5 chacune) ; marge du timeout de 10 s ≈ **8×** (265 ms en régime établi,
1 196 ms à froid).

**Conséquence / coût** : aucun réglage ne change — coût minimal. À surveiller, en revanche, un point de
défaillance unique qui n'apparaissait pas dans le récit : **si `.76` devient muet, il n'existe plus
aucune adresse de repli** et la collecte ne peut plus rien collecter, quel que soit le timeout. Le
signal d'alerte est un run `error` de type timeout sur la collecte, sans autre explication.

**Ce qui me ferait changer d'avis** : une **exécution réelle de WF1** montrant que le nœud HTTP, lui,
**ne** bascule pas — c'est le seul maillon que cette mesure ne prouve pas ; on reviendrait alors à
`D-012`, rotation et timeout à retravailler. Ou `.76` muet à son tour : le problème n'est plus un
réglage mais une **dépendance**, et la réponse serait un plan de repli (autre voie d'accès à l'API),
décidé à ce moment-là.

**Qui exécute** : Automation (ne change rien à la configuration du nœud) · Orchestrateur (n'ouvre
rien — le ticket de mesure est clos — et surveille le premier run `error` de collecte) · le PO
(l'arbitrage écrit ici).

**Origine** : ticket de mesure annoncé par `D-012`, exécuté le 2026-10-26 ; revue
[`reviews/2026-10-26-sprint-1-review.md`](reviews/2026-10-26-sprint-1-review.md) §5, décision n° 2.

**Consigné** : PR **#45** fusionnée en squash `99efd2c`, CI de `main` **verte** (run 40335525914).

---

## D-015 — L'exécution réelle a prouvé la chaîne et révélé deux défauts bloquants · 2026-10-26 · en vigueur — **point 1 révisé par D-016** (le nœud HTTP de n8n bascule : le défaut A n'existe pas)

**Décision** : quatre points, dont le premier corrige une décision que j'ai prise trois heures plus tôt.

1. **`D-014` est révisée, et sa conclusion est fausse pour le client qui compte.** Elle affirmait que
   la panne d'adresses est « absorbée par le client » — vérifié sur un client Node **nu**, démenti sur
   le **nœud HTTP de n8n** : deux exécutions réelles, **3 tentatives × 10 s, 3 timeouts**, rien
   collecté. Le timeout de 10 s n'était pas l'obstacle, l'adresse choisie l'était.
2. **Deux défauts mesurés deviennent des tickets de levée, en tête du sprint 2** :
   - **Défaut A — sélection d'adresse.** La collecte ne doit pas dépendre du hasard du résolveur :
     il faut un moyen d'atteindre l'adresse vivante, décidé sur mesure (pas d'épinglage `/etc/hosts`
     en production, qui transformerait une adresse muette en panne **définitive**).
   - **Défaut B — attribution des pages.** `pairedItem.item` d'un nœud HTTP **paginé** est l'index de
     **page**, pas celui du couple : au-delà de la première page, la collecte est soit abandonnée
     (index hors bornes — visible), soit **mal attribuée en silence** (les pages d'un couple
     comparées au département d'un autre). Le rattachement de `S1-04` doit être refait sur une
     **clé portée par la donnée**, jamais sur un index implicite.
   Ces deux défauts bloquent la collecte d'une campagne réelle : ils passent **avant tout nouveau
   périmètre** du sprint 2.
3. **La prémisse « ≤ 25 éléments » est abandonnée.** Mesuré : sur **30 couples** testés, **2**
   tenaient sur une page ; `43.21A` × `974` en compte **1 515** (61 pages). Toute preuve de collecte
   doit désormais se faire sur un couple **multi-pages** — sinon elle ne prouve rien du cas normal.
4. **`S1-07` passe en `Prêt`.** Sa condition de retour (`D-013`) est **remplie** : une exécution a
   réellement appelé l'API publique et écrit **20 lignes `companies`** (`runs.status = success`,
   `items_processed = 20`, compteurs cohérents). La documentation devra décrire l'état **réel**,
   défauts compris, plutôt qu'un idéal.

**Pourquoi** : cela sert l'objectif « une chaîne qui collecte réellement » et le garde-fou de
**vérité d'état**. Le défaut B mérite à lui seul une décision : il **corrompt des données en
silence** quand deux couples partagent un code NAF, ce qui est exactement la classe du défaut
critique de `S1-04` (un mensonge qui ressemble à un succès). Le défaut A, lui, rend la collecte
impossible : aucune campagne réelle ne peut être honorée aujourd'hui.

**Règle d'arbitrage utilisée** : `(valeur × certitude) / effort`, ajustée du **coût du délai**. Le
coût d'un défaut silencieux est le plus élevé du journal (il a déjà coûté 6 jours sur `main`) ; ces
correctifs passent donc devant le périmètre de WF2. Certitude : **totale**, les deux défauts sont
mesurés, pas déduits.

**Options écartées** :

- *Livrer les correctifs dans la foulée de la preuve* : la Definition of Ready exige un ticket avec
  ses critères vérifiables **avant** le code, et la DoD exige une relecture en contexte neuf — que
  la même session ne peut pas fournir. Décider et exécuter dans le même souffle, c'est rejouer
  l'écart de `S1-04`.
- *Contourner le défaut A par un `/etc/hosts` ou un `--add-host` en production* : cela fixe une IP
  dans une configuration invisible du dépôt ; le jour où l'adresse change, la panne devient
  **définitive** (plus aucun repli) et sans propriétaire.
- *Ne traiter que le défaut A* (le plus visible) : c'est le défaut B qui écrit de **fausses lignes**,
  et il touche la quasi-totalité des campagnes réelles (2 couples sur 30 tiennent sur une page).
  Traiter le visible et laisser le silencieux serait l'erreur exacte que ce sprint a déjà payée.
- *Garder `S1-07` refusé* : sa condition est remplie telle que `D-013` l'a écrite ; la refuser encore
  reviendrait à déplacer les poteaux. Une doc qui décrit une chaîne à deux défauts connus est
  **plus** utile qu'une doc écrite quand tout marchait.
- *Refaire la preuve sur `43.21A` × `974` pour « voir de ses yeux »* : déjà fait (run 3), coûte 125 s
  et 61 pages, et le procès du défaut B est instruit par deux mini-workflows isolés.

**Preuves utilisées** :
[`reviews/2026-10-26-execution-reelle-wf1-api-publique.md`](reviews/2026-10-26-execution-reelle-wf1-api-publique.md)
— protocole, 4 exécutions avec leurs sorties, 2 mini-workflows de diagnostic, sondes de pagination
(`1 515` résultats / 61 pages), et **remise en état de la base** (20 entreprises écrites → supprimées,
base relevée à **0 / 0 / 0**). En bref : run 1 et 2 `error` (3 × timeout), run 3 `error` (60 pages
sans couple rattachable), run 4 **`success`** + 20 lignes + compteurs cohérents.

**Conséquence / coût** : la collecte sur l'API publique est **inutilisable en l'état** pour une
campagne réelle — non par le timeout, mais par l'adresse choisie et l'attribution des pages. Coût
assumé : deux tickets avant tout nouveau périmètre, et une **preuve multi-pages** à refaire après
correctif. Ce qui a été prouvé reste acquis : la chaîne écrit correctement, les compteurs sont
cohérents, et un échec est **toujours** visible dans `runs`.

**Ce qui me ferait changer d'avis** : une collecte **multi-pages** réussie après correctif (2 couples,
≥ 2 pages chacun, `runs.details` cohérents et lignes attribuées au **bon** département) ; ou la
preuve que l'API répond normalement depuis un autre réseau d'exécution — la panne d'adresses serait
alors locale, et le défaut A n'existerait que sur ce poste.

**Qui exécute** : Automation (les deux correctifs, sur tickets) · Reviewer (relecture en contexte
neuf, obligatoire cette fois) · Orchestrateur (ouvrir les deux tickets en tête du sprint 2, refaire
la preuve sur un couple multi-pages) · le PO (l'arbitrage écrit ici).

**Origine** : exécution de bout en bout exigée par `D-011` et par la condition de retour de `D-013`,
faite le 2026-10-26 ; révise `D-014` ; complète `D-012`.

**Tickets ouverts** : **`S2-01`** (défaut A — atteindre une adresse vivante) et **`S2-02`** (défaut B
— rattacher chaque page au bon couple), en tête du backlog du sprint 2, critères d'acceptation et
DoR compris : [`sprint-02.md`](sprint-02.md) — PR **#49** fusionnée en squash `0f5ca02`, CI de
`main` **verte** (run 40341246152).

**Consigné** : PR **#47** fusionnée en squash `cd6bbb4`, CI de `main` **verte** (run 40339795807).

---

## D-016 — Le défaut A n'existe pas : le nœud HTTP de n8n bascule bien d'adresse · 2026-10-26 · en vigueur

**Décision** : cinq points, dont le premier **corrige `D-015`** — que j'avais écrite le matin même.

1. **Le défaut A est requalifié : il n'existe pas.** Le nœud HTTP de n8n **bascule** d'adresse —
   **10 exécutions sur 10** réussies sans aucun épinglage (22 résultats, < 1 s), et la trace réseau du
   code de n8n montre le repli exercé : deux adresses muettes à 500 ms chacune, puis l'adresse
   vivante connectée. Le point 1 de `D-015` (« le nœud HTTP de n8n ne bascule pas ») est **révisé**.
2. **L'échec du 2026-10-26 s'explique par ce que le résolveur rendait, pas par le client** : le
   symptôme enregistré — 3 tentatives × 10 s, `timeout of 10000ms exceeded`, rien collecté — se
   reproduit **à volonté** dès qu'aucune adresse du jeu ne répond (`40,1 s` mesurées en épinglant le
   nom sur une adresse muette). Pendant les runs 1 et 2, aucune adresse du jeu rendu ne répondait.
   Le contre-argument « un client Node **nu** réussit 8 fois sur 8 » **ne départage pas** : ce relevé
   n'est pas daté par rapport aux deux échecs, et le repli ne fabrique pas une adresse qui répond.
3. **`S2-01` se clôt sans une ligne de code changée** — et le ticket avait raison de demander une
   décision écrite : ici, *corriger* signifie corriger **le dossier**. Critère 1 (collecte réussie
   sans épinglage) et critère 2 (mode d'échec intact) sont **vérifiés** ; critère 4 (politesse)
   l'est **par construction** (`n8n/workflows/` non modifié).
4. **Deux réglages passent en interdit explicite**, mesurés comme les seuls à reproduire la panne
   **sans** épingler le nom : figer la famille d'adresses (`family`) et **désactiver l'autosélection**
   (`autoSelectFamily: false`) réduisent la résolution à une adresse (timeout 10,0 s mesuré dans les
   deux cas, contre 200 en 1,9 s sans eux). Épingler le nom sur une adresse muette reste autorisé
   **en preuve** — c'est l'outil qui reproduit le mode d'échec — et reste **interdit en production**.
   
   Règle générale qui en sort, et qui vaut au-delà de ce ticket : **un symptôme reproduit n'est pas
   une cause attribuée.** Deux mesures non simultanées comparées comme si elles l'étaient ont coûté
   un ticket, une section de `AGENTS.md` §10 fausse, et une révision de décision. Toute attribution
   (« c'est X qui ne suit pas ») doit être établie **dans la même fenêtre**, sur le même chemin
   d'exécution, ou rester une hypothèse.
5. **Le défaut B reste le seul défaut de la collecte, et `S2-02` reste le ticket de levée.** Sa
   dépendance (`S2-01`) est **satisfaite** : le code peut être préparé et éprouvé dès maintenant. Un
   **constat annexe** est consigné — deux campagnes dues dans un même lot : deux lignes `runs` créées
   dans la même transaction, **une seule** clôturée, la seconde campagne affamée et sa ligne figée en
   `running` — mais il n'est **pas** transformé en ticket ici : la Definition of Ready exige des
   critères vérifiables, je n'ai qu'une observation **non isolée**. À instruire au planning, avec sa
   propre mesure ; ne pas décider sur une observation incidente, c'est exactement l'erreur du matin.

**Pourquoi** : `D-011` ne rend un « vérifié » utilisable que s'il est vrai ; ici, la règle a produit
l'effet inverse de celui espéré — elle a transformé une panne transitoire en défaut de code, et un
ticket a été ouvert pour corriger un composant qui fonctionne. Laisser ce dossier en l'état coûterait
un correctif inutile dans la partie la plus fragile de WF1 (le rattachement des pages, là où `S2-02`
intervient pour de vrai), et surtout **laisserait croire que « ça marche depuis mon poste » ne dit rien
de la collecte** — ce qui est faux : la mesure montre l'inverse. Corriger la fiche fait gagner le
correctif, et rend la prochaine panne d'adresse interprétable en trois minutes.

**Règle d'arbitrage utilisée** : `(valeur × certitude) / effort`, ajustée du **coût du délai**.
Certitude : **totale**, et c'est le point — `10/10` en environnement réel, une trace réseau, un
symptôme reproduit à volonté, une preuve de bout en bout en base. Effort du « correctif » : **nul**,
puisqu'il n'y a rien à corriger ; valeur : élevée, parce que la cause est nommée et le mode de
défaillance reste **visible** (`error`, jamais un faux `success`).

**Options écartées** :

- *Écrire quand même un correctif dans le nœud* (repli maison, second appel, hôte substitué) : le
  repli existe déjà et fonctionne (10/10, trace à l'appui). Ajouter du code pour un défaut non
  constaté, dans la partie de WF1 que `S2-02` doit de toute façon refaire, serait du travail sans
  mesure — et le prochain débugueur chercherait un défaut qui n'existe pas.
- *Augmenter le timeout de 10 s* : une adresse muette ne répond à **aucun** délai (SYN sans réponse —
  timeouts de 4 s reproduits ici, 6 essais sur 6 lors de la mesure du matin) et le mode d'échec dure
  déjà 40 s. `D-012` tient : le timeout n'est pas le sujet.
- *Viser l'adresse vivante par épinglage, ou figer la famille d'adresses en production* : le premier
  transforme une adresse muette en panne **définitive** (interdit par `S2-01` et par `D-015`) ; le
  second **crée** la panne — `family: 4` et `autoSelectFamily: false` la reproduisent à volonté.
- *Ressusciter `D-014`* (« la panne est **absorbée par le client** ») : sa conclusion est vraie, mais
  elle ne suffisait pas — « le client bascule » et « le client ne bascule pas » sont deux mauvaises
  réponses à une question mal posée. La bonne est « **aucune adresse ne répondait** ». Ni `D-014` ni
  `D-015` ne l'avaient isolée ; `D-016` ne rétablit donc pas `D-014`, elle la remplace sur ce point.
- *Ouvrir un troisième ticket dans la foulée* (le constat annexe) : décider sur une observation
  incidente non isolée, c'est rejouer l'écart du matin. Le planning instruira.
- *Clore `S2-01` sur « rien à faire », sans exécution de bout en bout* : la règle de preuve de
  [`sprint-02.md`](sprint-02.md) l'interdit — un ticket de la chaîne de collecte ne se clôt que sur
  une exécution complète et la ligne `runs` lue en base. Elle a été faite (§ Preuves).

**Preuves utilisées** :
[`reviews/2026-10-26-requalification-defaut-a-bascule-adresse.md`](reviews/2026-10-26-requalification-defaut-a-bascule-adresse.md)
— image et digests, résolveur relevé 20 fois sur 20, **trace verbatim** du repli dans le code de n8n,
le nœud de WF1 copié tel quel **10 fois sur 10 en 200**, le mode d'échec reproduit à volonté (40,1 s),
les deux réglages qui cassent la bascule, et **WF1 entier sans épinglage** : une campagne due,
`runs.status = success`, `items_processed = 20`, `details = {recuperees: 22, ecartees: 2}`, 20 lignes
`companies` rattachées à leur campagne, `website` intact (D-009), `runs.error = null` — puis base
rendue à **0 / 0 / 0**, identique au relevé d'avant. Le constat annexe vient d'une exécution
accidentelle à deux campagnes dues (deux lignes `runs` au même `started_at`, une seule clôturée).

**Conséquence / coût** : `S2-01` ✅ **clos sans correctif**, sur une décision écrite et des mesures
reproductibles (`n8n/workflows/` n'a pas changé d'une ligne : `git diff` vide). Coût assumé : une
section de `AGENTS.md` §10 à réécrire — celle qui affirmait le contraire — et le constat annexe à ne
pas perdre. Ce qui reste vrai de la panne : une campagne réelle **mono-page** se collecte
normalement aujourd'hui ; une campagne **multi-pages** ne le peut pas encore, à cause du défaut B
(`S2-02`), et une API qui cesse de répondre produit un `error` exploitable — jamais un faux `success`.

**Ce qui me ferait changer d'avis** : une exécution de WF1 qui échoue en `timeout of 10000ms exceeded`
**alors que** le jeu d'adresses rendu contient une adresse qui répond (constaté au même instant, dans
le même conteneur) — là, le client serait bien en cause et le correctif redeviendrait légitime ; ou la
découverte que les runs 1 et 2 du 26/10 tournaient avec la famille figée ou l'autosélection coupée
(`family`, `autoSelectFamily`, `--add-host` oublié dans le harnais) — l'attribution redeviendrait
locale, mais au harnais, jamais au nœud.

**Qui exécute** : Automation (mesure et preuve — fait) · Orchestrateur (poursuivre sur `S2-02`, faire
instruire le constat annexe au planning) · Reviewer (relecture **en contexte neuf** du correctif de
`S2-02` — cette décision-ci n'ajoute pas de code, elle ne demande qu'à être reproduite).

**Origine** : ticket **`S2-01`** (« instruire pourquoi le nœud HTTP de n8n ne bascule pas, puis
écrire la décision et corriger »), traité le 2026-10-26 ; **révise le point 1 de `D-015`** ; referme
la question ouverte par `D-014` ; confirme `D-011`, `D-012` et le point 3 de `D-015`.

**Tickets** : **`S2-01`** ✅ clos sans correctif (critères 1, 2, 3, 4, 5 vérifiés —
[`sprint-02.md`](sprint-02.md)) · **`S2-02`** 🟦 prêt, dépendance levée.

**Consigné** : PR **#51** fusionnée en squash `e93d69e`, CI de `main` **verte** (run 40348892594).

---

## D-017 — Le rattachement des pages se fait sur la donnée, et la preuve se fait sur le plus grand couple multi-pages que l'API admet · 2026-10-27 · en vigueur

**Décision** : trois choses, et elles se tiennent.

1. **Le rattachement page ↔ couple ne lit plus aucun index.** `Filtrage et compteurs` attribue chaque
   page à son couple **par la donnée que la page porte** : une page `page = 1` ouvre le segment du
   couple suivant, dans l'ordre de « Préparation de collecte » ; un segment se ferme sur une dernière
   page partielle (`< 25` résultats) ou sur une erreur. Et **tout écart est une erreur nommée** — nombre
   de segments ≠ nombre de couples, page hors séquence, `total_results` qui varie, somme servie ≠ total
   annoncé, segment jamais fermé (plafond de pagination). Jamais une attribution silencieuse.
2. **L'écart de preuve est assumé, pas contourné.** Le critère 1 du ticket nommait `43.21A × 974`
   (1 515 résultats, 61 pages) : l'API **ne le permet pas aujourd'hui** (limite de débit partagée sur
   l'IP de sortie). La preuve se fait donc sur les **plus petits couples réellement multi-pages** que la
   fenêtre admet — `43.21A × 05` (36 résultats, 2 pages) et `43.21A × 70` (33, 2 pages), avec le filtre
   d'effectif de `D-008` à `effectif_min = 3`. Le volume nommé reste **non prouvé**, et c'est écrit au
   ticket.
3. **Le défaut de robustesse découvert n'est pas corrigé ici.** Un **seul** `429` fait échouer tout un
   couple : `retryOnFail ×3` relance la **pagination entière**, pas la page en échec. C'est une question
   de robustesse de la collecte, pas de rattachement : le planning l'instruit, et **avant** tout
   élargissement de périmètre (WF2).

**Pourquoi** : le défaut B n'était pas cosmétique — il **abandonnait** une collecte multi-pages (page 2
lue comme le couple suivant, puis index hors bornes) et, à deux couples de même NAF, pouvait attribuer
les pages d'un couple à l'autre **en silence**. Une seule voie tenait, et elle a été mesurée avant d'être
écrite : n8n **range** l'index de l'item d'entrée puis **fait lire** l'index de sortie, et le nœud HTTP
ne peut pas transporter de clé. La règle retenue est donc la seule qui ne dépende pas d'un comportement
interne non contractuel — et elle **échoue bruyamment** quand l'ordre ne permet pas de la vérifier, ce
que `S1-04` exigeait déjà.

**Options écartées** :

- *Garder `pairedItem` et corriger l'index par un décalage cumulé* (page − 1 + pages précédentes) : ce
  serait encore un **index implicite**, recalculé sur un champ que n8n réécrit (mesuré) ; il casserait au
  premier changement de `batchSize` ou d'ordre de sortie, et une page manquante resterait **silencieuse**.
  Le décalage juste aujourd'hui, faux demain.
- *Faire porter la clé par le nœud HTTP* (`outputPropertyName`, expression) : **impossible**, mesuré deux
  fois — le champ ne s'applique qu'aux réponses `text`/`file` (la branche JSON l'ignore) et il est lu **une
  seule fois, sur l'item 0**.
- *Lire l'appartenance dans la réponse* : `matching_etablissements` **n'a pas** de champ `departement`
  (25 résultats sur 25, mesuré), et le déduire du `code_postal` est faux pour la Corse et l'outre-mer, et
  absent quand l'entreprise a été retenue sur son siège. L'API n'écho pas la requête.
- *Attendre une fenêtre calme pour prouver `43.21A × 974` et clore sur elle* : six tentatives, de la
  cadence livrée à 4 s par page, **toutes** en échec. Faire dépendre une clôture d'une marge qui
  n'appartient pas au produit, c'est une loterie ; et le code prouvé serait le même.
- *Clore sur les onze scénarios hors réseau* : la règle de preuve de `D-011` et `D-015` exige une
  **exécution de bout en bout** et la ligne `runs` lue en base. Elle a été faite (§ Preuves).
- *Corriger le `429` dans la foulée* : hors périmètre du ticket, et décider d'une stratégie de reprise sur
  un épisode non isolé rejouerait l'écart que `D-016` vient de consigner.
- *Requalifier le défaut B en défaut de l'API* (« les pages ne sont pas rattachables ») : faux, et
  mesuré — l'API ne dit pas à quel couple appartient une page, mais elle **ordonne** les séries, et
  l'ordre suffit **à condition d'être vérifié**. C'est ce que fait le correctif.

**Preuves utilisées** :
[`reviews/2026-10-27-rattachement-des-pages-par-la-donnee.md`](reviews/2026-10-27-rattachement-des-pages-par-la-donnee.md)
— le défaut reproduit de zéro (stub qui écho la demande, nœud de WF1 copié tel quel : `pairedItem` lu
`0, 1, 2, 3` là où les couples étaient `0, 0, 0, 1`) ; l'impossibilité de faire porter la clé (deux
mesures) ; **onze scénarios hors réseau, 30 assertions, exit 0**, dont six échecs provoqués, et le
**rouge → vert** du critère 3 sur le code de `S1-04` pris dans git ; et **trois exécutions de bout en
bout** sur instance jetable (n8n 2.43.5), à la **cadence livrée**, base relevée avant et rendue après
(`0 / 0 / 0`) : `43.21A × 05` → `success`, `items_processed = 22`, `details = {recuperees: 36,
ecartees: 14}`, `error = null`, 22 lignes dont **tous** les sièges en `05` ; `43.21A × 05 + 70` (même
NAF) → `success`, **42** lignes, `details = {recuperees: 69 = 36 + 33, ecartees: 27}`, répartition
**22 / 20** par département, **0 hors zone**, et **aucune** ligne d'un couple ne portant un établissement
apparié de l'autre ; `43.21A × 99` → `status = error`, `items_processed = 0`, **HTTP 400** nommé, **0**
ligne écrite.

**Conséquence / coût** : `S2-02` passe **en review** (critères 1 à 4 vérifiés ; le cinquième — relecture en
contexte neuf — est la revue de la PR). Le changement ne touche **qu'**un Code node, sa note et le
`versionId` : ni le schéma SQL, ni le contrat d'upsert (ADR 0007), ni la CI. Deux coûts assumés : la
**limite de débit de l'API** devient une contrainte de preuve et de cadence de production (elle était
déjà une contrainte réelle, elle est maintenant écrite) ; et une **dette de robustesse** est ouverte
(`429` → tout un couple perdu), à instruire avant WF2.

**Ce qui me ferait changer d'avis** : une exécution de `43.21A × 974` **réussie** à la cadence livrée (ou à
n'importe quel espacement ≤ 4 s), avec `recuperees = 1 515` — l'écart de preuve du point 2 tomberait
alors ; ou une page qui **porterait** son couple (écho de la requête par l'API, ou `departement` dans
`matching_etablissements`) — l'ordre des segments pourrait être remplacé par une vraie clé ; ou une
exécution réelle où la segmentation **refuse** une collecte pourtant correcte (pages réordonnées par le
nœud, par exemple) — la règle serait alors trop stricte, et c'est le correctif qu'il faudrait réviser,
pas le ticket.

**Qui exécute** : Automation (correctif, mesures, preuves — fait) · **Reviewer** en contexte neuf
(critère 5 : relecture de la PR, non négociable) · Orchestrateur et planning (ouvrir le ticket de
robustesse `429`, et fixer la cadence de production à la lumière de la limite mesurée).

**Origine** : ticket **`S2-02`** (« rattacher chaque page au bon couple, sans index implicite »), traité le
2026-10-27 ; applique la règle de `D-015` (défaut B) ; reprend la leçon de `D-016` (mesure simultanée,
écart écrit) ; confirme `D-002` (compteurs) et `D-008` (filtre d'effectif, employé pour rendre la preuve
admissible).

**Tickets** : **`S2-02`** 🟦 **en review** — critères 1 à 4 vérifiés ; 5 : **revue faite puis confirmée par une session indépendante** ([verdict](reviews/2026-10-27-revue-pr-53.md) § 11 — même verdict, approuvé sous réserves, aucun bloquant) ·
**`S2-03`** ⬜ **ouvert le 2026-10-27** sur instruction du propriétaire — « la collecte doit survivre à un refus de débit » ([`sprint-02.md`](sprint-02.md)) — le constat et les mesures du § 3 de
la revue).

**Consigné** : PR **#53** fusionnée en squash `e85c7ba`, CI de `main` **verte** (run 40507634553).
## D-018 — La collecte passe de l'item-couple à la page, et le `retry-after` devient un plancher lu · 2026-10-28 · en vigueur

**Décision** : quatre choses, et elles se tiennent.

1. **La page devient l'unité de collecte.** WF1 ne demande plus un couple entier en une pagination
   native : il boucle **couple par couple**, et **une requête = une page**. Une panne ne coûte donc plus
   que la page en échec — mesuré : **8 requêtes pour 5 pages** avec trois refus, contre **9 requêtes pour
   0 page** à l'ancien réglage, dans la même fenêtre de refus.
2. **Le délai de reprise se lit dans la réponse.** `retry-after` est un **plancher** : nouvelle tentative
   de la **même page** après `retry-after + 1 s` (jamais moins de 5 s), **5 essais au plus** par page. La
   marge d'une seconde est mesurée, pas prudente : le minuteur du nœud `Wait` rend la main **avant l'échéance demandée**
   (474 ms pour 1 000, 4 069 ms pour 5 000). L'attente d'un refus est donc posée comme une
   **échéance** relue à chaque tour, jamais comme une durée appliquée une fois.
3. **Le pire cas est un abandon nommé.** Refus métier (`4xx` hors `408`/`429`), budget épuisé, ou attente
   demandée au-delà de **60 s** → **le couple est abandonné**, le run sort en `error` (ou `partial` si
   d'autres couples ont produit), le message **nomme le couple, la page et le statut**, et **aucune ligne**
   n'est écrite pour ce couple. Un couple tronqué présenté comme complet serait un succès muet — ce que
   `S1-04` interdit.
4. **La politesse de crawl ne bouge pas.** 1 requête/s, tenue par une **garde horodatée** devant **chaque** requête
   (`Rythme de la requête` → `Attendre encore ?` → `Attente de cadence`) — un simple nœud `Wait`
   laissait passer des écarts de **0,85 s** et **0,52 s** (mesuré), `User-Agent` inchangé, **100 pages** au plus par couple (`MAX_PAGES`, l'ex-`maxRequests`),
   `timeout` 10 s. Et la pression **baisse** au lieu de monter : un refus coûte **une** requête, plus la
   profondeur du refus.

**Pourquoi** : la mesure du critère 1 fermait deux des trois voies du ticket (reprendre à la page en
échec ; sortir en `partial` avec les pages acquises), et la troisième — « réessayer en respectant
`retry-after` » — ne tient pas non plus, pour deux raisons vérifiées et non supposées. D'abord
`waitBetweenTries` est **plafonné à 5 000 ms** dans `n8n-core` (`Math.min(5000, …)`) : allonger l'attente
est impossible, seule la **quantité** de tentatives est réglable. Ensuite, augmenter cette quantité
**aggrave** le gaspillage quand la fenêtre ne se rouvre pas : mesuré, 5 tentatives = 15 requêtes pour
zéro page, contre 9 pour le même résultat nul. Sur une API qui refuse **pour cause de débit**, réessayer
plus fort est un amplificateur — le critère 4 du ticket l'interdit explicitement. Faire de la page
l'unité est la seule structure qui rende la reprise **locale**, donc compatible à la fois avec la
résilience (critère 2) et avec la pression (critère 4).

**Options écartées** :

- *Garder la pagination et augmenter `maxTries`* : mesuré au banc — 5 tentatives récupèrent un refus de
  25 s, mais coûtent **15 requêtes pour 0 page** quand le refus dure, et le délai reste plafonné à 5 s.
  Plus de pression pour un gain qui dépend de la durée de la fenêtre.
- *Garder la pagination et lire `retry-after`* : impossible dans cette structure. Le `429` n'arrive avec
  **aucun en-tête** quand le nœud est en `continueRegularOutput` (item `{message, name, code, status}`),
  et de toute façon le délai du réessai d'item est plafonné par `n8n-core`.
- *Reprendre à la page en échec dans la pagination native* : aucun point de reprise exposé — mesuré, le
  réessai repart de `page = 1`.
- *Sortir en `partial` avec les pages acquises du couple* : rejeté, et pas pour une raison technique.
  Le `partial` existe au niveau du **run** (des couples réussis, d'autres non) ; l'étendre au **couple**
  écrirait une entreprise sur deux pages sur deux et présenterait la moitié d'un couple comme un
  résultat complet. Cela contredirait `S1-04` et `D-002`.
- *Découper en lots de N pages plutôt qu'en pages* : moins de nœuds, mais une reprise par lot reperd
  jusqu'à N pages par panne, et il faut la même boucle. Le gain d'écriture ne valait pas la perte de
  précision.
- *Déporter le rythme dans `requestInterval`* : il n'existe plus une fois la pagination retirée ; la
  cadence est tenue par le nœud `Wait` que `S1-04` avait déjà posé, et **devant chaque requête**.

**Preuves utilisées** :
[`reviews/2026-10-28-collecte-page-par-page.md`](reviews/2026-10-28-collecte-page-par-page.md)
— le banc A/B (ancien réglage : 9 requêtes, 0 page ; « plus patient » : 14 requêtes, 5 pages ; fenêtre
fermée : 15 requêtes, 0 page) ; la lecture du code de `n8n-core` pour le plafond de 5 000 ms ; quatre
scénarios sur stub avec le journal du serveur (**5** requêtes sans refus ; **8** avec 3 refus et des
écarts de **8,05 / 8,05 / 8,14 s** pour un `retry-after: 7` ; **7** requêtes et un `error` nommé quand le
refus ne cesse pas ; **10** requêtes et **240** lignes pour deux couples du même NAF) ; et **deux exécutions de bout en bout** sur l'API réelle et la base réelle, base
relevée avant (`campaigns 0 / companies 0 / runs 0`) et **rendue après** (`0 / 0 / 0`) :
`43.21A × 05` (2 pages) → `success`, `items_processed = 22`, `details = {recuperees: 36, ecartees: 14}`,
**22** entreprises — **les mêmes chiffres qu'avant la refonte** ; `43.21A × 99` (échec provoqué) →
`error`, `items_processed = 0`, message nommant `43.21A|99` et citant l'API, **0** ligne écrite.**Conséquence / coût** : WF1 gagne **huit nœuds** et l'état du tick (couples, page courante, pages acquises) vit dans les *static data* du workflow, remis à zéro à chaque tick — c'est le prix de la reprise locale, et c'est écrit dans le code comme dans la note collée. Trois coûts assumés : **la durée
d'un run peut s'allonger** (jusqu'à 5 × 60 s par page durablement refusée, multiplié par le nombre de
couples) ; **l'abandon après 5 essais est un choix**, pas un optimum démontré ; et le couple **abandonné
n'écrit rien**, donc son travail est à refaire au tick suivant — c'est le compromis inverse de
« conserver des pages tronquées ». `requestInterval` disparaît du nœud HTTP (il n'y a plus de
pagination) : la cadence est tenue par `Wait 1 s`, le `git diff` et la mesure le montrent.

**Ce qui me ferait changer d'avis** : une API qui annoncerait régulièrement un `retry-after` supérieur à
60 s — le plafond d'abandon serait à revoir ; une fenêtre de débit si longue qu'aucun budget de 5 essais
ne la couvre — le bon mécanisme serait alors le **report au tick suivant** (relancer la campagne plus
tard) plutôt que plus d'essais ; ou une exécution réelle où la boucle **perd** une page sans le dire —
alors c'est le réassemblage (`Pages collectées`) qu'il faudrait revoir, pas le principe. À l'inverse, si
un jour n8n expose un point de reprise de pagination ou un délai de réessai non plafonné, la boucle
maison redeviendrait inutile.

**Qui exécute** : Automation + Architecte (structure, mesures, preuves — fait) · **Reviewer** en contexte
neuf (relecture — [verdict](reviews/2026-10-28-revue-pr-s2-03.md)) · Orchestrateur (consignation, fusion —
faite) · **session indépendante** (confirmation du critère 7 — [rapport](reviews/2026-10-28-confirmation-independent-s2-03.md) :
**faite** — elle a rejeté le banc elle-même, écrit 92 tests à elle, et rendu le même verdict *approuvé
sous réserves*, aucun bloquant, aucune réserve ne portant sur les critères 2 à 5).

**Origine** : ticket **`S2-03`** (« la collecte doit survivre à un refus de débit »), ouvert le
2026-10-27 ; applique le point 3 de `D-017` (« le défaut de robustesse n'est pas corrigé ici ») ; suit la
mesure du critère 1 ([reprise d'une pagination refusée](reviews/2026-10-27-reprise-d-une-pagination-refusee.md)) ;
confirme `D-002` (compteurs) et `D-011`/`D-015` (preuve de bout en bout, base rendue).

**Tickets** : **`S2-03`** ✅ **fait (2026-10-28)** — critères **1 à 7** vérifiés : mesure du mécanisme
(1), couple multi-pages qui survit (2), `retry-after` plancher observé (3), politesse mesurée (4), pire
cas honnête (5), preuve de bout en bout avec échec provoqué et base rendue (6), relecture en contexte
neuf **puis confirmation par une session indépendante** (7) — *approuvé sous réserves*, **aucun
bloquant** sur aucun critère.

**Consigné** : PR **#59** fusionnée en squash `46b9696`, CI de `main` **verte** (run 40687098565).

---

## D-019 — Le lot de campagnes est traité campagne par campagne : la boucle au `batchSize: 1` · 2026-10-29 · en vigueur

**Décision** : quand **plusieurs campagnes sont dues dans le même tick**, le lot est traité
**campagne par campagne** : le nœud **« Pour chaque campagne (S1-02) »** passe de `batchSize: 10` à
**`batchSize: 1`**. L'invariant établi est **un passage = une campagne = un run** : chaque passage
emporte la création de la ligne `runs` de SA campagne, sa préparation, sa collecte (boucle page par
page de `S2-03` intacte), son rattachement (`S2-02` intact) et SA clôture. Les clôtures existantes
(`$json.run_id ?? $('Run démarré (campagne)').first().json.id`) deviennent correctes **sans
modification** — à `batchSize: 1`, le fallback `.first()` vise nécessairement le run du passage
courant. La politesse entre campagnes tient par `waitBetweenBatches: 1000` (1 s entre campagnes, en
plus de la garde horodatée de 1 s entre requêtes).

**Pourquoi** : la [mesure du mécanisme](reviews/2026-10-29-mesure-s2-04-lot-de-campagnes.md) a
reproduit isolément (trois fois, deux scénarios dont un échec provoqué, base 0/0/0 avant/après) le
defaut levé trois fois séparément : lot de deux campagnes dues → **deux** lignes `runs` créées
(`started_at` identiques à la microseconde — un POST multi-rows), **une seule** clôturée, la seconde
restée `running` et `campaigns_due` bloquée (24 h minimum). Le code pointe la faille **structurelle** :
« Préparation de collecte » est `runOnceForAllItems` et bâtit **tout l'aval** (couples, collecte,
compteurs, écriture) sur `$('Run démarré (campagne)').first()` — la campagne B n'a **jamais existé**
dans le passage. Corriger l'adressage seul (renvoyer le bon `run_id` à la clôture de B) ne clôturerait
rien : l'aval de B **n'existe pas**. La seule structure qui rende l'aval de B **existent** est le
passage par campagne.

**Options écartées** (instruction complète dans [`reviews/2026-10-29-instruction-des-pistes-s2-04.md`](reviews/2026-10-29-instruction-des-pistes-s2-04.md)) :

- *Un sous-workflow par campagne* : exige un second fichier de workflow — **hors du périmètre du
ticket** (nœuds amont de `wf1-collecte.json`) ; la preuve de bout en bout passerait par N exécutions,
et un sous-workflow interrompu après son POST « running » laisse **exactement** le run orphelin que
la mesure condamne ; l'isolation par `$execution.id` qu'il fournirait existe déjà et (a) n'entremêle
jamais deux campagnes.
- *Un run par élément du lot (campagnes au même passage)* : les lignes `runs` par élément existent déjà
— ce qui manque est **l'aval**, pas la création. Rendre l'aval multi-campagnes réécrirait préparation,
compteurs de filtrage (agrégats mélangés), lot des entreprises (N campagnes en un POST), conciliation
et clôtures — « l'échec d'une campagne ne fait pas tomber l'autre » deviendrait une preuve à
corriger, là où (a) le donne **par construction**. La condition du ticket (« si la mesure le montre »)
n'est pas remplie.
- *Corriger seulement l'adressage des clôtures (mapping par campaign_id)* : la mesure l'exclut — l'aval
de B (couples, collecte, écriture) **n'existe pas** dans le passage ; la clôture correcte ne clôturerait
qu'une ligne sans collecte derrière.

**Preuves utilisées** : [la mesure du mécanisme](reviews/2026-10-29-mesure-s2-04-lot-de-campagnes.md)
(trois reproductions, deux scénarios, base 0/0/0 avant/après, traces de clôture à un seul id de run) ;
la lecture du code exact (`batchSize: 10`, `runOnceForAllItems`, `.first()` dans la préparation et les
trois clôtures, sortie `done` non branchée).

**Conséquence / coût** : la collecte devient **séquentielle entre campagnes** (une campagne termine
avant que la suivante commence) — pour un tick de 2 campagnes c'est au plus la somme des durées, et la
politesse globale (1 requête/s sur la même API) ne se **dégrade pas** : elle devient simplement **plus
certaine**. Coût assumé : le débit d'un tick de N campagnes est la **durée de N cycles**. Ce qui
**ne bouge pas** : schéma SQL, contrat d'upsert (`D-0007`), la boucle page par page (`D-018`), la
politesse de crawl, la CI.

**Ce qui me ferait changer d'avis** : un besoin contré de collecte **parallèle** de campagnes (débit
tick contraignant) : alors ce serait la piste (c) — aval refondé multi-campagnes avec compteurs par
campagne — culminée par une mesure qui la justifie, jamais par préférence.

**Qui exécute** : Automation + Architecte (implémentation `batchSize: 1`, preuves des critères 2 à 5 :
deu campagnes réelles dues dans le même tick, échec provoqué inclus, base rendue 0/0/0) · Reviewer en
contexte neuf.

**Rectification au banc — même jour 2026-10-29**
([revue de correction](reviews/2026-10-29-s2-04-boucle-par-campagne.md)) : la promesse « les clôtures
deviennent correctes **sans modification** » ne tient que pour la préparation et les clôtures —
`.first()` vise bien le run du passage. Mais l'aval du passage **dépend aussi du seau interne** de
« Pour chaque couple (S2-03) » : une fois ce nœud épuisé à la fin du passage d'une campagne, l'arrivée
de la campagne suivante **ne rouvre rien** sans `options.reset` — et le banc l'a prouvé **en rouge** :
avec `batchSize: 1` seul, la seconde campagne du scénario `donnees` est restée **`running` à jamais**,
**0** ligne `companies` malgré 37 résultats réels à la sonde. Le correctif livré porte donc **deux
paramètres** : `batchSize: 1` sur « Pour chaque campagne », et `options.reset =
{{ $json.couple === true }}` sur « Pour chaque couple » (vrai sur les couples neufs de la préparation,
faux sur les rendus de la boucle) — touché **sous la clause du périmètre du ticket** (« sauf si la
mesure l'exige »), puis écrit au ticket. La présente décision reste en vigueur : son invariant
(**un passage = une campagne = un run**) est ce que le banc a vérifié en vert, une fois le tampon
interne réparé.

**Origine** : ticket **`S2-04`** (ouvert le 2026-10-28 à la clôture de `S2-03`, suite de `S2-01` /
`S2-03` ; instruction des pistes le [2026-10-29](reviews/2026-10-29-instruction-des-pistes-s2-04.md)) ;
suit la mesure du mécanisme du [2026-10-29](reviews/2026-10-29-mesure-s2-04-lot-de-campagnes.md).

**Tickets** : **`S2-04`** 🟡 **en cours** — critère 1 ✅ mesuré ; **critères 2 à 5 ✅ prouvés le
même jour** ([revue de correction](reviews/2026-10-29-s2-04-boucle-par-campagne.md), trois scénarios
verts après un rouge) ; reste la relecture en contexte neuf + la confirmation par une session
indépendante (critère 6) — avant WF2.
