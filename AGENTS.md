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
- **Toute migration doit être réapplicable sans perte ni duplication.** La CI les applique
  **deux fois** — la seconde en **fin** de job `sql`, sur une base **déjà peuplée** (seed + tests +
  données témoins), le cas réel d'un projet Supabase en service. Elle compare une empreinte
  **avant/après** (nombre de lignes **et** contenu), et échoue si quoi que ce soit a bougé. D'où :
  `if not exists`, `do $$ … if not exists …`, `create or replace`, et des migrations de données
  écrites pour être rejouables (`insert … on conflict do nothing`, `update` idempotent).
  Dans le doute, rejouer les migrations en local : `bash .github/sql/apply-migrations.sh`.
- **Une empreinte ne prouve que ce qu'il y a à perdre.** Sur une table vide, une migration
  destructrice est **invisible** : mesuré — `delete from public.blocklist` passait sans être
  détecté. D'où `.github/sql/witness-data.sql`, qui insère **une ligne témoin par table** juste
  avant la mesure. Conséquence directe : **toute nouvelle table de données doit être ajoutée à la
  fois** dans `.github/sql/db-fingerprint.sql` (la liste figée) **et** dans
  `.github/sql/witness-data.sql` — sinon elle n'est couverte par aucun contrôle, et la CI restera
  verte à tort.
- **Le contrôle regarde aussi le SCHÉMA, pas seulement les données.**
  `.github/sql/schema-fingerprint.sql` inventorie les objets de `public` — colonnes (type, not null,
  défaut), contraintes, index, déclencheurs, RLS activée/forcée, policies, privilèges réels de
  `anon`/`authenticated`/`service_role`, options de vue (`security_invoker`), fonctions — et le job
  `sql` le compare **avant/après** la réapplication. Sans lui, supprimer une policy ou un `grant` ne
  changerait aucune ligne : la comparaison de données resterait verte.
- **Aucun objet de `.github/sql/schema-baseline.txt` ne doit disparaître.** C'est la **référence** des
  objets que les migrations produisent, et le **seul** contrôle qui voit une destruction **rejouée à
  l'identique** : mesuré — un `drop index … if exists` détruit dans les deux passes, donc les
  comparaisons avant/après restent vertes, la référence non. Bénéfice de bord : désactiver la RLS
  d'une table ne fait échouer aucun test actuel et ne change aucune ligne — la référence le voit.
  Une suppression **voulue** régénère la référence **dans la même PR**, sur une base neuve :
  ```bash
  bash .github/sql/apply-migrations.sh
  psql -q -tA -f .github/sql/schema-fingerprint.sql | LC_ALL=C sort > .github/sql/schema-baseline.txt
  ```
  Les **ajouts** (colonne, index, table, policy) ne demandent aucune régénération : la comparaison
  ne signale **que les disparitions**, pour ne pas transformer chaque migration additive en péage.
  Deux exceptions, apprises en les rencontrant : une ligne dont le **texte change** (un
  `privilege_defaut` modifié par `roles.sql` — voir plus haut) et les lignes d'**environnement**
  (extensions, rôles) se régénèrent elles aussi dans la même PR.
- **RLS activée sur toute table créée**, et **aucune policy pour `anon`** (exigence du cahier des charges §4).
- **Un objet neuf de `public` naît lisible par `anon`** : sur un projet Supabase, `pg_default_acl`
  accorde `ALL` à `anon`, `authenticated` et `service_role` sur les tables, fonctions et séquences de
  `public`. Tout objet créé par une migration est donc lisible **et inscriptible** par `anon` *avant*
  le moindre `revoke`. `.github/sql/roles.sql` reproduit ces privilèges par défaut — sans quoi la CI ne
  voit pas le problème : mesuré, une table et une vue neuves, sans `revoke` ni RLS, étaient lisibles par
  `anon` sur une base « comme Supabase » et **invisibles** sur une base « comme la CI »
  ([`docs/reviews/2026-10-15-pre-vol-environnement-supabase.md`](docs/reviews/2026-10-15-pre-vol-environnement-supabase.md)).
  Règle qui en découle : **toute migration qui crée une table, une vue ou une séquence dans `public`
  doit révoquer `anon` explicitement** (`revoke all on public.<objet> from anon;`) — la RLS reste la
  première barrière, pas la seule. `supabase/tests/anon_privileges.sql` vérifie la propriété sur
  **tout le catalogue** et non sur six noms connus, donc un oubli est rouge, y compris sur une table
  ajoutée par un sprint suivant. Corollaire mesuré : ces privilèges par défaut élargissent aussi ceux
  d'`authenticated` (`insert`/`update`/`delete` sur les objets qu'une migration n'a pas restreints) —
  ce qui est filtré par la RLS, mais doit être su avant d'ajouter une policy d'écriture.
