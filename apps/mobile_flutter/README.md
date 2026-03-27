# bat_dating_app mobile

Flutter client for the stable-production path.

## Status

The app already covers the main MVP flows: game discovery, game detail, create game, my games, join requests, and profile/account actions. The UI is wired to the live API and the browser preview remains the primary review path.

## Stack

- Flutter
- `flutter_riverpod`
- `go_router`
- `dio`
- `flutter_secure_storage`

## Run

```bash
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 7357 --dart-define=API_BASE_URL=http://localhost:3000
```

For browser preview through the repo root stack, use `./scripts/preview-up.sh` and open `http://localhost:8080`. The preview script forces `API_BASE_URL` to stay empty so `/api` is always proxied on the same origin.

## Structure

- `lib/app`: app bootstrap, routing, shell
- `lib/core`: config, theme, network
- `lib/features`: feature-first pages
- `lib/shared`: shared models and widgets
