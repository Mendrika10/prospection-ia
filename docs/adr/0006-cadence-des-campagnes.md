# ADR 0006 — Cadence des campagnes : intervalle explicite + dernier passage lisible

- Statut : **accepté**
- Date : 2026-10-15
- Décideur : Product Owner
- Rôle auteur : Architecte

## Contexte

RF-03 demande de « planifier la fréquence d'exécution (cron) par campagne », et le modèle du
cahier des charges §7.1 prévoit une colonne `campaigns.cron`. Deux faits vérifiés le 2026-10-15
empêchent de la lire telle quelle :

1. **n8n ne peut pas lire un cron par ligne à l'exécution.** Le déclencheur est une propriété du
   nœud, et la documentation officielle est explicite (*Schedule Trigger → Common issues →
   Variables*) : les valeurs du déclencheur ne sont évaluées **qu'à la publication** du workflow ;
   les modifier ensuite ne change pas la fréquence. Ce n'est donc pas une difficulté
   d'implémentation, c'est une impossibilité.
2. **Rien n'enregistre le dernier passage d'une campagne.** `runs` n'a aucun rattachement à une
   campagne (`campaign_id` absent du schéma) : aucune campagne ne peut être « due » ou non.

Sans ces deux briques, RF-03 reste une case cochée sur le papier : WF1 rejouerait **toutes** les
campagnes actives à chaque tick, ou aucune — et le travail d'une campagne manuelle serait écrasé par
la suivante.

Une contrainte doit être conservée : le cahier des charges §7 note qu'un **cron régulier évite la
mise en pause du projet Supabase gratuit** après ~1 semaine d'inactivité. Le déclencheur ne peut donc
pas devenir « à la demande d'une campagne » : il doit continuer de tourner à vide.

## Décision

Trois règles, appliquées telles quelles par WF1 (`S1-01`) :

1. **Le déclencheur reste à cadence fixe** (propriété du nœud n8n). Il sert aussi à empêcher la mise
   en pause de Supabase. Il ne décide de rien.
2. **La fréquence par campagne est un intervalle explicite** :
   `campaigns.interval_minutes int not null default 1440 check (interval_minutes > 0)`.
   `campaigns.cron` reste au schéma mais devient **descriptif** : lisible par un humain, jamais
   interprété à l'exécution (un `comment on column` le dit).
3. **Le dernier passage devient lisible** par `runs.campaign_id` (nouvelle clé étrangère), et une vue
   `public.campaigns_due` expose les campagnes dues. La règle, écrite en clair et recopiée dans le
   test pour que l'agent Automation n'ait rien à réinterpréter :

```
une campagne est due si :
    active = true
ET  ( aucun run n'a jamais démarré pour elle
      OU  now() >= dernier_started_at + interval_minutes × 1 minute )
où dernier_started_at = max(runs.started_at) pour cette campagne, tous statuts confondus
```

## Alternatives écartées

- **Interpréter `campaigns.cron` dans le workflow.** Impossible côté n8n (fait 1 ci-dessus). Et
  l'écrire soi-même serait un projet à part : cinq champs, alias (`@daily`), listes, pas (`*/15`),
  avec ses tests — pour une collecte quotidienne qui n'a besoin d'aucune granularité horaire.
- **Un workflow n8n par campagne**, chacun avec son propre cron. C'est la seule façon d'avoir un vrai
  cron par campagne — et elle multiplie les workflows, les credentials et les points de rupture.
  Le cahier des charges §7.2 impose **un** WF1 ; à dix campagnes, la maintenance devient intenable.
- **`campaigns.last_run_at` mis à jour par WF1.** Séduisant, mais crée une **seconde source de
  vérité** en face de `runs` : elle dérive dès qu'un run échoue au milieu (date écrite sans collecte)
  ou qu'un run est repris à la main. `runs` est de toute façon la table d'observabilité imposée par
  §4 : dériver le dernier passage de `runs` supprime le risque de désynchronisation.
- **Un intervalle global** (variable d'environnement n8n). Une seule fréquence pour toutes les
  campagnes, alors que RF-03 la demande **par campagne**.
- **Une table de planification dédiée** (`campaign_schedule`). Sur-modélisation : le besoin tient en
  une colonne, une clé étrangère et une vue.

## Conséquences

- WF1 lit `campaigns_due` au lieu de `campaigns where active`. Il n'interprète aucune règle :
  la comparaison vit dans la vue, et le test la reprend en clair.
- **Un run en cours bloque sa campagne** (le dernier `started_at` compte quel que soit le statut) :
  une collecte longue n'est pas relancée par le tick suivant. Le revers est connu : un run resté
  bloqué en `running` empêcherait la campagne de repartir. Si ça se produit en exploitation, on
  ajoutera une **règle de péremption** (par exemple au-delà de 6 h) — par une décision écrite, pas
  par une improvisation dans le workflow.
- `runs.campaign_id` rend aussi calculable le **taux de rejet par campagne**, en croisant
  `runs.details` (S1-08) : c'est la métrique d'alerte du brief PO §5 (> 60 % = campagne trop large).
- Le défaut `1440` minutes (24 h) reproduit la cadence du `cron` par défaut : **aucune campagne
  existante ne change de comportement** à la migration.
- La vue est créée en **`security_invoker = true`**. Sans cela, une vue s'exécute avec les droits de
  son propriétaire et **contournerait la RLS** : `anon` lirait les campagnes, ce qui est une
  régression directe du critère d'acceptation v1 « un accès anonyme ne lit rien ». Le test le vérifie
  plutôt que de le supposer.
- Coût : une colonne, une clé étrangère, un index, une vue. **Aucun coût récurrent** (contrainte 0 €).
