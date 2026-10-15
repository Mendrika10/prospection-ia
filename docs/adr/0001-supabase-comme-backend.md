# ADR 0001 — Supabase comme backend unique (Postgres + RLS + Auth + PostgREST)

- Statut : accepté
- Date : 2026-10-15
- Décideur : Product Owner
- Rôle auteur : Architecte

## Contexte

Le projet a besoin de : un stockage relationnel (entreprises, analyses, leads), une
authentification simple (1 utilisateur), une API lisible depuis un dashboard Next.js, et
une sécurité par ligne qui survive à un client navigateur — le tout avec **0 € de coût récurrent**
(contrainte principale du cahier des charges).

Le dashboard parle directement au backend depuis le navigateur : il faut donc que la
sécurité soit **dans la base** (RLS), pas seulement dans une couche applicative.

## Décision

Supabase, en offre gratuite, comme backend unique : Postgres + Row Level Security +
Auth + API PostgREST. Trois rôles structurent l'accès :

| Rôle | Usage | RLS |
|---|---|---|
| `anon` | clé publique exposée au navigateur | **aucune policy → aucun accès** |
| `authenticated` | moi, dans le dashboard | lecture totale, écriture du pipeline |
| `service_role` | n8n uniquement | contournée (privilège complet) |

## Alternatives écartées

- **Postgres managé seul** (Neon, Aiven, Crunchy Bridge, Tiger Cloud) : excellents pour le
  Postgres, mais il faudrait réécrire à la main l'authentification, les policies exposées
  côté API et la couche d'accès — c'est-à-dire reconstruire Supabase.
- **Firebase** : NoSQL, pas de SQL pour les agrégations du dashboard, et RLS/`join` peu adaptés
  au modèle `companies → analyses → leads`.
- **Postgres auto-hébergé sur le VPS** : une base à sauvegarder et à sécuriser soi-même ;
  le VPS arrive déjà à S7 pour n8n, on ne cumule pas les risques le même jour.
- **Backend applicatif « maison »** entre le front et la base : du code à écrire, tester et
  maintenir pour un seul utilisateur.

## Conséquences

- **À surveiller** : offre gratuite = 500 Mo et mise en pause après ~1 semaine d'inactivité.
  Un cron régulier (WF1) évite la pause ; c'est aussi le risque R3 du cahier des charges.
- La clé `anon` peut vivre dans le navigateur **à condition** que la RLS soit réellement
  correcte : d'où le test `supabase/tests/rls.sql` qui vérifie que `anon` ne lit rien.
- La clé `service_role` devient le secret le plus sensible du projet : credentials n8n
  exclusivement (voir `AGENTS.md` §7).
- Le dashboard dépend du contrat d'API PostgREST (noms de tables/colonnes) : toute migration
  fait partie du périmètre front.
- La conformité des CGU Vercel Hobby (usage non commercial) reste un sujet séparé : ADR à
  écrire avant la mise en production (risque R4).
