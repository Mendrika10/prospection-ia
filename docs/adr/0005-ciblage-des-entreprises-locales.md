# ADR 0005 — Ciblage local : filtrer sur le siège, pas sur l'établissement

- Statut : **proposé** (en attente de validation du Product Owner — décision attendue avant le ticket S1-02)
- Date : 2026-10-15
- Décideur : Product Owner
- Rôle auteur : Architecte

## Contexte

RF-01 permet de cibler une campagne par départements/villes. En vérifiant le contrat réel de
l'API Recherche d'entreprises le 2026-10-15, un comportement est apparu :

> Les filtres `departement`, `code_postal` et `code_commune` filtrent sur les **établissements**,
> pas sur le **siège** de l'unité légale. Il n'existe **aucun** paramètre « siège uniquement ».

Mesure sur `activite_principale=43.21A&departement=974&etat_administratif=A&per_page=25` :
**12 résultats sur 25 seulement avaient leur siège dans le 974.** Les 13 autres sont des groupes
nationaux ayant une agence locale — EIFFAGE ÉNERGIE SYSTÈMES (siège à Mulhouse, agence à
La Possession), SATELEC (siège dans l'Essonne, agence au Port), etc.

Conséquence produit : sans règle explicite, WF1 remplirait `companies` avec le **siège** de groupes
nationaux, et le dashboard proposerait de démarcher EIFFAGE ou La Poste pour refaire leur site.
C'est exactement le type de faux positif qui consomme du temps commercial pour rien
(risques R1 et R5 du cahier des charges), et l'adresse stockée serait géographiquement fausse.

## Décision

À valider par le PO. Recommandation de l'Architecte, en deux règles :

1. **Ne conserver que les unités légales dont `siege.departement` correspond au ciblage.**
   Le filtre serveur reste utile — il réduit le volume avant de trier — mais il ne suffit pas :
   un contrôle côté workflow est **obligatoire** avant l'écriture en base.
2. **Stocker l'adresse du siège** (`siege.adresse`, `siege.code_postal`, `siege.libelle_commune`),
   jamais l'adresse d'un `matching_etablissements`, puisque seuls les sièges sont conservés.

Critère de rejet à l'écriture : si `siege.departement` ne fait pas partie des départements de la
campagne, l'entreprise est écartée et **comptée comme écartée** dans `runs` (et non silencieusement
perdue) — sinon on ne saura jamais calibrer ce filtre.

## Alternatives écartées

- **Garder les établissements locaux des groupes nationaux** : l'adresse serait locale, mais la
  décision d'achat ne l'est pas. Un site de groupe se refait au niveau du groupe, pas de l'agence.
  Mauvais prospect, et un signal de qualité dégradé pour tout le flux.
- **Filtrer sur `nombre_etablissements`** (écarter les groupes par un seuil, ex. > 5 établissements) :
  heuristique utile en complément, mais elle écarte aussi des PME régionales légitimes et ne remplace
  pas la règle 1. À calibrer après observation, pas à décider à l'aveugle.
- **Ne rien filtrer et trier côté dashboard** : déplace le problème vers l'humain, à chaque lead,
  et alimente une base dont la moitié des adresses est fausse.
- **Utiliser `sort_by_size`** pour reléguer les gros groupes en fin de liste : allège le haut de
  liste mais ne supprime pas le problème, et les dernières pages contiennent toujours des non-locaux.

## Conséquences

- WF1 doit lire `siege.departement` et comparer aux `campaigns.departements`. **Cela conditionne le
  ticket S1-02** : la règle doit être décidée avant l'écriture du workflow, sinon il faudra le réécrire.
- Le volume de leads utiles est **divisé par ~2** sur un ciblage départemental : l'objectif O1
  (≥ 500 entreprises/semaine) se calcule donc sur des entreprises collectées, pas sur des entreprises
  conservées. À suivre dans les métriques de collecte.
- Le compteur « écartées pour cause de siège hors zone » devient un indicateur de calibrage :
  s'il est trop élevé (> 60 %), c'est que le découpage des campagnes est trop large.
- Les métriques par run (`runs.items_processed`) doivent distinguer *récupérées* / *écartées* / *écrites*.
  Cela élargit le sens du champ : à acter lors de l'écriture de WF1 (schéma `runs` inchangé pour
  l'instant, on peut détailler dans `error` ou ajouter un `raw jsonb` plus tard — nouvelle décision).
- Cette règle ne s'applique qu'au ciblage **départemental**. Si un jour un `villes` est utilisé
  (`code_commune`), la même question se pose : le filtre porte aussi sur les établissements.
