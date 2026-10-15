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

`S1-05` est **déjà fait** (en review, PR #1). `S1-07` est **refusé du sprint** ce cycle.
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
| S0-04 | Projet Supabase « dev » + clés | **Humain** (identifiants) | S | — | 🟡 projet créé, `.env` et migrations à faire · ⛔ **verrou du sprint 1** |
| S0-05 | Dépôt GitHub public + board + `main` protégée | DevOps | S | — | 🟡 dépôt, CI et protection faits et testés ; board reporté (D-005) |
| S0-06 | Comptes externes : bot Telegram + clé PageSpeed | **Humain** (comptes) | S | — | ⬜ |
| S1-01 | WF1 — squelette : cadence, campagnes dues, log `runs` | Automation | M | **S1-09**, S0-04 | ⬜ |
| S1-02 | WF1 — API Recherche d'entreprises : pagination + ciblage | Automation | M | S0-04 | ⬜ |
| S1-03 | WF1 — upsert `companies` par SIREN (dédoublonnage) | Automation | M | S1-01 | ⬜ |
| S1-04 | WF1 — politesse de crawl et robustesse | Automation | M | S1-02 | ⬜ |
| S1-05 | Garde-fou de format des codes NAF | Backend/Data | S | — | 🟦 en review |
| S1-06 | WF5 — workflow d'erreurs + trace en base | Automation | S | — | ⬜ |
| S1-07 | Documentation d'exploitation de WF1 | Documentation | S | S1-04 | ❌ **refusé du sprint 1** (§7) |
| S1-08 | `runs.details` — compteurs récupérées / écartées (**D-002**) | Backend/Data | S | — | ⬜ |
| S1-09 | `campaigns`/`runs` — rendre la fréquence par campagne implémentable (créé au planning) | Backend/Data | S | — | ⬜ |

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
| `S1-01` | 🟡 **Prêt sous condition** | **Le critère « cron défini par campagne » n'est pas implémentable** : n8n ne peut pas lire un cron par ligne à l'exécution, et rien n'enregistre le dernier passage d'une campagne. Un ticket qui demande l'impossible n'est pas Prêt. → créé `S1-09` |
| `S1-02` | 🟡 **Prêt sous condition** | Deux manques réels : (1) le critère « le vocabulaire d'effectif est confirmé contre la documentation » est une **tâche, pas un critère vérifiable** ; (2) `campaigns.effectif_min` (entier) face au filtre codé de l'API n'était traité nulle part. → critères reformulés + `D-007` |
| `S1-03` | ✅ **Prêt** | Rien à signaler. Tous les critères sont observables en base. |
| `S1-04` | 🟡 **Prêt sous condition** | Le test « NAF invalide » est **devenu impossible** : depuis `S1-05`, la base refuse d'enregistrer une campagne au mauvais format. Le ticket demandait de tester par une porte qu'on a fermée exprès. → méthode de test remplacée |
| `S1-05` | ✅ Déjà fait | En review. **Note du planning** : il annonçait que la revue dépendait de `S0-05` — c'est périmé, le dépôt existe et la PR #1 est ouverte. Seule la relecture manque. |
| `S1-06` | ✅ **Prêt** | Portée réduite par D-003, plus aucune dépendance externe. Testable en provoquant une erreur. |
| `S1-07` | ❌ **Refusé** | Voir « Ce qui est refusé » ci-dessous. |
| `S1-08` | 🟡 **Prêt sous condition** | Un critère **ne peut pas échouer** (« `details` est du JSONB exploitable ») : le type de colonne le garantit, donc le test ne prouve rien. → critère remplacé par une lecture réelle des compteurs |
| `S1-09` | 🟡 **Prêt sous condition** | Créé par ce planning. Condition : **une décision d'architecture** doit être consignée avant l'implémentation (comment calculer l'échéance d'une campagne sans écrire un analyseur de cron). Décision d'Architecte, ~20 min, **ne dépend pas de l'humain**. |

#### Corrections apportées aux tickets par le PO

Un ticket rendu « Prêt sous condition » est corrigé dans ce fichier, pas laissé en l'état :

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

### S0-04 — Projet Supabase « dev » + clés ⬜

**Objectif** : disposer d'une base réelle pour appliquer les migrations et brancher n8n.

**Contexte** : ADR 0001 (Supabase) · cahier des charges §6.4 (environnements).
**Action humaine obligatoire** : le projet existe déjà, mais il reste à remplir `.env` et à appliquer
les migrations — un agent n'a ni les clés ni l'accès DDL. Aucun agent ne peut se substituer à toi ici.

**Critères d'acceptation**
- [ ] Projet Supabase `prospection-dev` créé, région **`eu-west-3`** (proche des cibles françaises)
- [ ] Les 6 tables existent (migration S0-02 appliquée via l'éditeur SQL ou `supabase db push`)
- [ ] `supabase/tests/rls.sql` passe **sur le vrai projet** (pas seulement sur Postgres local)
- [ ] `.env` renseigné : `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`
- [ ] Un accès avec la clé `anon` ne lit **rien** (vérification à la main, pas seulement par le test)
- [ ] Aucune de ces clés n'apparaît dans `git status`

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

### S1-01 — WF1 squelette : cron, campagnes actives, log `runs` ⬜

**Objectif** : WF1 existe, s'exécute à vide sans écrire de données métier, et journalise son passage.

**Contexte** : cahier des charges §7.2 (WF1), §4 (observabilité).

**Critères d'acceptation**
- [ ] Le déclencheur est à **cadence fixe** (documentée dans le workflow) ; WF1 décide **ensuite**,
      campagne par campagne, si elle est due — la règle exacte vient de `S1-09` (correction du planning :
      « un cron par campagne lu à l'exécution » n'est pas implémentable dans n8n)
- [ ] Lecture des campagnes avec `active = true` ; une campagne inactive n'est **jamais** traitée
- [ ] Une ligne `runs` est créée au démarrage (`status = 'running'`), puis passée à `success`
      ou `error` avec `finished_at` renseigné
- [ ] Une exécution sans campagne active se termine en `success` avec `items_processed = 0`
      (pas d'erreur : ce n'est pas un échec)
- [ ] Le workflow est **exporté** dans `n8n/workflows/wf1-collecte.json` et importé avec succès
- [ ] Aucun secret dans le JSON exporté (credentials référencés par nom)

**Preuve attendue** : sortie de l'import + exécution n8n, et la ligne correspondante dans `runs`.

**Périmètre** : `n8n/workflows/` — **interdit** : `supabase/migrations/`, `apps/`
**Dépendances** : `S1-09` (schéma), `S0-04` (vérification finale) · **Taille** : M · **Rôle** : Automation

---

### S1-02 — WF1 : API Recherche d'entreprises (pagination + ciblage) ⬜

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
- [ ] Une campagne = un appel par couple (code NAF × département), avec pagination jusqu'à épuisement
- [ ] Le workflow **vérifie** que les résultats renvoyés portent bien le code NAF demandé et le bon
      `etat_administratif` (défense contre l'ignorance silencieuse des paramètres)
- [ ] **Règle ADR 0005** : seules les unités légales dont `siege.departement` est dans
      `campaigns.departements` sont conservées ; les autres sont **comptées comme écartées**
- [ ] L'adresse stockée est celle du **siège** (`siege.adresse`, `siege.code_postal`, `siege.libelle_commune`)
- [ ] `tranche_effectif_salarie` : le vocabulaire de codes retenu est **écrit dans cette section**
      avec la requête qui l'a prouvé (correction du planning : « confirmer contre la doc » est une
      tâche, pas un critère — et un code observé dans une réponse n'est pas forcément un code accepté
      en filtre)
- [ ] **Filtre d'effectif conditionnel (`D-007`)** : le filtre n'est appliqué que si le code est
      confirmé ; sinon la campagne est collectée **sans** ce filtre et l'écart est tracé dans
      `runs.details`. Un filtre non vérifié ne doit pas bloquer une collecte
- [ ] Aucun appel si une campagne n'a ni `naf_codes` ni `departements` (validation d'entrée)
- [ ] Le JSON brut de chaque entreprise est conservé dans `companies.raw`

**Périmètre** : `n8n/workflows/wf1-collecte.json` · **Dépendances** : S0-04, **ADR 0005 validé**
**Taille** : M · **Rôle** : Automation

---

### S1-03 — WF1 : upsert `companies` par SIREN (dédoublonnage) ⬜

**Objectif** : relancer WF1 deux fois ne duplique rien et n'écrase pas les données enrichies.

**Contexte** : RF-05 · critère d'acceptation v1 « alimente `companies` sans doublon ».

**Critères d'acceptation**
- [ ] Upsert sur la clé primaire `siren` (jamais d'insertion en doublon)
- [ ] Un second passage sur la même campagne ne change **pas** le nombre de lignes
- [ ] Les champs déjà enrichis (`website`, `email`, `website_source`) ne sont **pas** écrasés par `null`
      lors d'un re-passage (piège classique de l'upsert : un `null` qui écrase une valeur trouvée)
- [ ] `updated_at` est bien actualisé à l'écriture
- [ ] Les entreprises récupérées hors zone (ADR 0005) ne sont pas insérées

**Périmètre** : `n8n/workflows/wf1-collecte.json` · **Dépendances** : S1-01
**Taille** : M · **Rôle** : Automation

---

### S1-04 — WF1 : politesse de crawl et robustesse ⬜

**Objectif** : WF1 ne se fait pas bannir, ne bloque pas la nuit sur une erreur, et reprend après un échec réseau.

**Contexte** : cahier des charges §4 (fiabilité, politesse du crawl), §7.2 (bonnes pratiques n8n), risque R2.

**Critères d'acceptation**
- [ ] Lots de 10 à 25 éléments (*Split in Batches*), jamais un appel par élément
- [ ] Nœud *Wait* entre les appels : **max 1 requête/s** ; timeout **10 s** par appel
- [ ] *Retry on Fail* ×3 avec délai croissant sur les appels réseau
- [ ] `Continue on Fail` : **un élément en erreur ne bloque pas le lot**
- [ ] User-Agent identifiable mentionnant le projet (pas d'User-Agent de navigateur usurpé)
- [ ] Fin d'exécution : `runs.status = 'partial'` si des éléments ont échoué, `'success'` sinon
- [ ] **Test d'erreur réseau** : un endpoint d'API volontairement faux produit `partial` ou `error`
      avec un message exploitable, et **pas** un plantage silencieux
- [ ] **Test de réponse vide** : un département inexistant ne doit **pas** produire d'erreur
      (réponse vide = cas nominal, à ne pas confondre avec une panne)
- [ ] ~~Test par campagne au NAF invalide~~ : **impossible depuis `S1-05`**, la base refuse
      d'enregistrer une telle campagne. Remplacé par les deux tests ci-dessus

**Preuve attendue** : exécution réelle sur un lot réduit (≤ 25), avec la ligne `runs` à l'appui.

**Périmètre** : `n8n/workflows/wf1-collecte.json` · **Dépendances** : S1-02
**Taille** : M · **Rôle** : Automation

---

### S1-05 — Garde-fou de format des codes NAF 🟦 en review

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

**Historique de la branche** : `feat/s1-05-garde-fou-naf` (commit non fusionné).

**Reste à faire avant `fait`** (DoD) : revue par un agent **Reviewer** en contexte neuf, et validation PO.

> **Note du planning (2026-10-15)** : ce ticket annonçait que ces deux étapes dépendaient de `S0-05`.
> C'est **périmé** : le dépôt existe, la protection est active et la PR #1 est ouverte. Il ne manque
> que la relecture. C'est le seul ticket du sprint dont l'avancement n'attend rien d'autre qu'un agent.

**Périmètre** : `supabase/migrations/`, `supabase/tests/` · **Dépendances** : aucune
**Taille** : S · **Rôle** : Backend/Data

---

### S1-06 — WF5 : workflow d'erreurs + notification d'échec ⬜

**Objectif** : un workflow qui échoue le dit, au lieu de rester silencieux toute la nuit.

**Contexte** : cahier des charges §4 (observabilité), §7.2 (WF5), risque R7.

**Portée réduite par D-003 (2026-10-15)** : la trace en base est **obligatoire**, la notification
Telegram est un **plus non bloquant**. Le ticket ne dépend donc plus de `S0-06`.

**Critères d'acceptation**
- [ ] WF5 déclenché par un *Error Trigger* n8n
- [ ] `runs.status = 'error'` écrit avec le message dans `runs.error` — **c'est le cœur du ticket**
- [ ] Testé en provoquant volontairement une erreur dans WF1 (preuve collée dans la PR)
- [ ] Une notification en échec **ne relance pas** WF5 en boucle
- [ ] *(facultatif, seulement si `S0-06` est fait)* notification Telegram contenant le nom du
      workflow, l'heure et le message d'erreur

**Périmètre** : `n8n/workflows/wf5-erreurs.json` · **Dépendances** : aucune
**Taille** : S · **Rôle** : Automation

---

### S1-07 — Documentation d'exploitation de WF1 ⬜

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

---

### S1-08 — `runs.details` : distinguer récupérées / écartées / écrites (**D-002**) ⬜

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
      (correction du planning : « c'est bien du JSONB » ne peut pas échouer, le type de colonne le
      garantit — donc ce critère ne prouvait rien)
- [ ] Le fichier de test ne laisse aucune ligne derrière lui (`begin; … rollback;`) et la CI passe

**Pourquoi maintenant** : le taux de rejet est la seule métrique qui dit si une campagne est trop
large (seuil d'alerte : > 60 %, brief PO §5). Sans lui, aucun calibrage n'est possible — et D-001
prévoit un arrêt de la collecte à 100 analyses si les faux positifs dépassent 30 %.

**Périmètre** : `supabase/migrations/`, `supabase/tests/` — **interdit** : `n8n/`, `apps/`
**Dépendances** : aucune · **Taille** : S · **Rôle** : Backend/Data

---

### S1-09 — Rendre la fréquence par campagne implémentable (créé au planning) ⬜

**Objectif** : pouvoir décider, campagne par campagne, si elle est due — sans quoi RF-03 reste une
case cochée sur le papier.

**Contexte** : RF-03 (fréquence d'exécution par campagne) · **constat du planning du 2026-10-15** en
validant la DoR de `S1-01` : `campaigns.cron` existe, mais **rien n'enregistre le dernier passage**.
Un workflow ne peut donc pas savoir si une campagne est due. Le ticket `S1-01` demandait
« un cron défini par campagne, pas en dur » : ce n'est pas implémentable dans n8n, où le cron est une
propriété du nœud de déclenchement, pas une valeur lue en base à l'exécution.

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
| `S0-04` — clés Supabase absentes, migrations non appliquées | Aucun ticket S1 ne peut être **vérifié** : la DoD exige une exécution réelle | Coller les 2 migrations dans l'éditeur SQL + remplir `.env` (~10 min) | **Humain** (identifiants) |
| `S0-05` — board Projects absent | **Aucun impact sur le sprint** : D-005 a tranché, le tableau versionné est la source de vérité | `gh auth refresh -s project,read:project` | **Humain** (scope du jeton) |
| `S0-06` — bot Telegram | Ne bloque plus rien (D-003) ; requis seulement pour WF4 (S4) et la notification de WF5 | Créer le bot | **Humain** (compte externe) |
| PR #1 non relue | `S1-05` reste `en review`, pas `fait` : la DoD exige une relecture en contexte neuf | Lancer une session `Reviewer` | **Agent** (`prompts/roles.md` §7) |
| Décision d'architecture pour `S1-09` | Le ticket ne démarre pas sans elle (condition du planning) | Trancher entre durée explicite / dernier passage lisible / les deux | **Agent** (Architecte, ~20 min) |

*Blocages levés : `ADR 0005` (décision du 2026-10-15) · `S0-05` dépôt, CI et protection — faits
et **testés** (push direct et merge anticipé refusés par GitHub).*

## 5. Métriques à relever en review (vendredi 23/10)

| Indicateur | Objectif | Valeur relevée |
|---|---|---|
| Vélocité (tickets terminés) | stable ou croissante | — |
| Lead time (`Prêt` → `Fait`) | < 2 jours | — |
| Taux de PR refusées par le Reviewer | décroissant | — |
| Échecs de CI | < 20 % | — |
| Bugs échappés en production | 0 critique | — |

## 6. Fin de sprint — questions à trancher en rétro

1. `ADR 0005` a-t-il évité des faux positifs, ou surestimé le problème ?
2. La limite WIP de 2 a-t-elle réellement été respectée ? Si non, pourquoi ?
3. Quelles erreurs se sont répétées ? → à ajouter dans `AGENTS.md` §10 (pièges connus).
4. Le découpage de WF1 en 4 tickets (S1-01..S1-04) était-il le bon grain, ou trop fin ?

---

## 7. Reporté aux sprints suivants (à ne pas perdre)

Ces points ne sont pas des tickets de ce sprint : ils appartiennent à un sprint dont le backlog
n'est pas encore écrit. Ils sont listés ici pour ne pas disparaître entre deux sprints.

| Élément | Sprint | Pourquoi c'est noté |
|---|---|---|
| Supprimer le garde-fou `node` de `.github/workflows/ci.yml` | S5 | Tant qu'il est là, une CI « verte » ne prouve que le SQL : le job `node` s'annonce ignoré au lieu de vérifier quoi que ce soit |
| Écrire l'ADR hébergement front (Vercel Hobby non commercial, risque R4) | S7 | Décision à trancher **avant** la mise en production, pas après |
| **`S1-07` refusé du sprint 1** — Documentation d'exploitation de WF1 | dès 1 collecte réelle | Condition de retour **explicite** (planning 2026-10-15) : on documente une procédure qui a tourné au moins une fois, sinon elle sera réécrite au premier incident |
| Réévaluer la visibilité du dépôt dès qu'une donnée d'entreprise réelle entre dans le pipeline | fin S1 | Point de révision explicite de **D-004** : le dépôt est public, aucune donnée d'entreprise ne peut y entrer |
| Protocole de calibrage de la grille (30 fiches relues à la main) | S3 | Point de déclenchement de **D-001** : à 100 analyses réelles, avant toute nouvelle collecte |

*(Le sens de `runs.items_processed` a été tranché par **D-002** : ce n'est plus un report, c'est le
ticket **S1-08**.)*
