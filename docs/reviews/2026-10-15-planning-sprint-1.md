# Revue — planning du Sprint 1 et décisions **D-006** / **D-007**

> Rôle : **Reviewer** (`prompts/roles.md` §7) · Date : 2026-10-15 · Auteur du livrable relu :
> la session **Product Owner** du même jour.

## Ce qui était relu

`docs/sprint-01.md` §2 (planning : Definition of Ready, ordre de passage, refus) ·
`docs/product-decisions.md` **D-006** et **D-007** · et, comme conséquence, les tickets que le
planning a modifiés (`S1-01`, `S1-02`, `S1-04`, `S1-08`, `S1-09`).

## Limite d'indépendance — à lire avant le verdict

Le brief exige une revue **en contexte neuf**. Ici l'auteur du planning et le relecteur sont la
**même session** : c'est une revue **non indépendante**, et je ne la présenterai pas autrement.
Ce qui lui donne une valeur vérifiable n'est pas le regard neuf, c'est la **méthode** : chaque
affirmation a été re-dérivée depuis une source primaire — schéma SQL, **API appelée pour de vrai**,
documentation n8n officielle — et non relue dans la prose de l'auteur. Deux constats ci-dessous
contredisent le planning, dont un **bloquant** : c'est le signe que ce n'était pas un tampon.

## Ce qui a été re-dérivé, et avec quoi

| Affirmation relue | Source primaire interrogée | Résultat |
|---|---|---|
| « rien n'enregistre le dernier passage d'une campagne » | `supabase/migrations/20261015000001_init.sql` | **Confirmé** — aucune colonne de dernier passage |
| « le cron ne peut pas être lu par ligne à l'exécution » | doc officielle n8n, *Schedule Trigger → Variables* | **Confirmé**, et **plus fort que formulé** : les valeurs du déclencheur ne sont évaluées **qu'à la publication** du workflow |
| « `tranche_effectif_salarie=53` renvoie 200 avec 0 résultat » | API appelée : `43.21A` × `53` | **Confirmé** (HTTP 200, `total_results=0`) |
| « l'API ignore silencieusement un paramètre inconnu » | API appelée avec un paramètre mal orthographié | **Confirmé** (HTTP 200, résultats **non filtrés**) |
| « `runs.details` est créé par `S1-08` » | schéma sur `main` | **Confirmé** — la colonne est absente |
| « la base refuse la campagne invalide depuis `S1-05` » | schéma sur `main` + état de la PR #1 | **Infirmé sur `main`** → constat **important** n° 3 |
| tautologie du critère `S1-08` | texte du critère avant le planning (`5aa7819`) | **Exagéré** → constat mineur n° 5 |

### Sondage du vocabulaire d'effectif (nouveau, non fait par le planning)

16 valeurs testées sur l'API, tous NAF confondus :

```
acceptés   : 00 01 02 03 11 12 21 22 31 32 41 42 51 52 53   (HTTP 200, résultats > 0)
refusés    : 13 23 33 43 50 54 55 99 A1 ZZ                  (HTTP 400)
```

Deux conclusions vérifiables : la validation porte sur le **vocabulaire** (54 et 50 sont
syntaxiquement des codes à deux chiffres et sont refusés), et ces 15 codes sont exactement les
**tranches d'effectif salarié de l'unité légale** de l'INSEE — corroboré par deux sources
(INSEE, `etalab/sirene_as_api`). Le « 0 résultat » de `43.21A` × `53` était donc bien une
**intersection** NAF × effectif : `53` seul renvoie 91 entreprises.

**Sémantique de liste, découverte ici :**

```
tranche_effectif_salarie=52        -> 172
tranche_effectif_salarie=53        ->  91
tranche_effectif_salarie=52,53     -> 263   = 172 + 91   (union)
tranche_effectif_salarie=52&…=53   ->  91                (le dernier gagne)
```

## Constats, classés par gravité

### 🔴 BLOQUANT

