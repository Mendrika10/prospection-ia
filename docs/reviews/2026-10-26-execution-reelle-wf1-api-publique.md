# Exécution réelle de WF1 contre l'API publique — première preuve de bout en bout

> Objet : le **garde-fou de clôture de `D-011`** (« le vérifié d'un ticket de collecte est une
> exécution de bout en bout ») et la **condition de retour de `D-013`** pour `S1-07`. Date :
> **2026-10-26**. Demandé explicitement : 1 campagne, 1 couple, ≤ 25 éléments, puis **remise en état
> de la base**. C'est cette exécution qui **révise `D-014`** par **`D-015`**.
>
> **Requalifié le même jour — à lire avant de citer le défaut A** : le « défaut A » de ce relevé
> n'en est pas un. Le nœud HTTP de n8n **bascule bien d'adresse** (`10/10` sans épinglage, trace
> réseau à l'appui) ; la panne d'adresses de ce jour-là était **transitoire**. Voir
> [`2026-10-26-requalification-defaut-a-bascule-adresse.md`](2026-10-26-requalification-defaut-a-bascule-adresse.md)
> et `D-016`. Le **défaut B**, lui, reste entier — c'est toujours la preuve de `S2-02`.

## Ce qui a été lancé, et comment

| Élément | Mise en œuvre |
|---|---|
| n8n | conteneur **jetable** (`docker run --rm`), image `docker.n8n.io/n8nio/n8n:latest` — **celle du `docker-compose.yml` du dépôt** |
| Workflow | l'**export versionné** `n8n/workflows/wf1-collecte.json`, importé tel quel — **une seule** copie, dans le conteneur, avec **un seul ajout** : un nœud `executeWorkflowTrigger` (25 → 26 nœuds) branché sur « Campagnes dues (campaigns_due) », parce que le CLI `n8n execute` exige un déclencheur exécutable (le `scheduleTrigger` du workflow ne l'est pas en ligne de commande) |
| Credential Supabase | construit **dans le conteneur** à partir du `.env` monté en lecture seule, avec l'`id` attendu par le workflow ; **aucune valeur n'a été affichée ni écrite dans le dépôt** |
| Campagne | créée par PostgREST (`service_role`), `active`, `interval_minutes = 1440`, sans filtre d'effectif — donc **due** (`campaigns_due` la renvoie) |
| Base avant | **0 campagne, 0 entreprise, 0 run** (relevé avant chaque essai) |
| Base après | remise à **0 / 0 / 0** (voir § Nettoyage) |

## Les quatre exécutions

| # | Couple | Résolution du nom | Durée | Ligne `runs` | Entreprises écrites |
|---|---|---|---|---|---|
| **1** | `43.21A` × `974` | DNS réel | 50 s | `status = error` — « 1 couple(s) en echec — 43.21A\|974 : `timeout of 10000ms exceeded` — ECONNABORTED » | **0** |
| **2** | `43.21A` × `974` | DNS réel | 51 s | idem (message identique) | **0** |
| **3** | `43.21A` × `974` | nom **épinglé** sur l'adresse vivante (`.76`) | 125 s | `status = error` — « echec de collecte WF1 : **60 page(s) sans couple rattachable** (pairedItem perdu) — collecte interrompue » | **0** |
| **4** | `41.20A` × `48` | nom épinglé sur `.76` | **6,5 s** | **`status = success`**, `items_processed = 20`, `error = null`, `details = {recuperees: 22, ecartees: 2, bandes_appliquees: []}` | **20** |

### Extrait du run 4 (`runs`, lu en base)

```json
{"workflow":"wf1-collecte","status":"success","items_processed":20,"error":null,
 "details":{"recuperees":22,"ecartees":2,"bandes_appliquees":[]},
 "started_at":"2026-10-26T14:20:13.629238+00:00","finished_at":"2026-10-26T14:20:20.133+00:00"}
```

### Extrait des `companies` écrites (3 lignes sur 20)

