# ADR 0003 — Dépôt unique (monorepo léger) pour base, workflows, front et docs

- Statut : accepté
- Date : 2026-10-15
- Décideur : Product Owner
- Rôle auteur : Architecte

## Contexte

Le produit est fait de pièces qui évoluent **ensemble** : une colonne ajoutée par une migration
n'est utile que si le workflow n8n et le dashboard la connaissent. Trois dépôts séparés
(Base / Workflows / Front) obligeraient à coordonner trois versions à chaque changement de
contrat, avec un CI et une revue par dépôt — pour un seul développeur.

## Décision

Un seul dépôt, en monorepo **léger** (pas de gestionnaire de workspace multi-paquets pour
l'instant), avec des dossiers par responsabilité :

```
supabase/     migrations + seed + tests SQL     → rôle Backend/Data
n8n/          docker-compose + workflows JSON   → rôle Automation
apps/dashboard/  Next.js                        → rôle Frontend
docs/         cahier des charges, méthode, ADR, sprints
.github/      CI, modèles de ticket et de PR
AGENTS.md     conventions partagées
```

Un seul pipeline CI pour tout, et **un ticket = un dossier** : le périmètre verrouillé du
ticket (règle anti-chaos n°2) se lit directement dans l'arborescence.

## Alternatives écartées

- **Trois dépôts séparés** : coordination de versions à la main, trois CI, trois historiques —
  coût de coordination élevé pour un développeur unique.
- **Monorepo avec workspace pnpm / Turborepo dès maintenant** : outillage utile à partir de
  plusieurs paquets partagés, inutile pour un front unique. On l'introduira si un paquet
  partagé (types générés depuis la base) apparaît réellement.
- **Tout dans le même paquet Node** : mélangerait le dashboard déployé sur Vercel et le SQL
  versionné pour Supabase ; impossible de filtrer proprement ce que déploie Vercel.

## Conséquences

- Un changement de contrat (nom de colonne, statut, format de `reasons`) touche **plusieurs
  dossiers dans la même PR** : c'est autorisé, mais le ticket doit alors lister explicitement
  ces dossiers dans son périmètre — sinon la règle anti-chaos bloque.
- La CI filtre par job, pas par dépôt : les jobs `sql` et `secrets` tournent sur toutes les PR,
  même purement front. Acceptable (quelques secondes) tant que le dépôt est petit.
- Les workflows n8n exportés vivent à côté du schéma qu'ils utilisent : la revue d'une PR peut
  vérifier la cohérence SQL ↔ JSON en un seul diff.
- Le dépôt doit rester **privé** (`.env` ignoré, mais les exports de workflows contiennent la
  logique commerciale et les endpoints internes).
