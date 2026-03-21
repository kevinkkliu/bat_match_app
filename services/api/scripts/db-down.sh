#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="bat-dating-postgres"

if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
  docker rm -f "$CONTAINER_NAME" >/dev/null
  echo "Postgres container removed."
  exit 0
fi

echo "Postgres container does not exist."
