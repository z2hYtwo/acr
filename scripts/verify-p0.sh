#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
load_env
bash scripts/check-env.sh
docker compose config --quiet
docker compose up -d --wait --wait-timeout 150
if [[ "${1:-}" != --skip-tests ]]; then
  bash scripts/stop-dev.sh
  mvn -f backend/pom.xml verify -B
  (cd frontend && npm ci --no-audit --no-fund && npm run typecheck && npm run lint && npm run test -- --run && npm run build)
  (cd ai-engine && .venv/bin/python -m pytest -q)
  bash scripts/start-dev.sh --skip-build
fi
check() {
  local url="$1" expected="$2" token="${3:-}" status
  status="$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time 10 -H "Authorization: Bearer $token" "$url")"
  [[ "$status" == "$expected" ]] || { echo "HTTP $status expected $expected: $url" >&2; return 1; }
  printf '%s %s\n' "$status" "$url"
}
mkdir -p .run
{
  check "http://127.0.0.1:$BACKEND_PORT/api/v1/health" 200
  check "http://127.0.0.1:$FRONTEND_PORT/" 200
  check "http://127.0.0.1:$FRONTEND_PORT/api/v1/health" 200
  for port in "$BACKEND_PORT" "$AI_ENGINE_PORT"; do
    check "http://127.0.0.1:$port/internal/v1/health" 200 "$AI_ENGINE_TOKEN"
    check "http://127.0.0.1:$port/internal/v1/health" 401
    check "http://127.0.0.1:$port/internal/v1/health" 401 wrong
  done
} | tee .run/http-checks.txt
