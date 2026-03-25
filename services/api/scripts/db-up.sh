#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/docker-compose.yml"
ENV_FILE="$REPO_ROOT/.env"
ENV_EXAMPLE="$REPO_ROOT/.env.example"
CONTAINER_NAME="bat-dating-postgres"
POSTGRES_DB_NAME="${POSTGRES_DB:-bat_dating_app}"
POSTGRES_USER_NAME="${POSTGRES_USER:-postgres}"

resolve_docker_cmd() {
  if command -v docker.exe >/dev/null 2>&1; then
    echo "docker.exe"
    return
  fi

  if command -v docker >/dev/null 2>&1; then
    echo "docker"
    return
  fi

  echo "Docker CLI is not available in PATH." >&2
  exit 1
}

DOCKER_CMD="$(resolve_docker_cmd)"

if [ ! -f "$ENV_FILE" ] && [ -f "$ENV_EXAMPLE" ]; then
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  echo "Created $ENV_FILE from .env.example."
fi

"$DOCKER_CMD" compose -f "$COMPOSE_FILE" up -d postgres >/dev/null
echo "Postgres container is starting."

for _ in $(seq 1 30); do
  if "$DOCKER_CMD" exec "$CONTAINER_NAME" \
    pg_isready -U "$POSTGRES_USER_NAME" -d "$POSTGRES_DB_NAME" >/dev/null 2>&1; then
    echo "Postgres is ready."
    exit 0
  fi
  sleep 1
done

echo "Postgres container did not become ready in time." >&2
exit 1