```json
{"siren":"411535297","name":"HERVE CHABALIER","naf":"41.20A","city":"LUC","postal_code":"48250","effectif":"NN","campaign_id":"6973bffc-…","website":null}
{"siren":"341410983","name":"BATIR 48","naf":"41.20A","city":"MENDE","postal_code":"48000","effectif":"NN","campaign_id":"6973bffc-…","website":null}
{"siren":"930384987","name":"JB TRAVAUX","naf":"41.20A","city":"LANGOGNE","postal_code":"48300","effectif":"NN","campaign_id":"6973bffc-…","website":null}
```

Les 20 lignes portent **le `campaign_id` de la campagne** (passe de propriété d'ADR 0007) et
**`website` reste `null`** : les colonnes enrichies ne sont jamais touchées (D-009).

## Ce que cette exécution prouve

1. **La chaîne complète fonctionne, de l'API publique à la base.** Collecte HTTP réelle →
   filtrage et compteurs (`recuperees = 22`, `ecartees = 2`) → upsert par SIREN → passe de
   propriété → conciliation → clôture de campagne : **20 lignes écrites**, `runs.status = success`,
   `items_processed = 20`, cohérent avec les compteurs. C'est la **première fois** que la chaîne
   tourne d'un bout à l'autre contre l'API publique — et c'est le garde-fou de `D-011` qui l'a
   rendu possible en imposant l'exécution.
2. **Le run dit la vérité dans les deux sens.** En échec (runs 1 à 3) : `status = error`, message
   exploitable, **rien d'écrit** — jamais de « succès » muet. En réussite (run 4) : compteurs
   cohérents et `error = null`.
3. **Le défaut critique de `S1-04` est bien corrigé** : c'est exactement lui qui transforme
   aujourd'hui les trois échecs en erreurs lisibles au lieu de « `success`, 0 élément ».

## Défaut A — le nœud HTTP de n8n ne bascule pas d'adresse : la collecte échoue

> **Ce titre est faux, et il est conservé comme tel** : la mesure du même jour montre que le nœud
> HTTP de n8n **bascule** (`D-016`) — ce qui suit décrit un symptôme **réel**, pas sa cause. La
> cause retenue ici (« le nœud ne bascule pas ») a été **réfutée** ; lire la
> [requalification](2026-10-26-requalification-defaut-a-bascule-adresse.md) avant de s'appuyer sur
> cette section.

Mesuré, deux fois, à 3 minutes d'intervalle :

- **3 tentatives par exécution** (le `retryOnFail ×3` du ticket `S1-04`) et **3 timeouts** :
  le message d'erreur apparaît **3 fois** dans la sortie du run 2, et la durée (~50 s) correspond à
  3 × 10 s de timeout + 2 × 5 s de délai fixe.
- Le couple n'est jamais collecté : `recuperees = 0`, `items_processed = 0`, `runs.status = error`.
- **Seul** un épinglage du nom sur l'adresse vivante (`--add-host …:37.59.183.76`, donc **sans
  toucher au workflow**) fait réussir l'appel : c'est ce qui a permis les runs 3 et 4.

Conséquence pour `D-014` : sa conclusion — « le client bascule tout seul sur l'adresse vivante,
donc rien ne casse » — était **vraie pour un client Node nu** (8 appels sur 8) et **fausse pour le
nœud HTTP de n8n**, qui est le seul client qui compte. Le timeout de 10 s n'est pas le problème :
l'adresse choisie ne répond jamais. `D-014` est donc **révisée par `D-015`**.

## Défaut B — `pairedItem.item` d'un nœud HTTP paginé est l'index de **page**, pas celui du couple

Mesuré par différence, avec deux mini-workflows jetables (même nœud HTTP, même pagination que WF1) :

