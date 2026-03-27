#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API_DIR="$ROOT/services/api"

MODE="${1:-host}"

usage() {
  cat <<EOF
Usage: $0 [host|guest]

host  Seed the database and launch the host review path.
guest Seed the database and launch the browse-only review path.

Examples:
  $0 host
  $0 guest
EOF
}

case "$MODE" in
  -h|--help|help)
    usage
    exit 0
    ;;
  host|guest)
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

if [ ! -f "$ROOT/.env" ]; then
  cp "$ROOT/.env.example" "$ROOT/.env"
  printf 'Created %s from .env.example.\n' "$ROOT/.env"
fi

if [ ! -f "$API_DIR/.env" ]; then
  cp "$API_DIR/.env.example" "$API_DIR/.env"
  printf 'Created %s from .env.example.\n' "$API_DIR/.env"
fi

if [ -s "${HOME}/.nvm/nvm.sh" ]; then
  # shellcheck disable=SC1090
  . "${HOME}/.nvm/nvm.sh"
fi

if command -v nvm >/dev/null 2>&1; then
  nvm use 20 >/dev/null
fi

printf 'Seeding preview database...\n'
(
  cd "$API_DIR"
  npm run db:reset:seed
)

case "$MODE" in
  guest)
    export PREVIEW_DEV_USER_EMAIL=
    printf 'Demo mode: guest browse-only review.\n'
    ;;
  host)
    export PREVIEW_DEV_USER_EMAIL="${PREVIEW_DEV_USER_EMAIL:-kevin.seed@example.com}"
    printf 'Demo mode: seeded host preview user (%s).\n' "$PREVIEW_DEV_USER_EMAIL"
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

printf 'Launching browser preview...\n'
"$ROOT/scripts/preview-up.sh"

cat <<EOF

Demo path:
1. Keep this terminal running while the preview stack stays up.
2. Open http://localhost:${WEB_PORT:-8080}
3. Use "$0 host" for seeded host review
4. Use "$0 guest" for browse-only review
5. Keep the acceptance checklist open at ${ROOT}/docs/mvp-acceptance-checklist.md
EOF
