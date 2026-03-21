import type { FastifyPluginAsync } from 'fastify';

import { assertAuthenticatedUser, requireAuth } from '../../lib/auth';
import { AuthService } from './service';
import { loginBodySchema, registerBodySchema } from './schemas';

const authService = new AuthService();

export const authRoutes: FastifyPluginAsync = async (app) => {
  app.post('/register', async (request, reply) => {
    const body = registerBodySchema.parse(request.body);
    const user = await authService.register(body);
    const token = await reply.jwtSign({ sub: user.id });

    return reply.status(201).send({
      user,
      token,
    });
  });

  app.post('/login', async (request, reply) => {
    const body = loginBodySchema.parse(request.body);
    const user = await authService.login(body);
    const token = await reply.jwtSign({ sub: user.id });

    return reply.status(200).send({
      user,
      token,
    });
  });

  app.get('/me', { preHandler: requireAuth }, async (request) => {
    const { userId } = assertAuthenticatedUser(request);
    return authService.getCurrentUser(userId);
  });
};
