import type { GameSummaryDto, PaginatedResponse } from '../../contracts/api';
import { prisma } from '../../lib/prisma';
import {
  listCreatedGames as listCreatedGamesFlow,
  listJoinedGames as listJoinedGamesFlow,
} from '../join-requests/logic';

export class MeService {
  async listJoinedGames(userId: string): Promise<PaginatedResponse<GameSummaryDto>> {
    return listJoinedGamesFlow(userId);
  }

  async listCreatedGames(userId: string): Promise<PaginatedResponse<GameSummaryDto>> {
    return listCreatedGamesFlow(userId);
  }

  async updateFcmToken(userId: string, fcmToken: string): Promise<{ success: boolean; message: string }> {
    await prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
    });

    return { success: true, message: 'FCM token updated successfully.' };
  }
}
