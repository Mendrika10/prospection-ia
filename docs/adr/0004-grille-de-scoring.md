# ADR 0004 — Grille de scoring pondérée, plafonnée à 10, raisons stockées en JSONB

- Statut : accepté
- Date : 2026-10-15
- Décideur : Product Owner
- Rôle auteur : Architecte

## Contexte

Le cœur du produit : décider si le site d'une entreprise mérite une proposition de refonte.
Il faut un score exploitable (tri, seuil configurable), mais surtout un score **explicable** :
c'est l'explication qui sert à personnaliser l'approche commerciale, et c'est elle qui permet
de calibrer la grille après quelques dizaines de résultats réels.

Contraintes : les indicateurs disponibles varient (un site peut être inaccessible, bloqué,
sans PageSpeed), et certains sont mesurables de plusieurs façons (HTTPS, responsive, ancienneté).

## Décision

Score **0-10 additif et plafonné**, calculé sur des critères indépendants mesurables, chaque
critère déclenché ajoutant une **raison lisible** dans `leads.reasons` (JSONB) :

| Critère | Points | Détection |
|---|---|---|
| Aucun site trouvé | +4 | `website is null` après WF2 |
| Site inaccessible (4xx/5xx/timeout) | +4 | `http_status` |
| Pas de HTTPS | +2 | URL / redirection |
| Pas de balise `viewport` (non responsive) | +3 | HTML |
| Score PageSpeed mobile < 50 (`< 30` : +3) | +2 | API PSI |
| Copyright de plus de 3 ans | +1 | regex pied de page |
| Technologie datée (jQuery ancien, Flash, tables) | +1 | indices HTML |

Le score est **plafonné à 10** : un site cumulant sept défauts n'est pas « deux fois pire »
qu'un autre. Le seuil de livraison (`campaigns.score_threshold`, défaut 7) est **par campagne**,
donc modifiable sans redéploiement.

## Alternatives écartées

- **Score PageSpeed seul** : la métrique la plus objective, mais aveugle au cas le plus rentable
  (« pas de site du tout ») et instable dans le temps. Gardée comme un critère parmi d'autres.
- **LLM qui note le site** : coût par lead, non déterministe, impossible à reproduire en cas de
  contestation, et aucune dépendance payante n'est admissible en v1. Réservé à la rédaction de
  messages en v2 (avec validation humaine).
- **Score pondéré multiplicatif ou normalisé sur une échelle 0-100** : plus fin, mais le plafond
  et l'échelle 0-10 se lisent directement dans le dashboard et dans un message commercial.
- **Rejeter un lead sans PageSpeed** : un site inaccessible ou sans HTTPS n'a pas besoin de
  PageSpeed pour être un bon prospect. Le score doit rester calculable avec des indicateurs partiels.

## Conséquences

- Les **pondérations du tableau ci-dessus sont un point de départ**, pas une vérité : elles
  doivent être recalibrées après 50 à 100 résultats réels (cahier des charges §7.3). Changer
  les poids = une **nouvelle décision** (nouvel ADR), pas une modification silencieuse.
- `reasons` est du JSONB : la structure (liste de chaînes lisibles) est un **contrat** avec le
  dashboard et le message de notification. La faire évoluer est une PR à périmètre multiple.
- Les analyses sont **historisées** (`analyses`) et non écrasées : on peut mesurer si un prospect
  a corrigé son site entre deux analyses (RF-11), et revenir sur une décision de scoring passée.
- Le risque R5 (faux positif : site correct noté bas) est **assumé et compensé par un contrôle
  humain** avant contact, pas par un raffinement infini de la grille.
