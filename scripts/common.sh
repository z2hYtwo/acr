#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
load_env() {
  [[ -f .env ]] || { echo 'Create .env from .env.example first.' >&2; return 1; }
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    [[ "$line" =~ ^([A-Z][A-Z0-9_]*)=(.*)$ ]] || { echo 'Invalid .env line' >&2; return 1; }
    export "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
  done < .env
  for name in POSTGRES_DB POSTGRES_USER POSTGRES_PASSWORD AI_ENGINE_TOKEN; do
    [[ -n "${!name:-}" && "${!name}" != replace-with-* ]] || { echo "Configure $name" >&2; return 1; }
  done
  export DB_PORT="${DB_PORT:-5432}" BACKEND_PORT="${BACKEND_PORT:-8080}" AI_ENGINE_PORT="${AI_ENGINE_PORT:-8000}" FRONTEND_PORT="${FRONTEND_PORT:-5173}"
}
wait_http() {
  local url="$1" token="${2:-}" deadline=$((SECONDS+120))
  while ((SECONDS<deadline)); do
    if [[ -n "$token" ]]; then
      if curl --silent --fail --max-time 3 -H "Authorization: Bearer $token" "$url" >/dev/null; then return; fi
    elif curl --silent --fail --max-time 3 "$url" >/dev/null; then return; fi
    sleep .5
  done
  echo "Readiness timeout: $url" >&2; return 1
}