- **Un changement de `roles.sql` se répercute dans la référence de schéma.** Les `alter default
  privileges` de `roles.sql` et ceux de la migration 1 sont des lignes du **même** enregistrement
  `pg_default_acl` : mesurer après ce changement modifie une ligne de
  `.github/sql/schema-baseline.txt` au lieu d'en ajouter une — et une ligne dont le texte change
  compte comme une **disparition** pour `comm`. La régénérer dans la même PR, sur une base neuve.
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
| `sql` | **actif** | Migrations sur un Postgres neuf → seed → **tous** les tests de `supabase/tests/` → **données témoins** → **réapplication des migrations**, puis **trois** comparaisons : données avant/après, schéma avant/après, et aucun objet perdu par rapport à `.github/sql/schema-baseline.txt` |
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
  5. Un paramètre de query **vide** est refusé : `tranche_effectif_salarie=` (sans valeur) renvoie
     **HTTP 422** « Au moins un paramètre … est non valide » alors qu'un nom inconnu passe en
     silence. « Nul = aucun filtre » (D-008) signifie donc **omis** le paramètre, jamais envoyé vide
     (mesuré le 2026-10-16 : 422 reproduit puis fixé).
- **Le Code node de n8n (JsTaskRunner) n'a ni `fetch` ni `node:http`** (mesuré le 2026-10-16, v 2.x) :
  toute collecte réseau passe par le **nœud HTTP Request** avec sa pagination native
  (`$pageCount + 1`), pas par du code. Un `ReferenceError: fetch is not defined` sur un tick
  WF1 = une collecte qui a tenté le réseau depuis un Code node.
- **Fichiers de test SQL** : ils sont joués par la CI dans l'ordre alphabétique et partagent la même
  base. Un test ne doit pas laisser de lignes derrière lui (sinon il fausse les comptes des autres) :
  utiliser `begin; … rollback;` ou ne tester que des cas qui échouent.
- **Copier une base SQLite vivante y compris son `-wal` peut figer la copie** (rencontré les
  15-16/10/2026 en montant l'instance jetable de WF1) : les assemblages « `db` + `wal` (+ `shm`) »
  faisaient attendre indéfiniment la lecture de `campaigns_due` côté n8n, alors que la même vue
  répondait en 1,3 s en `curl`. Pour un snapshot consistant d'une base qui tourne, c'est SQLite qui
  livre l'instantané : `VACUUM INTO 'copie.sqlite'` depuis le serveur ; retirer le `-shm` à la main
  ne suffit pas (mesuré).
- **Tuer le serveur n8n pendant une lecture fige la ligne `runs` en `running` pour toujours**
  (rencontré les 15-16/10/2026) : la clôture en `success`/`error` n'aura plus personne pour
  l'écrire — des lignes de harnais sont restées `running` après un kill de conteneur en pleine
  lecture, à clôturer à la main. Avant d'« arrêter vite » un conteneur qui exécute, attendre la
  fin de l'exécution.
- **Migration non réapplicable : CI verte sur sa branche, cassée sur `main`** (rencontré le
  16/10/2026, S1-05) : un `alter table … add constraint` nu passe le `ci.yml` **de sa branche**
  (antérieur à l'étape « Réappliquer ») et casse `main` au merge (`42710 constraint already
  exists`, reproduit en arène Postgres 16, corrigé par un garde `do $$ if not exists $$`). Toute
  migration est à éprouver sur le `ci.yml` de la **cible de fusion**, pas de sa propre branche.
- **Un `` `$'` `` dans une chaîne de substitution JavaScript injecte « le texte suivant le match »**
  (rencontré le 16/10/2026, pendant la relecture S1-05) : deux essais de mutation ainsi bâtis ont
  lu leur preuve sur un fichier différent de celui qu'on croyait muter. Pour un `$` littéral dans
  la chaîne de remplacement, écrire `$$` — et vérifier l'effet mesuré du remplacement avant de
  conclure.
- **Le nœud Supabase de n8n poste les items d'un lot en un seul POST atomique** (mesuré le
  2026-10-20, preuve S1-02 sur instance jetable) : un seul doublon → 409 pour **tout** le lot, et
  l'échec du lot ressort comme **UN** item d'erreur (avec `continueRegularOutput` comme avec
  `continueErrorOutput`). D'où l'énigme « 6 tentées → items=1 » : le compteur lisait la sortie
  d'erreur, qui contient un item **par lot**, pas par ligne. Conséquences : compter des lots en
  échec, jamais des lignes ; et un lot **mixte** (un nouveau + un doublon) échoue au complet —
  c'est exactement ce que l'upsert `on conflict (siren)` (S1-03) doit résoudre.
- **Le champ du credential n8n `supabaseApi` porte la clé dans `serviceRole`** (nom vérifié dans
  le code du nœud, version en place) : l'ancien nom `secretKey` est **ignoré en silence** — le
  credential est créé vide et chaque appel sort en 401 « No API key found in request », seulement
  lisible dans les logs du conteneur. Règle : vérifier les noms de champs du schéma de la version
  réellement déployée, jamais supposer ceux d'une version précédente (deuxième occurrence du
  « paramètre inconnu ignoré silencieusement », côté n8n cette fois).
