# Prospection IA automatisée

Agent commercial automatisé : détecte les entreprises dont le site web est faible ou obsolète,
les note de 0 à 10, et livre les meilleurs leads dans un dashboard de suivi.

**Contrainte principale : 0 € de coût récurrent.** Stack : n8n (Docker) · Supabase ·
Next.js sur Vercel · GitHub.

📄 Cahier des charges complet : [`docs/cahier-des-charges.md`](docs/cahier-des-charges.md)

---

## Comment on travaille

Le projet est mené comme une **équipe Scrum** dont **tous les rôles sont tenus par des agents** —
y compris le Product Owner, qui arbitre les priorités, le périmètre et les seuils. Toi, tu
n'interviens que là où un agent ne peut pas : fournir un identifiant, engager de l'argent, agir
hors du dépôt. Un ticket = une branche = un agent, et rien n'est fusionné sans CI verte.

| À lire | Pour quoi |
|---|---|
| [`AGENTS.md`](AGENTS.md) | **Conventions + règles de travail + pièges connus** — contexte partagé de tout agent |
| [`docs/methode-equipe-agents.md`](docs/methode-equipe-agents.md) | La méthode : rôles, rituels, Definition of Ready / Done, CI |
| [`docs/sprint-01.md`](docs/sprint-01.md) | Le sprint en cours : cadre, rituels, tableau et **tickets** |
| [`docs/prompts/product-owner.md`](docs/prompts/product-owner.md) | **Le Product Owner (agent)** : autorité, méthode d'arbitrage, anti-patrons, format de décision |
| [`docs/product-decisions.md`](docs/product-decisions.md) | Le journal des décisions produit (D-000 à D-005) |
| [`docs/prompts/roles.md`](docs/prompts/roles.md) | Les 9 autres prompts de rôle prêts à copier |
| [`docs/adr/`](docs/adr/README.md) | Les décisions d'architecture (et celles en attente de ta décision) |
| [`docs/daily.md`](docs/daily.md) | Le daily asynchrone : fait / prévu / bloqué |

---

## Structure du dépôt

```
.
├── AGENTS.md                # conventions partagées (humains + agents)
├── apps/dashboard/          # Next.js (S5)
├── supabase/
│   ├── migrations/          # SQL versionné (schéma, RLS, index)
│   ├── tests/               # tests SQL rejouables, sortent en code ≠ 0 si échec
│   │   └── rls.sql          #   dont « anon ne lit rien » (critère d'acceptation v1)
│   └── seed.sql             # données de dev
├── n8n/
│   ├── docker-compose.yml   # n8n édition communautaire (local)
│   └── workflows/           # exports JSON wf1..wf5
├── docs/
│   ├── cahier-des-charges.md
│   ├── methode-equipe-agents.md
│   ├── sprint-01.md         # sprint en cours + tickets
│   ├── daily.md             # daily asynchrone
│   ├── adr/                 # décisions d'architecture
│   └── prompts/roles.md     # prompts de rôle
├── .github/
│   ├── workflows/ci.yml     # jobs sql · secrets · node
│   ├── sql/roles.sql        # rôles Supabase pour un Postgres nu (CI / dev local)
│   ├── ISSUE_TEMPLATE/ticket.md
│   └── PULL_REQUEST_TEMPLATE.md
├── .env.example             # jamais de vrais secrets
└── README.md
```

## Démarrage

```bash
# 1. Variables d'environnement
cp .env.example .env
openssl rand -hex 32        # -> N8N_ENCRYPTION_KEY

# 2. n8n en local (UI : http://localhost:5678)
#    Au premier démarrage, créer le compte propriétaire dans l'UI
#    (les anciennes variables N8N_BASIC_AUTH_* n'existent plus depuis n8n 1.0).
docker compose -f n8n/docker-compose.yml up -d

# 3. Base de données : appliquer la migration sur le projet Supabase
#    (soit via l'éditeur SQL du dashboard Supabase : copier supabase/migrations/*.sql)
#    soit via le CLI :
npx supabase link --project-ref <ref>
npx supabase db push

# 4. Vérifier : TOUTES les suites de supabase/tests/ (pas seulement rls.sql), chacune
#    doit afficher son « PASSENT » et sortir en code 0.
#    Rôle anon : aucun accès. service_role (n8n) : écriture. authenticated : pipeline.
for f in supabase/tests/*.sql; do psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$f"; done
```

