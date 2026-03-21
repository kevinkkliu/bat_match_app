#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

API_BASE_URL="${API_BASE_URL:-http://10.0.2.2:3000}"
DEV_USER_EMAIL="${DEV_USER_EMAIL:-kevin.seed@example.com}"
DEVICE_ID="${ANDROID_DEVICE_ID:-}"

if [[ -z "$DEVICE_ID" ]]; then
  exec flutter run \
    --dart-define=API_BASE_URL="$API_BASE_URL" \
    --dart-define=DEV_USER_EMAIL="$DEV_USER_EMAIL" \
    "$@"
fi

exec flutter run \
  -d "$DEVICE_ID" \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=DEV_USER_EMAIL="$DEV_USER_EMAIL" \
  "$@"
