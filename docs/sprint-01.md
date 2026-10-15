# Sprint 0 & Sprint 1 — cadre, rituels et tickets

> Source de vérité du sprint en cours. Mis à jour par l'agent **Orchestrateur** (et par le PO).
> Rappels de méthode : [`methode-equipe-agents.md`](methode-equipe-agents.md) ·
> conventions : [`../AGENTS.md`](../AGENTS.md) · rôle à jouer : [`prompts/roles.md`](prompts/roles.md)

---

## 1. Cadre

| Élément | Sprint 0 | Sprint 1 |
|---|---|---|
| Dates | 2026-10-15 → 2026-10-17 (3 j) | **2026-10-19 → 2026-10-23** (lun → ven) |
| Objectif | Environnement prêt, méthode en place | **Une campagne configurée déclenche WF1 et alimente `companies` sans doublon** (1er critère d'acceptation du cahier des charges) |
| Durée | Sprints de 1 semaine | idem |
| Taille du backlog | 6 tickets | 7 tickets |
| Limite WIP | **2 tickets « En cours » maximum** | idem |
| Branches | `feat/<ticket>-<slug>`, vie < 1 jour | idem |
| Intégration | CI verte obligatoire avant merge | idem |

**Définition de « En cours »** : la limite de 2 inclut l'attente de relecture. Un ticket en Review
compte comme En cours — sinon on empile les PR ouvertes.

### Ordre de passage (Sprint 1)

1. `S0-04` (compte Supabase) — **bloque tout le reste** : c'est une action PO, à faire en premier.
2. `S1-01` → squelette WF1, qui donne une base importable et testable.
3. `S1-02` → le cœur métier (API + règle de ciblage), dépend d'`ADR 0005` **et** de `S0-04`.
4. `S1-03`, `S1-04`, `S1-05` en parallèle possible (fichiers distincts).
5. `S1-06`, `S1-07` en fin de sprint.

### Rituels du Sprint 1

| Rituel | Quand | Contenu | Qui |
|---|---|---|---|
| Sprint Planning | **lundi 19/10, 30 min** | Valider les tickets `Prêt`, confirmer l'ordre de passage | PO + Orchestrateur |
| Daily asynchrone | chaque jour, 5 min | `docs/daily.md` : fait / prévu / bloqué | Orchestrateur |
| Affinage backlog | **mercredi 21/10, 20 min** | Découper les tickets trop gros, lever `ADR 0005` | PO + Architecte |
| Sprint Review | **vendredi 23/10, 20 min** | Démo de ce qui tourne réellement (base alimentée) | PO |
| Rétrospective | **vendredi 23/10, 15 min** | 1 à garder, 1 à arrêter, 1 à essayer → mise à jour `AGENTS.md` | PO + Orchestrateur |

---

## 2. Tableau du sprint

Statuts : `⬜ à faire` · `🟡 en cours` · `🟦 en review` · `✅ fait` · `⛔ bloqué`

| ID | Ticket | Rôle | Taille | Dépend de | Statut |
|---|---|---|---|---|---|
| S0-01 | Structure du dépôt, `AGENTS.md`, CI | DevOps + Architecte | M | — | ✅ |
| S0-02 | Schéma initial + RLS + test SQL | Backend/Data | M | S0-01 | ✅ |
| S0-03 | n8n édition communautaire en Docker local | DevOps | S | S0-01 | ✅ |
| S0-04 | Projet Supabase « dev » + clés | **PO** | S | — | ⬜ |
| S0-05 | Dépôt GitHub privé + board + `main` protégée | DevOps (**validation PO**) | S | — | ⬜ |
| S0-06 | Comptes externes : bot Telegram + clé PageSpeed | **PO** | S | — | ⬜ |
| S1-01 | WF1 — squelette : cron, campagnes actives, log `runs` | Automation | M | S0-04 | ⬜ |
| S1-02 | WF1 — API Recherche d'entreprises : pagination + ciblage | Automation | M | S0-04 | ⬜ |
| S1-03 | WF1 — upsert `companies` par SIREN (dédoublonnage) | Automation | M | S1-01 | ⬜ |
| S1-04 | WF1 — politesse de crawl et robustesse | Automation | M | S1-02 | ⬜ |
| S1-05 | Garde-fou de format des codes NAF | Backend/Data | S | — | 🟦 en review |
| S1-06 | WF5 — workflow d'erreurs + notification d'échec | Automation | S | S0-06 | ⬜ |
| S1-07 | Documentation d'exploitation de WF1 | Documentation | S | S1-04 | ⬜ |

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
**Action externe : compte à créer — validation PO requise.**

**Critères d'acceptation**
- [ ] Projet Supabase `prospection-dev` créé, région **`eu-west-3`** (proche des cibles françaises)
- [ ] Les 6 tables existent (migration S0-02 appliquée via l'éditeur SQL ou `supabase db push`)
- [ ] `supabase/tests/rls.sql` passe **sur le vrai projet** (pas seulement sur Postgres local)
- [ ] `.env` renseigné : `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`
- [ ] Un accès avec la clé `anon` ne lit **rien** (vérification à la main, pas seulement par le test)
- [ ] Aucune de ces clés n'apparaît dans `git status`

**Périmètre** : `.env` (ignoré par Git) — **interdit** : commiter `.env`
**Dépendances** : aucune · **Bloque** : S1-01, S1-02, S1-03, S1-04 · **Taille** : S · **Rôle** : PO

---

### S0-05 — Dépôt GitHub privé + board + `main` protégée ⬜

**Objectif** : que le travail passe par des PR et que la CI bloque un merge rouge.

**Critères d'acceptation**
- [ ] Dépôt **privé** `prospection-ia` créé et `main` poussée
- [ ] Branche renommée `master` → **`main`**
- [ ] Board Projects avec les colonnes `Backlog → Prêt → En cours → Review → Fait`
- [ ] Les tickets de ce fichier existent comme *issues* (modèle `.github/ISSUE_TEMPLATE/ticket.md`)
- [ ] Merge dans `main` impossible avec une CI rouge
- [ ] Workflow Git documenté : `feat/<ticket>-<slug>`, commits conventionnels

**Commandes** (validation PO obligatoire — créent des ressources externes) :
```bash
gh repo create prospection-ia --private --source=. --remote=origin --push
gh project create --owner @me --title "prospection-ia"
```
Les 5 colonnes et la limite WIP se règlent dans l'UI (2 min) : `gh` n'expose pas la
suppression des options par défaut du champ `Status`.

> ⚠️ **À vérifier au moment de l'exécution** : la protection de branche avec *required status checks*
> sur un dépôt **privé** dépend du plan GitHub. Si elle n'est pas disponible, la règle reste une
> convention d'équipe (documentée dans `AGENTS.md`) au lieu d'être technique. À trancher, pas à supposer.

**Périmètre** : configuration GitHub · **Taille** : S · **Rôle** : DevOps (validation PO)

---

### S0-06 — Comptes externes : bot Telegram + clé PageSpeed ⬜

**Objectif** : les notifications (WF4) et les mesures de performance (WF3) sont possibles.

**Critères d'acceptation**
- [ ] Bot Telegram créé, `TELEGRAM_BOT_TOKEN` et `TELEGRAM_CHAT_ID` obtenus (sans carte bancaire)
- [ ] Clé PageSpeed Insights obtenue (**gratuite, sans carte bancaire** — sinon on change d'approche)
- [ ] Message de test reçu sur le chat visé depuis n8n
- [ ] Les deux secrets sont saisis dans les **credentials n8n**, pas dans un fichier du dépôt

**Périmètre** : comptes externes + credentials n8n · **Bloque** : S1-06 (WF5), S4 (WF4)
**Taille** : S · **Rôle** : PO

---

### S1-01 — WF1 squelette : cron, campagnes actives, log `runs` ⬜

**Objectif** : WF1 existe, s'exécute à vide sans écrire de données métier, et journalise son passage.

**Contexte** : cahier des charges §7.2 (WF1), §4 (observabilité).

**Critères d'acceptation**
- [ ] Workflow déclenché par un **cron** défini par campagne (`campaigns.cron`), pas en dur
- [ ] Lecture des campagnes avec `active = true` ; une campagne inactive n'est **jamais** traitée
- [ ] Une ligne `runs` est créée au démarrage (`status = 'running'`), puis passée à `success`
      ou `error` avec `finished_at` renseigné
- [ ] Une exécution sans campagne active se termine en `success` avec `items_processed = 0`
      (pas d'erreur : ce n'est pas un échec)
- [ ] Le workflow est **exporté** dans `n8n/workflows/wf1-collecte.json` et importé avec succès
- [ ] Aucun secret dans le JSON exporté (credentials référencés par nom)

**Preuve attendue** : sortie de l'import + exécution n8n, et la ligne correspondante dans `runs`.

**Périmètre** : `n8n/workflows/` — **interdit** : `supabase/migrations/`, `apps/`
**Dépendances** : S0-04 · **Taille** : M · **Rôle** : Automation

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
- [ ] `tranche_effectif_salarie` : le vocabulaire de codes accepté est **confirmé contre la
      documentation officielle** avant usage (un code observé dans une réponse n'est pas
      forcément un code accepté en filtre — à vérifier, pas à supposer)
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
- [ ] Un test avec une campagne volontairement mauvaise (NAF invalide) produit `partial` ou `error`
      avec un message exploitable, et **pas** un plantage silencieux

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
Ces deux étapes exigent le dépôt GitHub (`S0-05`) — d'où le statut « en review » et non « fait ».

**Périmètre** : `supabase/migrations/`, `supabase/tests/` · **Dépendances** : aucune
**Taille** : S · **Rôle** : Backend/Data

---

### S1-06 — WF5 : workflow d'erreurs + notification d'échec ⬜

**Objectif** : un workflow qui échoue le dit, au lieu de rester silencieux toute la nuit.

**Contexte** : cahier des charges §4 (observabilité), §7.2 (WF5), risque R7.

**Critères d'acceptation**
- [ ] WF5 déclenché par un *Error Trigger* n8n
- [ ] Notification envoyée (Telegram) contenant : nom du workflow, heure, message d'erreur
- [ ] `runs.status = 'error'` écrit avec le message dans `runs.error`
- [ ] Testé en provoquant volontairement une erreur dans WF1 (et la preuve est collée dans la PR)
- [ ] Une notification en échec **ne relance pas** WF5 en boucle

**Périmètre** : `n8n/workflows/wf5-erreurs.json` · **Dépendances** : S0-06
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

## 4. Ce qui bloque le sprint

| Blocage | Impact | Levée |
|---|---|---|
| `S0-04` Supabase non créé | Aucun ticket S1 ne peut être **vérifié** (le DoD exige une exécution réelle) | Action PO, 10 min |
| `S0-05` dépôt GitHub absent | Pas de PR, pas de CI, pas de board : la revue par un agent tiers n'existe pas. **S1-05 est bloqué en `en review` pour cette raison** | Action DevOps + validation PO |

*(Le blocage `ADR 0005` est levé : décision PO du 2026-10-15, voir `docs/adr/0005-*.md`.)*

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
| Trancher le sens de `runs.items_processed` (récupérées / écartées / écrites) | S1-04 | Conséquence d'ADR 0005 : le compteur devra distinguer les trois, sinon le filtre de ciblage n'est pas calibrable |
