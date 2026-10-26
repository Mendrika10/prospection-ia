# Défaut A requalifié — le nœud HTTP de n8n **bascule** bien d'adresse

> Objet : le ticket **`S2-01`** demandait d'instruire **pourquoi** le nœud HTTP de n8n ne bascule pas
> d'adresse, puis de corriger. La mesure répond à la première moitié par la négative : **il bascule**.
> Ce document est la preuve de `D-016`, qui **révise le point 1 de `D-015`**.
> Date : **2026-10-26**, même journée que l'exécution qui avait attribué la panne au nœud.
>
> Il ne remplace pas [`2026-10-26-execution-reelle-wf1-api-publique.md`](2026-10-26-execution-reelle-wf1-api-publique.md) :
> celle-là reste le relevé de la première exécution réelle et reste la preuve du **défaut B**, intact.

## Ce qui était affirmé, et ce qui a été mesuré

| Affirmation de `D-015` | Mesure du jour |
|---|---|
| « le **nœud HTTP de n8n ne bascule pas** » d'adresse | **faux** : le nœud bascule — trace `connect: autodetecting` ci-dessous, et **10 exécutions sur 10** réussies sans épinglage |
| « la panne est absorbée par le client » (`D-014`) | **vrai pour le nœud aussi** : l'autosélection de Node est active et effective dans le code que le nœud exécute |
| « 3 tentatives × 10 s, 3 timeouts, rien collecté » reproduit la panne d'adresse | **exact, et c'est le symptôme d'autre chose** : il se reproduit **à volonté** dès qu'**aucune** adresse du jeu ne répond — pas quand le nœud est en cause |

## Instruments (tous jetables, aucun épinglage DNS sauf mention contraire)

| Élément | Valeur |
|---|---|
| Image | `docker.n8n.io/n8nio/n8n:latest` · `sha256:4467641177a3fa6a7b353bd0ee9719799bfe93e45d5bab57e61bffb5ff3d52be` (créée le 2026-10-14) |
| Versions | n8n **2.43.5** · node **v26.7.0** — l'image de la preuve du 26/10 |
| Conteneurs | `docker run --rm`, un par mesure, base Supabase réelle lue puis **remise en état** |
| Instrument 1 | `NODE_DEBUG=net` sur **le code HTTP de n8n lui-même** (`@n8n/backend-network/dist/http/axios/request.js`, celui qu'appelle le nœud *HTTP Request*) |
| Instrument 2 | un workflow de diagnostic contenant **le nœud de WF1 copié tel quel** (même URL, mêmes paramètres, `per_page=25`, `timeout 10 s`, `requestInterval 1 s`, `retryOnFail ×3`, `User-Agent`), déclenché par webhook |
| Instrument 3 | WF1 **entier**, copie de l'export versionné (déclencheur de preuve ajouté, déclencheur horaire désactivé dans la copie), campagnes créées puis supprimées par PostgREST |

## 1. Le résolveur — inchangé depuis le 26/10

`recherche-entreprises.api.gouv.fr` (CNAME `wildcard-api.infra.data.gouv.fr`) rend **trois** adresses :
`37.59.183.76` répond (**TCP en ~0,2 s**, HTTP 200), `37.59.183.77` et `37.59.183.78` sont **muettes au
niveau TCP** (SYN sans réponse). **20 résolutions sur 20** ont rendu le même jeu, contenant l'adresse
vivante, en **≤ 20 ms** — dont l'ordre, lui, **varie** (`.78`, `.76` ou `.77` en tête selon l'appel).
Aucune résolution lente, aucun jeu sans adresse vivante pendant la mesure.

## 2. Le code HTTP de n8n bascule — trace, avec une adresse muette **en premier**

Extrait **verbatim** de la trace (`NODE_DEBUG=net`, appel de `httpRequest` de n8n, `timeout 10 s`) :

```
NET 8: connect: dns options { family: undefined, hints: 32 }
NET 8: connect: autodetecting
NET 8: connect/multiple: will try the following addresses [
  { address: '37.59.183.77', family: 4 },
  { address: '37.59.183.78', family: 4 },
  { address: '37.59.183.76', family: 4 }
]
NET 8: connect/multiple: attempting to connect to 37.59.183.77:443 (addressType: 4)
NET 8: connect/multiple: setting the attempt timeout to 500 ms
NET 8: connect/multiple: connection to 37.59.183.77:443 timed out
NET 8: connect/multiple: attempting to connect to 37.59.183.78:443 (addressType: 4)
NET 8: connect/multiple: setting the attempt timeout to 500 ms
NET 8: connect/multiple: connection to 37.59.183.78:443 timed out
NET 8: connect/multiple: attempting to connect to 37.59.183.76:443 (addressType: 4)
NET 8: connect/multiple: connection attempt to 37.59.183.76:443 completed with status 0
```

