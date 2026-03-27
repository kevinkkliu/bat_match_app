# bat_dating_app

This repo now keeps only the Flutter client and TypeScript API.

## Structure

- `<path_to_your_project>/apps/mobile_flutter`
- `<path_to_your_project>/services/api`
- `<path_to_your_project>/prisma`
- `<path_to_your_project>/docs`

## Demo Preview

This is the recommended QA and demo path. The root demo script reseeds the database, starts the same-origin preview, and keeps the browser review path on `http://localhost:8080`.

```bash
cd <path_to_your_project>
./scripts/demo-preview.sh host
```

Use guest mode for browse-only review:

```bash
cd <path_to_your_project>
./scripts/demo-preview.sh guest
```

What to remember:

- `host` seeds the preview host account and opens the full review path
- `guest` launches browse-only review with no preview login
- both modes reseed the database before launching the preview
- open `http://localhost:8080`
- run `./scripts/demo-preview.sh --help` if you forget the flags

QA checklist:

- [docs/mvp-acceptance-checklist.md](<path_to_your_project>/docs/mvp-acceptance-checklist.md)

Helpful scripts:

```bash
./scripts/preview-up.sh
./scripts/preview-down.sh
./scripts/preview-reset.sh
./scripts/demo-preview.sh host
./scripts/demo-preview.sh guest
```

Preview defaults:

- `DEV_USER_EMAIL=kevin.seed@example.com` so the browser opens in preview mode with a seeded host account
- Set `PREVIEW_DEV_USER_EMAIL=` before `./scripts/preview-up.sh` if you want to review the true guest flow without reseeding
- Seed accounts:
  - `kevin.seed@example.com` / host preview user
  - `mina.seed@example.com`
  - `sean.seed@example.com`

If you only want the preview stack without reseeding, use `./scripts/preview-up.sh`.

## Local Flutter Web

Use this only when you want to run the Flutter web app directly against the local API process.

```bash
cd <path_to_your_project>/apps/mobile_flutter
flutter analyze
flutter test
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 7357 --dart-define=API_BASE_URL=http://localhost:3000
```

## API

```bash
cd <path_to_your_project>/services/api
source ~/.nvm/nvm.sh
nvm use 20
npm install
npm run db:up
npm run prisma:generate
npm run db:reset:seed
npm run dev
```

The seeded browser-review path is the same demo preview flow above.

## Notes

- Local Postgres runs in Docker as `bat-dating-postgres`
- Seed data is created by `<path_to_your_project>/services/api/src/scripts/seed.ts`
- The old Expo/React Native prototype has been removed from the repo
