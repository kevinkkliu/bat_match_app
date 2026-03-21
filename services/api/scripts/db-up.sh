#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="bat-dating-postgres"
VOLUME_NAME="bat_dating_postgres_data"

if ! docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
  docker volume create "$VOLUME_NAME" >/dev/null
fi

if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
  echo "Postgres container is already running."
  for _ in $(seq 1 30); do
    if docker exec "$CONTAINER_NAME" pg_isready -U postgres -d bat_dating_app >/dev/null 2>&1; then
      echo "Postgres is ready."
      exit 0
    fi
    sleep 1
  done
  echo "Postgres container is running but did not become ready in time." >&2
  exit 1
fi

if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
  docker start "$CONTAINER_NAME" >/dev/null
  echo "Postgres container started."
  for _ in $(seq 1 30); do
    if docker exec "$CONTAINER_NAME" pg_isready -U postgres -d bat_dating_app >/dev/null 2>&1; then
      echo "Postgres is ready."
      exit 0
    fi
    sleep 1
  done
  echo "Postgres container started but did not become ready in time." >&2
  exit 1
fi

docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -e POSTGRES_DB=bat_dating_app \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e TZ=Asia/Taipei \
  -p 5432:5432 \
  -v "$VOLUME_NAME:/var/lib/postgresql/data" \
  postgres:16-alpine >/dev/null

echo "Postgres container created and started."

for _ in $(seq 1 30); do
  if docker exec "$CONTAINER_NAME" pg_isready -U postgres -d bat_dating_app >/dev/null 2>&1; then
    echo "Postgres is ready."
    exit 0
  fi
  sleep 1
done

echo "Postgres container started but did not become ready in time." >&2
exit 1
