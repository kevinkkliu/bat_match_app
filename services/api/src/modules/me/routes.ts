import type { FastifyPluginAsync } from 'fastify';

import { assertAuthenticatedUser, requireAuth } from '../../lib/auth';
import { MeService } from './service';

const meService = new MeService();

export const meRoutes: FastifyPluginAsync = async (app) => {
  app.get('/games/joined', { preHandler: requireAuth }, async (request) => {
    const { userId } = assertAuthenticatedUser(request);
    return meService.listJoinedGames(userId);
  });

  app.get('/games/created', { preHandler: requireAuth }, async (request) => {
    const { userId } = assertAuthenticatedUser(request);
    return meService.listCreatedGames(userId);
  });

  app.patch<{ Body: { fcmToken: string } }>(
    '/fcm-token',
    { preHandler: requireAuth },
    async (request) => {
      const { userId } = assertAuthenticatedUser(request);
      const { fcmToken } = request.body;
      return meService.updateFcmToken(userId, fcmToken);
    }
  );
};