| Montage | Ce que `pairedItem.item` vaut | Ce que WF1 en déduit |
|---|---|---|
| 1 couple → **2 pages** | page 1 → `{item: 0}` · page 2 → **`{item: 1}`** | page 1 : le couple. Page 2 : **plus rien** (`couplesPrep[1]` n'existe pas) → « sans couple rattachable » → **le run s'arrête** |
| 2 couples (`A` sur 2 pages, `B` sur 1 page) | pages → `{item: 0}`, **`{item: 1}`** | page 2 de `A` est attribuée à **`B`** — ce n'est pas une absence, c'est une **mauvaise attribution** |

`Filtrage et compteurs` lit `pairedItem.item` comme l'index du couple dans « Préparation de
collecte » (choix de `S1-04`). Pour un nœud paginé, n8n y met le **numéro de page**. Conséquences :

- **Cas 1 couple** (runs 1 à 3) : les pages 2..N sont hors bornes → le garde-fou anti-silence
  **abandonne** la collecte avec un message clair. C'est le comportement voulu (mieux vaut ne rien
  écrire), et c'est ce qu'on a vu sur `43.21A × 974`.
- **Cas ≥ 2 couples** : les pages d'un couple peuvent être attribuées à un **autre** couple. Le
  contrôle anti-silence ne l'attrape que si les codes NAF diffèrent ; si le NAF est le même, c'est
  le **département du mauvais couple** qui décide du filtre de siège d'ADR 0005 — donc des lignes
  gardées ou écartées à tort, **silencieusement**.
- Ce défaut n'était pas visible en `S1-02` / `S1-03` / `S1-04` : **aucun de ces essais n'a produit
  plus d'une page par couple**. La preuve `S1-06` portait sur 13 résultats (une page).

### Et la réalité des volumes invalide la prémisse « ≤ 25 éléments »

Sonde sur l'API (adresse vivante), mêmes paramètres que WF1 :

| Requête | `total_results` | Pages |
|---|---|---|
| `43.21A` × `974` | **1 515** | **61** (25 par page ; page 61 → 15 ; page 100 → 0) |
| `41.20A` × `48` | **22** | 1 |
| `41.20A` × `15` | **14** | 1 |

Sur **30 couples** testés (3 codes NAF × 10 départements), **2 seulement** tiennent sur une page :
26 à 1 568 résultats partout ailleurs. La pagination n'est donc pas un cas de bord, c'est le
**cas normal** — et le défaut B frappe la quasi-totalité des campagnes réelles. Filtre d'effectif à
l'appui : sur `43.21A` × `974`, les bandes hautes ne ramènent pas à une page sans écarter aussi les
sièges locaux (bandes `51,52,53` → 1 résultat, siège en `68` → **0 ligne** après ADR 0005).

## Ce que cette preuve ne dit pas (limites)

- **Le chemin de production n'est pas exercé** : l'exécution passe par un déclencheur ajouté à une
  copie et par le CLI, pas par le `scheduleTrigger` d'un workflow **activé**. Le cron, l'activation
  et l'error workflow (`WF5`) ne sont donc **pas** couverts ici.
- **L'épinglage DNS n'est pas une configuration de production.** Il sert à isoler la cause ; il ne
  corrige rien et n'a pas été livré.
- **Un seul réseau, une seule fenêtre** (2026-10-26, ~14 h) et **une seule image** (`latest`, node
  v26.7.0), alors que la preuve de `S1-04` utilisait n8n **2.43.5**.
- **Un seul couple réussi** (`41.20A` × `48`), choisi justement parce qu'il tient sur une page : la
  chaîne est prouvée, la **collecte d'une campagne réelle** ne l'est pas.
- Aucun test de charge, aucune mesure de coût, et la table `blocklist`, les statuts de lead et la
  RLS ne sont pas concernés par cette exécution.

## Nettoyage — remise en état de la base

```
avant  : {"campaigns":1,"companies":20,"runs":1}
delete companies campaign_id=6973bffc-… → 200 · 20 lignes
delete runs      campaign_id=6973bffc-… → 200 ·  1 ligne
delete campaigns id=6973bffc-…          → 200 ·  1 ligne
après  : {"campaigns":0,"companies":0,"runs":0}   → relevé final : 0 / 0 / 0, campaigns_due vide
```

Aucune trace laissée : conteneurs `--rm` tous arrêtés (aucun volume nommé créé), scripts de sonde
supprimés du dépôt, aucun secret affiché ni écrit.