**1. `S1-02` écrit dans une colonne créée par `S1-08`, sans déclarer la dépendance.**
`sprint-01.md:392-393` exige que l'écart de filtre soit « tracé dans `runs.details` » ;
`runs.details` est créé par `S1-08` (`sprint-01.md:546`, absent de la migration initiale — vérifié) ;
or `sprint-01.md:398` déclare `**Dépendances** : S0-04, **ADR 0005 validé**`, et `S1-08` se déclare
lui-même « **Dépendances** : aucune » (`sprint-01.md:563`).
La **DoR n'est donc pas satisfaite** sur son 4ᵉ critère (« dépendances identifiées »), alors que le
planning la présente comme validée pour les 5 critères.
*Correction attendue* : ajouter `S1-08` aux dépendances de `S1-02`. L'ordre de passage place déjà
`S1-08` en 2ᵉ position : le risque pratique est contenu, la DoR ne l'était pas.

### 🟠 IMPORTANT

**2. L'état « Prêt sous condition » n'existe pas dans la méthode.**
Il apparaît 5 fois (`sprint-01.md:96, 97, 99, 103, 104`) et une fois en prose (`:108`). La Definition
of Ready de la méthode est **binaire** — 5 cases à cocher (`methode-equipe-agents.md` §2.3) — et le
terme est absent de `methode-equipe-agents.md` comme d'`AGENTS.md`.
Or, après les corrections que le planning a lui-même écrites dans les tickets, **4 de ces 5 tickets
sont Prêt** : une dépendance *déclarée* n'empêche pas de démarrer, c'est précisément ce que demande le
critère 4. Effet concret : un Orchestrateur peut lire « 5 tickets sur 7 ne démarrent pas ».
*Correction attendue* : dire « Prêt (corrigé au planning) » et réserver la mention d'attente aux
**dépendances**, qui sont déjà listées au §4. Si l'équipe veut un état intermédiaire, il appartient à
la **méthode** (propriété de l'Orchestrateur), pas à un planning isolé.

**3. Le motif de rejet du test de `S1-04` s'appuie sur une contrainte absente de `main`.**
`sprint-01.md:99` : « le test “NAF invalide” est **devenu impossible** : depuis `S1-05`, la base
refuse… ». `S1-05` est **en review**, sa migration n'est pas fusionnée (PR #1 ouverte), et le schéma
de `main` ne contient **aucune** contrainte de format NAF (vérifié : les seules occurrences de `naf`
sont la colonne `naf_codes`, la colonne `companies.naf` et un index).
*Correction attendue* : conditionner la phrase (« dès que la PR #1 est fusionnée »). La méthode de
test de remplacement reste valable dans les deux cas — c'est la **justification** qui est fausse
aujourd'hui, pas la correction.

**4. `D-007` a atteint son propre déclencheur de révision.**
`product-decisions.md:292` s'engage : « dès qu'une requête prouve le vocabulaire (elle renvoie les
codes attendus **et seulement eux**), je rends le filtre obligatoire ». Le sondage ci-dessus apporte
cette preuve : 15 codes acceptés avec résultats, 9 valeurs hors vocabulaire refusées en HTTP 400.
La raison d'être de la conditionnalité — craindre qu'un filtre mal formé passe **silencieusement** —
tombe précisément pour un code prouvé : un code faux lève une **erreur visible** (400) au lieu de
rendre des résultats non filtrés.
*Correction attendue* : appliquer la révision annoncée **par une nouvelle décision** (le brief §3
interdit de réécrire une décision passée en silence) → **D-008**.

**5. `campaigns.effectif_min` promet une précision que l'API ne peut pas fournir.**
`campaigns.effectif_min` est un **entier** ; l'API ne filtre que par **bandes**. « au moins 60
salariés » n'est donc pas exprimable : le meilleur résultat est la bande qui contient 60 (`21`,
50-99), qui inclut des entreprises de 50 à 59 salariés. Rien dans le sprint ne traite cet écart.
*Correction attendue* : la règle doit être **écrite** (bande contenant `effectif_min`, puis **union
de cette bande et de toutes les bandes supérieures**, en une seule requête grâce à la sémantique de
liste vérifiée ci-dessus). Le résultat est un **sur-ensemble assumé**, jamais un sous-ensemble —
à déclarer, parce que les campagnes existantes (`effectif_min = 1`) changent de comportement :
elles excluront désormais les unités à 0 salarié.

### 🟡 MINEUR

**6. Le motif donné pour remplacer le critère de `S1-08` est trop fort.**
`sprint-01.md:103` (repris en `:554`) : « un critère **ne peut pas échouer** ». Le critère d'origine —
« un test vérifie que `details` est du JSONB exploitable, pas une chaîne de texte » — **est**
falsifiable dans sa première lecture : il échoue si la migration déclare `text`. Ce qui est vrai, c'est
qu'il ne prouve rien sur l'**exploitabilité** (structure des clés, valeurs numériques).
*Correction attendue* : rectifier la justification (le critère ne teste pas ce qu'il prétend). Le
critère de remplacement, lui, est meilleur et doit rester : c'est un jugement sur la **preuve
invoquée**, pas sur l'action.

**7. La revendication n8n est exacte mais non sourcée.**
`S1-09` affirme que le cron d'un déclencheur n'est pas une valeur lue en base. C'est confirmé — et
même renforcé — par la documentation officielle (*Schedule Trigger → Common issues → Variables* :
les valeurs ne sont évaluées **qu'à la publication**) : un cron par campagne ne serait donc pas
seulement difficile, il serait **impossible**.
*Correction attendue* : citer la source. Une affirmation juste sans référence se re-débat au prochain
sprint.

**8. Le verdict « Déjà fait » de `S1-05` contredit la Definition of Done.**
Dans un tableau de la **DoR**, le verdict « ✅ Déjà fait » (`sprint-01.md:100`) est plus fort que la DoD
ne le permet : la relecture en contexte neuf manque, or c'est elle qui rend un ticket `fait`. Le statut
exact est **« implémenté, en review »**.
*Correction attendue* : « Déjà implémenté » — la nuance est celle de la DoD, pas de la politesse.

## Suites données à cette revue

Les huit constats ont été corrigés le jour même dans `docs/sprint-01.md` et
`docs/product-decisions.md` (**D-007** marquée révisée, **D-008** écrite), et journalisés dans
`docs/daily.md`. Deux d'entre eux changent le **contenu** du sprint : `S1-02` a une dépendance de plus
(constat bloquant) et le filtre d'effectif passe de conditionnel à **obligatoire** (constat n° 4).

Ce que la revue **n'a pas** changé, volontairement : le **refus de `S1-07`**, l'**ordre de passage** et
la **règle d'exécution** face à `S0-04`. Ils sont motivés, chiffrés et révisables ; je n'ai aucune
mesure qui les contredise, et un Reviewer n'a pas à préférer son jugement à un arbitrage documenté.

## Points que je n'ai pas pu vérifier (et que je n'approuve donc pas)

- Que le JSONB `runs.details` soit **exploitable en pratique** pour un taux de rejet : aucune ligne
  n'existe, la colonne n'étant pas encore créée. Le critère de `S1-08` le prouvera ou non.
- Que `S1-06` (WF5) soit réellement « testable en provoquant une erreur » : aucune trace n'est encore
  écrite par WF1, donc la boucle d'erreur n'est pas démontrable aujourd'hui. Le verdict « Prêt » du
  planning n'est pas contredit, il n'est **pas vérifiable** en l'état.
- Que le refus de `S1-07` serve le sprint : c'est un **jugement de valeur** sur le coût du délai. Je
  n'ai pas de mesure pour le trancher ; la décision est motivée et révisable, ce qui est le niveau
  d'exigence correct.
- La contrainte NAF de `S1-05` elle-même (elle vit sur la branche `feat/s1-05-garde-fou-naf`, non
  fusionnée — c'est l'objet de la revue de la PR #1, pas de celle-ci).

## Trouvé conforme (pour éviter une seconde relecture)

Périmètre respecté (les 3 fichiers du rôle PO + l'écart de périmètre **déclaré** dans `daily.md`) ·
aucun secret, aucun code, aucun SQL touché · aucun check affaibli · ordre de passage compatible avec
toutes les dépendances déclarées · renvois `§7` et `§4` résolus · tailles conformes à
`methode-equipe-agents.md` §5.1 (M = ≤ ½ journée) · les **quatre** verrous humains, cohérents avec le
brief après correction · faits de l'API reproductibles · `.github/sql/roles.sql` cité par la règle
d'exécution **existe** bien.
