#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .env ]; then
  cp .env.example .env
  printf 'Created .env from .env.example for browser preview.\n'
fi

"$(dirname "$0")/compose.sh" up -d --build
printf 'Browser preview is available at http://localhost:%s\n' "${WEB_PORT:-8080}"
