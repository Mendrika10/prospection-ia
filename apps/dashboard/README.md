# Dashboard (Next.js)

Arrive au **Sprint S5**. Stack prévue (cahier des charges §7.4) :

- Next.js (App Router) + TypeScript
- Tailwind CSS
- `@supabase/ssr` (session par cookies, clé `NEXT_PUBLIC_SUPABASE_ANON_KEY` uniquement)
- TanStack Table (tri, filtres, pagination côté serveur)

## Routes à implémenter

| Route | Contenu | Sprint |
|---|---|---|
| `/login` | Authentification Supabase (RF-15) | S5 |
| `/` | KPIs : leads du jour, score moyen, répartition par statut | S5 |
| `/leads` | Tableau filtrable + tri + pagination serveur + export CSV (RF-16, RF-14) | S5/S6 |
| `/leads/[siren]` | Fiche détaillée, raisons du score, historique, notes, statut (RF-17, RF-18) | S5 |
| `/campaigns` | CRUD campagnes (RF-01 à RF-03) | S6 |
| `/runs` | Journal des exécutions et erreurs (RF-19) | S6 |

> ⚠️ La clé `SUPABASE_SERVICE_ROLE_KEY` ne doit **jamais** apparaître ici (cahier des charges §7.6).
