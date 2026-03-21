#!/usr/bin/env bash
set -euo pipefail

unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy ALL_PROXY all_proxy
export DOCKER_HOST="${DOCKER_HOST:-unix:///var/run/docker.sock}"

if [ -x "${HOME}/.docker/cli-plugins/docker-compose" ]; then
  exec "${HOME}/.docker/cli-plugins/docker-compose" "$@"
fi

if docker compose version >/dev/null 2>&1; then
  exec docker compose "$@"
fi

echo "Docker Compose plugin not found. Install docker compose or place the plugin at ~/.docker/cli-plugins/docker-compose." >&2
exit 1
