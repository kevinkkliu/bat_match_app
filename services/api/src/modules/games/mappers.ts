import type {
  GameDetailDto,
  GameSummaryDto,
  JoinRequestDto,
  UserSummaryDto,
} from '../../contracts/api';

type GameHost = {
  id: string;
  nickname: string;
  avatarUrl: string | null;
  gender: UserSummaryDto['gender'];
  skillLevel: UserSummaryDto['skillLevel'];
  preferredCity: string | null;
  preferredDistrict: string | null;
  phoneNumber?: string | null;
  lineId?: string | null;
};

type GameRow = {
  id: string;
  title: string;
  city: string;
  district: string;
  venueName: string;
  venueAddress: string;
  gameDate: Date;
  startAt: Date;
  endAt: Date;
  skillLevelMin: GameSummaryDto['skillLevelMin'];
  skillLevelMax: GameSummaryDto['skillLevelMax'];
  fee: number;
  capacity: number;
  availableSpots: number;
  courtCount: number;
  shuttleType: GameSummaryDto['shuttleType'];
  approvalMode: GameSummaryDto['approvalMode'];
  status: GameSummaryDto['status'];
  host: GameHost;
};

type GameDetailRow = GameRow & {
  notes: string | null;
  joinRequests: Array<{
    id: string;
    status: JoinRequestDto['status'];
    createdAt: Date;
  }>;
};

type JoinRequestApplicant = {
  id: string;
  nickname: string;
  avatarUrl: string | null;
  gender: UserSummaryDto['gender'];
  skillLevel: UserSummaryDto['skillLevel'];
  preferredCity: string | null;
  preferredDistrict: string | null;
};

export function mapUserSummary(user: GameHost): UserSummaryDto {
  return {
    id: user.id,
    nickname: user.nickname,
    avatarUrl: user.avatarUrl,
    gender: user.gender,
    skillLevel: user.skillLevel,
    preferredCity: user.preferredCity,
    preferredDistrict: user.preferredDistrict,
    ...(user.phoneNumber ? { phoneNumber: user.phoneNumber } : {}),
    ...(user.lineId ? { lineId: user.lineId } : {}),
  };
}

export function mapGameSummary(game: GameRow): GameSummaryDto {
  return {
    id: game.id,
    title: game.title,
    city: game.city,
    district: game.district,
    venueName: game.venueName,
    venueAddress: game.venueAddress,
    gameDate: toDateOnlyString(game.gameDate),
    startAt: game.startAt.toISOString(),
    endAt: game.endAt.toISOString(),
    skillLevelMin: game.skillLevelMin,
    skillLevelMax: game.skillLevelMax,
    fee: game.fee,
    capacity: game.capacity,
    availableSpots: game.availableSpots,
    courtCount: game.courtCount,
    shuttleType: game.shuttleType,
    approvalMode: game.approvalMode,
    status: game.status,
    host: mapUserSummary(game.host),
  };
}

export function mapGameDetail(game: GameDetailRow): GameDetailDto {
  const summaryCounts = game.joinRequests.reduce(
    (acc, joinRequest) => {
      if (joinRequest.status === 'PENDING') {
        acc.pendingCount += 1;
      }

      if (joinRequest.status === 'APPROVED') {
        acc.approvedCount += 1;
      }

      return acc;
    },
    {
      pendingCount: 0,
      approvedCount: 0,
    }
  );

  return {
    ...mapGameSummary(game),
    notes: game.notes,
    joinSummary: {
      currentUserStatus: null,
      currentUserRequestId: null,
      currentUserRequestedAt: null,
      pendingCount: summaryCounts.pendingCount,
      approvedCount: summaryCounts.approvedCount,
    },
  };
}

export function mapJoinRequest(joinRequest: {
  id: string;
  gameId: string;
  userId: string;
  status: JoinRequestDto['status'];
  message: string | null;
  respondedAt: Date | null;
  approvedAt: Date | null;
  rejectedReason: string | null;
  createdAt: Date;
  updatedAt: Date;
  user: JoinRequestApplicant;
}): JoinRequestDto {
  return {
    ...joinRequest,
    respondedAt: toNullableIsoString(joinRequest.respondedAt),
    approvedAt: toNullableIsoString(joinRequest.approvedAt),
    createdAt: joinRequest.createdAt.toISOString(),
    updatedAt: joinRequest.updatedAt.toISOString(),
    applicant: mapUserSummary(joinRequest.user),
  };
}

function toDateOnlyString(value: Date): string {
  return value.toISOString().slice(0, 10);
}

function toNullableIsoString(value: Date | null): string | null {
  return value ? value.toISOString() : null;
}
