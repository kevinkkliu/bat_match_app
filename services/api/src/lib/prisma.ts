import { PrismaClient } from '@prisma/client';

declare global {
  // eslint-disable-next-line no-var
  var __batDatingPrisma: PrismaClient | undefined;
}

export const prisma =
  globalThis.__batDatingPrisma ??
  new PrismaClient({
    log: ['error', 'warn'],
  });

if (process.env.NODE_ENV !== 'production') {
  globalThis.__batDatingPrisma = prisma;
}
