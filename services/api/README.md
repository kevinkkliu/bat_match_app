# bat_dating_app api

Stable-first backend skeleton based on:

- Fastify
- Zod
- Prisma
- PostgreSQL

## Commands

```bash
npm install
npm run db:up
npm run prisma:generate
npm run db:reset:seed
npm test
npm run typecheck
npm run dev
```

`npm test` uses a dedicated `bat_dating_app_test` database in the local Postgres container, resets it with Prisma, and runs the integration suite for join, approval, rejection, withdraw, and `me/games`.

`npm run db:up` creates the repo-root `.env` from `.env.example` if needed, then starts the compose-managed Postgres on local port `5433`.

## Browser Preview

The root preview stack serves Flutter web through nginx and keeps the browser on the same origin as the API. That means the preview build uses an empty `API_BASE_URL`, while local `flutter run -d web-server` can still point at `http://localhost:3000`.

The preview scripts create `.env` from `.env.example` if needed.

```bash
cd /mnt/d/Project/bat_dating_app
./scripts/preview-up.sh
```

The preview UI is available at `http://localhost:8080`.

## Local Flutter Web Integration

Default Flutter web dev server in this repo uses port `7357`.

Example `.env`:

```bash
PORT=3000
HOST=0.0.0.0
CORS_ORIGIN=http://localhost:7357,http://127.0.0.1:7357
```

## Seed Data

The seed creates:

- 3 users
- 3 upcoming games in Taipei/New Taipei
- approved and pending join requests for detail-page testing

After seeding, Flutter discovery/detail screens should show real data.

## Prisma source of truth

This service intentionally reuses the repo-level schema:

- `/mnt/d/Project/bat_dating_app/prisma/schema.prisma`

So there is only one Prisma schema during the transition period.
