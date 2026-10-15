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

## Décisions en attente

| Décision | Ticket / ADR | Qui | Quand | Statut |
|---|---|---|---|---|
| Ciblage local : filtrer sur le siège | [ADR 0005](adr/0005-ciblage-des-entreprises-locales.md) | PO | avant S1-02 | ✅ accepté le 2026-10-15 |
| Créer le dépôt GitHub privé et pousser `main` | `S0-05` | PO | dès que possible | ✅ fait le 2026-10-15 |
| Dépôt **privé sans protection** ou **public avec protection** ? | `S0-05` | PO | avant le prochain merge | ⬜ en attente |
| Scope `project` sur le jeton `gh` (board) | `S0-05` | PO | à ta convenance | ⬜ en attente |
| Remplir `.env` + appliquer les 2 migrations sur Supabase | `S0-04` | PO | bloque S1-01..S1-04 | ⬜ en attente (les clés ne doivent **pas** passer par un prompt d'agent — `AGENTS.md` §7) |
| Vercel Hobby (usage non commercial, risque R4) | ADR à écrire | PO | avant S7, mais à ne pas oublier | ⬜ |
| Nom de domaine / réputation d'envoi (v2) | hors périmètre v1 | PO | plus tard | ⬜ |
