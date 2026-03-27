import { ApprovalMode, GameStatus, JoinRequestStatus, type Prisma } from '@prisma/client';

import type {
  GameMutationSummary,
  GameSummaryDto,
  JoinRequestDto,
  PaginatedResponse,
} from '../../contracts/api';

import { AppError } from '../../lib/errors';
import { prisma } from '../../lib/prisma';
import { mapGameSummary, mapJoinRequest } from '../games/mappers';

const GAME_HOST_SELECT = {
  id: true,
  nickname: true,
  avatarUrl: true,
  gender: true,
  skillLevel: true,
  preferredCity: true,
  preferredDistrict: true,
} as const;

const GAME_SUMMARY_INCLUDE = {
  host: {
    select: GAME_HOST_SELECT,
  },
} as const;

const JOIN_REQUEST_WITH_GAME_SELECT = {
  id: true,
  gameId: true,
  userId: true,
  status: true,
  message: true,
  respondedAt: true,
  approvedAt: true,
  rejectedReason: true,
  createdAt: true,
  updatedAt: true,
  user: {
    select: {
      id: true,
      nickname: true,
      avatarUrl: true,
      gender: true,
      skillLevel: true,
      preferredCity: true,
      preferredDistrict: true,
    },
  },
  game: {
    select: {
      id: true,
      hostId: true,
      availableSpots: true,
      status: true,
    },
  },
} as const;

const JOIN_REQUEST_SELECT = {
  id: true,
  gameId: true,
  userId: true,
  status: true,
  message: true,
  respondedAt: true,
  approvedAt: true,
  rejectedReason: true,
  createdAt: true,
  updatedAt: true,
  user: {
    select: {
      id: true,
      nickname: true,
      avatarUrl: true,
      gender: true,
      skillLevel: true,
      preferredCity: true,
      preferredDistrict: true,
    },
  },
} as const;

type JoinRequestRecord = Prisma.JoinRequestGetPayload<{
  select: typeof JOIN_REQUEST_SELECT;
}>;

type JoinRequestWithGameRecord = Prisma.JoinRequestGetPayload<{
  select: typeof JOIN_REQUEST_WITH_GAME_SELECT;
}>;

function createGameMutationSummary(game: {
  id: string;
  availableSpots: number;
  status: GameStatus;
}): GameMutationSummary {
  return {
    id: game.id,
    availableSpots: game.availableSpots,
    status: game.status,
  };
}

function ensureGameJoinable(gameStatus: GameStatus): void {
  if (gameStatus === 'CANCELLED' || gameStatus === 'COMPLETED') {
    throw new AppError(409, 'GAME_NOT_JOINABLE', 'This game is no longer joinable.');
  }
}

function ensureGameJoinRequestActionable(gameStatus: GameStatus): void {
  if (gameStatus === GameStatus.CANCELLED || gameStatus === GameStatus.COMPLETED) {
    throw new AppError(
      409,
      'GAME_NOT_EDITABLE',
      'Cancelled or completed games cannot change join requests.'
    );
  }
}

function ensureHost(userId: string, hostId: string, message: string): void {
  if (userId !== hostId) {
    throw new AppError(403, 'FORBIDDEN', message);
  }
}

function ensureNotHost(userId: string, hostId: string, message: string): void {
  if (userId === hostId) {
    throw new AppError(403, 'FORBIDDEN', message);
  }
}

function ensurePending(joinRequest: JoinRequestRecord): void {
  if (joinRequest.status !== JoinRequestStatus.PENDING) {
    throw new AppError(409, 'INVALID_JOIN_REQUEST_STATE', 'Only pending requests can be processed.');
  }
}

function ensureRequestMutatable(joinRequest: JoinRequestRecord): void {
  if (joinRequest.status !== JoinRequestStatus.PENDING && joinRequest.status !== JoinRequestStatus.APPROVED) {
    throw new AppError(409, 'INVALID_JOIN_REQUEST_STATE', 'Only pending or approved requests can be withdrawn.');
  }
}

function ensureGameWithdrawable(gameStatus: GameStatus): void {
  if (gameStatus === GameStatus.CANCELLED || gameStatus === GameStatus.COMPLETED) {
    throw new AppError(
      409,
      'GAME_NOT_WITHDRAWABLE',
      'Cancelled or completed games cannot be withdrawn from.'
    );
  }
}

