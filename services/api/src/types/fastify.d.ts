import 'fastify';
import type { AuthenticatedUser } from '../lib/auth';

declare module 'fastify' {
  interface FastifyRequest {
    authUser?: AuthenticatedUser;
  }
}
