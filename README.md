# bat_dating_app

This repo now keeps only the Flutter client and TypeScript API.

## Structure

- `/mnt/d/Project/bat_dating_app/apps/mobile_flutter`
- `/mnt/d/Project/bat_dating_app/services/api`
- `/mnt/d/Project/bat_dating_app/prisma`
- `/mnt/d/Project/bat_dating_app/docs`

## Browser Preview

The browser preview is the primary review path. It runs the Flutter web build behind nginx and proxies `/api` to the API container on the same origin. The preview scripts create `.env` from `.env.example` if it is missing, so the first run stays one command.

```bash
cd /mnt/d/Project/bat_dating_app
./scripts/preview-up.sh
```

Open:

```text
http://localhost:8080
```

Helpful scripts:

```bash
./scripts/preview-up.sh
./scripts/preview-down.sh
./scripts/preview-reset.sh
```

## Local Flutter Web

Use this only when you want to run the Flutter web app directly against the local API process.

```bash
cd /mnt/d/Project/bat_dating_app/apps/mobile_flutter
flutter analyze
flutter test
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 7357 --dart-define=API_BASE_URL=http://localhost:3000
```

## API

```bash
cd /mnt/d/Project/bat_dating_app/services/api
source ~/.nvm/nvm.sh
nvm use 20
npm install
npm run db:up
npm run prisma:generate
npm run db:reset:seed
npm run dev
```

## Notes

- Local Postgres runs in Docker as `bat-dating-postgres`
- Seed data is created by `/mnt/d/Project/bat_dating_app/services/api/src/scripts/seed.ts`
- The old Expo/React Native prototype has been removed from the repo