- **Un workflow importé dans n8n doit être archivé avant suppression** : `DELETE
  /rest/workflows/<id>` renvoie 400 « Workflow must be archived before it can be deleted » ; la
  voie qui marche est `POST /rest/workflows/<id>/archive` puis `DELETE`. Un PATCH avec
  `{ isArchived: true }` renvoie 200 **sans effet** (mesuré) : ne pas conclure à l'archivage
  d'après un 200 — vérifier par le DELETE qui le prouve.
- **`pairedItem.sourceOverwrite` n'existe pas dans un item n8n** (mesuré le 2026-10-26, preuve
  `S1-04`) : le lire renvoie `undefined`. Un Code node qui en fait dépendre le contexte d'une page
  (`if (!paired.sourceOverwrite) return null`) perd **tous** ses rattachements — et un échec réseau
  complet (endpoint inexistant, délai dépassé) ressort alors en **`success` avec 0 élément**, sans
  un mot. Le rattachement se fait sur `pairedItem.item` (l'index de l'item d'entrée du nœud amont),
  et un rattachement raté doit être une **erreur**, jamais un `continue` : « je n'ai pas su
  rattacher » et « il n'y avait rien à rattacher » ne sont pas la même chose.
- **Un nœud sans arête entrante ne s'exécute jamais — et rien ne le signale** (mesuré le
  2026-10-26, preuve `S1-04`) : « Conciliation des écritures (S1-02) » a porté la logique de statut
  `partial` pendant deux tickets sans être branchée ; le contrôle passait à côté parce qu'il ne
  regardait que les nœuds branchés. À lister dans toute relecture de workflow : les nœuds **sans
  entrant** (hors déclencheurs et notes) — puis les brancher ou les supprimer.
- **Un « département inexistant » n'est pas une « réponse vide »** pour l'API Recherche
  d'entreprises (mesuré le 2026-10-26, preuve `S1-04`) : `departement=99` comme `departement=XX`
  renvoient **HTTP 400** (« Au moins un paramètre `departement` est non valide. Les valeurs
  valides : […] »). Le cas « aucune entreprise » s'éprouve avec un département **valide** × un NAF
  **valide** sans résultat : `05.10Z` × `2A` → HTTP 200, `total_results: 0`. Confondre les deux,
  c'est croire qu'on teste le silence alors qu'on teste une panne.
- **`recherche-entreprises.api.gouv.fr` résout trois adresses, et une seule répond** (mesuré le
  2026-10-26, re-mesuré le même jour : `docs/reviews/2026-10-26-mesure-rotation-api.md`, D-014) :
  `37.59.183.76` → HTTP 200 en ~0,2 s (TCP) / ~0,27 s (HTTP) ; `37.59.183.77` et `37.59.183.78` →
  **muettes au niveau TCP** (SYN sans réponse : 6 essais sur 6 en timeout à 12 s, 15,0 s à la
  première mesure). Ce ne sont donc **pas** des adresses lentes qu'un timeout plus long sauverait.
  **Correction du 2026-10-26** : la version précédente de ce piège affirmait qu'aucun client ne
  réessaie une autre adresse — c'est **faux**, mesuré par différence : `http`/`https` de Node ≥ 20
  bascule seul sur une autre adresse quand la première ne répond pas (`autoSelectFamily`, actif par
  défaut), et **8 appels sur 8** ont réussi depuis un résolveur qui rendait l'adresse **muette** en
  premier. Le vrai piège n'est donc pas le timeout : c'est que **l'API dépend d'une seule adresse
  vivante**, et que cette dépendance est **masquée** par la bascule du client. Le jour où elle tombe,
  aucun repli n'existe plus — et c'est au run de le dire (`error` + message), jamais au silence.
- **Le message d'une erreur HTTP n'a pas de forme unique dans n8n** (mesuré le 2026-10-26, preuve
  `S1-04`) : un délai dépassé porte `message` + `name` (`timeout of 10000ms exceeded`), une réponse
  en erreur porte `statusCode` + `error` et **pas** de `message` (`{statusCode: 500, error: "…"}`).
  Lire `error.message` seul affiche « erreur API » sur toutes les pannes HTTP : inexploitable, là
  où le ticket en exige un exploitable.
