# Sprint 2 — backlog

> **Ce que ce fichier est** : le backlog du sprint 2, **ouvert le 2026-10-26** par la décision
> **`D-015`**, avec les **deux tickets de levée** que cette décision place **en tête**. Le
> **planning** du sprint 2 (rituel du lundi, agent Product Owner) **n'a pas encore eu lieu** : son
> reste sera construit ce jour-là, sans préempter son verdict. Les reports du sprint 1 sont listés
> dans [`sprint-01.md`](sprint-01.md) §7.
>
> **Pourquoi ces deux-là d'abord** : ils portent les deux défauts révélés par la **première
> exécution réelle de WF1 sur l'API publique** (2026-10-26,
> [`reviews/2026-10-26-execution-reelle-wf1-api-publique.md`](reviews/2026-10-26-execution-reelle-wf1-api-publique.md)).
> Sans eux, **aucune campagne réelle ne peut être collectée** — le premier bloque la collecte, le
> second écrit de fausses lignes en silence. Ils passent donc avant tout élargissement de périmètre
> (WF2), comme le dit `D-015`.

Statuts : `⬜ à faire` · `🟦 Prêt` · `🟡 en cours` · `🟦 en review` · `✅ fait` · `⛔ bloqué`

| ID | Ticket | Rôle | Taille | Dépend de | Statut |
|---|---|---|---|---|---|
| S2-01 | WF1 — la collecte doit atteindre une adresse vivante de l'API (**défaut A**) | Automation + Architecte | S puis M | — | 🟦 **Prêt** |
| S2-02 | WF1 — rattacher chaque page au bon couple, sans index implicite (**défaut B**) | Automation | M | **S2-01** | 🟦 **Prêt** |

## Règle de preuve applicable aux deux tickets (`D-011` + `D-015`)

Un ticket qui touche la chaîne de collecte n'est `fait` que sur une **exécution de bout en bout** :
instance n8n **jetable**, **copie** du workflow exporté, **la ligne `runs` lue en base** à l'appui,
**scénario d'échec provoqué** s'il touche la robustesse, et **base rendue à son état d'avant**
(comptes relevés avant/après). Et depuis `D-015` : la preuve se fait sur un couple **multi-pages** —
le mono-page ne prouve rien du cas normal.

---

## S2-01 — WF1 : la collecte doit atteindre une adresse vivante de l'API (défaut A) · 🟦 Prêt

**Objectif** : une exécution de WF1 sur l'API publique doit collecter **sans** dépendre de l'adresse
que le résolveur rend en premier.

**Contexte — ce qui est mesuré, pas supposé** : `recherche-entreprises.api.gouv.fr` résout **trois**
adresses ; `37.59.183.76` répond (HTTP 200 en ~0,2 s au TCP, ~0,27 s en HTTP), `37.59.183.77` et
`37.59.183.78` sont **muettes au niveau TCP** (SYN sans réponse : 6 essais sur 6 en timeout à 12 s).
Un client Node **nu** bascule seul d'adresse (`autoSelectFamily`) et réussit 8 fois sur 8 ; le
**nœud HTTP de n8n ne bascule pas** — deux exécutions réelles de WF1 : **3 tentatives × 10 s, 3
timeouts**, `details.recuperees = 0`, `items_processed = 0`, rien écrit. **Seul** un épinglage du nom
au niveau du conteneur (`--add-host …:37.59.183.76`) a permis d'atteindre l'adresse vivante — c'est
un diagnostic, **pas** un correctif. **Le timeout de 10 s n'est pas la cause** : une adresse morte ne
répond à aucun délai.

**Critères d'acceptation**
- [ ] Une exécution de WF1 **sans épinglage DNS** sur l'API publique produit `runs.status = success`
      et `items_processed ≥ 1` — la ligne `runs` lue en base **à l'appui**
- [ ] Le mode d'échec reste **intact** quand aucune adresse ne répond : nom épinglé sur une adresse
      noire → `status = error` avec message exploitable, **jamais** un `success`
