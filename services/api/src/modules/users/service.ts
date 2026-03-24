import type { UserSummaryDto } from '../../contracts/api';
import type { PatchMeBody } from '../auth/schemas';
import { AppError } from '../../lib/errors';
import { prisma } from '../../lib/prisma';
import { toUserSummary } from '../auth/serializers';

export class UsersService {
  async updateCurrentUser(userId: string, input: PatchMeBody): Promise<{ user: UserSummaryDto }> {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
      },
    });

    if (!user) {
      throw new AppError(404, 'USER_NOT_FOUND', 'User does not exist.');
    }

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        ...(input.nickname ? { nickname: input.nickname.trim() } : {}),
        ...(input.avatarUrl !== undefined ? { avatarUrl: input.avatarUrl } : {}),
        ...(input.gender !== undefined ? { gender: input.gender } : {}),
        ...(input.skillLevel ? { skillLevel: input.skillLevel } : {}),
        ...(input.preferredCity !== undefined ? { preferredCity: input.preferredCity.trim() } : {}),
        ...(input.preferredDistrict !== undefined
          ? { preferredDistrict: input.preferredDistrict.trim() }
          : {}),
        ...(input.lineId !== undefined ? { lineId: input.lineId ? input.lineId.trim() : null } : {}),
      },
      select: {
        id: true,
        nickname: true,
        avatarUrl: true,
        gender: true,
        skillLevel: true,
        preferredCity: true,
        preferredDistrict: true,
        phoneNumber: true,
        lineId: true,
      },
    });

    return {
      user: toUserSummary(updatedUser),
    };
  }
}
