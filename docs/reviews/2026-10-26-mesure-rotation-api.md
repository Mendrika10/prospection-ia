# Mesure — joignabilité des trois adresses de l'API Recherche d'entreprises

> Objet : le **ticket de mesure** annoncé par `D-012` (« la rotation d'adresses se mesure avant
> d'être décidée »). Date : **2026-10-26**. Aucune écriture en base, aucun conteneur n8n permanent,
> aucun fichier temporaire conservé. C'est cette mesure qui **révise `D-012`** par **`D-014`**.

## La question posée, en une phrase

`recherche-entreprises.api.gouv.fr` résout **trois adresses** et, le 2026-10-26, **deux ne répondaient
pas**. Question : depuis l'hôte qui exécute WF1, l'appel de collecte **échoue-t-il** ? Et un réessai
atteint-il une autre adresse ?

## Protocole

1. Les adresses de l'enregistrement `A`, puis **ce que le client obtient réellement** :
   `dns.lookup` (c'est ce qu'utilise le nœud HTTP de n8n — une seule adresse, celle du résolveur).
2. **Chaque adresse forcée une par une** (`Host` + SNI conservés, certificat vérifié) : 3 essais,
   timeout 12 s. C'est ce qui distingue « adresse muette » de « délai trop court ».
3. **8 appels par le nom**, exactement comme les fait la collecte (timeout 10 s, l'`User-Agent` de
   WF1), en relevant **l'adresse réellement jointe**.
4. **Contrôle TCP pur** (`net.connect` sur `:443`, 5 s) sur les trois adresses : une adresse peut être
   muette au niveau TCP (SYN sans réponse) ou refuser à un autre niveau.
5. Exécuté **deux fois** : sur l'**hôte**, et **dans le conteneur n8n** (`docker.n8n.io/n8nio/n8n`,
   même chemin réseau que la collecte, même runtime Node).

## Relevé 1 — sur l'hôte (node v24.12.0, `autoSelectFamily` par défaut : `true`)

```
A records       : ["37.59.183.76","37.59.183.78","37.59.183.77"]
dns.lookup × 5  : ["37.59.183.78","37.59.183.78","37.59.183.78","37.59.183.78","37.59.183.78"]

-- chaque adresse forcée, 3 essais, timeout 12 s --
  37.59.183.76  essai 1 → HTTP 200  787 ms        essai 2 → HTTP 200  530 ms      essai 3 → HTTP 200  651 ms
  37.59.183.77  essai 1 → ERREUR TIMEOUT 12010 ms essai 2 → ERREUR TIMEOUT 12004 ms essai 3 → ERREUR TIMEOUT 12002 ms
  37.59.183.78  essai 1 → ERREUR TIMEOUT 12004 ms essai 2 → ERREUR TIMEOUT 12004 ms essai 3 → ERREUR TIMEOUT 12005 ms

-- 8 appels par le nom, timeout 10 s (conditions de production) --
  essai 1 → HTTP 200 1196 ms  adresse 37.59.183.76
  essai 2 → HTTP 200  331 ms  adresse 37.59.183.76
  essai 3 → HTTP 200  276 ms  adresse 37.59.183.76
  essai 4 → HTTP 200  266 ms  adresse 37.59.183.76
  essai 5 → HTTP 200  265 ms  adresse 37.59.183.76
  essai 6 → HTTP 200  263 ms  adresse 37.59.183.76
  essai 7 → HTTP 200  656 ms  adresse 37.59.183.76
  essai 8 → HTTP 200  265 ms  adresse 37.59.183.76

-- contrôle TCP (net.connect :443, timeout 5 s) --
  37.59.183.76 → connectée                      199 ms
  37.59.183.77 → timeout (SYN sans réponse)    5001 ms
  37.59.183.78 → timeout (SYN sans réponse)    5001 ms

BILAN : 8/8 en HTTP 200 · 0 échec · adresses jointes ["37.59.183.76"]
```

## Relevé 2 — dans le conteneur n8n (node v26.7.0, même chemin réseau que la collecte)

