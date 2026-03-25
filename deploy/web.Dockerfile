FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY apps/mobile_flutter/pubspec.yaml apps/mobile_flutter/pubspec.lock /app/apps/mobile_flutter/
WORKDIR /app/apps/mobile_flutter
RUN flutter pub get

COPY apps/mobile_flutter/ /app/apps/mobile_flutter/

ARG API_BASE_URL=
ARG DEV_USER_EMAIL=kevin.seed@example.com

RUN flutter build web --release \
  --dart-define=API_BASE_URL="${API_BASE_URL}" \
  --dart-define=DEV_USER_EMAIL="${DEV_USER_EMAIL}"

FROM nginx:1.27-alpine AS runtime

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/apps/mobile_flutter/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