Deux adresses muettes, **500 ms chacune**, puis l'adresse vivante : c'est le repli de Node
(`autoSelectFamily`), **exercé par le code de n8n**, sans qu'aucun réglage du workflow n'ait à le
demander. Vérifié aussi dans les réglages : `net.getDefaultAutoSelectFamily()` → **`true`**,
`net.getDefaultAutoSelectFamilyAttemptTimeout()` → **500 ms**.

Et rien dans n8n ne le désactive : dans l'image, la clé `autoSelectFamily` n'apparaît que dans
`@n8n/backend-network/dist/proxy/proxied-agents.js` (liste d'options d'un **agent de proxy**) ;
la protection SSRF est **désactivée par défaut** (`SsrfProtectionConfig.enabled = false`) et son
`createSecureLookup()`, quand elle est active, rend **toutes** les adresses dès que Node les demande
(`{ hints: 32, all: true }` — mesuré). Ni l'un ni l'autre ne concerne la collecte de WF1.

## 3. Le nœud réel, sans aucun épinglage — 10 essais sur 10

Workflow de diagnostic, **nœud de WF1 copié tel quel**, `41.20A × 48`, déclenché 10 fois par webhook :

```
essai  1 … essai 10 · HTTP 200 · 742-801 ms · {"pages":1,"detail":[{"status":null,"erreur":null,
                                        "results":22,"total_results":22,"premier_siren":"411306608"}]}
```

**10/10 `HTTP 200`**, aucun `error`, 22 résultats — et une durée **inférieure** à 1 s, parce que
l'adresse vivante était souvent la première essayée. Aucune capture n'a été retenue de côté : les dix
essais ont la même forme.

## 4. Le mode d'échec, lui, se reproduit **à volonté**

Nom épinglé sur une adresse **muette** (`.77`) dans le conteneur — c'est un **diagnostic**, pas une
configuration :

```
essai 1 · HTTP 200 (réponse du harnais) · 40 167 ms · {"detail":[{"erreur":"timeout of 10000ms exceeded",
                                                   "results":null,"total_results":null}]}
```

**40,1 s** = 3 tentatives × 10 s de timeout + 2 × 5 s d'attente entre essais, message
`timeout of 10000ms exceeded`, **0 résultat** : c'est **exactement** la signature des runs 1 et 2 du
26/10 (`3 tentatives × 10 s, 3 timeouts`, ~50 s, rien collecté). Le symptôme enregistré ne dit donc
pas « le nœud n'a pas su basculer », il dit **« aucune adresse atteignable dans le jeu rendu »**.

## 5. Ce qui, à l'inverse, casse la bascule — et c'est mesuré

Deux réglages reproduisent la panne **sans** épingler le nom, en gardant le jeu complet :

| Réglage du client | Ce que Node fait de la résolution | Résultat |
|---|---|---|
| aucun (défaut) | lookup `{ hints: 32, all: true }` → les trois adresses | **HTTP 200 en 1,9 s** |
| `family: 4` | lookup `{ family: 4, hints: 0 }` → **une** adresse (`.78`, muette) | **timeout 10 016 ms** |
| `autoSelectFamily: false` | repli désactivé, une adresse | **timeout 10 011 ms** |

