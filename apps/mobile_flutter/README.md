# bat_dating_app mobile

Flutter app skeleton for the stable-production path.

## Stack

- Flutter
- `flutter_riverpod`
- `go_router`
- `dio`
- `flutter_secure_storage`

## Run

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

For browser preview through the repo root stack, use `./scripts/preview-up.sh` and open `http://localhost:8080`. The preview scripts create `.env` from `.env.example` if needed, and the browser build keeps `API_BASE_URL` empty so `/api` is proxied on the same origin.

## Structure

- `lib/app`: app bootstrap, routing, shell
- `lib/core`: config, theme, network
- `lib/features`: feature-first pages
- `lib/shared`: shared models and widgets
