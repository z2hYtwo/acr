#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
load_env
bash scripts/check-env.sh
[[ ! -f .run/processes.tsv ]] || { echo 'Run stop-dev.sh first' >&2; exit 1; }
for port in "$BACKEND_PORT" "$AI_ENGINE_PORT" "$FRONTEND_PORT"; do
  if ss -ltnH "sport = :$port" | grep -q .; then echo "Port $port occupied" >&2; exit 1; fi
done
mkdir -p .run
docker compose up -d --wait --wait-timeout 150
if [[ "${1:-}" != --skip-build ]]; then
  mvn -f backend/pom.xml verify -B
  (cd frontend && npm ci --no-audit --no-fund && npm run build)
fi
trap 'bash "$ROOT/scripts/stop-dev.sh"' ERR
record() { printf '%s\t%s\n' "$1" "$(ps -p "$1" -o lstart=)" >> .run/processes.tsv; }
nohup java -jar backend/comic-boot/target/comic-boot-0.1.0-SNAPSHOT.jar >.run/backend.log 2>.run/backend.err.log &
record "$!"
wait_http "http://127.0.0.1:$BACKEND_PORT/api/v1/health"
(cd ai-engine && exec nohup .venv/bin/python -m uvicorn main:create_app --factory --host 127.0.0.1 --port "$AI_ENGINE_PORT") >.run/ai-engine.log 2>.run/ai-engine.err.log &
record "$!"
wait_http "http://127.0.0.1:$AI_ENGINE_PORT/internal/v1/health" "$AI_ENGINE_TOKEN"
(cd frontend && exec nohup node node_modules/vite/bin/vite.js) >.run/frontend.log 2>.run/frontend.err.log &
record "$!"
wait_http "http://127.0.0.1:$FRONTEND_PORT/"
wait_http "http://127.0.0.1:$FRONTEND_PORT/api/v1/health"
trap - ERR
echo "P0 ready: http://127.0.0.1:$FRONTEND_PORT/"
