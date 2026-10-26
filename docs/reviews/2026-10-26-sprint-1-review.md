# Sprint Review & Rétrospective — Sprint 1 · 2026-10-26

**Rôle tenu** : agent **Product Owner** (brief [`prompts/product-owner.md`](../prompts/product-owner.md)) ·
**Périmètre écrit** : `docs/` uniquement — cette review ne modifie aucun code.
**Rituels dus** : Sprint Review (vendredi 23/10, 20 min) et Rétrospective (15 min) des §5 et §6 de
[`sprint-01.md`](../sprint-01.md), tenus avec **3 jours de retard**, le 2026-10-26.
**Pourquoi ils sont dus** : le 22/10, `S1-04` a été fusionnée avec, dans sa propre PR, la mention
« Preuve attendue … *(à faire pour la DoD complète)* ». Faire cette preuve est ce qui a déclenché
cette review — et elle a trouvé un défaut critique.

---

## 1. Démo de ce qui tourne réellement

La CI ne prouve que le SQL (voir §9 d'[`AGENTS.md`](../../AGENTS.md)). Ce tableau ne liste donc que
ce qui a été **exécuté** et vérifié par sa sortie.

| Ce qui tourne | Preuve observée | Date |
|---|---|---|
| WF1 collecte, écrit, attribue et clôture une campagne | `runs` `status = success`, `items_processed = 2` ; **2 lignes `companies` réellement écrites** avec `campaign_id` posé | 2026-10-26 |
| WF1 politesse de crawl | User-Agent `Prospection-ia/1.0 (n8n WF1 collecte)` **observé sur le fil** par un hôte d'écho ; **948 ms** entre deux appels consécutifs | 2026-10-26 |
| WF1 — un couple en panne ne bloque pas les autres | 1 couple HTTP 500 + 1 couple sain → `partial`, `items_processed = 1`, message d'erreur exploitable | 2026-10-26 |
| WF1 — échec réseau : le run le dit | hôte inexistant → `status = error`, `getaddrinfo ENOTFOUND …` ; réponse vide (département valide) → `success`, 0 écrit | 2026-10-26 |
| WF1 — retry ×3 | 503, 503, 200 → `success` (les 3 tentatives sont dans le journal de l'écho) | 2026-10-26 |
| WF5 trace un échec de WF1 en base | 2 scénarios provoqués (échec avant / après ouverture de ligne) → `runs.status = error` | 2026-10-20 |
| Schéma, RLS, codes NAF, `campaigns_due`, `runs.details` | 4 suites SQL sur le **vrai** projet + 2 fichiers de test joués par la CI | 2026-10-15 → 20 |
| `main` protégée | push direct et merge anticipé **refusés** par GitHub (mesuré) | 2026-10-15 |

**Ce qui ne tourne pas encore, et ce n'est pas un échec** : analyse de site (WF2), scoring (WF3),
notification (WF4) — sprints suivants. `S0-06` (bot Telegram, clé PageSpeed) reste un **verrou
humain** sans impact sur le sprint (D-003).

---

## 2. Métriques du §5 — relevées, avec leur mode de mesure

| Indicateur | Objectif | Valeur relevée | Comment c'est mesuré |
|---|---|---|---|
| **Vélocité** (tickets terminés) | stable ou croissante | Sprint 1 : **8 faits** (S1-01→S1-06, S1-08, S1-09), **1 refusé** (S1-07) · Sprint 0 : 4 faits + `S0-05` partiel → **croissante** | tableau du §2 de `sprint-01.md` |
| **Lead time** (`Prêt` → `Fait`) | < 2 jours | médiane **0,1 h** ; **8 PR sur 9** sous 48 h ; **1 outlier à 89 h** (PR #25, `S1-02`) | premier commit de la branche → `mergedAt` (`gh pr view <n> --json commits,mergedAt`). **Proxy assumé** : aucune trace d'horodatage « Prêt » n'existe, et il sous-estime les tickets rebasés (`S1-05`, dates de commit réécrites) |
| **Taux de PR refusées par le Reviewer** | décroissant | **0 PR refusée** — 38 ouvertes, 38 fusionnées. **Mais la métrique mesure mal ce sprint** : 3 tickets sur 8 ont reçu un correctif issu d'une relecture en contexte neuf (`S1-01` retry ×3 absent, `S1-02` 4 points, `S1-05` migration non réapplicable) et **4 ont été fusionnés sans relecture tierce**, l'écart étant écrit au ticket (`S1-03`, `S1-04`, `S1-06`, `S1-08`/`S1-09`) | `gh pr list --state all` + tickets |
| **Échecs de CI** | < 20 % | **1 échec réel sur 91 runs (1,1 %)** ; 2 non-succès en comptant 1 run annulé (**2,2 %**) | `gh run list --limit 200` |
| **Bugs échappés en production** | 0 critique | **1 critique** : WF1 sortait en `success` avec **0 élément sur n'importe quel échec réseau**, et ne collectait donc rien du tout — livré sur `main` le 2026-10-20 (PR #35), trouvé le 2026-10-26 en faisant la preuve de `S1-04` | preuve du 2026-10-26, §3 |

**Une seule ligne est rouge, et c'est la plus importante.** Le garde-fou « Bugs échappés » a échoué :
un défaut critique a vécu **6 jours sur `main`** derrière une CI verte, deux tickets marqués `fait` et
des preuves locales complètes. Les quatre autres indicateurs sont bons — ce qui est exactement le
problème : ils ne l'ont pas vu.

Note de méthode : `S1-02` porte à lui seul l'outlier de lead time (89 h) ; il est aussi le ticket qui
a produit la ligne rouge. **Les deux signaux ne sont pas indépendants** : c'est le ticket livré le plus
vite qui a le mieux résisté à la vérification, pas celui livré le plus lentement.

---

## 3. Rétrospective — une chose à garder, une à arrêter, une à essayer

**À garder : la preuve d'exécution réelle avant `fait`.**
C'est elle, et rien d'autre, qui a trouvé le défaut critique. Le mode opératoire est rodé et écrit
dans les tickets : instance n8n **jetable** (conteneurs jetables sur un volume dédié), **copie** du
workflow exporté — jamais un harnais de test livré —, et **la ligne `runs` à l'appui**.
Les preuves de `S1-02`, `S1-03`, `S1-06` et `S1-04` suivent toutes ce même schéma.

**À arrêter : clore un ticket dont la preuve est « à faire ».**
`S1-04` a été fusionnée le 22/10 avec « *(à faire pour la DoD complète)* » écrit dans sa propre PR, un
tableau passé à `✅ fait`, et une section de ticket restée à `⬜` avec ses critères vides — écart que
personne n'a vu pendant 4 jours. **Un `✅` sans preuve est un `🟦`.** Deux autres tickets portaient
encore, le 2026-10-26, un en-tête qui contredisait le tableau (`S1-05` « en review », `S1-07` « à
faire ») : un en-tête qui diverge du tableau fait perdre du temps à la relecture suivante.

**À essayer : exiger une exécution de bout en bout avant de clore tout ticket qui touche la chaîne
de collecte.**
Une campagne, un couple, ≤ 25 éléments, la ligne `runs` à l'appui — environ 30 minutes. La raison est
que `S1-02`, `S1-03` et `S1-04` ont **chacun** passé leur CI et leur preuve locale, et que la chaîne
entière n'avait **jamais** tourné d'un bout à l'autre avant le 2026-10-26. Trois défauts l'ont
traversée sans être vus : le rattachement des couples (écrit en `S1-02`, faux jusqu'à `S1-04`), la
conciliation restée **orpheline** (deux tickets de logique morte), le harnais de test **cassé**
(`onError` au mauvais endroit, sortie sans destination).

`AGENTS.md` §10 est à jour (question 3 du §6, faite le 2026-10-26 : 5 pièges **mesurés**, PR #38).

---

## 4. Les quatre questions du §6

**1. `ADR 0005` a-t-il évité des faux positifs, ou surestimé le problème ?**
Mesure : sur `43.21A` × `974`, **13 récupérées / 7 écartées** — soit **54 % de rejet**. Le seuil
d'alerte du brief PO est « plus de 60 % signale un découpage de campagne trop large » : on passe
**juste en dessous**. La règle a bien écarté des sièges hors zone (groupes nationaux avec une agence
locale — cas EIFFAGE relevé le 2026-10-15). Verdict : **pas surestimée**, mais **proche du seuil** ;
à rouvrir si une campagne dépasse 60 %.

**2. La limite WIP de 2 a-t-elle été réellement respectée ?**
**Non mesurable a posteriori, et c'est un défaut du suivi** : aucun ticket n'a jamais porté `🟡 en
cours`, donc le tableau ne garde que l'état final. Ce qui est mesurable : **38 PR en 12 jours**, dont
6 fusionnées le 2026-10-20 et 3 le 2026-10-26 — la contrainte réelle n'a pas été le WIP mais la
**disponibilité des preuves**. Si la limite doit être contrôlée, elle doit le devenir dans les faits :
un statut `🟡` tenu à jour au moment où un ticket démarre.

**3. Quelles erreurs se sont répétées ? → `AGENTS.md` §10**
**Fait le 2026-10-26** (PR #38) : 5 pièges, tous mesurés, pas déduits — `pairedItem.sourceOverwrite`
inexistant, nœud sans entrant jamais exécuté, « département inexistant » ≠ réponse vide (HTTP 400),
API publique à trois adresses dont deux muettes, forme du message d'erreur HTTP variable.

**4. Le découpage de WF1 en 4 tickets (`S1-01`..`S1-04`) était-il le bon grain, ou trop fin ?**
**Le grain est bon, le propriétaire manquait.** Les quatre tranches sont réellement indépendantes
(cadence, collecte, écriture, politesse) et chacune a pu être prouvée isolément — c'est ce qui a
permis d'avancer vite. Ce qui manquait : **aucun ticket n'était propriétaire de la chaîne complète**,
donc personne ne l'a jamais exécutée en entier. Verdict : garder le découpage, et fermer le trou par
l'item « à essayer » ci-dessus plutôt qu'en fusionnant les tickets.

---

## 5. Décisions mises sur la table — **tranchées le 2026-10-26**

Cette review avait laissé les trois arbitrages ci-dessous **sur la table, non tranchés**. Ils ont été
**tranchés le jour même par écrit** : **D-011**, **D-012** et **D-013** de
[`product-decisions.md`](../product-decisions.md). Les énoncés ci-dessous restent tels qu'ils ont été
écrits dans la review, chacun suivi de sa décision.

1. **Garde-fou de clôture** — exiger une exécution de bout en bout de WF1 (1 campagne, 1 couple, ≤ 25,
   la ligne `runs` à l'appui) avant tout `fait` sur un ticket touchant la chaîne de collecte.
   *Coût* : ~30 min par ticket concerné. *Ce qui le rendrait inutile* : une CI capable d'exercer WF1.
   → **retenu tel quel : `D-011`** (il formalise la ligne « vérifié sur l'environnement cible » de la DoD).
2. **Timeout de 10 s face à l'API publique** — mesuré le 2026-10-26 :
   `37.59.183.76` → HTTP 200 en 2,0 s, `37.59.183.77` → délai dépassé après 15,0 s, `37.59.183.78` →
   délai dépassé après 12,7 s ; aucun client ne réessaie une autre adresse. Monter le timeout
   **masquerait** la panne sans la traiter ; garder 10 s produit des runs `error` corrects et visibles.
   *Hypothèse assumée* : le défaut est côté réseau/API, pas côté WF1.
   → **tranché : `D-012`** — 10 s conservés, rotation d'adresses **à mesurer** avant toute décision.
   → **mesuré le 2026-10-26, puis révisé : `D-014`** — deux adresses sur trois sont muettes **au
   niveau TCP**, mais le client bascule tout seul sur la vivante (**8/8 collectes réussies**, sur
   l'hôte et dans le conteneur n8n) : aucun réglage ne change, et le vrai risque est que l'API dépende
   d'**une seule** adresse vivante. La phrase « aucun client ne réessaie une autre adresse » ci-dessus
   est **démentie par la mesure** (c'était l'hypothèse, pas un fait).
   Détail : [`2026-10-26-mesure-rotation-api.md`](2026-10-26-mesure-rotation-api.md).
   → **et re-démenti, dans l'autre sens, par l'exécution réelle du même jour : `D-015`**. Le client qui
   bascule est un client Node **nu** ; le **nœud HTTP de n8n ne bascule pas** — 2 exécutions réelles,
   3 tentatives × 10 s, **3 timeouts**, rien collecté. La collecte n'est donc pas seulement « une
   partie des runs » en erreur : elle est **inutilisable en l'état** sur l'API publique. Détail :
   [`2026-10-26-execution-reelle-wf1-api-publique.md`](2026-10-26-execution-reelle-wf1-api-publique.md).
3. **`S1-07`** — sa condition de retour est « dès 1 collecte réelle ». Une collecte réelle a bien
   tourné le 2026-10-26… **contre un hôte d'écho local** (pour prouver la robustesse), pas sur l'API
   publique. La condition n'est donc **pas remplie à la lettre**, et le ticket reste refusé.
   → **tranché : `D-013`** — refus maintenu, condition de retour rendue **vérifiable** (1 ligne
   `companies` écrite par un appel réel à `recherche-entreprises.api.gouv.fr`).

---

## 6. Ce que cette review ne prouve pas

- Elle est écrite par la **même session** qui a corrigé `S1-04` : ce n'est **pas** une relecture en
  contexte neuf de ce correctif. L'écart de DoD reste ouvert (« un agent ne valide pas son propre
  travail »), comme pour `S1-03`, `S1-06`, `S1-08` et `S1-09`.
- Deux critères de `S1-04` (politesse, Continue on Fail) ont été prouvés contre un **écho local**, avec
  **seule l'URL de collecte substituée** — la collecte sur l'API publique n'a pas pu aboutir en
  `success` le 2026-10-26 (cf. décision 2 ci-dessus).
- Aucune donnée de production n'existe : la base est à **0 campagne, 0 entreprise, 0 run**. Il n'y a
  donc rien à démontrer côté volume, et les anti-métriques du brief PO (lignes en base, workflows
  écrits, volume collecté) sont à zéro — ce qui est l'état attendu à ce stade, pas un résultat.
- Le lead time est un **proxy** (premier commit → fusion), faute d'horodatage « Prêt ».
