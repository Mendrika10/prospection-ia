# Sprint 0 & Sprint 1 — cadre, rituels et tickets

> Source de vérité du sprint en cours. Mis à jour par l'agent **Product Owner** et l'agent **Orchestrateur**.
> Rappels de méthode : [`methode-equipe-agents.md`](methode-equipe-agents.md) ·
> conventions : [`../AGENTS.md`](../AGENTS.md) · rôle PO : [`prompts/product-owner.md`](prompts/product-owner.md) ·
> autres rôles : [`prompts/roles.md`](prompts/roles.md) · décisions produit : [`product-decisions.md`](product-decisions.md)

---

## 1. Cadre

| Élément | Sprint 0 | Sprint 1 |
|---|---|---|
| Dates | 2026-10-15 → 2026-10-17 (3 j) | **2026-10-19 → 2026-10-23** (lun → ven) |
| Objectif | Environnement prêt, méthode en place | **Une campagne configurée déclenche WF1 et alimente `companies` sans doublon** (1er critère d'acceptation du cahier des charges) |
| Durée | Sprints de 1 semaine | idem |
| Taille du backlog | 6 tickets | 8 soumis → **7 à faire** + 1 déjà fait, 1 refusé (planning ci-dessous) |
| Limite WIP | **2 tickets « En cours » maximum** | idem |
| Branches | `feat/<ticket>-<slug>`, vie < 1 jour | idem |
| Intégration | CI verte obligatoire avant merge | idem |

**Définition de « En cours »** : la limite de 2 inclut l'attente de relecture. Un ticket en Review
compte comme En cours — sinon on empile les PR ouvertes.

### Ordre de passage (Sprint 1) — **confirmé par le planning du 2026-10-15**

1. **`S1-09`** → prérequis de schéma découvert au planning : sans lui, `S1-01` n'est pas
   implémentable (rien n'enregistre le dernier passage d'une campagne).
2. **`S1-08`** → compteurs de ciblage. Faisable **sans Supabase** (schéma + tests en CI).
3. `S1-01` → squelette WF1 (dépend de `S1-09`).
4. `S1-02` → le cœur métier (API + règle de ciblage) ; applique `ADR 0005`.
5. `S1-06` → observabilité, *avant l'upsert* (D-003) : on n'ajoute pas d'écritures en volume avant de
   pouvoir voir les échecs. Trace en base uniquement.
6. `S1-03` → upsert (dédoublonnage) : c'est ici que l'écriture en volume commence.
7. `S1-04` → politesse de crawl et robustesse.

`S1-01`, `S1-02` et `S1-05` sont **faits** : relus en contexte neuf, fusionnés (#22 et #1 le
16/10, **#25 le 20/10** — ce qui y a été corrigé est consigné ci-dessus), CI de `main` verte sur les squash-merges.
**Prochain ticket : `S1-03`** (l'upsert préparé le 2026-10-20 — l'ordre D-006 est levé depuis la mise en
service de WF5) ;
`S1-04` (politesse de crawl) reste dans l'ordre ci-dessus.
`S1-07` est **refusé du sprint** ce cycle.
`S0-04` est bien un ticket, mais son exécution est **humaine** : c'est le verrou qui conditionne la fin
du sprint (voir la règle d'exécution) — et le seul point sur lequel un agent ne peut pas se substituer à toi.

### Rituels du Sprint 1

| Rituel | Quand | Contenu | Qui |
|---|---|---|---|
| Sprint Planning | **lundi 19/10, 30 min** | Valider les tickets `Prêt`, confirmer l'ordre de passage | Agent PO + Orchestrateur |
| Daily asynchrone | chaque jour, 5 min | `docs/daily.md` : fait / prévu / bloqué | Orchestrateur |
| Affinage backlog | **mercredi 21/10, 20 min** | Découper les gros tickets, lever les décisions en attente | Agent PO + Architecte |
| Sprint Review | **vendredi 23/10, 20 min** | Démo de ce qui tourne réellement (base alimentée) + métriques | Agent PO |
| Rétrospective | **vendredi 23/10, 15 min** | 1 à garder, 1 à arrêter, 1 à essayer → mise à jour `AGENTS.md` §10 | Agent PO + Orchestrateur |

---

## 2. Tableau du sprint

Statuts : `⬜ à faire` · `🟡 en cours` · `🟦 en review` · `✅ fait` · `⛔ bloqué`

| ID | Ticket | Rôle | Taille | Dépend de | Statut |
|---|---|---|---|---|---|
| S0-01 | Structure du dépôt, `AGENTS.md`, CI | DevOps + Architecte | M | — | ✅ |
| S0-02 | Schéma initial + RLS + test SQL | Backend/Data | M | S0-01 | ✅ |
| S0-03 | n8n édition communautaire en Docker local | DevOps | S | S0-01 | ✅ |
| S0-04 | Projet Supabase « dev » + clés | **Humain** (identifiants) | S | — | ✅ vérifié sur le vrai projet (région `eu-west-1`, écart consigné) |
| S0-05 | Dépôt GitHub public + board + `main` protégée | DevOps | S | — | 🟡 dépôt, CI et protection faits et testés ; board reporté (D-005) |
| S0-06 | Comptes externes : bot Telegram + clé PageSpeed | **Humain** (comptes) | S | — | ⬜ |
| S1-01 | WF1 — squelette : cadence, campagnes dues, log `runs` | Automation | M | **S1-09**, S0-04 | ✅ fait — PR #22 relue en contexte neuf (retry ×3 absent, corrigé), fusionnée, CI de `main` verte |
| S1-02 | WF1 — API Recherche d'entreprises : pagination + ciblage | Automation | M | S0-04 | ✅ fait — PR #25 relue en contexte neuf (4 points importants corrigés : conciliation des écrites, statut `partial`, plafond de pagination, contrat `siren`), preuves réelles sur instance jetable (`partial`/`ecrites` sur le cas doublons), fusionnée en squash (`76ae1eb`), CI de `main` verte |
| S1-03 | WF1 — upsert `companies` par SIREN (dédoublonnage) | Automation | M | S1-01 | ✅ fait — PR #30 fusionnée en squash `e6e2c14` (ADR 0007, D-009/D-010), preuves réelles sur instance jetable (dédoublonnage lot mixte, upsert atomique PostgREST, passe de propriété), CI de `main` verte |
| S1-04 | WF1 — politesse de crawl et robustesse | Automation | M | S1-02 | ✅ fait — PR #32 (réglages) + **correctif PR #36** après la **preuve réelle du 2026-10-26** : 3 défauts corrigés (échec réseau avalé en silence, échecs de collecte non comptés, nœud de conciliation orphelin) ; User-Agent **observé sur le fil**, ~1 req/s, retry ×3, `Continue on Fail` → `partial`, endpoint faux → `error`, réponse vide → `success` |
| S1-05 | Garde-fou de format des codes NAF | Backend/Data | S | — | ✅ fait — PR #1 relue en contexte neuf (migration non réapplicable : corrigée), rebasée, fusionnée, CI de `main` verte |
| S1-06 | WF5 — workflow d'erreurs + trace en base | Automation | S | — | ✅ fait — PR #28 (re-revue demandée puis fusion en squash `2969c3d`), CI de `main` verte |
| S1-07 | Documentation d'exploitation de WF1 | Documentation | S | S1-04 | 🟦 **Prêt** — condition de retour **remplie le 2026-10-26** (`D-015`) : une exécution réelle a appelé l'API publique et écrit **20 lignes** (`success`, `items_processed = 20`) ; la doc devra décrire les **deux défauts** ouverts en §7, pas une chaîne idéale |
| S1-08 | `runs.details` — compteurs récupérées / écartées (**D-002**) | Backend/Data | S | — | ✅ vérifié sur le vrai projet · écart de relecture consigné |
| S1-09 | `campaigns`/`runs` — rendre la fréquence par campagne implémentable (créé au planning) | Backend/Data | S | — | ✅ vérifié sur le vrai projet · écart de relecture consigné |

---

### Planning du Sprint 1 — résultat de la validation (2026-10-15, agent Product Owner)

**Capacité** : 5 jours ouvrés, WIP max 2, une session à la fois → cible pratique **7 à 8 tickets**.
Backlog soumis : **8** (`S1-01` à `S1-08`). Retenus tels quels : **6** · refusé : **1** (`S1-07`) ·
créé : **1** (`S1-09`) → **7 tickets à faire**, et `S1-05` déjà fait hors compte.
Le compte ferme : 6 retenus + 1 refusé + 1 déjà fait = 8 soumis.

**La contrainte réelle n'est pas la capacité.** Le sprint est limité par un **verrou humain non levé**
(`S0-04` : clés Supabase + migrations). Aucun ticket qui écrit en base ne peut atteindre sa Definition
of Done tant que ce verrou tient. Je refuse de présenter un sprint qui ne peut pas finir sans l'écrire
noir sur blanc — d'où la **règle d'exécution** ci-dessous, qui permet d'avancer sans lui.

#### Definition of Ready — ticket par ticket

Les cinq critères : objectif en une phrase · critères d'acceptation **vérifiables** · périmètre
verrouillé · dépendances identifiées · taille ≤ ½ journée.

| Ticket | Verdict | Constat du planning |
|---|---|---|
| `S1-01` | ✅ **Prêt (corrigé)** | **Le critère « cron défini par campagne » n'est pas implémentable** : n8n ne peut pas lire un cron par ligne à l'exécution (doc officielle : les valeurs du déclencheur ne sont évaluées **qu'à la publication**), et rien n'enregistre le dernier passage d'une campagne. → créé `S1-09` ; dépendance `S1-09` **déclarée**, blocage enregistré au §4 |
| `S1-02` | ✅ **Prêt (corrigé)** | Deux manques réels : (1) le critère « le vocabulaire d'effectif est confirmé contre la documentation » est une **tâche, pas un critère vérifiable** ; (2) `campaigns.effectif_min` (entier) face au filtre codé de l'API n'était traité nulle part. → critères reformulés, `D-007` puis **`D-008`**, vocabulaire **prouvé par l'API** et écrit dans le ticket. **Revue** : dépendance `S1-08` ajoutée (le ticket écrit dans `runs.details`, colonne créée par `S1-08`) |
| `S1-03` | ✅ **Prêt** | Rien à signaler. Tous les critères sont observables en base. |
| `S1-04` | ✅ **Prêt (corrigé)** | Le test « NAF invalide » **deviendra impossible dès que la PR #1 sera fusionnée** : `S1-05` est en review, sa contrainte n'est **pas encore sur `main`**. Le ticket demandait de tester par une porte qu'on ferme exprès. → méthode de test remplacée, valable dans les deux cas |
| `S1-05` | ✅ **Déjà implémenté** | En review, donc **pas `fait`** au sens de la DoD (qui exige une relecture en contexte neuf). **Note du planning** : il annonçait que la revue dépendait de `S0-05` — c'est périmé, le dépôt existe et la PR #1 est ouverte. Seule la relecture manque. |
| `S1-06` | ✅ **fait** | Preuves create/update sans doublon sur instance jetable (2026-10-20), fusionné (PR #28). |
| `S1-07` | ❌ **Refusé** | Voir « Ce qui est refusé » ci-dessous. |
| `S1-08` | ✅ **Prêt (corrigé)** | Critère d'origine trop faible, mais **pas infalsifiable** : « `details` est du JSONB exploitable » échoue si la migration déclare `text` ; en revanche il ne prouve rien sur l'exploitabilité. → remplacé par la lecture réelle de trois compteurs distincts |
| `S1-09` | ✅ **Prêt (créé)** | Créé par ce planning. Démarrage conditionné par **une décision d'architecture** déclarée (comment calculer l'échéance sans écrire un analyseur de cron) : dépendance d'un agent, ~20 min, inscrite au §4 — **ne dépend pas de l'humain** |

#### Corrections apportées aux tickets par le PO

Un ticket corrigé par le planning l'est **dans le ticket lui-même**, pas laissé en l'état. L'état
intermédiaire « Prêt sous condition » a été **supprimé après la revue** : la Definition of Ready de la
méthode est binaire, et une dépendance *déclarée* n'empêche pas de démarrer (critère 4). Détail et
constats : [`reviews/2026-10-15-planning-sprint-1.md`](reviews/2026-10-15-planning-sprint-1.md).

1. `S1-01` — « cron défini par campagne, pas en dur » remplacé par « cadence fixe du déclencheur +
   décision par campagne d'être due ou non », dépendance `S1-09` ajoutée.
2. `S1-02` — le critère de confirmation documentaire devient un critère applicable : le vocabulaire
   retenu doit être **écrit dans le ticket** avec la requête qui le prouve ; le filtre d'effectif
   devient **conditionnel** (`D-007`).
3. `S1-04` — le test par « campagne au NAF invalide » est remplacé par deux tests possibles :
   un **endpoint d'API volontairement faux** (erreur réseau) et un **département inexistant**
   (réponse vide, cas nominal à ne pas confondre avec une erreur).
4. `S1-08` — le critère non discriminant est remplacé par : les trois compteurs doivent être
   **lus séparément** (`items_processed` d'un côté, `details->>'ecartees'` de l'autre) et donner
   des valeurs différentes sur un même run.
5. `S1-05` — note de dépendance périmée corrigée (le dépôt existe, seule la relecture manque).

#### Tickets du Sprint 0 encore ouverts — traités par ce planning, pas oubliés

La Definition of Ready ne s'applique qu'aux tickets **soumis à ce sprint**. Quatre lignes du Sprint 0
restent ouvertes : elles sont ci-dessous avec leur sort, pour qu'aucune ne disparaisse du radar.

| Ticket | Reste à faire | Pourquoi il n'est **pas** re-planifié |
|---|---|---|
| `S0-03` | 1 case : importer et exécuter un workflow témoin | Se coche **à la première exécution de WF1** (`S1-01`) : le témoin, c'est la collecte réelle. Pas de travail séparé. |
| `S0-04` | `.env` + 2 migrations | **Verrou humain** (identifiants) : hors de portée d'un agent. Non bloquant pour `S1-08`/`S1-09` — voir la règle d'exécution. |
| `S0-05` | Board Projects | Reporté par **D-005** (ne bloque aucune décision) ; le reste du ticket est fait **et testé**. |
| `S0-06` | Bot Telegram + clé PageSpeed | **Retiré du chemin critique** par **D-003**. Dû avant S4 (WF4), pas avant. |

Aucun de ces quatre points n'est un ticket de développement : trois sont des **verrous ou des reports
assumés**, le quatrième se ferme tout seul au premier run réel. Les re-planifier ajouterait du bruit au
sprint sans changer une ligne de code.

#### Ce qui est refusé, et à quelle condition ça revient

**`S1-07` — Documentation d'exploitation de WF1 : refusé du sprint 1.**

Raison : on documenterait un workflow qui **n'a jamais tourné sur des données réelles**. La
procédure d'exploitation écrite maintenant serait réécrite dès le premier incident, et sa seconde
moitié (« mettre à jour la section Avancement du README ») est déjà faite à chaque revue par le PO et
le daily. C'est le ticket à plus faible coût du délai du sprint, à la différence de `S1-04` (la
politesse de crawl est un contrat avec une API publique, pas du confort) et de `S1-06` (sans trace
d'erreur, un échec nocturne reste invisible).

**Condition de retour, explicite** : dès qu'une collecte réelle a abouti **une fois** (première
exécution de WF1 sur au moins une campagne, avec des lignes dans `companies`). À ce moment-là, la
documentation décrit du vécu. Le point de révision est inscrit au §7.

#### Règle d'exécution du sprint (pour avancer sans le verrou humain)

> **`S0-04` est levé depuis le 2026-10-15** (voir §4) : ce qui suit a joué jusqu'à cette date et reste
> écrit tel qu'il a été appliqué. La DoD n'a pas bougé, seule la contrainte de départ a disparu — les
> tickets suivants se vérifient désormais directement sur le vrai projet.

Tant que `S0-04` n'est pas levé :

- Le **développement** se fait contre un **Postgres local** (le même que celui de la CI :
  `.github/sql/roles.sql` + `supabase/migrations/*.sql`). Cette voie existe déjà, elle est éprouvée,
  et elle ne dépend d'aucun identifiant.
- La **Definition of Done** d'un ticket qui écrit en base reste **vérifiée sur Supabase** avant
  `fait`. Le Postgres local sert à avancer, jamais à déclarer terminé.
- Les tickets **sans dépendance au verrou** (`S1-08`, `S1-09`) restent prioritaires : ils peuvent
  atteindre leur DoD complète dès maintenant.

---

## 3. Tickets

Format : objectif · contexte · critères d'acceptation · périmètre verrouillé · dépendances.
Le détail du format est dans [`methode-equipe-agents.md`](methode-equipe-agents.md) §5.1 ;
la version « à coller dans GitHub » est `.github/ISSUE_TEMPLATE/ticket.md`.

---

### S0-01 — Structure du dépôt, `AGENTS.md`, CI ✅

**Objectif** : disposer d'un dépôt qui applique les règles de l'équipe sans qu'on ait à y penser.

**Contexte** : cahier des charges §7.5 (structure du dépôt), §4 (maintenabilité, secrets hors Git) ;
méthode §6 (CI minimale).

**Critères d'acceptation**
- [x] Arborescence `apps/ · supabase/ · n8n/ · docs/` présente
- [x] `AGENTS.md` à la racine (conventions + règles + pièges connus)
- [x] `.env.example` documenté, `.env` ignoré par Git
- [x] CI : job `sql` (migrations + tests) et job `secrets` (scan de JWT / clé privée)
- [x] `git check-ignore .env` renvoie bien `.gitignore`
- [x] Scan des secrets : aucune correspondance sur le dépôt

**Périmètre** : racine, `.github/`, `docs/` — **interdit** : `supabase/migrations/`
**Taille** : M · **Rôle** : DevOps + Architecte

---

### S0-02 — Schéma initial + RLS + test SQL ✅

**Objectif** : le schéma de `docs/cahier-des-charges.md` §7.1 existe, sécurisé et vérifié par un test.

**Critères d'acceptation**
- [x] 6 tables : `campaigns`, `companies`, `analyses`, `leads`, `runs`, `blocklist`
- [x] RLS activée sur les 6, **aucune policy pour `anon`**
- [x] Index du §7.1 en place (+ index partiels utiles à WF2 et au digest WF4)
- [x] `supabase/tests/rls.sql` : 7 assertions, sortie en code 0
- [x] Vérifié sur un Postgres 16 neuf : migration + seed + tests

**Preuve d'exécution** (Postgres 16 dans Docker, 2026-10-15) :
```
OK  service_role écrit dans companies / analyses / leads / runs
OK  anon ne peut pas lire leads (permission denied)
OK  anon ne peut pas lire companies (permission denied)
OK  authenticated lit les leads (1 ligne)
OK  authenticated met à jour le statut d'un lead
OK  authenticated corrige une fiche entreprise + trigger updated_at
OK  authenticated ne peut pas écrire dans runs
=== TOUS LES TESTS RLS PASSENT ===        (EXIT=0)
```

**Points d'attention (déjà dans `AGENTS.md` §10)**
- `service_role` n'avait **aucun privilège** : sans `grant all` explicite, n8n n'aurait rien pu écrire.
- Le premier jet du seed utilisait le format NAF compact (`4321A`) : **rejeté en HTTP 400** par l'API
  → corrigé en format pointé (`43.21A`). Le garde-fou permanent est le ticket **S1-05**.

**Périmètre** : `supabase/` · **Taille** : M · **Rôle** : Backend/Data

---

### S0-03 — n8n édition communautaire en Docker local ✅

**Objectif** : pouvoir construire et exécuter les workflows WF1..WF5 en local, gratuitement.

**Critères d'acceptation**
- [x] `n8n/docker-compose.yml` valide (`docker compose config` passe)
- [x] Volume persistant + clé de chiffrement via variable d'environnement
- [x] Aucune variable obsolète (`N8N_BASIC_AUTH_*` supprimées depuis n8n 1.0)
- [x] Dossier `n8n/workflows/` versionné, avec ses conventions d'export
- [ ] *(à faire à l'exécution)* importer puis exécuter un workflow témoin

**Périmètre** : `n8n/` · **Taille** : S · **Rôle** : DevOps

---

### S0-04 — Projet Supabase « dev » + clés ✅ fait

**Avancement (2026-10-15, soir)** : **vérifié sur le projet réel `rexnoeixlkedvdhzeoqk`** — les 3
migrations appliquées par `supabase db push`, les **4 suites de tests sortent en code 0 sur le vrai
projet** (`rls.sql` compris : c'est le critère explicite ci-dessous), `anon` reçoit **401 `permission
denied`** sur les 7 objets via PostgREST **avec 4 lignes de données en face** (sinon le contrôle ne
prouverait rien), `service_role` **écrit** (HTTP 201, ligne ensuite supprimée — le chemin n8n), et
l'empreinte de schéma du vrai projet **ne manque aucun objet** de notre référence
(`.github/sql/schema-baseline.txt`) : seules 3 lignes `privilege_defaut` diffèrent par leur **texte**
(l'entrée propriétaire `postgres=` existe côté plateforme, absente côté CI) alors que l'effet est le
même — les `anon=arwdDxtm` y sont.
**Un écart mesuré, consigné et arbitré** : le projet est en **`eu-west-1`** (Irlande), pas `eu-west-3`.
L'intention du critère (« région UE, proche des cibles françaises ») est respectée, sa lettre non ;
le propriétaire a tranché de garder le projet tel quel.
**Deux faits d'environnement à retenir, parce qu'ils se paient en minutes** : l'hôte direct
(`db.<ref>.supabase.co`) n'est résolu qu'en **IPv6**, et le pooler **session (port 5432)** est
**injoignable depuis ce réseau** ; c'est le **pooler transaction (port 6543)** qui sert — migrations
comprises (`db push --db-url`) et tests compris (les `BEGIN/ROLLBACK` des scripts y sont épinglés pour
la durée de la transaction). `DATABASE_URL` d`.env` l'encode.
**Résidu des tests supprimé** : `rls.sql` n'est pas transactionnel par conception ; ses quatre lignes
ont été supprimées après vérification, toutes les tables sont revenues à 0.

**Objectif** : disposer d'une base réelle pour appliquer les migrations et brancher n8n.

**Contexte** : ADR 0001 (Supabase) · cahier des charges §6.4 (environnements).
**Action humaine obligatoire** : le projet existe déjà, mais il reste à remplir `.env` et à appliquer
les migrations — un agent n'a ni les clés ni l'accès DDL. Aucun agent ne peut se substituer à toi ici.

**Critères d'acceptation**
- [x] Projet Supabase `prospection-dev` créé — région **`eu-west-1`** au lieu d'`eu-west-3` : écart
      mesuré, consigné ci-dessus et arbitré (le critère visait une région UE proche des cibles)
- [x] Les 6 tables existent (migration S0-02 appliquée via `supabase db push`, historique enregistré
      dans `supabase_migrations.schema_migrations`)
- [x] `supabase/tests/rls.sql` passe **sur le vrai projet** — et les trois autres suites aussi
- [x] `.env` renseigné : `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_URL`,
      `SUPABASE_SERVICE_ROLE_KEY` (la clé d'abord transmise était en réalité la clé `anon` — même
      empreinte, claims `role=anon` ; la vraie a été récupérée par l'API et ses claims vérifiés)
- [x] Un accès avec la clé `anon` ne lit **rien** — vérification à la main : 401 sur les 6 tables et
      sur la vue, alors que les tables contenaient des lignes
- [x] Aucune de ces clés n'apparaît dans `git status` (`git check-ignore` → `.gitignore:2:.env`)

**Périmètre** : `.env` (ignoré par Git) — **interdit** : commiter `.env`
**Dépendances** : aucune · **Bloque** : S1-01, S1-02, S1-03, S1-04
**Taille** : S · **Rôle** : **Humain** (identifiants — verrou du §2 du brief PO)

---

### S0-05 — Dépôt GitHub public + board + `main` protégée 🟡

**Objectif** : que le travail passe par des PR et que la CI bloque un merge rouge.

**Critères d'acceptation**
- [x] Dépôt `prospection-ia` créé et `main` poussée — <https://github.com/Mendrika10/prospection-ia>
- [x] Branche renommée `master` → **`main`**
- [x] La CI tourne sur GitHub : 3 jobs verts sur la PR #1 (`sql` 21-24 s, `secrets` 5 s, `node` 7-8 s),
      et le job `sql` a bien exécuté les 12 assertions (vérifié **dans le log**, pas seulement au statut)
- [x] **Merge dans `main` impossible avec une CI rouge** — appliqué ET testé, voir ci-dessous
- [x] Workflow Git en place : `feat/s1-05-garde-fou-naf` poussée, PR #1 ouverte depuis `main`
- [ ] Board Projects avec les colonnes `Backlog → Prêt → En cours → Review → Fait`
- [ ] Les tickets de ce fichier existent comme *issues* (modèle `.github/ISSUE_TEMPLATE/ticket.md`)

#### Protection de branche : la décision et sa vérification

L'incertitude signalée dans ce ticket était réelle. Réponses vérifiées contre l'API GitHub :

| Tentative | Réponse |
|---|---|
| Protection sur dépôt **privé** | **403** « Upgrade to GitHub Pro or make this repository public » |
| Rulesets sur dépôt **privé** (alternative) | **403**, même message |
| Protection après passage en **public** | **200** — appliquée |

Décision du Product Owner (2026-10-15) : **dépôt public**, pour obtenir un vrai verrou sans payer
(GitHub Pro serait contraire à la contrainte « 0 € »).

Configuration en place, relue depuis GitHub :

```
required_status_checks : [sql, secrets, node]   strict: true
enforce_admins         : true
allow_force_pushes     : false
allow_deletions        : false
```

**Et le verrou fonctionne** — ce n'est pas déduit de la configuration, c'est testé. Tentative de
push direct sur `main` avec un commit vide :

```
remote: error: GH006: Protected branch update failed for refs/heads/main.
remote: - 3 of 3 required status checks are expected.
! [remote rejected] main -> main (protected branch hook declined)
```

Contrôle complémentaire : le hash de `origin/main` est identique avant et après la tentative.

> **Conséquence à assumer** (et elle est notée dans `AGENTS.md` §10) : le dépôt est public. Aucune
donnée d'entreprise, aucun secret et aucun export contenant des identifiants ne doit y entrer.
> Scan de **tout l'historique** relancé après le passage en public : aucune correspondance.

**Board Projects — encore bloqué** : le jeton `gh` n'a pas le scope `project`
(`error: your authentication token is missing required scopes [project read:project]`).
Déblocage : `gh auth refresh -s project,read:project` (ouvre le navigateur), **ou** création
manuelle du board dans l'UI. Les 5 colonnes et la limite WIP se règlent ensuite dans l'UI :
`gh` n'expose pas la suppression des options par défaut du champ `Status`.

**Périmètre** : configuration GitHub · **Taille** : S
**Rôle** : DevOps pour le travail, **humain** pour le scope `gh` (verrou du §2 du brief PO)

---

### S0-06 — Comptes externes : bot Telegram + clé PageSpeed ⬜

**Objectif** : les notifications (WF4) et les mesures de performance (WF3) sont possibles.

**Critères d'acceptation**
- [ ] Bot Telegram créé, `TELEGRAM_BOT_TOKEN` et `TELEGRAM_CHAT_ID` obtenus (sans carte bancaire)
- [ ] Clé PageSpeed Insights obtenue (**gratuite, sans carte bancaire** — sinon on change d'approche)
- [ ] Message de test reçu sur le chat visé depuis n8n
- [ ] Les deux secrets sont saisis dans les **credentials n8n**, pas dans un fichier du dépôt

**Périmètre** : comptes externes + credentials n8n · **Bloque** : S4 (WF4) uniquement
**Taille** : S · **Rôle** : **Humain** (comptes externes) — **ne bloque plus S1-06** depuis D-003

---

### S1-01 — WF1 squelette : cadence fixe, campagnes dues, log `runs` ✅ fait

**Objectif** : WF1 existe, s'exécute à vide sans écrire de données métier, et journalise son passage.

**Contexte** : cahier des charges §7.2 (WF1), §4 (observabilité).

**Critères d'acceptation**
- [x] Le déclencheur est à **cadence fixe** (documentée dans le workflow) ; WF1 décide **ensuite**,
      campagne par campagne, si elle est due — la règle exacte vient de `S1-09` (correction du planning :
      « un cron par campagne lu à l'exécution » n'est pas implémentable dans n8n)
- [x] Lecture des campagnes avec `active = true` ; une campagne inactive n'est **jamais** traitée
- [x] Une ligne `runs` est créée au démarrage (`status = 'running'`), puis passée à `success`
      ou `error` avec `finished_at` renseigné
- [x] Une exécution sans campagne active se termine en `success` avec `items_processed = 0`
      (pas d'erreur : ce n'est pas un échec)
- [x] Le workflow est **exporté** dans `n8n/workflows/wf1-collecte.json` et importé avec succès
- [x] Aucun secret dans le JSON exporté (credentials référencés par nom)

**Preuve attendue** : sortie de l'import + exécution n8n, et la ligne correspondante dans `runs`.

**Preuve d'import** (instance n8n **jetable** : copie de la base dans un volume dédié, jamais celle de l'équipe) :
```
$ n8n import:workflow --input=n8n/workflows/wf1-collecte.json
Importing 1 workflows...
Successfully imported 1 workflow.
artéfact vs base de la copie : nœuds identiques=true · connexions=true · settings=true
```

**Preuve d'exécution** (trace n8n, 2026-10-15) :
```
• Run démarré (running)          → success  1 item  {"workflow":"wf1-collecte","status":"running","finished_at":null}
• Campagnes dues (campaigns_due) → success  1 item  {"name":"[S1-01] campagne active due","active":true,...}
                                              sortie d'erreur : vide
• Run terminé (success)          → success  1 item  {"status":"success","finished_at":"2026-10-15T11:52:09.554+00:00","items_processed":0}
• Run en erreur (error)          → success  1 item  {"status":"error","finished_at":"…","error":"echec WF1 : détail dans l'exécution n8n"}
```
Ce que la trace prouve : le run est créé en `running` **puis** clos ; `campaigns_due` ne renvoie **que** la
campagne `active = true` (l'inactive n'apparaît sur **aucune** sortie, même quand elle existe en base) ;
un run sans campagne due se termine en `success` avec `items_processed = 0` ; le chemin d'erreur écrit
`error` **et** `finished_at` (forcé par un nom de table inexistant, sans toucher à l'artéfact).

**Ligne `runs` correspondante sur le vrai projet** (Project Supabase `prospection-dev`) :
```
wf1-collecte | success | fini=true | items=0
```
Deux campagnes de test (une active, une inactive) et les quatre lignes écrites par les harnais de mesure
(trace, chemin d'erreur, variante planifiée) ont été **supprimées après vérification** : l'état final ne
contient qu'une seule ligne, celle de l'artéfact.

**Limites de cette vérification, dites telles quelles**
- Le déclenchement **horaire réel** n'a pas été observé : sur la copie jetable, activer un workflow exige
  une **publication** (n8n 2.x : `Building workflow dependency index… Processed 0 published workflows`),
  et l'API d'activation est protégée par le verrou d'écriture collaboratif. La chaîne exécutée est bien
  celle de l'artéfact importé (mêmes nœuds, mêmes connexions, mêmes réglages), démarrée par l'API interne
  qu'utilise le bouton « Execute workflow » de l'UI.
- `runs.error` contient le **repli** de l'expression : la charge utile d'un item de sortie d'erreur n'est
  pas `{error:{message,description}}` en n8n 2.43.5 (mesuré, pas supposé). À reprendre quand `S1-02`
  introduira de vrais modes d'échec.
- Un démarrage **manuel** d'un workflow à déclencheur horaire laisse l'exécution n8n à l'état `running`
  alors que la chaîne s'est exécutée (prouvé par la ligne `runs`) : c'est la trace n8n qui reste ouverte,
  pas le workflow. Un déclencheur manuel finalise normalement.
- `import:workflow` **désactive toujours** le workflow importé, quel que soit `active: true` dans le JSON :
  l'activation est un geste dans l'UI (ou une publication par l'API), à porter en `AGENTS.md` §10 à la rétro.

**Périmètre** : `n8n/workflows/` — **interdit** : `supabase/migrations/`, `apps/`
**Dépendances** : `S1-09` (schéma), `S0-04` (vérification finale) · **Taille** : M · **Rôle** : Automation

---

### S1-02 — WF1 : API Recherche d'entreprises (pagination + ciblage) ✅ fait

**Objectif** : WF1 récupère réellement les entreprises ciblées par campagne, sans faux positifs géographiques.

**Contexte** : RF-04 · **ADR 0005 — accepté le 2026-10-15, à appliquer tel quel** · `AGENTS.md` §10 (contrat de l'API).

**Contrat vérifié le 2026-10-15** (ne pas réinventer, ne pas se fier au code HTTP) :
- `GET https://recherche-entreprises.api.gouv.fr/search`
- Le filtre d'activité s'appelle **`activite_principale`**, au format **pointé** (`43.21A`) ;
  le format compact (`4321A`) renvoie **HTTP 400**, et un **nom de paramètre inconnu est ignoré
  silencieusement** (HTTP 200 avec des résultats non filtrés).
- `per_page` **≤ 25** (au-delà : HTTP 400) ; `page` fonctionne au-delà de 1 000 résultats.
- `etat_administratif=A` pour les entreprises actives (RF-06).

**Critères d'acceptation**

**Vérifié le 2026-10-16 sur une instance n8n jetable** (v 2.x, exécutions #20/#22/#23, conteneur
local `wf1-s102` arrêté et nettoyé ensuite — preuves = lignes `runs` et `companies` lues via
l'API REST, jamais supposées) :

- [x] Une campagne = un appel par couple (code NAF × département), avec pagination jusqu'à épuisement
      — camp 44 : 74 pages internes (1 841 résultats), 1 requête par page, 1 s entre les pages ;
      camp 974 : 61 pages (1 509 résultats)
- [x] Le workflow **vérifie** que les résultats renvoyés portent bien le code NAF demandé et le bon
      `etat_administratif` (défense contre l'ignorance silencieuse des paramètres) — mesuré : un
      `tranche_effectif_salarie` vide (bug, corrigé depuis) renvoyait **HTTP 422** et le run passait
      en `error` avec le détail, pas de plantage silencieux
- [x] **Règle ADR 0005** : seules les unités légales dont `siege.departement` est dans
      `campaigns.departements` sont conservées ; les autres sont **comptées comme écartées**
      — camp 44 : 193 écartées sur 1 841 (sièges hors 44) ; camp 974 : 68 sur 1 509
- [x] L'adresse stockée est celle du **siège** (`siege.adresse`, `siege.code_postal`,
      `siege.libelle_commune`) — vérifiée sur des entreprises écrites : adresse/cp/ville = siège
- [x] `tranche_effectif_salarie` : le filtre utilise **ce vocabulaire, figé** —
      `00 01 02 03 11 12 21 22 31 32 41 42 51 52 53` (tranches d'effectif salarié de l'unité légale,
      INSEE). Vérifié **par l'API** le 2026-10-15 : ces 15 codes sont acceptés, et
      `13 23 33 43 50 54 55 99` sont refusés en **HTTP 400** — la validation porte donc sur le
      vocabulaire, pas sur la syntaxe. Requête qui le prouve :
      `curl -s "https://recherche-entreprises.api.gouv.fr/search?tranche_effectif_salarie=53&per_page=1" | grep -o '"total_results":[0-9]*"'`
      → `91`. Un `0` sur un croisement NAF × effectif ne prouve **rien** sur la validité du code.
      **Le nom du paramètre doit être exact** : un nom mal orthographié est ignoré **en silence**
      (vérifié : HTTP 200 avec des résultats non filtrés).
- [x] **Filtre d'effectif obligatoire (`D-008`)** : dès qu'une campagne déclare un `effectif_min`, le
      filtre est appliqué — en **union de bandes**, dans **une seule** requête
      (`tranche_effectif_salarie=21,22,31,…`) : la bande contenant `effectif_min`, **puis toutes les
      bandes supérieures** ; écrites dans `runs.details`. **`effectif_min` nul = aucun filtre** —
      le paramètre est **omis** de la requête, jamais vide (un `tranche_effectif_salarie` vide
      renvoie HTTP 422 — mesuré) ; camp 974 sans filtre : `bandes_appliquees: []`, param absent,
      1 509 résultats ; camp 974 avec `effectif_min=50` : `bandes_appliquees: ["21",…,"53"]`
      (bande ≥50 en union), 13 résultats
- [x] Aucun appel si une campagne n'a ni `naf_codes` ni `departements` (validation d'entrée)
      — critère dans le Code node de préparation ; les campagnes de validation vides n'appellent pas
      l'API (tick à vide : `runs` à `campaign_id NULL`, 0 appel — comportement déjà testé en S1-01)
- [x] Le JSON brut de chaque entreprise est conservé dans `companies.raw`
      — 29 clés par `raw` sur les échantillons lus

**Preuves mesurées (passe 2, exécution #22)** — lignes `runs` lues directement :
- camp 44 : `recuperees=1841, ecartees=193, bandes_appliquees=[]`, `items_processed=1648`, status `success`
- camp 974 sans filtre : `recuperees=1509, ecartees=68, bandes_appliquees=[]`, `items_processed=1441`, status `success`
- camp 974 avec bande D-008 : `recuperees=13, ecartees=7, bandes_appliquees=["21"…"53"]`, status `success`
- 3 090 entreprises écrites (1 648 + 1 441 + 1 ligne test directe) puis **données de test intégralement
  supprimées** (`companies`, `runs`, `campaigns`) ; les doublons de SIREN sont **intentionnellement
  laissés à S1-03** (upsert `on conflict (siren)`).

**Deux découvertes d'exécution ajoutées à `AGENTS.md` §10** : (1) un paramètre de query vide
(`tranche_effectif_salarie=`) est **refusé (422)** là où un nom inconnu passe en silence ;
(2) le n8n Code node (JsTaskRunner) n'a **ni `fetch` ni `node:http`** — la collecte passe par un
nœud HTTP Request native avec pagination intégrée, pas par du code.

**Périmètre** : `n8n/workflows/wf1-collecte.json` · **Dépendances** : `S1-08` (colonne `runs.details`
— revue du 2026-10-15), S0-04, **ADR 0005 validé**
**Taille** : M · **Rôle** : Automation

---

### S1-03 — WF1 : upsert `companies` par SIREN (dédoublonnage) ✅ fait

**Objectif** : relancer WF1 deux fois ne duplique rien, n'écrase pas les données enrichies, et un
lot d'entreprises **mixtes** (nouv. + déjà en base) ne fait pas échouer tout le lot.

**Contexte** : RF-05 · critère d'acceptation v1 « alimente `companies` sans doublon » · **mise à
jour du 2026-10-20** — découvertes de la preuve S1-02 (PR #25, `AGENTS.md` §10) : le nœud Supabase
de n8n poste les items d'un lot en **un seul POST atomique** — avec l'`insert` simple en place :
(1) **tout** doublon SIREN fait échouer tout le lot ; (2) un lot **mixte** échoue au complet ;
(3) un échec de lot ressort comme **UN** item d'erreur (les échecs se comptent en lots, pas en
lignes). C'est le cas de la campagne B de la preuve : 6 conservées, 0 écrites.

**Fait vérifié dans le code du nœud (image n8n en place, 2026-10-20)** : les opérations du nœud
Supabase sont `create`, `delete`, `get`, `getAll`, `update` — **aucun** upsert (`grep -icE
'upsert|on_conflict|merge-duplicates'` → 0). Un upsert est donc **techniquement impossible** par
ce nœud : la voie passe forcément ailleurs.

**Décision d'architecte posée puis appliquée (ADR 0007, créé le 2026-10-20)** — la chaîne de
substitution, à la place du nœud Supabase natif :
- **Nœud HTTP Request** : `POST {SUPABASE}/rest/v1/companies?on_conflict=siren` avec l'en-tête
  `Prefer: return=representation,resolution=merge-duplicates` (sémantique PostgREST
  `ON CONFLICT DO UPDATE`) — l'URL du projet n'est pas un secret (elle est publique par nature
  côté front) ; la clé est portée par le **type prédéfini `supabaseApi`** du nœud HTTP, référencé
  par `id`/`name` — **aucune clé dans le JSON exporté**
- **Un item = un lot d'entreprises** (pas un POST par entreprise) : le lot est construit et
  **dédupliqué par SIREN** dans un Code node (garde PostgREST : un payload contenant **deux fois
  la même clé** échoue avec « ON CONFLICT DO UPDATE command cannot affect row a second time »)
- **Passe de propriété distincte** (ADR 0007, point 3) : après le POST, le `campaign_id` est
  attribué par un PATCH ciblé `campaign_id=is.null` + `siren=in.(…)`, dont les SIREN viennent du
  **lot lui-même** — pas de la réponse du POST (la forme d'items n8n n'est pas garantie) ; le
  filtre suffit à ne toucher que les lignes fraîches (D-009 : une ligne déjà attribuée — au
  re-passage ou par une autre campagne — n'est jamais re-attribuée)
- **Alternatives écartées** : (a) `update` puis `create` en cascade — deux requêtes, course
  possible entre ticks, et un lot sans atomicité ; (b) une fonction SQL `on conflict` appelée
  via RPC — fiable mais elle sort du périmètre Automation et met du SQL dans le nœud

**Avancement (2026-10-20)** : implémenté et **vérifié en conditions réelles** sur l'instance n8n
jetable (conteneur `wf1-verif-s106`) avec le projet réel : collecte NAF 43.21A × 974 (13
récupérées, 7 écartées ADR 0005, 6 écrites), deux passages de la même campagne, manipulation des
lignes témoins entre les deux, test du dédoublonnage en Code node. Les deux arbitrares PO
demandés par le ticket sont écrits : **D-009** (le payload d'upsert ne porte jamais
`campaign_id`) et **D-010** (doublon intra-lot : le **premier** gagne, rejeté et compté avant
l'écriture).

**Critères d'acceptation** (tous exercés par le nouveau chemin sur le projet réel)
- [x] La requête émise porte `?on_conflict=siren` et
      `Prefer: return=representation,resolution=merge-duplicates` — **observée** par une copie
      d'écho du même nœud (hôte substitué) : URL, en-tête Prefer, les **deux en-têtes
      d'authentification** via le credential `supabaseApi`, et un corps de 6 lignes aux colonnes
      exactes (`siren, name, naf, address, city, postal_code, effectif, raw`) — ni `campaign_id`,
      ni colonnes enrichies
- [x] Un second passage sur la même campagne ne change **pas** le nombre de lignes
      (6 lignes témoins avant/après, comptées via l'API — pas un « rien vu dans l'UI »)
- [x] Un **lot mixte** : SIREN déjà en base mis à jour (name rafraîchi, raw réactualisé),
      SIREN absent recréé ; run `success`, `items_processed = 6` (D-002)
- [x] Un payload en double du même SIREN est détecté **avant** l'écriture — test réel du Code
      node : lot de 3 items dont un doublon → lot de 2, `doublons_rejetes = 1`, **le premier
      gagne** (D-010), la garde PostgREST (« cannot affect row a second time ») jamais exposée
- [x] Les colonnes `website`, `email`, `phone`, `website_source` ne figurent **pas dans le
      payload** — observé dans le corps du POST écho, et re-vérifié dans le test du Code node
- [x] `updated_at` reste actualisé à l'écriture, `raw` est mis à jour, et la passe de propriété
      (D-009) respecte le contrat : une ligne réattribuée à une campagne créée manuellement
      avant le re-passage garde son `campaign_id` et ses colonnes enrichies posées à la main ;
      une ligne supprimée avant re-passage est recréée et attribuée à la campagne de test
      (passe distincte) ; les 6 lignes ont un `updated_at` rafraîchi au second passage
- [x] Les entreprises récupérées hors zone (ADR 0005) ne sont pas insérées (7 écartées,
      compteurs `runs.details` intacts : 13 récupérées / 7 écartées)

**Découvertes consignées au fil de la preuve (à porter dans `AGENTS.md` §10 à la rétro)**
1. **Deux en-têtes obligatoires sur la passerelle Postgres du projet** : `Authorization: Bearer …`
   seul renvoie 401 « No API key found in request », `apikey` seul renvoie 401 « permission
   denied for role anon ». Le seul credential qui porte les deux depuis le même secret est le
   **type prédéfini `supabaseApi`** du nœud HTTP (`SupabaseApi.credentials.js` l. 28-33).
2. **Syntaxe du filtre `in.` PostgREST** : `siren=in.819…,310…` échoue en **PGRST100**
   (« expecting "(" ») ; il faut `siren=in.("819…","310…")` — parenthèses **et** guillemets.
   La garde (rejets « cannot affect a second time ») n'a jamais été touchée : le POST du lot
   est resté sain.
3. **`sendHeaders`/`headerParameters` du nœud HTTP v3 sont des paramètres de RACINE**, pas des
   `options` (`HttpRequestV3.js` l. 185) : mis dans `options`, un en-tête est **silencieusement
   non émis**. Conséquence `S1-04` : le User-Agent de la collecte est à re-vérifier et corriger
   à l'occasion de « politesse de crawl ».
4. **La passe d'attribution lit les SIREN dans le lot, pas dans la réponse du POST** : la forme
   d'items n8n renvoyée n'est pas garantie ; le filtre `campaign_id=is.null` suffit à ne toucher
   que les lignes fraîches — plus robuste et plus simple. Deux faux « NON PRUVE » intermédiaires
   (harnais : comptage sur la seule campagne de test, puis exigence « ≥ 2 runs » incompatible
   avec la purge des runs entre passages) ont été corrigés **dans le harnais**, pas dans le
   workflow : les critères ont été écrits puis lus pour ce qu'ils disent, jamais assouplis.

**Fusion (2026-10-20)** : **PR #30 fusionnée en squash `e6e2c14`** sur instruction explicite du propriétaire,
CI de la PR **verte** (run 39433897410 : secrets, sql, node) ; re-revue **demandée sur la PR** (reviewer attribué,
4 points de lecture listés en commentaire). **Écart de relecture, assumé et écrit** : la fusion a suivi sur
instruction explicite du propriétaire avant toute review signée d'un tiers — même pratique que
`S1-06`/`S1-08`/`S1-09` : l'exigence « l'agent ne valide pas son propre travail » n'est pas satisfaite à la
lettre, l'écart est consigné ici plutôt que tué en silence.

**Nettoyage** : base verte — `companies` / `runs` / `campaigns` comptés avant/après la preuve,
identiques ; les campagnes de test (`S1-03-verif`, `S1-03-propriété-test`) et leurs lignes ont
été supprimées. La preuve n'a rien laissé derrière elle, aucune donnée de production touchée.

**Périmètre étendu** : `n8n/workflows/wf1-collecte.json` (chaîne d'écriture complète : Code
« Lot des entreprises (S1-03) » → HTTP « Upsert des entreprises (S1-03) » → Code « Attribution
des nouvelles lignes (S1-03) » → HTTP « Attribution campagne (S1-03) » → conciliations
« Conciliation du lot (S1-03) » et « Conciliation échec de lot (S1-03) ») ·
`docs/adr/0007-upsert-par-requete-postgrest.md` (créé : en-têtes doubles via credential
prédéfini, passe de propriété) · `docs/product-decisions.md` (D-009, D-010)
**Taille** : M · **Rôle** : Automation
**Dépendances réalisées** : S1-01 (réalisé), S1-06 fait (ordre D-006 levé)

---

### S1-04 — WF1 : politesse de crawl et robustesse ✅ fait

**Avancement (2026-10-26)** : le ticket avait été **clos trop vite**. La PR #32 avait fusionné les
réglages de politesse **et** un harnais de test embarqué dans le workflow, mais sa propre preuve
restait à faire : *« Preuve attendue : exécution réelle … (à faire pour la DoD complète) »*. La
preuve a donc été faite ici — et elle a mis au jour **trois défauts réels**, dont un qui rendait
WF1 inopérant.

**Ce qui a été corrigé**

1. **Échec réseau avalé en silence (le plus grave).** `Filtrage et compteurs (S1-02)` rattachait
   chaque page à son couple via `pairedItem.sourceOverwrite` — un champ que **n8n ne remplit
   jamais**. Le couple était donc toujours introuvable, le résultat tombait dans la branche
   « aucune donnée » et le run sortait en **`success` avec 0 élément**. Mesuré : un endpoint
   inexistant (`ENOTFOUND`) comme un timeout de 10 s ressortaient tous deux en `success`,
   `items_processed = 0`. Le rattachement se fait désormais sur `pairedItem.item` (= l'index du
   couple dans « Préparation de collecte »), et un rattachement perdu devient une **erreur**,
   jamais un silence.
2. **Échec de collecte jamais compté.** Le nœud qui portait la logique `echecs_collecte` était
   **orphelin** (aucun entrant depuis S1-03) : la règle « un couple en panne ⇒ `partial` » était
   du code mort. La logique est passée dans le nœud réellement branché
   (« Conciliation du lot (S1-03) »), l'orphelin est supprimé, et `runs.error` porte enfin le
   message exploitable.
3. **Harnais de test embarqué retiré** : quatre nœuds (`Tests S1-04 ?`, deux appels HTTP de test,
   `Verdict tests S1-04`), un drapeau `test_s104` codé en dur, et une sortie **qui ne menait nulle
   part**. Ils étaient de plus **cassés** (`onError` placé dans `parameters` au lieu de la racine,
   en-têtes User-Agent replacés dans `options` — exactement le piège d'`AGENTS.md` §10 qu'ils
   prétendaient corriger). La preuve exigée par le ticket est une **exécution réelle sur copie**
   (pratique S1-02/S1-06), pas des nœuds de démonstration livrés en production.
4. **Retry** : `waitBetweenTries` valait 1 000 ms alors que la PR, le daily et la note annonçaient
   5 000 ms. Aligné à **5 000 ms**, comme les autres nœuds de clôture.

**Ce qui a été *vérifié*, pas supposé**

| Critère | Résultat mesuré |
|---|---|
| Lots de 10 à 25 éléments (*Split in Batches*), jamais un appel par élément | `batchSize = 10` sur « Pour chaque campagne » ; un appel HTTP couvre un **couple** (NAF × département) |
| Nœud *Wait* entre appels, **max 1 req/s**, timeout **10 s** | écart **mesuré** entre deux appels consécutifs : **948 ms** (nœud Wait 1 s + `batching.batchInterval` 1 000 ms du nœud HTTP) ; `options.timeout = 10 000` |
| *Retry on Fail* ×3, délai croissant | `retryOnFail = true`, `maxTries = 3`, `waitBetweenTries = 5 000`. **ÉCART ASSUMÉ** : n8n n'offre qu'un délai **fixe** (plafonné à 5 000 ms) — le « délai croissant » du ticket n'est pas implémentable tel quel |
| `Continue on Fail` : un élément en erreur ne bloque pas le lot | 2 couples, un en panne (HTTP 500) + un sain → **1 écriture**, run **`partial`**, message `1 couple(s) en echec — 43.21A\|971 : HTTP 500 — {"erreur":"panne simulee par le banc de preuve (departement 971)"}` |
| User-Agent identifiable mentionnant le projet | observé **sur le fil** par un hôte d'écho : `Prospection-ia/1.0 (n8n WF1 collecte)` — la valeur est bien *émise* ; elle ne l'était pas tant qu'elle vivait dans `options` |
| Fin d'exécution : `runs.status = 'partial'` si échecs, `'success'` sinon | mesuré sur les 6 scénarios ci-dessous (et `error` quand la collecte n'a rien produit) |
| **Test d'erreur réseau** : endpoint faux → `partial` ou `error` avec message exploitable, **pas** de plantage silencieux | hôte inexistant → `status = error`, `error = "1 couple(s) en echec — 43.21A\|974 : getaddrinfo ENOTFOUND api-s104-inexistante.invalid — ENOTFOUND"` |
| **Test de réponse vide** : pas d'erreur | département **valide** `2A` × NAF **valide** sans résultat → **`success`**, `items_processed = 0`, `details.recuperees = 0` |

**Preuves** — instance n8n jetable (n8n **2.43.5**, image `docker.n8n.io/n8nio/n8n:latest`,
conteneurs jetables sur un volume dédié), projet Supabase réel, **26/10/2026** :

- **collecte réelle, 2 couples** : campagne `43.21A` × `974` + `976` → ligne `runs`
  `status = success`, `items_processed = 2`, `details = {recuperees: 2, ecartees: 0}` ; **deux
  lignes `companies` réellement écrites** (`997400001`, `997600001`) avec `campaign_id` posé, et
  colonnes enrichies (`website`, `email`, `phone`, `website_source`) **restées nulles** — contrat
  `S1-03` tenu.
- **politesse** : les deux requêtes portent le User-Agent ci-dessus ; écart **948 ms**.
- **retry ×3** : deux réponses HTTP 503 puis 200 → run `success`, 1 écriture ; les trois tentatives
  sont visibles dans le journal de l'écho.
- **Continue on Fail**, **endpoint faux**, **réponse vide** : cf. tableau.
- **Base rendue à l'état d'avant** après chaque scénario (`campaigns` / `companies` / `runs`
  comptés avant/après : **0 / 0 / 0**).

**Limitation constatée, non bloquante (environnement, pas WF1)** : la collecte sur l'**API
publique** n'a pas pu être rejouée en `success`. Le nom `recherche-entreprises.api.gouv.fr` résout
**trois** adresses et **deux d'entre elles ne répondent jamais** depuis ce réseau — mesuré :
`37.59.183.76 → HTTP 200 en 2,0 s`, `37.59.183.77 → timeout après 15,0 s`,
`37.59.183.78 → timeout après 12,7 s` (l'hôte aussi met parfois 14-17 s là où le conteneur met
1,5 s). Selon l'adresse tirée, l'appel dépasse donc le timeout de 10 s que le ticket impose — et
c'est **le comportement voulu** que le run le dise (`error` + message) au lieu de le taire. La
preuve ci-dessus utilise la **même copie de workflow**, avec **seule l'URL de collecte substituée**
par un hôte d'écho local (même pratique que S1-02/S1-06 : preuves sur copie, aucun harnais livré).

> **Correction du même jour** : la dernière phrase ci-dessus (« selon l'adresse tirée, l'appel
> dépasse le timeout de 10 s ») était une **hypothèse**, démentie par la mesure de la rotation
> ([`reviews/2026-10-26-mesure-rotation-api.md`](reviews/2026-10-26-mesure-rotation-api.md), `D-014`) :
> les deux adresses muettes le restent au niveau TCP, mais le client bascule seul sur la vivante —
> **8 appels sur 8 réussis**, sur l'hôte comme dans le conteneur n8n. Le timeout de 10 s n'était donc
> pas l'obstacle. Ce qui reste vrai : l'API n'est joignable que par **une** adresse sur trois.

**Découvertes consignées (à porter dans `AGENTS.md` §10 à la rétro)**
1. **`pairedItem.sourceOverwrite` n'existe pas dans un item n8n** : le lire renvoie `undefined`, et
   un garde-fou du type `if (!sourceData) return null` transforme alors **tout** échec réseau en
   « succès 0 élément ». Un rattachement raté doit être une **erreur**, jamais un `continue`.
2. **Un « département inexistant » n'est PAS une réponse vide** pour cette API : `departement=99`
   comme `departement=XX` renvoient **HTTP 400** (« … est non valide. Les valeurs valides : […] »).
   Le cas vide nominal est un département **valide** × un NAF **valide** sans résultat
   (`05.10Z` × `2A` → HTTP 200, `total_results: 0`). Le test d'origine (PR #32) testait donc
   l'inverse de ce qu'il annonçait.
3. **Un nœud sans arête entrante ne s'exécute jamais — et rien ne le signale.**
   « Conciliation des écritures (S1-02) » a porté la logique de statut `partial` pendant deux
   tickets sans être branchée. Contrôle à inscrire dans toute relecture de workflow : lister les
   nœuds sans entrant.


**Fusion (2026-10-26)** : **PR #36 fusionnée en squash `3945450`** sur instruction explicite du
propriétaire ; CI de la PR **verte** (run 40325057310 : sql, secrets, node) et CI de `main` **verte**
(run 40325270121). Écart de relecture assumé, écrit ci-dessous, comme `S1-03`/`S1-06`/`S1-08`/`S1-09`.
**Correctif (PR #36, 2026-10-26)** : les trois défauts ci-dessus ont été corrigés dans la foulée de la preuve, avec les six scénarios rejoués après correction.

**Écart de relecture, assumé et écrit** : comme `S1-03`/`S1-06`/`S1-08`/`S1-09`, la revue en
contexte neuf par un agent **Reviewer** n'a pas été faite avant la mise en `fait` — les preuves
ci-dessus sont produites par l'auteur. À rattraper au sprint review.

**Périmètre** : `n8n/workflows/wf1-collecte.json` · **Dépendances** : S1-02, S1-03
**Taille** : M · **Rôle** : Automation

---

### S1-05 — Garde-fou de format des codes NAF ✅ fait

**Objectif** : rendre impossible l'erreur qui a produit le bug du seed : un code NAF au mauvais format.

**Contexte** : `AGENTS.md` §10 (l'API rejette le format compact en HTTP 400) · règle « tests d'abord ».

**Critères d'acceptation**
- [x] Un test dans `supabase/tests/schema.sql` : insérer une campagne avec `naf_codes = ['4321A']`
      **doit échouer** ; avec `['43.21A']` doit réussir
- [x] Une nouvelle migration ajoute la contrainte (fonction `immutable` appelée dans un `check`) —
      la migration initiale n'a **pas** été modifiée
- [x] La contrainte accepte le tableau vide `'{}'` (une campagne peut être en cours de configuration)
- [x] Le test ne laisse aucune ligne derrière lui (`begin; … rollback;`)
- [x] La CI joue bien les deux fichiers de test (`supabase/tests/*.sql`)

**Preuve — rouge d'abord, vert ensuite** (Postgres 16 dans Docker, 2026-10-15) :

```
# AVANT la migration — le test doit détecter l'absence de contrainte
OK  code NAF pointé (43.21A, 43.99C) accepté
ERROR:  ECHEC  le code NAF compact 4321A a été accepté (l'API le rejette en HTTP 400)
>>> EXIT=3

# APRÈS la migration — les 5 cas passent
OK  code NAF pointé (43.21A, 43.99C) accepté
OK  code NAF compact (4321A) refusé
OK  tableau de codes vide accepté (campagne en cours de configuration)
OK  code NAF en minuscules (43.21a) refusé
OK  code NAF tronqué (43.2A) refusé
=== TESTS DE SCHEMA : PASSENT ===        (EXIT=0)
```

Le premier cas (acceptation d'un code valide) est placé **avant** les cas négatifs pour une raison
précise : sans lui, un refus pour *permission denied* ferait passer les tests négatifs pour la bonne
raison apparente alors qu'ils ne prouveraient rien. Chaque cas négatif vérifie donc que l'échec est
bien une `check_violation` (23514) et pas une `insufficient_privilege` (42501).

**Historique de la branche** : `feat/s1-05-garde-fou-naf` — **PR #1 relue en contexte neuf** (un
bloquant trouvé et corrigé : migration non réapplicable), rebasée puis **fusionnée**, CI de `main`
verte (§4).

**Avancement** : relecture en contexte neuf **faite** le 2026-10-16 — un bloquant trouvé et corrigé
(migration non réapplicable), rebasée, fusionnée ; CI de `main` verte (§4 et tableau du §2). Les deux
lignes ci-dessus (« commit non fusionné », « reste à faire ») étaient **périmées** et ont été alignées
sur le tableau le **2026-10-26**.

> **Note du planning (2026-10-15)** : ce ticket annonçait que ces deux étapes dépendaient de `S0-05`.
> C'est **périmé** : le dépôt existe, la protection est active et la PR #1 est ouverte. Il ne manquait
> que la relecture. **Fait le 2026-10-16** — la note est conservée pour l'historique du planning,
> elle n'est plus un état courant.

**Périmètre** : `supabase/migrations/`, `supabase/tests/` · **Dépendances** : aucune
**Taille** : S · **Rôle** : Backend/Data

---

### S1-06 — WF5 : workflow d'erreurs + notification d'échec ✅ fait

**Avancement (2026-10-20)** : implémenté et **vérifié en conditions réelles** sur une instance n8n
jetable (échecs provoqués dans deux copies de WF1 reliées à `settings.errorWorkflow`, déclencheur
réactivé en minutes pour passer par le vrai chemin « trigger ») — **PR #28 fusionnée en squash
`2969c3d`**, CI de `main` **verte** (run 39390859370). **Écart de relecture, assumé et écrit** :
la re-revue a été **demandée sur la PR** (reviewer attribué, points de lecture listés dans un
commentaire) ; la fusion a suivi sur **instruction explicite du propriétaire** — l'exigence
« l'agent ne valide pas son propre travail » n'est donc pas satisfaite à la lettre (pas de
review signée d'un tiers), même pratique que `S1-08`/`S1-09` : l'écart est consigné ici plutôt
que tué en silence.

- **Cas A — échec avant toute ouverture de ligne** : l'exécution 17 échoue au nœud
  « Run démarré (campagne) » → WF5 (exécution 18) **crée** la ligne `runs` :
  `status error`, sans campagne, `finished_at` posé, `error` = message n8n complet
  (`echec workflow n8n — « WF1 … » — exécution N — dernier nœud : … — détail`).
- **Cas B — échec après ouverture** : la collecte ouvre une ligne `running` (campagne de test),
  puis la clôture sabote (`tableId runs_typo` → 404 PostgREST) → l'exécution 19 échoue →
  WF5 (exécution 20) **clôt la ligne `running` en `error`** (exactement la ligne ouverte :
  `campaign_id` de la campagne de test, `finished_at` posé, message n8n dans `runs.error`).
- **Pas de boucle** : exactement 1 exécution WF5 par échec de WF1, aucune exécution WF5
  déclenchée par une exécution WF5, **0 ligne figée** en `running` après les deux scénarios.
- Le nettoyage rend la base à l'état avant (`companies`/`runs`/`campaigns` comptés avant/après).

**Découvertes consignées (2026-10-20)**
1. **Le mode « manual » ne déclenche jamais l'error workflow** — prouvé dans le code n8n en place
   (`execution-lifecycle-hooks.js`, l. 516-520 : `!isManualMode` requis). Toute vérification S1-06
   doit passer par le mode **trigger** (activation réelle du workflow), pas par « Executer
   le workflow » de l'UI. De même, WF5 doit être **activé** pour servir d'error workflow.
2. **Bug corrigé pendant la preuve** : le filtre « Ligne(s) runs encore running » comparait le
   champ `runs.workflow` au **nom n8n** de l'exécution, or le contrat pose une **clé constante**
   (`wf1-collecte`, l. 70/131 de `wf1-collecte.json`). Le run orphelin restait donc figé et WF5
   créait une ligne doublon. Le nœud « Présentation » porte désormais la correspondance explicite
   nom n8n → clé du contrat (`ALIAS_RUNS`, avec traitement des copies de test « Nom (suffixe) »).
3. **Verrou de versions n8n** : la mise à jour par REST (`PATCH`) persiste bien le JSON
   (vérifié par relecture GET), mais les exécutions continuaient de charger l'ancienne version du
   workflow. Contournement : **archiver + supprimer + réimporter à neuf** le workflow.

**Critères d'acceptation**
- [x] WF5 déclenché par un *Error Trigger* n8n
- [x] `runs.status = 'error'` écrit avec le message dans `runs.error` — **c'est le cœur du ticket**
- [x] Testé en provoquant volontairement une erreur dans WF1 (preuve collée dans la PR)
- [x] Une notification en échec **ne relance pas** WF5 en boucle
- [ ] *(facultatif, seulement si `S0-06` est fait)* notification Telegram contenant le nom du
      workflow, l'heure et le message d'erreur

**Objectif** : un workflow qui échoue le dit, au lieu de rester silencieux toute la nuit.

**Contexte** : cahier des charges §4 (observabilité), §7.2 (WF5), risque R7.

**Portée réduite par D-003 (2026-10-15)** : la trace en base est **obligatoire**, la notification
Telegram est un **plus non bloquant**. Le ticket ne dépend donc plus de `S0-06`.

**Périmètre** : `n8n/workflows/wf5-erreurs.json` (créé), `n8n/workflows/wf1-collecte.json`
(uniquement `settings.errorWorkflow` → l'id fixe de WF5, branchement S1-06) · **Dépendances** : aucune
**Taille** : S · **Rôle** : Automation

---

### S1-07 — Documentation d'exploitation de WF1 🟦 **Prêt** (remis en `Prêt` le 2026-10-26)

**Avancement (2026-10-26)** : refusé au planning du 2026-10-15, faute d'avoir jamais tourné
« pour de vrai ». Sa condition de retour, réécrite par **`D-013`** en « une exécution de WF1 a
réellement appelé `recherche-entreprises.api.gouv.fr` et écrit au moins une ligne `companies` », est
**remplie** : exécution du 2026-10-26 → `runs.status = success`, `items_processed = 20`,
`recuperees = 22` / `ecartees = 2`, **20 lignes `companies`** avec leur `campaign_id`
([`reviews/2026-10-26-execution-reelle-wf1-api-publique.md`](reviews/2026-10-26-execution-reelle-wf1-api-publique.md),
**`D-015`**). Reste au ticket : décrire l'état **réel**, défauts A et B compris (cf. §7).

**Objectif** : pouvoir relancer WF1 et diagnostiquer un échec sans relire le workflow.

**Critères d'acceptation**
- [ ] `n8n/workflows/README.md` : comment importer, exécuter, relancer WF1
- [ ] Où regarder en cas d'échec : `runs` (statut, `items_processed`, `error`) et l'UI n8n
- [ ] Ce qu'il ne faut **pas** faire : lancer WF1 sur toutes les campagnes d'un coup, modifier
      une migration appliquée, mettre la clé `service_role` ailleurs que dans n8n
- [ ] `README.md` : section « Avancement » à jour (S1 réellement terminé, pas « prévu »)
- [ ] Les écarts constatés entre la doc et le code réel sont **listés**, pas corrigés en silence

**Périmètre** : `n8n/workflows/README.md`, `README.md`, `docs/` · **Dépendances** : S1-04
**Taille** : S · **Rôle** : Documentation

**Statut (aligné le 2026-10-26)** : **refusé du sprint 1** par le planning du 2026-10-15 (voir §7) —
l'état `⬜` de l'en-tête laissait croire à un ticket en attente alors que le tableau du §2 le porte
refusé. Condition de retour **explicite** : « dès 1 collecte réelle », pour ne pas documenter une
procédure qui n'a jamais tourné.

---

### S1-08 — `runs.details` : distinguer récupérées / écartées / écrites (**D-002**) ✅ fait

**Avancement (2026-10-15)** : implémenté, **CI verte** — PR #12 fusionnée.
`supabase/migrations/20261015000003_runs_details.sql` + `supabase/tests/runs_details.sql` (6 assertions,
rouge avant la migration puis vert, et le test mord au retrait du `comment on column`).
**Avancement (2026-10-15, soir) — dernière condition levée** : **vérifié sur le projet réel** après
`supabase db push` — `runs_details.sql` sort en **code 0** sur le vrai projet, ses 6 assertions lues
dans la sortie ; `runs.details` et les `comment on column` des deux colonnes existent dans le catalogue
du projet réel ; l'empreinte de schéma du projet ne manque **aucun** objet de la référence.
**Écart de relecture, assumé et écrit** : la relecture est une revue **adversariale non indépendante**
([`reviews/2026-10-15-s1-08-s1-09.md`](reviews/2026-10-15-s1-08-s1-09.md), qui le déclare en tête) —
l'exigence du dépôt « un agent ne valide jamais son propre travail » n'est donc **pas satisfaite à la
lettre**. Le propriétaire a tranché de passer le ticket à `fait` en consignant l'écart, plutôt que
d'abandonner l'exigence en silence. **Ses trois constats restent ouverts** et sont, eux, mesurés :
`items_processed` nullable, `prochain_run` NULL sur une campagne due, et — pour `S1-09` — un run en
`error` qui bloque sa campagne un intervalle entier.

**Objectif** : rendre le ciblage calibrable en séparant trois compteurs aujourd'hui confondus.

**Contexte** : décision produit **D-002** ([`product-decisions.md`](product-decisions.md)) ·
conséquence d'`ADR 0005` (règle de ciblage sur le siège) · cahier des charges §4 (observabilité).

**Critères d'acceptation**
- [ ] Une migration ajoute `runs.details jsonb` — **ne pas modifier** la migration initiale, déjà appliquée
- [ ] `runs.items_processed` garde un sens **unique** : nombre de lignes **écrites** en base
- [ ] `runs.details` contient au minimum `recuperees` et `ecartees` (entiers), documentés par un
      `comment on column` — la colonne doit s'expliquer toute seule, sans ce fichier
- [ ] Un test SQL vérifie que les trois valeurs coexistent et s'interrogent séparément
      (cas d'usage réel : le taux de rejet par campagne)
- [ ] Les trois compteurs se lisent **séparément** sur un même run : `items_processed` d'un côté,
      `details->>'recuperees'` et `details->>'ecartees'` de l'autre, avec des valeurs **différentes**
      (correction du planning, précisée par la revue : « c'est bien du JSONB » n'échouerait que si
      la migration déclarait `text` — ce critère ne prouvait donc rien sur **l'exploitabilité** ; le
      test ci-dessus, lui, lit trois compteurs distincts)
- [ ] Le fichier de test ne laisse aucune ligne derrière lui (`begin; … rollback;`) et la CI passe

**Pourquoi maintenant** : le taux de rejet est la seule métrique qui dit si une campagne est trop
large (seuil d'alerte : > 60 %, brief PO §5). Sans lui, aucun calibrage n'est possible — et D-001
prévoit un arrêt de la collecte à 100 analyses si les faux positifs dépassent 30 %.

**Périmètre** : `supabase/migrations/`, `supabase/tests/` — **interdit** : `n8n/`, `apps/`
**Dépendances** : aucune · **Taille** : S · **Rôle** : Backend/Data

---

### S1-09 — Rendre la fréquence par campagne implémentable (créé au planning) ✅ fait

**Avancement (2026-10-15)** : **condition de démarrage levée** par
[`ADR 0006`](adr/0006-cadence-des-campagnes.md), puis implémenté et **vérifié en CI** — PR #13 fusionnée.
`20261015000004_campaigns_due.sql` + `campaigns_due.sql` (10 assertions : la règle d'échéance, le
blocage par un run en cours, les droits de `service_role`/`authenticated`, et le refus de `anon`
**même quand la vue lui est ouverte**). Deux mutations vérifient que le test mord.
**Avancement (2026-10-15, soir) — dernière condition levée** : **vérifié sur le projet réel** après
`supabase db push` — `campaigns_due.sql` sort en **code 0** sur le vrai projet, ses 10 assertions lues
dans la sortie, **y compris le contrôle discriminant** « `anon`, même avec le droit sur la vue, ne lit
rien » et les contrôles positifs de `service_role`/`authenticated`. `security_invoker=true` est mesuré
dans `pg_class` du projet réel, la vue `campaigns_due` y existe, et l'accès `anon` à la base rend
**401 `permission denied for view campaigns_due`**.
**Écart de relecture, assumé et écrit** : même situation que `S1-08` — revue adversariale **non
indépendante**, consignée, l'exigence « Reviewer en contexte neuf » n'étant pas satisfaite à la lettre.
Le constat qui reste ouvert est le premier : **un run en `error` bloque sa campagne aussi longtemps
qu'un run en cours** (24 h par défaut), sans que l'ADR 0006 l'ait arbitré ni qu'un test l'exerce.

**Objectif** : pouvoir décider, campagne par campagne, si elle est due — sans quoi RF-03 reste une
case cochée sur le papier.

**Contexte** : RF-03 (fréquence d'exécution par campagne) · **constat du planning du 2026-10-15** en
validant la DoR de `S1-01` : `campaigns.cron` existe, mais **rien n'enregistre le dernier passage**.
Un workflow ne peut donc pas savoir si une campagne est due. Le ticket `S1-01` demandait
« un cron défini par campagne, pas en dur » : ce n'est pas implémentable dans n8n, où le cron est une
propriété du nœud de déclenchement, pas une valeur lue en base à l'exécution — la documentation
officielle le confirme (*Schedule Trigger → Common issues → Variables* : les valeurs du déclencheur ne
sont évaluées **qu'à la publication** du workflow, les modifier ensuite ne change pas la fréquence).
Ce n'est donc pas seulement difficile, c'est **impossible**.

**Condition de démarrage** : une **décision d'Architecte** doit être consignée avant l'implémentation
(ADR ou section d'ADR) sur la façon de calculer l'échéance. C'est une décision technique, elle ne
dépend pas de l'humain. Options à trancher :

1. Ajouter une **durée** en minutes à la campagne (`campaigns.interval_minutes`) plutôt que d'interpréter
   `cron` à l'exécution — le plus simple, mais s'écarte du modèle du cahier des charges §7.1.
2. Rendre le **dernier passage lisible** (`runs.campaign_id`, ou `campaigns.last_run_at`) et comparer
   à `now()` — utile par ailleurs, car aucun `runs` n'est aujourd'hui rattachable à une campagne.
3. Les deux : rattachement des runs **et** intervalle explicite.

**Critères d'acceptation**
- [ ] Une migration (nouvelle, la initiale n'est **pas** modifiée) rend le dernier passage d'une
      campagne déterminable — la forme exacte dépend de la décision ci-dessus
- [ ] Un test vérifie qu'une campagne **jamais exécutée est due** (premier passage toujours autorisé)
- [ ] Un test vérifie qu'une campagne exécutée **récemment n'est pas due**
- [ ] La comparaison d'échéance est **écrite dans le test** en clair, pour que l'agent Automation
      l'applique sans réinterpréter la règle
- [ ] Un test vérifie qu'une campagne **désactivée** reste hors jeu, même due (`active = false`)
- [ ] CI verte, et aucun test laisse de lignes derrière lui

**Périmètre** : `supabase/migrations/`, `supabase/tests/` — **interdit** : `n8n/`
**Dépendances** : aucune (faisable **sans Supabase**, en CI) — sauf la condition de démarrage ci-dessus
**Taille** : S · **Rôle** : Backend/Data (et Architecte pour la décision)

---

## 4. Ce qui bloque le sprint

Chaque blocage nomme **qui peut le lever** : un agent pour le travail, un humain pour les quatre
verrous du §2 du brief Product Owner (identifiants, argent, hors dépôt, suppression).

| Blocage | Impact | Levée | Qui peut lever |
|---|---|---|---|
| ~~`S0-04` — clés Supabase absentes, migrations non appliquées~~ **levé le 2026-10-15** : 3 migrations appliquées par `db push`, les **4 suites passent sur le vrai projet**, `anon` refusé à la main, `service_role` écrit | Les tickets S1 peuvent désormais être **vérifiés sur l'environnement cible** | — | — |
| `S0-05` — board Projects absent | **Aucun impact sur le sprint** : D-005 a tranché, le tableau versionné est la source de vérité | `gh auth refresh -s project,read:project` | **Humain** (scope du jeton) |
| `S0-06` — bot Telegram | Ne bloque plus rien (D-003) ; requis seulement pour WF4 (S4) et la notification de WF5 | Créer le bot | **Humain** (compte externe) |
| ~~PR #1 non relue~~ **levée le 2026-10-16** : relecture en contexte neuf faite (un bloquant — migration non réapplicable — trouvé et corrigé), rebasée puis fusionnée ; CI de `main` verte sur le squash | — | — |
| ~~Décision d'architecture pour `S1-09`~~ | **Levée le 2026-10-15** — [`ADR 0006`](adr/0006-cadence-des-campagnes.md) : cadence fixe du déclencheur, intervalle explicite par campagne, dernier passage lisible, vue `campaigns_due` | — | **Fait** (Architecte) |

*Blocages levés : `ADR 0005` (décision du 2026-10-15) · `S0-05` dépôt, CI et protection — faits
et **testés** (push direct et merge anticipé refusés par GitHub) · **`ADR 0006`** (cadence des
campagnes, 2026-10-15) — condition de démarrage de `S1-09`, levée et implémentée dans la foulée.*

## 5. Métriques à relever en review (vendredi 23/10) — **relevées le 2026-10-26**

| Indicateur | Objectif | Valeur relevée |
|---|---|---|
| Vélocité (tickets terminés) | stable ou croissante | **8** (`S1-01`→`S1-06`, `S1-08`, `S1-09`) + 1 refusé (`S1-07`) · Sprint 0 : 4 + `S0-05` partiel → **croissante** |
| Lead time (`Prêt` → `Fait`) | < 2 jours | médiane **0,1 h** ; **8 PR sur 9** sous 48 h ; **1 outlier à 89 h** (PR #25, `S1-02`) — proxy *premier commit → fusion*, faute d'horodatage « Prêt » |
| Taux de PR refusées par le Reviewer | décroissant | **0 PR refusée** (38 ouvertes, 38 fusionnées) ; **mais** 3 tickets sur 8 corrigés après une relecture en contexte neuf et **4 fusionnés sans relecture tierce** (écart écrit au ticket) |
| Échecs de CI | < 20 % | **1 échec réel sur 91 runs (1,1 %)** — 2,2 % en comptant 1 run annulé |
| Bugs échappés en production | 0 critique | **1 critique** : WF1 sortait en `success` avec **0 élément** sur n'importe quel échec réseau (livré le 2026-10-20, trouvé le 2026-10-26) |

Détail, mode de mesure de chaque ligne et limites :
[`reviews/2026-10-26-sprint-1-review.md`](reviews/2026-10-26-sprint-1-review.md).
**La seule ligne rouge est celle des bugs échappés** — les quatre autres indicateurs sont bons, et
c'est précisément pourquoi ils ne l'ont pas vu : un défaut critique a vécu 6 jours sur `main` derrière
une CI verte et deux tickets marqués `fait`.

**Consigné** : PR **#39** fusionnée en squash `3313343`, CI de `main` **verte** (run 40328217731).

## 6. Fin de sprint — questions à trancher en rétro

1. `ADR 0005` a-t-il évité des faux positifs, ou surestimé le problème ?
2. La limite WIP de 2 a-t-elle réellement été respectée ? Si non, pourquoi ?
3. Quelles erreurs se sont répétées ? → à ajouter dans `AGENTS.md` §10 (pièges connus).
4. Le découpage de WF1 en 4 tickets (S1-01..S1-04) était-il le bon grain, ou trop fin ?

### Rétrospective — **tenue le 2026-10-26** (3 jours de retard)

Mesures, mode de mesure et limites de chaque métrique :
[`reviews/2026-10-26-sprint-1-review.md`](reviews/2026-10-26-sprint-1-review.md).

- **À garder** : la preuve d'exécution réelle avant `fait` — c'est elle qui a trouvé le défaut critique.
- **À arrêter** : clore un ticket dont la preuve est « à faire » — **un `✅` sans preuve est un `🟦`**
  (`S1-04` a vécu 4 jours dans cet état, section restée à `⬜`).
- **À essayer** : une **exécution de bout en bout de WF1** (1 campagne, 1 couple, ≤ 25 éléments, la
  ligne `runs` à l'appui) avant de clore tout ticket qui touche la chaîne de collecte — la raison est
  que `S1-02`, `S1-03` et `S1-04` ont chacun passé leur CI et leur preuve locale, et que la chaîne
  entière n'avait jamais tourné d'un bout à l'autre.

**Décisions prises le 2026-10-26** ([`product-decisions.md`](product-decisions.md)) — elles étaient
restées « sur la table, non prises » pendant la review :

- **`D-011`** — garde-fou de clôture : pour tout ticket touchant la chaîne de collecte, le « vérifié »
  de la DoD est **une exécution de bout en bout de WF1**, la ligne `runs` lue en base à l'appui.
- **`D-012`** — timeout de **10 s conservé** (le rallonger masquerait la panne) ; la rotation
  d'adresses était **à mesurer** avant toute décision. **Mesure faite le 2026-10-26**
  ([`reviews/2026-10-26-mesure-rotation-api.md`](reviews/2026-10-26-mesure-rotation-api.md)) : deux
  adresses sur trois sont muettes au TCP, mais le client **bascule tout seul** sur la vivante —
  **8/8 collectes réussies**, **→ révisée par `D-014`** (aucun réglage ne change ; ce qui apparaît,
  c'est que l'API dépend d'**une seule** adresse vivante).
- **`D-013`** — `S1-07` **reste refusé**, avec une condition de retour désormais **vérifiable** :
  1 ligne `companies` écrite par un appel réel à `recherche-entreprises.api.gouv.fr`.

**Consigné** : PR **#41** fusionnée en squash `41b6b86`, CI de `main` **verte** (run 40330489974).
**Consigné (suite)** : la mesure de la rotation et `D-014` — PR **#45** fusionnée en squash `99efd2c`,
CI de `main` **verte** (run 40335525914).

---

## 7. Reporté aux sprints suivants (à ne pas perdre)

Ces points ne sont pas des tickets de ce sprint : ils appartiennent à un sprint dont le backlog
n'est pas encore écrit. Ils sont listés ici pour ne pas disparaître entre deux sprints.

| Élément | Sprint | Pourquoi c'est noté |
|---|---|---|
| Supprimer le garde-fou `node` de `.github/workflows/ci.yml` | S5 | Tant qu'il est là, une CI « verte » ne prouve que le SQL : le job `node` s'annonce ignoré au lieu de vérifier quoi que ce soit |
| Écrire l'ADR hébergement front (Vercel Hobby non commercial, risque R4) | S7 | Décision à trancher **avant** la mise en production, pas après |
| **Défaut A — la collecte n'atteint pas l'adresse vivante de l'API** (aucun repli sur une autre adresse côté nœud HTTP de n8n) | **S2, prioritaire** | Mesuré le 2026-10-26 : 2 exécutions réelles, **3 tentatives × 10 s, 3 timeouts**, rien collecté ([`reviews/2026-10-26-execution-reelle-wf1-api-publique.md`](reviews/2026-10-26-execution-reelle-wf1-api-publique.md), **`D-015`**). La collecte est **inutilisable** pour une campagne réelle tant que ce défaut vit. Le timeout de 10 s n'est pas la cause |
| **Défaut B — les pages d'un couple sont mal attribuées** (`pairedItem.item` d'un nœud HTTP paginé = index de **page**) | **S2, prioritaire** | Mesuré le 2026-10-26 (2 mini-workflows) : au-delà de la 1ʳᵉ page, le rattachement de `S1-04` soit **abandonne** la collecte (index hors bornes), soit l'**attribue au mauvais couple** — en silence si les deux couples partagent un NAF. **2 couples sur 30** seulement tiennent sur une page (`43.21A` × `974` = **1 515** résultats, 61 pages) : ce n'est pas un cas de bord. Correctif à faire sur une **clé portée par la donnée** |
| ~~**`S1-07` refusé du sprint 1** — Documentation d'exploitation de WF1~~ | **remis en `Prêt` le 2026-10-26** | Condition de retour **remplie** (`D-013` → `D-015`) : une exécution réelle a écrit 20 lignes. La doc doit décrire l'état réel, **défauts A et B compris** |
| Réévaluer la visibilité du dépôt dès qu'une donnée d'entreprise réelle entre dans le pipeline | fin S1 | Point de révision explicite de **D-004** : le dépôt est public, aucune donnée d'entreprise ne peut y entrer |
| Protocole de calibrage de la grille (30 fiches relues à la main) | S3 | Point de déclenchement de **D-001** : à 100 analyses réelles, avant toute nouvelle collecte |

*(Le sens de `runs.items_processed` a été tranché par **D-002** : ce n'est plus un report, c'est le
ticket **S1-08**.)*