Autrement dit : dès que la famille est **figée** (`family`) ou l'autosélection **coupée**, la
résolution se réduit à une adresse et la panne du 26/10 redevient systématique. Ces réglages ne sont
**pas** dans le nœud de WF1 (`agentOptions` n'y figure pas), mais ce sont les seuls suspects qui
produiraient le même symptôme : c'est la piste à écarter en premier si la panne revient.

## 6. WF1 entier, de bout en bout, **sans épinglage**

| | |
|---|---|
| Campagne | `preuve S2-01 — 41.20A × 48` : un couple, `naf_codes=["41.20A"]`, `departements=["48"]`, sans filtre d'effectif, `interval_minutes=1440`, `active` — **due** (`campaigns_due` la rend) |
| Déclenchement | webhook sur la **copie activée** de l'export versionné (déclencheur horaire de la copie désactivé pour qu'aucun tick ne s'intercale) |
| Base avant | **0 / 0 / 0** (campagnes / entreprises / runs) |

Ligne `runs` lue en base :

```json
{"workflow":"wf1-collecte","status":"success","items_processed":20,"error":null,
 "details":{"ecartees":2,"recuperees":22,"bandes_appliquees":[]},
 "started_at":"2026-10-26T15:14:04.748106+00:00","finished_at":"2026-10-26T15:14:08.95+00:00"}
```

- **20 lignes `companies`** écrites, toutes rattachées à la campagne, `website` **resté `null`**
  (D-009) ; `items_processed` = **20** = lignes réellement écrites (D-002) ;
  `recuperees (22) = écrites (20) + ecartees (2)`.
- Durée **4,2 s** — soit la collecte normale, là où les runs 1 et 2 du 26/10 expiraient en 50 s.
- **Base rendue à 0 / 0 / 0**, identique au relevé d'avant (campagne, run et 20 lignes supprimés).

## Ce que cette mesure établit — et pourquoi l'attribution du 26/10 tombe

1. **Quand le jeu d'adresses contient une adresse vivante, le nœud l'atteint** : 10/10 en environnement
   réel, et la trace montre le repli exercé depuis une adresse muette placée en premier.
2. **Quand aucune adresse du jeu ne répond, la panne a exactement la forme enregistrée** : 3 × 10 s,
   `timeout of 10000ms exceeded`, rien de collecté.
3. Les runs 1 et 2 du 26/10 portent **cette forme-là**. Donc, pendant ces deux exécutions, **aucune
   adresse du jeu rendu ne répondait** — la cause est dans ce que le résolveur a rendu, ou dans la
   joignabilité du service à cet instant, **pas dans le client**.
4. Le contre-argument du ticket (« un client Node **nu** réussit 8 fois sur 8 ») **ne départage pas** :
   ce relevé **n'est pas daté** par rapport aux deux échecs, et de toute façon un client nu, avec le
   même jeu sans adresse vivante, **échouerait de même** — le repli ne fabrique pas une adresse qui
   répond. C'est l'écart de méthode qui a produit l'attribution : deux mesures **non simultanées**
   comparées comme si elles l'étaient.

C'est précisément la condition de révision que `D-015` avait écrite elle-même : « *ou la preuve que
l'API répond normalement depuis un autre réseau d'exécution — la panne d'adresses serait alors locale* ».
La mesure est faite, depuis **le même** réseau d'exécution : l'API répond normalement, la chaîne
collecte, et le défaut A **n'existe pas** tel qu'il avait été formulé.

## Constat annexe, relevé sans être isolé (piste de ticket, pas décision)

Pendant la mise au point, une campagne laissée par un essai interrompu a fait tourner WF1 sur
**deux campagnes dues dans le même lot**. Ce qui a été observé en base :

| | |
|---|---|
| Lignes `runs` | **2**, créées par la même transaction (`started_at` **identique à la microseconde** : `15:08:10.643709`) |
| Clôture | **une seule** : `success`, `items_processed = 20` — l'autre ligne est restée **`running`** |
| Entreprises | **20**, toutes rattachées à la campagne clôturée ; la seconde campagne n'a **rien** reçu |

Lecture du code, cohérente avec l'observation : « Préparation de collecte » et la clôture lisent
`$('Pour chaque campagne (S1-02)').first()` / `$('Run démarré (campagne)').first()` — un lot de deux
campagnes prépare et clôture donc **la première**, laissant la seconde **affamée** et sa ligne `runs`
**figée en `running`** (que `campaigns_due` compte ensuite comme « dernier passage », donc la campagne
n'est plus due avant l'intervalle écoulé). **Ce n'est pas un défaut de `S2-01`**, et ce n'est pas
prouvé isolément : à ouvrir comme ticket avec sa propre mesure — un lot de campagnes se traite
campagne par campagne, et le cas « deux campagnes dues au même tick » est déjà atteignable avec le
`batchSize: 10` du nœud.

## Ce que cette mesure ne dit pas (limites)

- **Un seul réseau, une seule fenêtre** (2026-10-26, ~15 h), une seule image : la même limite que la
  preuve du matin. Ce qui a changé n'est pas le réseau, c'est ce que le résolveur rend.
- **L'attribution rétroactive est impossible** : rien ne permet de dire si, à 14 h 05, l'adresse
  vivante était **absente** du jeu ou **muette**. Les deux produisent la panne observée, et aucune
  n'incrimine n8n.
- **Le mode d'échec est provoqué par un épinglage**, donc par une adresse choisie à la main : c'est un
  diagnostic autorisé, jamais une configuration de production (interdit par `S2-01`, et déjà interdit
  par `D-015`).
- **La preuve est mono-page** : `41.20A × 48` = 22 résultats, une page — choisie **exprès**, puisque le
  défaut B (rattachement des pages) n'est pas corrigé. Un couple multi-pages reste **incollectable**
  aujourd'hui : `S2-02` reste le ticket de levée.
- **La politesse de crawl n'a pas été ré-observée sur le fil** : elle est **inchangée par
  construction** — `n8n/workflows/` n'est pas modifié (`git diff` vide), le nœud de collecte garde
  `User-Agent`, `requestInterval` et `retryOnFail ×3` de `S1-04`, dont l'observation sur le fil reste
  la référence.
- Le *retry* ×3, lui, est **re-mesuré** ici : les 40,1 s du §4 sont exactement 3 tentatives et
  2 attentes de 5 s.

## Nettoyage

Aucun conteneur conservé (`--rm`), aucun volume créé, **aucun fichier de harnais conservé** dans le
dépôt, aucun secret affiché. Base relevée **0 / 0 / 0** avant et après la preuve §6, et les
campagnes d'essai interrompu supprimées (2 campagnes, 1 run, 20 lignes) — relevé final : `campaigns=0`,
`companies=0`, `runs=0`, `campaigns_due` vide.
