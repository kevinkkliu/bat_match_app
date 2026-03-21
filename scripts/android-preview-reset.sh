#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

"${ROOT}/scripts/compose.sh" down -v
"${ROOT}/scripts/compose.sh" up -d postgres api

printf 'Android preview backend was reset and is available on http://10.0.2.2:%s\n' "${API_PORT:-3000}"