function nextActiveGameStatus(availableSpots: number): GameStatus {
  return availableSpots > 0 ? GameStatus.OPEN : GameStatus.FULL;
}

function normalizeMessage(message?: string): string | null {
  if (typeof message !== 'string') {
    return null;
  }

  const trimmed = message.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function assertJoinAvailability(game: { availableSpots: number }): void {
  if (game.availableSpots <= 0) {
    throw new AppError(409, 'GAME_FULL', 'This game has no available spots left.');
  }
}

export async function listJoinedGames(userId: string): Promise<PaginatedResponse<GameSummaryDto>> {
  const now = new Date();

  const [total, joinedGames] = await prisma.$transaction([
    prisma.game.count({
      where: {
        joinRequests: {
          some: {
            userId,
            status: JoinRequestStatus.APPROVED,
          },
        },
        startAt: {
          gte: now,
        },
        status: {
          in: [GameStatus.OPEN, GameStatus.FULL],
        },
      },
    }),
    prisma.game.findMany({
      where: {
        joinRequests: {
          some: {
            userId,
            status: JoinRequestStatus.APPROVED,
          },
        },
        startAt: {
          gte: now,
        },
        status: {
          in: [GameStatus.OPEN, GameStatus.FULL],
        },
      },
      include: GAME_SUMMARY_INCLUDE,
      orderBy: [{ startAt: 'asc' }, { createdAt: 'asc' }],
    }),
  ]);

  return {
    items: joinedGames.map(mapGameSummary),
    page: 1,
    pageSize: total,
    total,
  };
}

export async function listCreatedGames(userId: string): Promise<PaginatedResponse<GameSummaryDto>> {
  const now = new Date();

  const [total, games] = await prisma.$transaction([
    prisma.game.count({
      where: {
        hostId: userId,
        startAt: {
          gte: now,
        },
        status: {
          not: GameStatus.COMPLETED,
        },
      },
    }),
    prisma.game.findMany({
      where: {
        hostId: userId,
        startAt: {
          gte: now,
        },
        status: {
          not: GameStatus.COMPLETED,
        },
      },
      include: GAME_SUMMARY_INCLUDE,
      orderBy: [{ startAt: 'asc' }, { createdAt: 'asc' }],
    }),
  ]);

  return {
    items: games.map(mapGameSummary),
    page: 1,
    pageSize: total,
    total,
  };
}

export async function listGameJoinRequests(
  userId: string,
  gameId: string
): Promise<PaginatedResponse<JoinRequestDto>> {
  const game = await prisma.game.findUnique({
    where: {
      id: gameId,
    },
    select: {
      id: true,
      hostId: true,
    },
  });

  if (!game) {
    throw new AppError(404, 'GAME_NOT_FOUND', 'Game does not exist.');
  }

  ensureHost(userId, game.hostId, 'Only the host can view join requests for this game.');

  const [total, joinRequests] = await prisma.$transaction([
    prisma.joinRequest.count({
      where: {
        gameId,
      },
    }),
    prisma.joinRequest.findMany({
      where: {
        gameId,
      },
      orderBy: [{ createdAt: 'desc' }, { updatedAt: 'desc' }],
      select: JOIN_REQUEST_SELECT,
    }),
  ]);

  const orderedJoinRequests = sortJoinRequestsForHost(joinRequests);

  return {
    items: orderedJoinRequests.map(mapJoinRequest),
    page: 1,
    pageSize: total,
    total,
  };
}

export async function createJoinRequest(
  userId: string,
  gameId: string,
  message?: string
): Promise<{ joinRequest: JoinRequestDto; game: GameMutationSummary }> {
  return prisma.$transaction(async (tx) => {
    const game = await tx.game.findUnique({
      where: {
        id: gameId,
      },
      select: {
        id: true,
        hostId: true,
        approvalMode: true,
        availableSpots: true,
        status: true,
      },
    });

    if (!game) {
      throw new AppError(404, 'GAME_NOT_FOUND', 'Game does not exist.');
    }

    ensureNotHost(userId, game.hostId, 'Game hosts cannot join their own games.');
    ensureGameJoinable(game.status);

    const existingJoinRequest = await tx.joinRequest.findFirst({
      where: {
        gameId,
        userId,
      },
      select: JOIN_REQUEST_SELECT,
    });

    if (
      existingJoinRequest &&
      (existingJoinRequest.status === JoinRequestStatus.PENDING ||
        existingJoinRequest.status === JoinRequestStatus.APPROVED)
    ) {
      throw new AppError(409, 'JOIN_REQUEST_EXISTS', 'You already have an active request for this game.');
    }

    const normalizedMessage = normalizeMessage(message);
    const now = new Date();

    if (game.approvalMode === ApprovalMode.AUTO) {
      assertJoinAvailability(game);

      const joinRequest = existingJoinRequest
        ? await tx.joinRequest.update({
            where: {
              id: existingJoinRequest.id,
            },
            data: {
              status: JoinRequestStatus.APPROVED,
              message: normalizedMessage ?? existingJoinRequest.message,
              respondedAt: now,
              approvedAt: now,
              rejectedReason: null,
            },
            select: JOIN_REQUEST_SELECT,
          })
        : await tx.joinRequest.create({
            data: {
              gameId,
              userId,
              status: JoinRequestStatus.APPROVED,
              message: normalizedMessage,
              respondedAt: now,
              approvedAt: now,
            },
            select: JOIN_REQUEST_SELECT,
          });

      const remainingSpots = game.availableSpots - 1;
      const updatedGame = await tx.game.update({
        where: {
          id: game.id,
        },
        data: {
          availableSpots: {
            decrement: 1,
          },
          status: nextActiveGameStatus(remainingSpots),
        },
        select: {
          id: true,
          availableSpots: true,
          status: true,
        },
      });

      return {
        joinRequest: mapJoinRequest(joinRequest),
        game: createGameMutationSummary(updatedGame),
      };
    }

    const joinRequest = existingJoinRequest
      ? await tx.joinRequest.update({
          where: {
            id: existingJoinRequest.id,
          },
          data: {
            status: JoinRequestStatus.PENDING,
            message: normalizedMessage ?? existingJoinRequest.message,
            respondedAt: null,
            approvedAt: null,
            rejectedReason: null,
          },
          select: JOIN_REQUEST_SELECT,
        })
      : await tx.joinRequest.create({
          data: {
            gameId,
            userId,
            status: JoinRequestStatus.PENDING,
            message: normalizedMessage,
          },
          select: JOIN_REQUEST_SELECT,
        });

    return {
      joinRequest: mapJoinRequest(joinRequest),
      game: createGameMutationSummary({
        id: game.id,
        availableSpots: game.availableSpots,
        status: game.status,
      }),
    };
  });
}

export async function approveJoinRequest(
  userId: string,
  joinRequestId: string
): Promise<JoinRequestDto> {
  return prisma.$transaction(async (tx) => {
    const joinRequest = await tx.joinRequest.findUnique({
      where: {
        id: joinRequestId,
      },
      select: JOIN_REQUEST_WITH_GAME_SELECT,
    });

    if (!joinRequest) {
      throw new AppError(404, 'JOIN_REQUEST_NOT_FOUND', 'Join request does not exist.');
    }

    ensureHost(userId, joinRequest.game.hostId, 'Only the host can approve this join request.');
    ensureGameJoinable(joinRequest.game.status);
    ensurePending(joinRequest);
    assertJoinAvailability(joinRequest.game);

    const now = new Date();
    const updatedJoinRequest = await tx.joinRequest.update({
      where: {
        id: joinRequest.id,
      },
      data: {
        status: JoinRequestStatus.APPROVED,
        respondedAt: now,
        approvedAt: now,
        rejectedReason: null,
      },
      select: JOIN_REQUEST_SELECT,
    });

    const updatedGame = await tx.game.update({
      where: {
        id: joinRequest.gameId,
      },
      data: {
        availableSpots: {
          decrement: 1,
        },
        status: nextActiveGameStatus(joinRequest.game.availableSpots - 1),
      },
      select: {
        id: true,
        availableSpots: true,
        status: true,
      },
    });

    void updatedGame;

    return mapJoinRequest(updatedJoinRequest);
  });
}

export async function rejectJoinRequest(
  userId: string,
  joinRequestId: string,
  reason?: string
): Promise<JoinRequestDto> {
  return prisma.$transaction(async (tx) => {
    const joinRequest = await tx.joinRequest.findUnique({
      where: {
        id: joinRequestId,
      },
      select: JOIN_REQUEST_WITH_GAME_SELECT,
    });

    if (!joinRequest) {
      throw new AppError(404, 'JOIN_REQUEST_NOT_FOUND', 'Join request does not exist.');
    }

    ensureHost(userId, joinRequest.game.hostId, 'Only the host can reject this join request.');
    ensureGameJoinRequestActionable(joinRequest.game.status);
    ensurePending(joinRequest);

    const updatedJoinRequest = await tx.joinRequest.update({
      where: {
        id: joinRequest.id,
      },
      data: {
        status: JoinRequestStatus.REJECTED,
        respondedAt: new Date(),
        approvedAt: null,
        rejectedReason: normalizeMessage(reason),
      },
      select: JOIN_REQUEST_SELECT,
    });

    return mapJoinRequest(updatedJoinRequest);
  });
}

export async function withdrawJoinRequest(
  userId: string,
  joinRequestId: string
): Promise<JoinRequestDto> {
  return prisma.$transaction(async (tx) => {
    const joinRequest = await tx.joinRequest.findUnique({
      where: {
        id: joinRequestId,
      },
      select: JOIN_REQUEST_WITH_GAME_SELECT,
    });

    if (!joinRequest) {
      throw new AppError(404, 'JOIN_REQUEST_NOT_FOUND', 'Join request does not exist.');
    }

    if (joinRequest.userId !== userId) {
      throw new AppError(403, 'FORBIDDEN', 'Only the requester can withdraw this join request.');
    }

    ensureGameWithdrawable(joinRequest.game.status);
    ensureRequestMutatable(joinRequest);

    const now = new Date();

    const updatedJoinRequest = await tx.joinRequest.update({
      where: {
        id: joinRequest.id,
      },
      data: {
        status: JoinRequestStatus.WITHDRAWN,
        respondedAt: now,
        approvedAt: joinRequest.approvedAt,
        rejectedReason: null,
      },
      select: JOIN_REQUEST_SELECT,
    });

    if (joinRequest.status === JoinRequestStatus.APPROVED) {
      const updatedSpots = joinRequest.game.availableSpots + 1;

      await tx.game.update({
        where: {
          id: joinRequest.gameId,
        },
        data: {
          availableSpots: {
            increment: 1,
          },
          status:
            joinRequest.game.status === GameStatus.CANCELLED || joinRequest.game.status === GameStatus.COMPLETED
              ? joinRequest.game.status
              : nextActiveGameStatus(updatedSpots),
        },
        select: {
          id: true,
        },
      });
    }

    return mapJoinRequest(updatedJoinRequest);
  });
}

export async function withdrawJoinRequestByGame(
  userId: string,
  gameId: string
): Promise<JoinRequestDto> {
  const joinRequest = await prisma.joinRequest.findFirst({
    where: {
      gameId,
      userId,
    },
    select: {
      id: true,
    },
  });

  if (!joinRequest) {
    throw new AppError(404, 'JOIN_REQUEST_NOT_FOUND', 'Join request does not exist.');
  }

  return withdrawJoinRequest(userId, joinRequest.id);
}

function sortJoinRequestsForHost(joinRequests: JoinRequestRecord[]): JoinRequestRecord[] {
  return [...joinRequests].sort((left, right) => {
    const leftPriority = joinRequestPriority(left.status);
    const rightPriority = joinRequestPriority(right.status);

    if (leftPriority !== rightPriority) {
      return leftPriority - rightPriority;
    }

    const createdAtDiff = right.createdAt.getTime() - left.createdAt.getTime();
    if (createdAtDiff !== 0) {
      return createdAtDiff;
    }

    return right.updatedAt.getTime() - left.updatedAt.getTime();
  });
}

function joinRequestPriority(status: JoinRequestDto['status']): number {
  switch (status) {
    case 'PENDING':
      return 0;
    case 'APPROVED':
      return 1;
    case 'REJECTED':
      return 2;
    case 'WITHDRAWN':
      return 3;
    case 'CANCELLED':
      return 4;
    default:
      return 5;
  }
}
