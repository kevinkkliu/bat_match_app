import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import Fastify, { type FastifyInstance } from 'fastify';

import type { AppEnv } from './lib/config';
import { prisma } from './lib/prisma';
import { normalizeError } from './lib/http';
import { authRoutes } from './modules/auth/routes';
import { lineAuthRoutes } from './modules/auth/line';
import { gamesRoutes } from './modules/games/routes';
import { healthRoutes } from './modules/health/routes';
import { joinRequestRoutes } from './modules/join-requests/routes';
import { meRoutes } from './modules/me/routes';
import { usersRoutes } from './modules/users/routes';

export function buildApp(env: AppEnv): FastifyInstance {
  const app = Fastify({
    logger: env.NODE_ENV === 'development',
  });

  const corsOrigin =
    env.CORS_ORIGIN.trim() === '*'
      ? true
      : env.CORS_ORIGIN
          .split(',')
          .map((value) => value.trim())
          .filter((value) => value.length > 0);

  void app.register(cors, {
    origin: corsOrigin,
    credentials: true,
  });
  void app.register(jwt, {
    secret: env.JWT_SECRET,
  });

  app.addHook('onClose', async () => {
    await prisma.$disconnect();
  });

  app.get('/', async () => {
    return {
      name: 'bat-dating-api',
      status: 'ok',
    };
  });

  void app.register(healthRoutes, { prefix: '/api/v1/health' });
  void app.register(authRoutes, { prefix: '/api/v1/auth' });
  void app.register(lineAuthRoutes, { prefix: '/api/v1/auth' });
  void app.register(gamesRoutes, { prefix: '/api/v1/games' });
  void app.register(joinRequestRoutes, { prefix: '/api/v1/join-requests' });
  void app.register(meRoutes, { prefix: '/api/v1/me' });
  void app.register(usersRoutes, { prefix: '/api/v1/users' });

  app.setErrorHandler((error, request, reply) => {
    request.log.error(error);

    const normalized = normalizeError(error);

    if (normalized) {
      return reply.status(normalized.statusCode).send({
        error: normalized.errorCode,
        message: normalized.message,
        details: normalized.details ?? null,
      });
    }

    return reply.status(500).send({
      error: 'INTERNAL_SERVER_ERROR',
      message: 'Unexpected server error.',
    });
  });

  return app;
}
