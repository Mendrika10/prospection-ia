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

## 2026-10-15 (jeudi, nuit) — le Product Owner devient un agent, et il a déjà décidé

- **Fait** : le rôle de Product Owner passe à un **agent** (décision D-000), avec un brief senior
  15+ ans : [`product-owner.md`](prompts/product-owner.md) — autorité, quatre verrous humains,
  méthode d'arbitrage, métriques et anti-métriques, 7 anti-patrons, format de décision obligatoire.
  Puis le PO agent a **exercé** le rôle au lieu de rester une étiquette : 5 décisions écrites dans
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
| Scope `project` du jeton `gh` | **Humain** | ticket `S0-05` | ⬜ non bloquant |
| `.env` Supabase + application des 2 migrations | **Humain** | ticket `S0-04` | ⛔ **bloquant** pour tout le sprint 1 |
| Vercel Hobby (usage non commercial, risque R4) | ADR à écrire | PO | avant S7, mais à ne pas oublier | ⬜ |
| Nom de domaine / réputation d'envoi (v2) | hors périmètre v1 | PO | plus tard | ⬜ |
