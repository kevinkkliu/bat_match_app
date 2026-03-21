#!/bin/sh
set -eu

cd /app/services/api

npx prisma db push --schema /app/prisma/schema.prisma
node dist/scripts/seed.js
exec node dist/server.js
