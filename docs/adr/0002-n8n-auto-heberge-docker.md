# ADR 0002 — n8n édition communautaire auto-hébergée (Docker) comme orchestrateur

- Statut : accepté
- Date : 2026-10-15
- Décideur : Product Owner
- Rôle auteur : Architecte

## Contexte

Cinq workflows doivent tourner en tâche de fond, chacun avec des particularités :
pagination d'API publique, lots avec pauses pour respecter des débits, réessais ×3,
« continuer malgré l'échec » sur l'analyse des sites, et surtout **observabilité**
(savoir quel run a échoué et pourquoi). Le critère de choix est la gratuité pour un usage
interne et la possibilité de voir/relancer une exécution sans écrire un dashboard d'admin.

## Décision

n8n **édition communautaire auto-hébergée** dans Docker, comme orchestrateur des 5 workflows
(WF1 collecte, WF2 enrichissement, WF3 analyse/scoring, WF4 digest, WF5 erreurs).
Local en développement ; VPS à partir du sprint S7.

## Alternatives écartées

- **Scripts Node + cron système** : gratuits et versionnables, mais on réécrit à la main les
  réessais, la reprise sur erreur, la visualisation des runs et la relance d'un élément — soit
  précisément ce que n8n donne. Et un script qui échoue la nuit ne se voit pas.
- **GitHub Actions planifié** : gratuit pour un dépôt privé dans la limite des minutes, mais
  l'analyse de sites réels est longue (PageSpeed + crawl poli) et les jobs planifiés sont
  désactivés après 60 jours d'inactivité du dépôt. Mauvais outil pour un cron métier durable.
- **Make / Zapier / n8n Cloud** : payants au-delà d'un quota faible. Contraire à la contrainte
  « 0 € » dès que le volume dépasse la démonstration.
- **Windmill / Airflow / Prefect** : plus lourds à exploiter pour cinq workflows et un seul
  utilisateur ; le gain d'Expressivité ne compense pas l'exploitation.

## Conséquences

- **Dépendance à une machine allumée** : tant qu'on est en local, l'automatisation s'arrête si
  le poste s'éteint (risque R7). Le VPS au S7 n'est pas optionnel si l'agent doit tourner 24/7.
- Les workflows sont **exportés en JSON et versionnés** (`n8n/workflows/`) : c'est la seule
  source de vérité, l'UI n'est pas sauvegardée. Une modification non exportée est une
  modification perdue (règle dans `AGENTS.md` §5).
- Les workflows ne peuvent pas lire les variables d'environnement librement : les secrets
  Supabase passent par les **credentials n8n**, jamais par le JSON exporté.
- Le volume n8n (`n8n_data`) contient la clé de chiffrement : il est local, ignoré par Git,
  et sa perte rend les credentials illisibles. `N8N_ENCRYPTION_KEY` doit être conservée
  hors du dépôt.
