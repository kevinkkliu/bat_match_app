import type { GameSummaryDto, PaginatedResponse } from '../../contracts/api';
import { listCreatedGames as listCreatedGamesFlow, listJoinedGames as listJoinedGamesFlow } from '../join-requests/logic';

export class MeService {
  async listJoinedGames(_userId: string): Promise<PaginatedResponse<GameSummaryDto>> {
    return listJoinedGamesFlow(_userId);
  }

  async listCreatedGames(_userId: string): Promise<PaginatedResponse<GameSummaryDto>> {
    return listCreatedGamesFlow(_userId);
  }
}
