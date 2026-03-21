import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';

import { assertAuthenticatedUser, requireAuth } from '../../lib/auth';
import { JoinRequestsService } from './service';

const joinRequestIdSchema = z.object({
  joinRequestId: z.string().uuid(),
});

const rejectBodySchema = z.object({
  reason: z.string().trim().min(1).max(300).optional(),
});

const joinRequestsService = new JoinRequestsService();

export const joinRequestRoutes: FastifyPluginAsync = async (app) => {
  app.patch('/game/:gameId/withdraw', { preHandler: requireAuth }, async (request) => {
    const { gameId } = z.object({ gameId: z.string().uuid() }).parse(request.params);
    const { userId } = assertAuthenticatedUser(request);
    return joinRequestsService.withdrawForGame(userId, gameId);
  });

  app.patch('/:joinRequestId/approve', { preHandler: requireAuth }, async (request) => {
    const { joinRequestId } = joinRequestIdSchema.parse(request.params);
    const { userId } = assertAuthenticatedUser(request);
    return joinRequestsService.approve(userId, joinRequestId);
  });

  app.patch('/:joinRequestId/reject', { preHandler: requireAuth }, async (request) => {
    const { joinRequestId } = joinRequestIdSchema.parse(request.params);
    const body = rejectBodySchema.parse(request.body);
    const { userId } = assertAuthenticatedUser(request);
    return joinRequestsService.reject(userId, joinRequestId, body.reason);
  });

  app.patch('/:joinRequestId/withdraw', { preHandler: requireAuth }, async (request) => {
    const { joinRequestId } = joinRequestIdSchema.parse(request.params);
    const { userId } = assertAuthenticatedUser(request);
    return joinRequestsService.withdraw(userId, joinRequestId);
  });
};
