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
