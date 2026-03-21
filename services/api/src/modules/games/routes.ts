import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';

import { assertAuthenticatedUser, requireAuth, resolveOptionalAuthUser } from '../../lib/auth';
import { GamesService } from './service';
import {
  createGameBodySchema,
  gameIdParamsSchema,
  gamesQuerySchema,
  patchGameBodySchema,
  patchGameStatusBodySchema,
} from './schemas';

const joinBodySchema = z.object({
  message: z.string().trim().min(1).max(300).optional(),
});

const gamesService = new GamesService();

export const gamesRoutes: FastifyPluginAsync = async (app) => {
  app.get('/', async (request) => {
    const query = gamesQuerySchema.parse(request.query);
    return gamesService.list(query);
  });

  app.get('/:gameId', async (request) => {
    const { gameId } = gameIdParamsSchema.parse(request.params);
    const authUser = await resolveOptionalAuthUser(request);
    return gamesService.detail(gameId, authUser?.userId);
  });

  app.post('/', { preHandler: requireAuth }, async (request, reply) => {
    const body = createGameBodySchema.parse(request.body);
    const { userId } = assertAuthenticatedUser(request);
    const result = await gamesService.create(userId, body);
    return reply.status(201).send(result);
  });

  app.patch('/:gameId', { preHandler: requireAuth }, async (request) => {
    const { gameId } = gameIdParamsSchema.parse(request.params);
    const body = patchGameBodySchema.parse(request.body);
    const { userId } = assertAuthenticatedUser(request);
    return gamesService.update(userId, gameId, body);
  });

  app.patch('/:gameId/status', { preHandler: requireAuth }, async (request) => {
    const { gameId } = gameIdParamsSchema.parse(request.params);
    const body = patchGameStatusBodySchema.parse(request.body);
    const { userId } = assertAuthenticatedUser(request);
    return gamesService.updateStatus(userId, gameId, body);
  });

  app.post('/:gameId/join', { preHandler: requireAuth }, async (request, reply) => {
    const { gameId } = gameIdParamsSchema.parse(request.params);
    const body = joinBodySchema.parse(request.body);
    const { userId } = assertAuthenticatedUser(request);
    const result = await gamesService.join(userId, gameId, body.message);
    return reply.status(201).send(result);
  });

  app.get('/:gameId/join-requests', { preHandler: requireAuth }, async (request) => {
    const { gameId } = gameIdParamsSchema.parse(request.params);
    const { userId } = assertAuthenticatedUser(request);
    return gamesService.listJoinRequests(userId, gameId);
  });
};
