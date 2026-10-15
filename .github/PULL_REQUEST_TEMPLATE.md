# Pull Request

Closes #<!-- numéro de ticket -->

## Résumé
<!-- Ce que fait cette PR, en 2-3 phrases. Le « pourquoi » avant le « comment ». -->

## Fichiers modifiés
<!-- Liste courte. Toute modification hors périmètre du ticket doit être justifiée ici. -->

## Preuves d'exécution
<!-- Coller la commande ET sa sortie. « Ça marche » n'est pas une preuve. -->

```
$ psql -v ON_ERROR_STOP=1 -f supabase/tests/rls.sql
…
```

```
$ # dès que le projet Node existe (S5)
$ pnpm lint && pnpm typecheck && pnpm test
…
```

## Points d'attention / risques
<!-- Ce que le Reviewer doit regarder en priorité. Ce qui reste incertain. -->

## Checks désactivés ou affaiblis ?
<!-- Si oui : lesquels et POURQUOI (exigence métier). Sinon : « aucun ». -->

## Definition of Done
- [ ] Critères d'acceptation du ticket validés
- [ ] Tests écrits et verts (CI verte)
- [ ] Aucun secret ajouté (`.env` non commité)
- [ ] RLS activée si nouvelle table ; aucune policy pour `anon`
- [ ] Documentation mise à jour si nécessaire
- [ ] Périmètre du ticket respecté
