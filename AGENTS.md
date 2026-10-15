# Conventions du projet — prospection-ia

> **Contexte partagé de l'équipe** (humains + agents). Tout agent lit ce fichier avant de produire
> quoi que ce soit. Mis à jour à chaque rétrospective (section 10) et à chaque erreur répétée.
>
> Lecture obligatoire associée : [`docs/cahier-des-charges.md`](docs/cahier-des-charges.md) (le quoi),
> [`docs/methode-equipe-agents.md`](docs/methode-equipe-agents.md) (le comment),
> [`docs/sprint-01.md`](docs/sprint-01.md) (le ticket en cours).

---

## 0. Organisation : qui décide quoi

Le **Product Owner est un agent**, pas le propriétaire du projet (décision D-000). Son brief :
[`docs/prompts/product-owner.md`](docs/prompts/product-owner.md). Ses décisions :
[`docs/product-decisions.md`](docs/product-decisions.md).

| Sujet | Décide | Où c'est écrit |
|---|---|---|
| Priorités, périmètre, seuils, ordre des tickets, critères d'arrêt | **Agent Product Owner** | `docs/product-decisions.md` |
| Décisions techniques (modèle de données, contrats, outillage) | **Agent Architecte**, validées par le PO | `docs/adr/` |
| Conformité au ticket et qualité du code | **Agent Reviewer** (contexte neuf) + CI | la PR |
| Fournir un identifiant ou une clé, dépenser de l'argent, agir hors du dépôt (compte externe, publication, production), supprimer des données | **Propriétaire humain** — un agent n'en a pas les moyens | ticket + `docs/daily.md` |

Trois règles qui en découlent :

1. **Un agent ne valide jamais son propre travail** : implémentation et relecture sont deux sessions.
2. **L'agent PO n'écrit aucun code** : il décide, priorise, et écrit ses motifs.
3. **Un blocage ne se lève qu'en nommant qui peut le lever** — un agent pour le travail, un humain
   pour l'un des quatre sujets ci-dessus.

---

## 1. Langue et style

- Code (identifiants, fichiers, branches) : **anglais**. Commentaires, docs, tickets, commits : **français**.
- TypeScript `strict`, ESLint + Prettier, **pas de `any`**.
- SQL en minuscules, une instruction par ligne, commentaires en français.
- Un fichier = une responsabilité ; pas de fichier > ~300 lignes sans raison.

## 2. Stack et versions

| Brique | Choix | Remarque |
|---|---|---|
| Runtime | **Node 24 LTS** (pnpm) | Aligné sur le poste de dev (`node -v` → v24.x) |
| Front | Next.js App Router + TypeScript + Tailwind | Sprint S5 |
| Base | Supabase Postgres (RLS + Auth + PostgREST) | ADR 0001 |
| Orchestration | n8n édition communautaire (Docker) | ADR 0002 |
| CI | GitHub Actions | `.github/workflows/ci.yml` |

Le gestionnaire de paquets est **pnpm**, pas npm ni yarn. `packageManager` doit être déclaré
dans le `package.json` racine dès qu'il existe (requis par `pnpm/action-setup` en CI).

## 3. Commits et branches

- Commits conventionnels : `feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`.
- Trunk-based : branches courtes `feat/<ticket>-<slug>`, **vie < 1 jour**.
- `main` est **protégée, et ce n'est pas qu'une convention** : push direct refusé, merge impossible
  sans les 3 checks verts (`sql`, `secrets`, `node`), force-push et suppression interdits.
  **Toute modification passe donc par une branche + une PR.** Vérifié le 2026-10-15 par une tentative
  de push direct rejetée par GitHub (`GH006 … 3 of 3 required status checks are expected`).
  Pourquoi c'est possible : le dépôt est **public** — GitHub refuse la protection sur un dépôt privé
  en offre gratuite (voir §10).
- PR < **300 lignes** ; au-delà, on découpe le ticket.
- **Un ticket = une branche = un agent.** Jamais deux agents sur les mêmes fichiers.

## 4. Base de données

- Une migration = un fichier daté `supabase/migrations/AAAAMMJJHHMMSS_<slug>.sql`.
- **Jamais de modification d'une migration déjà appliquée** → nouvelle migration à la place.
- **RLS activée sur toute table créée**, et **aucune policy pour `anon`** (exigence du cahier des charges §4).
- La clé `service_role` est réservée à n8n : elle ne sort **jamais** des credentials n8n,
  jamais dans le dashboard, jamais dans Git, jamais dans un prompt.
