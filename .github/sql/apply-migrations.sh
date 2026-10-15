#!/usr/bin/env bash
# =============================================================================
# Applique toutes les migrations de supabase/migrations/, dans l'ordre alphabétique
# (= ordre chronologique des préfixes AAAAMMJJHHMMSS).
#
# Utilisé DEUX fois par le job CI `sql` :
#   1. sur une base neuve, avant le seed ;
#   2. après le seed, sur une base DÉJÀ PEUPLÉE — le scénario réel d'un projet Supabase
#      en service qui reçoit une migration alors qu'il contient déjà des données.
#
# Conséquence, et c'est une règle du dépôt (AGENTS.md §4) : une migration doit être
# RÉAPPLICABLE sans perte ni duplication. D'où les `if not exists`, les blocs
# `do $$ … if not exists … $$`, les `create or replace`, et des migrations de données
# écrites pour être rejouables (`insert … on conflict do nothing`, `update` idempotent).
#
# Sort en code ≠ 0 au premier échec : c'est la CI qui décide, pas l'œil.
# Rappel : garder ce fichier en LF (voir .gitattributes) — un shebang en CRLF échoue
# en CI avec « bad interpreter ».
# =============================================================================
set -euo pipefail

shopt -s nullglob
files=(supabase/migrations/*.sql)

if [ ${#files[@]} -eq 0 ]; then
  echo "::error::Aucune migration trouvée dans supabase/migrations/"
  exit 1
fi

for f in "${files[@]}"; do
  echo "→ $f"
  psql -v ON_ERROR_STOP=1 -q -f "$f"
done
