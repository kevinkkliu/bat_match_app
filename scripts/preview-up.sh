#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .env ]; then
  cp .env.example .env
  printf 'Created .env from .env.example for browser preview.\n'
fi

PREVIEW_API_BASE_URL="${PREVIEW_API_BASE_URL:-}"
PREVIEW_DEV_USER_EMAIL="${PREVIEW_DEV_USER_EMAIL:-${DEV_USER_EMAIL:-kevin.seed@example.com}}"

API_BASE_URL="${PREVIEW_API_BASE_URL}" \
DEV_USER_EMAIL="${PREVIEW_DEV_USER_EMAIL}" \
  "$(dirname "$0")/compose.sh" up -d --build

printf 'Browser preview is available at http://localhost:%s\n' "${WEB_PORT:-8080}"

if [ -n "${PREVIEW_DEV_USER_EMAIL}" ]; then
  printf 'Preview mode user: %s\n' "${PREVIEW_DEV_USER_EMAIL}"
  printf 'Set PREVIEW_DEV_USER_EMAIL= to review the true guest flow.\n'
else
  printf 'Preview is running in guest mode.\n'
fi
