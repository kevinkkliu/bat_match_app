#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v flutter >/dev/null 2>&1; then
  # shellcheck disable=SC1090
  . "${HOME}/.bashrc"
fi

DEVICE_ID="${1:-}"
API_BASE_URL="${API_BASE_URL:-http://10.0.2.2:3000}"
DEV_USER_EMAIL="${DEV_USER_EMAIL:-kevin.seed@example.com}"

"${ROOT}/scripts/android-preview-up.sh"

if [ -z "${DEVICE_ID}" ]; then
  if command -v adb >/dev/null 2>&1; then
    DEVICE_ID="$(adb devices | awk '/^emulator-/ && $2 == "device" { print $1; exit }')"
  fi
fi

DEVICE_ID="${DEVICE_ID:-emulator-5554}"

cd "${ROOT}/apps/mobile_flutter"
exec flutter run \
  -d "${DEVICE_ID}" \
  --dart-define=API_BASE_URL="${API_BASE_URL}" \
  --dart-define=DEV_USER_EMAIL="${DEV_USER_EMAIL}"
