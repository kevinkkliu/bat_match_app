import type { FastifyReply, FastifyRequest } from 'fastify';

import { AppError } from './errors';
import { prisma } from './prisma';

type JwtPayload = {
  sub: string;
  email?: string;
};

export type AuthenticatedUser = {
  userId: string;
  email?: string;
};

export function assertAuthenticatedUser(request: FastifyRequest): AuthenticatedUser {
  if (!request.authUser) {
    throw new AppError(401, 'UNAUTHORIZED', 'Authentication is required.');
  }

  return request.authUser;
}

export async function resolveOptionalAuthUser(
  request: FastifyRequest
): Promise<AuthenticatedUser | null> {
  try {
    const payload = (await request.jwtVerify()) as JwtPayload;

    return {
      userId: payload.sub,
      email: payload.email,
    };
  } catch {
    if (process.env.NODE_ENV !== 'production') {
      const devUserEmailHeader = request.headers['x-dev-user-email'];
      const devUserEmail = Array.isArray(devUserEmailHeader)
        ? devUserEmailHeader[0]
        : devUserEmailHeader;

      if (typeof devUserEmail === 'string' && devUserEmail.trim().length > 0) {
        const user = await prisma.user.findUnique({
          where: { email: devUserEmail.trim() },
          select: {
            id: true,
            email: true,
          },
        });

        if (!user) {
          throw new AppError(401, 'UNAUTHORIZED', 'Development user email was not found.');
        }

        return {
          userId: user.id,
          email: user.email ?? undefined,
        };
      }
    }

    return null;
  }
}

export async function requireAuth(request: FastifyRequest, _reply: FastifyReply): Promise<void> {
  const authUser = await resolveOptionalAuthUser(request);

  if (!authUser) {
    throw new AppError(401, 'UNAUTHORIZED', 'Authentication is required.');
  }

  request.authUser = authUser;
}