⚠️ **Connexion à un vrai projet : mesuré le 2026-10-15, ça se paie en minutes sinon.**

- L'hôte **direct** (`db.<ref>.supabase.co`) n'est résolu qu'en **IPv6** : `supabase link` + `db push`
  peuvent donc expirer selon le réseau. Solution éprouvée : viser **le pooler** —
  `npx supabase db push --db-url "$DATABASE_URL"`.
- Le pooler **session (port 5432)** était **injoignable** depuis le réseau de dev ; c'est le pooler
  **transaction (port 6543)** qui répondait. Les scripts de `supabase/tests/` y fonctionnent : les
  `BEGIN/ROLLBACK` sont épinglés le temps de la transaction.
- `rls.sql` **n'est pas transactionnel** : il laisse quatre lignes derrière lui. À supprimer après
  vérification (les autres suites se terminent en `rollback`).

```bash

# Sans projet Supabase, on peut tout rejouer sur un Postgres jetable (c'est ce que fait la CI) :
docker run -d --name pg -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:16-alpine
psql -h localhost -U postgres -f .github/sql/roles.sql
for f in supabase/migrations/*.sql supabase/seed.sql supabase/tests/*.sql; do psql -h localhost -U postgres -v ON_ERROR_STOP=1 -f "$f"; done
```

## Modèle de données

| Table | Rôle | Écrite par |
|---|---|---|
| `campaigns` | ciblage NAF / département / seuil de score | dashboard |
| `companies` | entreprises du registre public (clé : SIREN) | n8n (WF1, WF2) |
| `analyses` | analyses techniques historisées | n8n (WF3) |
| `leads` | suivi commercial (score, raisons, statut) | n8n (WF3) + dashboard |
| `runs` | observabilité des exécutions | n8n |
| `blocklist` | liste d'opposition RGPD | dashboard / n8n |

RLS activée sur toutes les tables : `authenticated` lit tout et écrit le pipeline,
`anon` n'a **aucun** accès, n8n passe par la clé `service_role`.

## Conventions

- Commits conventionnels (`feat:`, `fix:`, `docs:`, `chore:`), branches `feat/*`, `main` protégée.
- Migrations SQL immuables une fois appliquées : toute évolution = nouveau fichier daté.
- Workflows n8n exportés en JSON à chaque modification significative (voir `n8n/workflows/README.md`).
- Aucun secret dans Git : `.env` est ignoré, `.env.example` documente les clés.

## Avancement

| Sprint | Contenu | État |
|---|---|---|
| **S0** | Dépôt Git, structure, `.env.example`, n8n Docker | 🟡 dépôt + CI en place ; comptes externes en cours (S0-04/05/06) |
| **S1** | Migrations SQL + RLS, WF1 Collecte | 🟡 SQL testé, WF1 à construire (7 tickets) |
| **S2** | WF2 Enrichissement (site + email) | ⬜ |
| **S3** | WF3 Analyse + scoring | ⬜ |
| **S4** | WF4 Digest + WF5 Erreurs | ⬜ |
| **S5** | Dashboard : login, liste, fiche, statuts | ⬜ |
| **S6** | Campagnes, runs, export CSV, réglage du scoring | ⬜ |
| **S7** | Déploiement prod (VPS + Vercel), monitoring | ⬜ |

## État des lieux externes — actions du Product Owner

Ces tickets **bloquent** le démarrage de WF1 (détail dans `docs/sprint-01.md`) :

- [x] `S0-05` Dépôt GitHub privé créé : <https://github.com/Mendrika10/prospection-ia> — la CI y tourne
- [ ] `S0-05` Board Projects + protection de `main` — **protégé impossible en privé/gratuit** (403 GitHub),
      décision du PO attendue ; le board attend le scope `project` du jeton `gh`
- [ ] `S0-04` Projet Supabase `rexnoeixlkedvdhzeoqk` : remplir `.env` et appliquer les 2 migrations
- [ ] `S0-06` Bot Telegram + clé PageSpeed Insights (gratuits, sans carte bancaire)

✅ `ADR 0005 — ciblage local` est tranché (filtrage sur le siège) ; la CI `sql` et la PR #1 sont vertes.

> Les clés Supabase (`anon`, `service_role`) se saisissent **dans `.env`, jamais dans un prompt**
> ni dans un ticket : c'est la règle `AGENTS.md` §7. `.env` est ignoré par Git (vérifié).
