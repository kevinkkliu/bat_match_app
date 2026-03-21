import type { FastifyPluginAsync } from 'fastify';

import { assertAuthenticatedUser, requireAuth } from '../../lib/auth';
import { patchMeBodySchema } from '../auth/schemas';
import { UsersService } from './service';

const usersService = new UsersService();

export const usersRoutes: FastifyPluginAsync = async (app) => {
  app.patch('/me', { preHandler: requireAuth }, async (request) => {
    const body = patchMeBodySchema.parse(request.body);
    const { userId } = assertAuthenticatedUser(request);
    return usersService.updateCurrentUser(userId, body);
  });
};
