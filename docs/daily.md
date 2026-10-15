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