- Tout changement de schéma vient avec un test rejouable dans `supabase/tests/`
  (modèle : [`supabase/tests/rls.sql`](supabase/tests/rls.sql)).
- Les scripts de test sortent en **code ≠ 0** en cas d'échec (sinon ils ne servent à rien en CI).

## 5. n8n

- Un workflow = un fichier exporté `n8n/workflows/wfN-<slug>.json`, versionné.
- Aucun secret dans le JSON : les credentials sont référencés par `id`/`name`, jamais par valeur.
- Bonnes pratiques obligatoires : *Split in Batches* 10-25, nœud *Wait* entre requêtes,
  *Retry on Fail* ×3 à délai croissant, `Continue on Fail` sur l'analyse de site.
- Chaque exécution écrit une ligne dans `runs` (`running` → `success` | `partial` | `error`).
- Politesse du crawl : max **1 req/s par domaine**, timeout **10 s**, respect de `robots.txt`,
  User-Agent identifiable. On ne contourne jamais un blocage anti-bot (risque R6).

## 6. Tests et vérifications

- **Tests d'abord**, ou au minimum en même temps que le code.
- Front : Vitest. SQL : `supabase/tests/*.sql`.
- Avant toute PR, l'équivalent local de la CI :
  ```bash
  psql -v ON_ERROR_STOP=1 -f supabase/tests/rls.sql   # schéma + sécurité
  pnpm lint && pnpm typecheck && pnpm test            # dès que le projet Node existe (S5)
  ```
- **Interdit** de faire passer un check en le désactivant (`test.skip`, assertion affaiblie,
  `any`, `eslint-disable`, `|| true`) sans justification écrite dans la PR. Un check qui échoue
  se corrige ou se signale, il ne se contourne pas.
- **Vérifier, ne pas croire** : un rapport de tâche contient la commande lancée et sa sortie.

## 7. Sécurité et RGPD

- Aucun secret dans Git, ni dans un ticket, ni dans un prompt d'agent.
  `.env` (ignoré par Git) + `.env.example` documentaire.
- Données limitées aux entreprises et emails professionnels.
- `blocklist` est consultée avant toute notification ou contact.
- Le job CI `secrets` refuse un JWT ou une clé privée commitée.

## 8. Règles de travail par ticket

1. Le **périmètre du ticket est verrouillé** : les dossiers autorisés sont listés dans le ticket.
   Tout le reste est interdit — même si « c'était évident ».
2. Si une information manque : **poser la question** plutôt que deviner.
3. Fin de tâche = **résumé écrit** : fichiers modifiés, commandes lancées + résultat, points d'attention.
4. **Décisions irréversibles = validation humaine** : migration destructrice, suppression de données,
   gestion de secrets, déploiement en production, création de compte externe. À l'inverse, une
   décision **produit** qui engage la suite est prise par l'agent PO — à condition qu'elle soit écrite
   dans le journal avec l'hypothèse assumée et le point de révision (`docs/product-decisions.md`).
5. Le **Reviewer** travaille avec un contexte neuf : il ne voit que la PR et les critères
   d'acceptation, pas l'historique de l'implémentation.

## 9. État actuel de la CI (à lire avant de conclure « c'est vert »)

| Job | Statut | Sens |
|---|---|---|
| `sql` | **actif** | Applique les migrations sur un Postgres neuf, joue `supabase/tests/rls.sql` |
| `secrets` | **actif** | Refuse tout JWT / clé privée commité |
| `node` | **auto-désactivé** | Aucun projet Node avant S5 : le job le **signale** (notice) au lieu de faire semblant de passer. À supprimer dès que `apps/dashboard/package.json` existe — suivi dans `docs/sprint-01.md` §7 |

Une CI verte aujourd'hui ne prouve donc **que** le SQL. Ne pas présenter un « CI verte »
comme une preuve que le produit fonctionne.

## 10. Pièges connus (mis à jour en rétro)

- **`service_role` n'a aucun privilège par défaut** sur une table créée : sans `grant all`
  explicite, n8n ne peut rien écrire même si la RLS est contournée. C'est arrivé sur la migration initiale.
- **`now()` est constant dans une transaction** : tester `updated_at = now()` juste après un
  `insert` ne prouve rien (les deux colonnes ont la même valeur). Pour tester un trigger
  `updated_at`, forcer une date passée et vérifier qu'elle est réécrite.
