#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/docker-compose.yml"

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

if "$DOCKER_CMD" compose -f "$COMPOSE_FILE" ps -a postgres >/dev/null 2>&1; then
  "$DOCKER_CMD" compose -f "$COMPOSE_FILE" rm -sf postgres >/dev/null
  echo "Postgres container removed."
  exit 0
fi

echo "Postgres container does not exist."
