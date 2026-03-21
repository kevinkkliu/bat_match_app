import type { JoinRequestDto, GameMutationSummary, PaginatedResponse } from '../../contracts/api';
import {
  approveJoinRequest as approveJoinRequestFlow,
  createJoinRequest as createJoinRequestFlow,
  listGameJoinRequests as listGameJoinRequestsFlow,
  rejectJoinRequest as rejectJoinRequestFlow,
  withdrawJoinRequest as withdrawJoinRequestFlow,
  withdrawJoinRequestByGame as withdrawJoinRequestByGameFlow,
} from './logic';

export class JoinRequestsService {
  async approve(_userId: string, _joinRequestId: string): Promise<JoinRequestDto> {
    return approveJoinRequestFlow(_userId, _joinRequestId);
  }

  async reject(_userId: string, _joinRequestId: string, _reason?: string): Promise<JoinRequestDto> {
    return rejectJoinRequestFlow(_userId, _joinRequestId, _reason);
  }

  async withdraw(_userId: string, _joinRequestId: string): Promise<JoinRequestDto> {
    return withdrawJoinRequestFlow(_userId, _joinRequestId);
  }

  async withdrawForGame(_userId: string, _gameId: string): Promise<JoinRequestDto> {
    return withdrawJoinRequestByGameFlow(_userId, _gameId);
  }

  async create(
    _userId: string,
    _gameId: string,
    _message?: string
  ): Promise<{ joinRequest: JoinRequestDto; game: GameMutationSummary }> {
    return createJoinRequestFlow(_userId, _gameId, _message);
  }

  async listForGame(_userId: string, _gameId: string): Promise<PaginatedResponse<JoinRequestDto>> {
    return listGameJoinRequestsFlow(_userId, _gameId);
  }
}
