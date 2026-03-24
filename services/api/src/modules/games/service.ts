import type {
  GameDetailDto,
  GameMutationSummary,
  JoinRequestDto,
  GameSummaryDto,
  PaginatedResponse,
} from '../../contracts/api';
import type {
  CreateGameBody,
  GamesQuery,
  PatchGameBody,
  PatchGameStatusBody,
} from './schemas';

import { GameStatus, JoinRequestStatus } from '@prisma/client';

import { AppError } from '../../lib/errors';
import { prisma } from '../../lib/prisma';
import { mapGameDetail, mapGameSummary } from './mappers';
import {
  createJoinRequest as createJoinRequestFlow,
  listGameJoinRequests as listGameJoinRequestsFlow,
} from '../join-requests/logic';

const SKILL_LEVEL_ORDER = ['L1', 'L2', 'L3', 'L4', 'L5'] as const;

export class GamesService {
  async list(query: GamesQuery): Promise<PaginatedResponse<GameSummaryDto>> {
    const where = buildGamesWhere(query);
    const skip = (query.page - 1) * query.pageSize;

    const [total, games] = await prisma.$transaction([
      prisma.game.count({ where }),
      prisma.game.findMany({
        where,
        orderBy: [{ gameDate: 'asc' }, { startAt: 'asc' }, { createdAt: 'asc' }],
        skip,
        take: query.pageSize,
        include: {
          host: {
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
        },
      }),
    ]);

    return {
      items: games.map(mapGameSummary),
      page: query.page,
      pageSize: query.pageSize,
      total,
    };
  }

  async detail(gameId: string, currentUserId?: string): Promise<GameDetailDto> {
    const game = await prisma.game.findUnique({
      where: { id: gameId },
      include: {
        host: {
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
        },
        joinRequests: {
          select: {
            id: true,
            status: true,
            createdAt: true,
          },
        },
      },
    });

    if (!game) {
      throw new AppError(404, 'GAME_NOT_FOUND', 'Game does not exist.');
    }

    const detail = mapGameDetail(game);

    if (currentUserId) {
      const currentUserJoinRequest = await prisma.joinRequest.findFirst({
        where: {
          gameId,
          userId: currentUserId,
        },
        select: {
          id: true,
          status: true,
          createdAt: true,
        },
      });

      detail.joinSummary.currentUserStatus = currentUserJoinRequest?.status ?? null;
      detail.joinSummary.currentUserRequestId = currentUserJoinRequest?.id ?? null;
      detail.joinSummary.currentUserRequestedAt =
        currentUserJoinRequest?.createdAt?.toISOString() ?? null;
    }

    const isHost = currentUserId === game.hostId;
    const isApproved = detail.joinSummary.currentUserStatus === 'APPROVED';

    if (!isHost && !isApproved) {
      delete detail.host.phoneNumber;
      delete detail.host.lineId;
    }

    return detail;
  }

  async create(_userId: string, _input: CreateGameBody): Promise<GameDetailDto> {
    const createdGame = await prisma.game.create({
      data: {
        hostId: _userId,
        title: _input.title,
        city: _input.city,
        district: _input.district,
        venueName: _input.venueName,
        venueAddress: _input.venueAddress,
        gameDate: new Date(`${_input.gameDate}T00:00:00.000Z`),
        startAt: new Date(_input.startAt),
        endAt: new Date(_input.endAt),
        skillLevelMin: _input.skillLevelMin,
        skillLevelMax: _input.skillLevelMax ?? null,
        fee: _input.fee,
        capacity: _input.capacity,
        availableSpots: _input.capacity,
        courtCount: _input.courtCount,
        shuttleType: _input.shuttleType ?? null,
        approvalMode: _input.approvalMode,
        status: 'OPEN',
        notes: _input.notes ?? null,
      },
      include: {
        host: {
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
        },
        joinRequests: {
          select: {
            id: true,
            status: true,
            createdAt: true,
          },
        },
      },
    });

    return mapGameDetail(createdGame);
  }

  async update(userId: string, gameId: string, input: PatchGameBody): Promise<GameDetailDto> {
    const game = await prisma.game.findUnique({
      where: {
        id: gameId,
      },
      select: {
        id: true,
        hostId: true,
        status: true,
      },
    });

    if (!game) {
      throw new AppError(404, 'GAME_NOT_FOUND', 'Game does not exist.');
    }

    ensureHost(userId, game.hostId);
    ensureEditableGame(game.status);

    const approvedCount = await prisma.joinRequest.count({
      where: {
        gameId,
        status: JoinRequestStatus.APPROVED,
      },
    });

    if (typeof input.capacity === 'number' && input.capacity < approvedCount) {
      throw new AppError(
        409,
        'GAME_CAPACITY_TOO_SMALL',
        'Capacity cannot be lower than the number of approved players.'
      );
    }

    const currentGame = await prisma.game.findUniqueOrThrow({
      where: { id: gameId },
      select: {
        gameDate: true,
        startAt: true,
        endAt: true,
        availableSpots: true,
        skillLevelMin: true,
        skillLevelMax: true,
        shuttleType: true,
        approvalMode: true,
        notes: true,
      },
    });

    const nextStartAt = input.startAt ? new Date(input.startAt) : currentGame.startAt;
    const nextEndAt = input.endAt ? new Date(input.endAt) : currentGame.endAt;
    const nextGameDate = input.gameDate ? new Date(`${input.gameDate}T00:00:00.000Z`) : currentGame.gameDate;

    if (nextEndAt <= nextStartAt) {
      throw new AppError(400, 'INVALID_GAME_TIME_RANGE', 'endAt must be later than startAt.');
    }

    const nextSkillLevelMin = input.skillLevelMin ?? currentGame.skillLevelMin;
    const nextSkillLevelMax = input.skillLevelMax ?? currentGame.skillLevelMax;

    if (nextSkillLevelMax != null && nextSkillLevelMax < nextSkillLevelMin) {
      throw new AppError(
        400,
        'INVALID_SKILL_RANGE',
        'skillLevelMax must be greater than or equal to skillLevelMin.'
      );
    }

    const nextAvailableSpots =
      typeof input.capacity === 'number' ? input.capacity - approvedCount : currentGame.availableSpots;
    const nextStatus = nextAvailableSpots > 0 ? GameStatus.OPEN : GameStatus.FULL;

    await prisma.game.update({
      where: {
        id: gameId,
      },
      data: {
        title: input.title,
        city: input.city,
        district: input.district,
        venueName: input.venueName,
        venueAddress: input.venueAddress,
        gameDate: nextGameDate,
        startAt: nextStartAt,
        endAt: nextEndAt,
        skillLevelMin: nextSkillLevelMin,
        skillLevelMax: nextSkillLevelMax,
        fee: input.fee,
        capacity: input.capacity,
        availableSpots: nextAvailableSpots,
        courtCount: input.courtCount,
        shuttleType: input.shuttleType ?? currentGame.shuttleType,
        approvalMode: input.approvalMode ?? currentGame.approvalMode,
        notes: input.notes ?? currentGame.notes,
        status: nextStatus,
      },
      select: {
        id: true,
      },
    });

    return this.detail(gameId, userId);
  }

  async updateStatus(userId: string, gameId: string, input: PatchGameStatusBody): Promise<GameDetailDto> {
    const game = await prisma.game.findUnique({
      where: {
        id: gameId,
      },
      select: {
        id: true,
        hostId: true,
        status: true,
      },
    });

    if (!game) {
      throw new AppError(404, 'GAME_NOT_FOUND', 'Game does not exist.');
    }

    ensureHost(userId, game.hostId);

    if (game.status === GameStatus.CANCELLED || game.status === GameStatus.COMPLETED) {
      if (game.status !== input.status) {
        throw new AppError(
          409,
          'GAME_NOT_EDITABLE',
          'Cancelled or completed games cannot be reopened or changed.'
        );
      }
      return this.detail(gameId, userId);
    }

    if (input.status === GameStatus.FULL && !(await hasNoRemainingSpots(gameId))) {
      throw new AppError(409, 'GAME_NOT_FULL', 'Game can only be marked full when no spots remain.');
    }

    if (input.status === GameStatus.OPEN) {
      const availableSpots = await getAvailableSpots(gameId);
      if (availableSpots <= 0) {
        throw new AppError(409, 'GAME_NOT_OPEN', 'Game cannot be marked open without spots.');
      }
    }

    await prisma.$transaction(async (tx) => {
      if (input.status === GameStatus.CANCELLED) {
        await tx.joinRequest.updateMany({
          where: {
            gameId,
            status: {
              in: [JoinRequestStatus.PENDING, JoinRequestStatus.APPROVED],
            },
          },
          data: {
            status: JoinRequestStatus.CANCELLED,
            respondedAt: new Date(),
            rejectedReason: null,
          },
        });
      }

      await tx.game.update({
        where: {
          id: gameId,
        },
        data:
          input.status === GameStatus.CANCELLED
            ? {
                status: input.status,
                availableSpots: 0,
              }
            : {
                status: input.status,
              },
        select: {
          id: true,
        },
      });
    });

    return this.detail(gameId, userId);
  }

  async listJoinRequests(_userId: string, _gameId: string): Promise<PaginatedResponse<JoinRequestDto>> {
    return listGameJoinRequestsFlow(_userId, _gameId);
  }

  async join(
    _userId: string,
    _gameId: string,
    _message?: string
  ): Promise<{ joinRequest: JoinRequestDto; game: GameMutationSummary }> {
    return createJoinRequestFlow(_userId, _gameId, _message);
  }
}

function ensureHost(userId: string, hostId: string): void {
  if (userId !== hostId) {
    throw new AppError(403, 'FORBIDDEN', 'Only the host can manage this game.');
  }
}

function ensureEditableGame(status: GameStatus): void {
  if (status === GameStatus.CANCELLED || status === GameStatus.COMPLETED) {
    throw new AppError(409, 'GAME_NOT_EDITABLE', 'Cancelled or completed games cannot be edited.');
  }
}

async function getAvailableSpots(gameId: string): Promise<number> {
  const game = await prisma.game.findUnique({
    where: {
      id: gameId,
    },
    select: {
      availableSpots: true,
    },
  });

  if (!game) {
    throw new AppError(404, 'GAME_NOT_FOUND', 'Game does not exist.');
  }

  return game.availableSpots;
}

async function hasNoRemainingSpots(gameId: string): Promise<boolean> {
  const availableSpots = await getAvailableSpots(gameId);
  return availableSpots <= 0;
}

function buildGamesWhere(query: GamesQuery): Record<string, unknown> {
  const conditions: Array<Record<string, unknown>> = [];
  const normalizedStatus = query.vacancyOnly ? 'OPEN' : query.status;

  if (query.city) {
    conditions.push({
      city: {
        contains: query.city,
        mode: 'insensitive',
      },
    });
  }

  if (query.district) {
    conditions.push({
      district: {
        contains: query.district,
        mode: 'insensitive',
      },
    });
  }

  if (query.date) {
    conditions.push({
      gameDate: new Date(`${query.date}T00:00:00.000Z`),
    });
  }

  if (query.startAtFrom || query.startAtTo) {
    const startAtFilter: Record<string, Date> = {};

    if (query.startAtFrom) {
      startAtFilter.gte = new Date(query.startAtFrom);
    }

    if (query.startAtTo) {
      startAtFilter.lte = new Date(query.startAtTo);
    }

    conditions.push({
      startAt: startAtFilter,
    });
  }

  if (normalizedStatus) {
    conditions.push({ status: normalizedStatus });
  }

  if (query.feeMin !== undefined || query.feeMax !== undefined) {
    const feeFilter: Record<string, number> = {};

    if (query.feeMin !== undefined) {
      feeFilter.gte = query.feeMin;
    }

    if (query.feeMax !== undefined) {
      feeFilter.lte = query.feeMax;
    }

    conditions.push({ fee: feeFilter });
  }

  if (query.vacancyOnly) {
    conditions.push({
      availableSpots: {
        gt: 0,
      },
    });
  }

  if (query.skillLevel) {
    const skillIndex = SKILL_LEVEL_ORDER.indexOf(query.skillLevel);
    const allowedMinLevels = SKILL_LEVEL_ORDER.slice(0, skillIndex + 1);
    const allowedMaxLevels = SKILL_LEVEL_ORDER.slice(skillIndex);

    conditions.push({
      skillLevelMin: {
        in: allowedMinLevels,
      },
      OR: [
        { skillLevelMax: null },
        {
          skillLevelMax: {
            in: allowedMaxLevels,
          },
        },
      ],
    });
  }

  return conditions.length > 0 ? { AND: conditions } : {};
}
