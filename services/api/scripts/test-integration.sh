#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ROOT_ENV_FILE="$REPO_ROOT/.env"
cd "$REPO_ROOT/services/api"

ROOT_POSTGRES_PORT=""
if [ -f "$ROOT_ENV_FILE" ]; then
  ROOT_POSTGRES_PORT="$(
    grep -E '^POSTGRES_PORT=' "$ROOT_ENV_FILE" | tail -n 1 | cut -d '=' -f 2- | tr -d '\r'
  )"
fi

POSTGRES_PORT="${POSTGRES_PORT:-${ROOT_POSTGRES_PORT:-5433}}"

export NODE_ENV=test
export PORT=3000
export HOST=0.0.0.0
export DATABASE_URL="postgresql://postgres:postgres@localhost:${POSTGRES_PORT}/bat_dating_app_test"
export JWT_SECRET="bat-dating-test-secret-for-integration-only-1234567890"
export CORS_ORIGIN="http://localhost:7357,http://127.0.0.1:7357,http://localhost:8080"
export POSTGRES_PORT

bash ./scripts/db-up.sh

DOCKER_CMD=""
if command -v docker >/dev/null 2>&1; then
  DOCKER_CMD="docker"
elif command -v docker.exe >/dev/null 2>&1; then
  DOCKER_CMD="docker.exe"
else
  echo "docker command is required for integration tests." >&2
  exit 1
fi

"$DOCKER_CMD" exec bat-dating-postgres sh -lc '
  set -e
  if ! psql -U postgres -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '\''bat_dating_app_test'\''" | grep -q 1; then
    createdb -U postgres bat_dating_app_test
  fi
'

TMPDIR=/tmp TMP=/tmp TEMP=/tmp ./node_modules/.bin/prisma generate --schema ../../prisma/schema.prisma
TMPDIR=/tmp TMP=/tmp TEMP=/tmp ./node_modules/.bin/prisma db push --force-reset --schema ../../prisma/schema.prisma
for test_file in test/integration/*.test.ts; do
  TMPDIR=/tmp TMP=/tmp TEMP=/tmp node --test --import tsx "$test_file"
done
