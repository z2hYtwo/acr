#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
java -version 2>&1 | grep -q 'version "17\.' || { echo 'JDK 17 required' >&2; exit 1; }
javac -version
mvn -version
node --version | grep -Eq '^v(22|24)\.' || { echo 'Node 22/24 LTS required' >&2; exit 1; }
npm --version
ai-engine/.venv/bin/python --version | grep -q '^Python 3\.12\.'
docker compose version
docker info --format '{{.ServerVersion}}'
ffmpeg -version | head -1
command -v curl >/dev/null
command -v ss >/dev/null
command -v ps >/dev/null
echo 'Environment checks passed'
