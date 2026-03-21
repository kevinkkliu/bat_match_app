#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$REPO_ROOT/services/api"

export NODE_ENV=test
export PORT=3000
export HOST=0.0.0.0
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/bat_dating_app_test"
export JWT_SECRET="bat-dating-test-secret-for-integration-only-1234567890"
export CORS_ORIGIN="http://localhost:7357,http://127.0.0.1:7357,http://localhost:8080"

bash ./scripts/db-up.sh

docker exec bat-dating-postgres sh -lc '
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
