import type { UserSummaryDto } from '../../contracts/api';
import { Prisma } from '@prisma/client';
import { AppError } from '../../lib/errors';
import { prisma } from '../../lib/prisma';
import { hashPassword, verifyPassword } from './password';
import { toUserSummary } from './serializers';
import type { LoginBody, RegisterBody } from './schemas';

export class AuthService {
  async register(input: RegisterBody): Promise<UserSummaryDto> {
    const email = input.email?.trim().toLowerCase() ?? null;
    const phoneNumber = input.phoneNumber?.trim() ?? null;
    const uniqueCriteria: Prisma.UserWhereInput[] = [];

    if (email) {
      uniqueCriteria.push({ email });
    }

    if (phoneNumber) {
      uniqueCriteria.push({ phoneNumber });
    }

    const existing =
      uniqueCriteria.length > 0
        ? await prisma.user.findFirst({
            where: {
              OR: uniqueCriteria,
            },
            select: {
              id: true,
            },
          })
        : null;

    if (existing) {
      throw new AppError(409, 'USER_ALREADY_EXISTS', 'Email or phone number is already in use.');
    }

    const user = await prisma.user.create({
      data: {
        email,
        phoneNumber,
        passwordHash: hashPassword(input.password),
        nickname: input.nickname.trim(),
        skillLevel: input.skillLevel,
      },
      select: {
        id: true,
        nickname: true,
        avatarUrl: true,
        gender: true,
        skillLevel: true,
        preferredCity: true,
        preferredDistrict: true,
      },
    });

    return toUserSummary(user);
  }

  async login(input: LoginBody): Promise<UserSummaryDto> {
    const identifier = input.emailOrPhone.trim();
    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { email: identifier.toLowerCase() },
          { phoneNumber: identifier },
        ],
      },
      select: {
        id: true,
        nickname: true,
        avatarUrl: true,
        gender: true,
        skillLevel: true,
        preferredCity: true,
        preferredDistrict: true,
        passwordHash: true,
      },
    });

    if (!user || !user.passwordHash || !verifyPassword(input.password, user.passwordHash)) {
      throw new AppError(401, 'INVALID_CREDENTIALS', 'Email/phone or password is invalid.');
    }

    return toUserSummary(user);
  }

  async getCurrentUser(userId: string): Promise<{ user: UserSummaryDto }> {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        nickname: true,
        avatarUrl: true,
        gender: true,
        skillLevel: true,
        preferredCity: true,
        preferredDistrict: true,
      },
    });

    if (!user) {
      throw new AppError(404, 'USER_NOT_FOUND', 'User does not exist.');
    }

    return {
      user: toUserSummary(user),
    };
  }
}
