# Workflows n8n (exports JSON versionnés)

Un fichier par workflow, exporté depuis l'UI n8n (`...` → *Download*) puis commité ici.

| Fichier | Workflow | Déclencheur | Sprint |
|---|---|---|---|
| `wf1-collecte.json` | WF1 Collecte | Cron | S1 |
| `wf2-enrichissement.json` | WF2 Enrichissement site | Cron | S2 |
| `wf3-analyse-scoring.json` | WF3 Analyse + scoring | Cron | S3 |
| `wf4-digest.json` | WF4 Digest / notification | Cron quotidien | S4 |
| `wf5-erreurs.json` | WF5 Erreurs | Error Trigger | S4 |

## Conventions

- **Export** : compléter `name`, `nodes`, `connections`, `settings`, `pinData: {}`, `versionId`, `meta`.
- **Pas de secret dans le JSON** : les credentials n8n sont référencés par `id`/`name`, jamais par valeur.
  Vérifier avant commit : `grep -iE "eyJ|service_role|token" n8n/workflows/*.json`
- **Réimport** : `docker compose exec n8n n8n import:workflow --input=/workflows/wf1-collecte.json`
- **Bonnes pratiques** (cahier des charges §7.2) : *Split in Batches* 10-25 items, nœud *Wait* entre
  requêtes, *Retry on Fail* ×3 à délai croissant, `Continue on Fail` sur l'analyse de site,
  et une entrée `runs` (status `success` | `partial` | `error`) à chaque exécution.