```
A records       : ["37.59.183.77","37.59.183.76","37.59.183.78", …]
dns.lookup × 5  : ["37.59.183.77","37.59.183.77","37.59.183.77","37.59.183.77","37.59.183.77"]

-- 8 appels par le nom, timeout 10 s --
  essai 1 → HTTP 200 1247 ms  adresse 37.59.183.76
  essai 2 → HTTP 200  280 ms  adresse 37.59.183.76
  essai 3 → HTTP 200  264 ms  adresse 37.59.183.76
  essai 4 → HTTP 200  268 ms  adresse 37.59.183.76
  essai 5 → HTTP 200  285 ms  adresse 37.59.183.76
  essai 6 → HTTP 200  374 ms  adresse 37.59.183.76
  essai 7 → HTTP 200  260 ms  adresse 37.59.183.76
  essai 8 → HTTP 200  283 ms  adresse 37.59.183.76

-- contrôle TCP --
  37.59.183.76 → connectée                      209 ms
  37.59.183.77 → timeout (SYN sans réponse)    5002 ms
  37.59.183.78 → timeout (SYN sans réponse)    5006 ms

BILAN : 8/8 en HTTP 200 · 0 échec · adresses jointes ["37.59.183.76"]
```

## Ce que la mesure établit

1. **La panne d'adresses est réelle, et c'est bien une panne TCP.** `.77` et `.78` ne répondent
   **jamais** : 6 essais sur 6 en `TIMEOUT` à 12 s, et **SYN sans réponse** au contrôle TCP pur — donc
   ce n'est ni un problème de certificat, ni un serveur lent, ni une page d'erreur applicative.
   `.76`, lui, répond en **199–209 ms** au TCP et en **263–656 ms** en HTTP. La mesure du 2026-10-26
   (15,0 s et 12,7 s) reste donc exacte.
2. **Le résolveur renvoie une adresse MUETTE en premier** — `.78` sur l'hôte (5 fois sur 5), `.77`
   dans le conteneur (5 fois sur 5). Un client qui prend la première adresse et s'y tient **échoue**.
3. **Et pourtant la collecte réussit 8 fois sur 8, des deux côtés.** Chaque appel est allé sur
   `.76` : le client **bascule tout seul** d'adresse quand la première ne répond pas
   (`autoSelectFamily`, actif par défaut depuis Node 20 — `true` sur les deux relevés). C'est
   **cette bascule**, et non une rotation du résolveur, qui sauve l'appel.
4. **La marge du timeout est large** : 265 ms en régime établi, **1 196 / 1 247 ms au premier appel**
   (`cold` : DNS + TLS). Le timeout de **10 s** du ticket `S1-02` offre donc environ **8×** la marge
   nécessaire, y compris à froid.
5. **L'API n'est joignable que par une adresse sur trois.** C'est le vrai risque mis au jour : la
   bascule du client **masque** cette dépendance. Le jour où `.76` devient muet, il n'existe plus
   aucune adresse de repli et la collecte ne peut plus rien faire.

## Ce que la mesure ne prouve pas (limites)

- **Le dernier maillon n'est pas prouvé ici** : ces 8/8 sont obtenus avec un client Node configuré
  comme le nœud HTTP de n8n, **pas par le nœud HTTP lui-même**. Une exécution réelle de WF1 sur l'API
  publique reste la seule preuve de bout en bout — et c'est déjà la condition de retour de `D-013`.
- **Version de runtime** : le conteneur mesuré est l'image présente en local (`latest`, node
  **v26.7.0**) ; la preuve de `S1-04` utilisait **n8n 2.43.5**. La bascule existe depuis Node 20 et les
  deux relevés la montrent active, mais la version exacte de `2.43.5` n'a pas été mesurée ici.
- **Une seule fenêtre temporelle** (2026-10-26, ~13 h 53) et **un seul réseau**. Un état par
  échantillon de 8 appels : cela donne un ordre de grandeur de la latence, pas une distribution.
- **Aucune écriture en base**, aucun `runs` produit : ce document ne prouve pas la collecte, il
  qualifie son maillon réseau.

## Ce que la mesure change

| Décision | Avant la mesure | Après la mesure |
|---|---|---|
| **`D-012`** | « 10 s conservés ; une part des runs sortira en `error`, à surveiller » | **révisée par `D-014`** : la prédiction ne se vérifie pas — la panne est **absorbée par le client**, aucun run en `error` ne vient de là |
| Ticket de mesure | « à ouvrir au sprint 2 » | **clos par cette mesure** : il n'y a pas de rotation à ajouter |
| Risque | « hypothèse : défaut réseau/API, pas WF1 » | **confirmé, et précisé** : l'API dépend d'**une** adresse vivante sur trois, dépendance masquée par la bascule du client |
