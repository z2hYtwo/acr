#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
if [[ -f .run/processes.tsv ]]; then
  while IFS=$'\t' read -r pid started; do
    [[ "$pid" =~ ^[0-9]+$ ]] || continue
    current="$(ps -p "$pid" -o lstart= || true)"
    if [[ -n "$current" && "$current" == "$started" ]]; then kill "$pid"; fi
  done < .run/processes.tsv
  rm -- .run/processes.tsv
fi
if [[ "${1:-}" == --stop-database ]]; then load_env; docker compose stop postgres; fi
echo 'Owned applications stopped; database volume preserved'
