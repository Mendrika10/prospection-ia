---
name: Ticket
about: Unité de travail — objectif, critères d'acceptation vérifiables, périmètre verrouillé
title: "[S1] "
---

## Objectif
<!-- Une phrase. Si vous ne tenez pas en une phrase, c'est deux tickets. -->

## Contexte
<!-- Lien cahier des charges (section), ADR, ou ticket parent. -->

## Critères d'acceptation
<!-- Vérifiables : une commande, un résultat attendu, une case à cocher. -->
- [ ] …
- [ ] …

## Périmètre
Fichiers/dossiers modifiables : `…`
**Interdit** : `…`

## Dépendances
<!-- Numéros de tickets, comptes externes, secrets à provisionner. -->

## Taille
<!-- S ≤ 2h · M ≤ ½ journée. Au-delà : découper. -->
S / M

## Rôle attendu
<!-- Orchestrateur · Architecte · Backend/Data · Automation · Frontend · QA · Reviewer · DevOps · Documentation -->
—

---

### Definition of Ready — à cocher AVANT de démarrer
- [ ] Objectif en une phrase
- [ ] Critères d'acceptation vérifiables
- [ ] Périmètre explicite
- [ ] Dépendances identifiées
- [ ] Taille ≤ ½ journée

### Definition of Done — à cocher AVANT de fermer
- [ ] Critères d'acceptation validés (avec la sortie de commande à l'appui)
- [ ] Tests écrits et verts en CI
- [ ] Relecture par un agent Reviewer (contexte neuf)
- [ ] Validation humaine (Product Owner)
- [ ] Aucun secret dans le code
- [ ] Documentation mise à jour si nécessaire
- [ ] *Si le ticket touche la chaîne de collecte (WF1)* : **exécution de bout en bout** (1 campagne, 1 couple, ≤ 25 attendus), **la ligne `runs` lue en base** à l'appui, et un **scénario d'échec provoqué** s'il touche la robustesse — `D-011`, §2.4 de [`methode-equipe-agents.md`](../../docs/methode-equipe-agents.md)
