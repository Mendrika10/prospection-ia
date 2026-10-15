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
Seuls les cinq verrous du §2 du brief remontent à l'humain, parce qu'un agent n'en a
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
créé, il faudra y recopier les 13 tickets — travail mécanique, à faire une fois, sans valeur ajoutée.
Assumé, parce que le report est gratuit et l'attente ne l'est pas.

**Ce qui me ferait changer d'avis** : dès qu'un deuxième agent travaille en parallèle sur le même
sprint, la lecture d'un fichier partagé ne suffit plus à éviter les collisions — le board devient
nécessaire et je le remets en tête de sprint.

**Qui exécute** : propriétaire humain (scope `gh`, quand il veut) · surveillance : PO.
