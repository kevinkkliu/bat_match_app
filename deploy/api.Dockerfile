FROM node:20-alpine AS build

WORKDIR /app

COPY services/api/package*.json /app/services/api/
WORKDIR /app/services/api
RUN npm ci

COPY services/api/ /app/services/api/
COPY prisma/ /app/prisma/

RUN npx prisma generate --schema /app/prisma/schema.prisma
RUN npm run build

FROM node:20-alpine AS runtime

WORKDIR /app
ENV NODE_ENV=production

COPY --from=build /app/services/api /app/services/api
COPY --from=build /app/prisma /app/prisma
COPY deploy/api-start.sh /usr/local/bin/bat-dating-api-start

RUN chmod +x /usr/local/bin/bat-dating-api-start

WORKDIR /app/services/api

EXPOSE 3000

CMD ["/usr/local/bin/bat-dating-api-start"]
