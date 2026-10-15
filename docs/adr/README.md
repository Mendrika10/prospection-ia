# ADR — Architecture Decision Records

Une décision d'architecture = un fichier, jamais modifié après coup (on en écrit un nouveau
qui remplace l'ancien). Le rôle **Architecte** les produit ; le **Product Owner** les valide.

## Format

```
# ADR NNNN — <titre à l'infinitif ou nominal>

- Statut : proposé | accepté | remplacé par ADR-NNNN
- Date : AAAA-MM-JJ
- Décideur : Product Owner
- Rôle auteur : Architecte

## Contexte
Pourquoi il faut trancher maintenant. Contraintes réelles (coût, RGPD, quotas…).

## Décision
La décision, en une ou deux phrases, à l'indicatif.

## Alternatives écartées
Option A — pourquoi non. Option B — pourquoi non.

## Conséquences
Ce que ça nous coûte, ce que ça nous interdit, ce qu'il faudra surveiller.
```

## Index

| ADR | Décision | Statut | Date |
|---|---|---|---|
| [0001](0001-supabase-comme-backend.md) | Supabase (Postgres + RLS + Auth + PostgREST) comme backend unique | accepté | 2026-10-15 |
| [0002](0002-n8n-auto-heberge-docker.md) | n8n édition communautaire auto-hébergée (Docker) comme orchestrateur | accepté | 2026-10-15 |
| [0003](0003-depot-unique.md) | Dépôt unique (monorepo léger) pour base + workflows + front + docs | accepté | 2026-10-15 |
| [0004](0004-grille-de-scoring.md) | Grille de scoring pondérée, plafonnée à 10, raisons stockées en JSONB | accepté | 2026-10-15 |
| [0005](0005-ciblage-des-entreprises-locales.md) | Ciblage local : filtrer sur le siège, pas sur l'établissement | accepté (validé par le PO) | 2026-10-15 |