- **`N8N_BASIC_AUTH_ACTIVE/USER/PASSWORD` n'existent plus** (supprimés depuis n8n 1.0) :
  au premier démarrage, n8n crée son **compte propriétaire** dans l'UI. Ne pas les remettre
  dans `docker-compose.yml` ni dans `.env.example`.
- **Postgres « nu » n'a pas les rôles `anon` / `authenticated` / `service_role`** : ils viennent
  de Supabase. Hors Supabase, les créer via `.github/sql/roles.sql` avant de jouer les migrations.
- **Vercel Hobby est réservé à l'usage non commercial** (risque R4 du cahier des charges) :
  à trancher avant toute mise en production, pas après.
- **La protection de branche suppose un dépôt public (ou payant).** Vérifié le 2026-10-15 sur
  `Mendrika10/prospection-ia` : en **privé** + offre gratuite, `PUT /branches/main/protection` **et**
  `POST /rulesets` renvoient tous deux **403 « Upgrade to GitHub Pro or make this repository
  public »**. Le dépôt a donc été passé **public** pour obtenir le verrou. Conséquence à assumer :
  tout ce qui entre dans le dépôt est public — aucune donnée d'entreprise, aucun secret, aucun
  export contenant des identifiants. Vérifier avant de commiter, pas après.
- **« Repository has been locked » (403) juste après un changement de visibilité** : erreur
  **transitoire** de propagation chez GitHub. Réessayer 30 s plus tard suffit — ne pas conclure
  trop vite à un blocage définitif.
- **`$?` après un pipe ne vaut rien** : dans `commande | tail`, `$?` renvoie le code de `tail`.
  Un « EXIT=0 » obtenu ainsi ne prouve pas que la commande testée a réussi. Utiliser
  `${PIPESTATUS[0]}`, ou comparer un état observable (hash, compteur de lignes).
- **`grep -c` renvoie 1 quand le compte est zéro** — et casse silencieusement une chaîne `&&`.
  Rencontré le 2026-10-15 : `fails=$(gh pr checks 5 | grep -c ...) && gh pr merge ...` n'a jamais
  exécuté le merge (0 correspondance → exit 1 → court-circuit), **sans le moindre message d'erreur**.
  La PR est restée ouverte alors que le script semblait avoir tout enchaîné. Utiliser un `if`
  explicite, ou `grep -c ... || true`.
- **Pour gatier un merge, compter n'est pas la bonne méthode** : `gh pr checks <n> --watch` renvoie
  **0 si tous les checks sont verts** et non zéro sinon. C'est le garde-fou à utiliser, vérifié le
  2026-10-15 — un comptage de chaînes peut se tromper d'une ligne et laisser passer un merge rouge.
- **API Recherche d'entreprises (`recherche-entreprises.api.gouv.fr`)** — contrat vérifié le 2026-10-15,
  ces quatre pièges coûtent une demi-journée chacun si on les découvre en production :
  1. Le filtre d'activité est **`activite_principale`**, pas `code_naf`. Un **nom de paramètre inconnu
     est ignoré silencieusement** (HTTP 200, résultats non filtrés) : toujours vérifier que la réponse
     ne contient bien que les codes visés, jamais se fier au code HTTP.
  2. Format **pointé obligatoire** : `43.21A` fonctionne, `4321A` renvoie **HTTP 400**.
     Les codes stockés dans `campaigns.naf_codes` sont donc au format APE pointé.
  3. `per_page` est plafonné à **25** (au-delà : HTTP 400). La pagination, elle, va au-delà de
     1 000 résultats (`page=40` avec `per_page=25` répond normalement).
  4. `departement` / `code_postal` / `code_commune` filtrent sur les **établissements**, pas sur le
     siège : sur une page de 25 résultats pour le 974, seuls **12 avaient leur siège dans le 974**
     (les autres sont des groupes nationaux avec une agence locale, ex. EIFFAGE basé à Mulhouse).
     Voir ADR 0005 — à trancher avant d'écrire WF1.
- **Fichiers de test SQL** : ils sont joués par la CI dans l'ordre alphabétique et partagent la même
  base. Un test ne doit pas laisser de lignes derrière lui (sinon il fausse les comptes des autres) :
  utiliser `begin; … rollback;` ou ne tester que des cas qui échouent.