- [ ] La solution retenue est **écrite** (ADR ou décision, options écartées comprises) et ne fixe
      **aucune** IP dans une configuration hors dépôt : `/etc/hosts`, `--add-host`, DNS privé non
      versionné sont **interdits** (le jour où l'adresse change, la panne deviendrait définitive)
- [ ] La politesse de crawl est **inchangée** : `User-Agent Prospection-ia/1.0 (n8n WF1 collecte)`
      observé sur le fil, ≈ **1 requête/s** entre les pages
- [ ] Aucune régression sur `retryOnFail ×3` (le cas 503 → 200 reste couvert)

**Pistes à instruire (aucune retenue d'avance)** : (a) comprendre **pourquoi** le nœud ne bascule pas
(agent HTTP/axios de n8n, résolution figée sur la première adresse ?) et si un réglage **supporté**
l'active ; (b) viser le nom mais **réessayer** jusqu'à obtenir une réponse d'une adresse vivante ;
(c) une autre voie d'accès, décidée sur mesure. Une piste n'entre dans le ticket qu'avec la mesure
qui la justifie.

**Definition of Ready** : objectif en une phrase ✓ · critères vérifiables ✓ · périmètre explicite ✓ ·
dépendances identifiées ✓ · taille ≤ ½ journée ✓

**Périmètre** : `n8n/workflows/wf1-collecte.json`, `n8n/docker-compose.yml`, `docs/` (décision, ADR)
**Interdit** : le schéma SQL, les migrations appliquées, la CI · **Dépendances** : aucune — démarrable
tout de suite · **Taille** : S (mesure) puis M si le correctif touche le workflow · **Rôle** :
Automation + Architecte (pour la décision)

---

## S2-02 — WF1 : rattacher chaque page au bon couple, sans index implicite (défaut B) · 🟦 Prêt

**Objectif** : qu'un couple de **plus de 25 résultats** soit collecté en entier, chaque page
attribuée **au bon couple**.

**Contexte — ce qui est mesuré, pas supposé** : `pairedItem.item` d'un nœud HTTP **paginé** est
l'index de **page**, pas celui de l'item d'entrée (mesuré sur deux mini-workflows : 1 couple sur
2 pages → `{item:0}` puis **`{item:1}`** ; 2 couples, A sur 2 pages et B sur 1 → la page 2 de A est
**attribuée à B**). Or « Filtrage et compteurs » lit cet index comme celui du couple (choix de
`S1-04`). Conséquences mesurées : index hors bornes → la collecte est **abandonnée** (« 60 page(s)
sans couple rattachable », rien écrit) ; avec ≥ 2 couples, les pages d'un couple peuvent être
attribuées à un **autre** — **silencieusement** si les deux partagent un code NAF, et c'est alors le
**département du mauvais couple** qui décide du filtre de siège d'ADR 0005. Et ce n'est **pas** un
cas de bord : sur 30 couples sondés, **2 seulement** tiennent sur une page ; `43.21A × 974` en compte
**1 515** (61 pages).

**Critères d'acceptation**
- [ ] Sur un couple **multi-pages** (`43.21A × 974` : 1 515 résultats, 61 pages) : `runs.status =
      success`, `details.recuperees = 1515`, `runs.error = null`, et `items_processed +
      details.ecartees = 1515` — la ligne `runs` lue en base **à l'appui**
- [ ] Sur **deux couples partageant le même code NAF** (ex. `43.21A × 974` **et** `43.21A × 15`),
      chaque ligne écrite appartient bien à son couple : le département lu dans la ligne est celui du
      couple — contrôle **par requête**, pas à l'œil. *(C'est le critère qui attrape le défaut
      silencieux ; sans lui, le ticket peut être vert et faux.)*
- [ ] Le rattachement **ne lit plus** `pairedItem.item` : la clé est **portée par la donnée**, et le
      test le montre (faire varier l'index du nœud ne change plus l'attribution)
- [ ] Le plafond de pagination (dernière page pleine = collecte tronquée) reste une **erreur**,
      jamais un silence
- [ ] Relecture par un **Reviewer en contexte neuf** — exigence de la DoD, non négociable ici :
      c'est précisément l'écart qui a laissé passer le défaut critique de `S1-04`

**Definition of Ready** : objectif en une phrase ✓ · critères vérifiables ✓ · périmètre explicite ✓ ·
dépendances identifiées ✓ · taille ≤ ½ journée ✓

**Périmètre** : les Code nodes de `n8n/workflows/wf1-collecte.json` (« Préparation de collecte »,
« Filtrage et compteurs ») ; `AGENTS.md` §10 si un piège nouveau en sort · **Interdit** : le schéma
SQL, le contrat d'upsert (ADR 0007), la CI
**Dépendances** : **`S2-01` pour sa preuve** — une preuve multi-pages exige une collecte qui atteint
l'API. Le code peut être préparé et éprouvé sur un hôte d'écho avant, mais le ticket **ne peut pas**
être clos avant `S2-01` · **Taille** : M · **Rôle** : Automation (+ Reviewer)

---

## Ce que ces deux tickets ne sont pas

- **Ils ne sont pas WF2.** L'enrichissement (recherche de site) est le périmètre naturel du sprint 2,
  mais il suppose une collecte qui fonctionne : le planning tranchera, ces deux tickets passent
  devant par décision (`D-015`), pas par préférence.
- **Ils ne modifient ni le schéma, ni le contrat d'upsert, ni la CI.** Le document de `S1-02` et
  l'ADR 0007 restent la référence : le défaut B est dans le **rattachement des pages**, pas dans
  l'écriture.
- **Ils ne « re-décident » pas `D-012`.** Le timeout de 10 s reste ; c'est l'adresse choisie qui est
  en cause, et le rattachement des pages.
