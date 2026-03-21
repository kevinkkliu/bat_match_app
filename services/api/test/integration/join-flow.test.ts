import assert from 'node:assert/strict';
import { after, before, beforeEach, test } from 'node:test';

import type { FastifyInstance } from 'fastify';
import type { PrismaClient } from '@prisma/client';

import type { AppEnv } from '../../src/lib/config';

const TEST_DATABASE_URL = 'postgresql://postgres:postgres@localhost:5432/bat_dating_app_test';
const TEST_JWT_SECRET = 'bat-dating-test-secret-for-integration-only-1234567890';

process.env.NODE_ENV ??= 'test';
process.env.PORT ??= '3000';
process.env.HOST ??= '0.0.0.0';
process.env.DATABASE_URL ??= TEST_DATABASE_URL;
process.env.JWT_SECRET ??= TEST_JWT_SECRET;
process.env.CORS_ORIGIN ??= 'http://localhost:7357,http://127.0.0.1:7357,http://localhost:8080';

let app: FastifyInstance;
let prisma: PrismaClient;
let buildApp: (env: AppEnv) => FastifyInstance;
let loadEnv: (source?: NodeJS.ProcessEnv) => AppEnv;

before(async () => {
  ({ buildApp } = await import('../../src/app'));
  ({ loadEnv } = await import('../../src/lib/config'));
  ({ prisma } = await import('../../src/lib/prisma'));

  app = buildApp(loadEnv(process.env));
  await app.ready();
});

beforeEach(async () => {
  await prisma.joinRequest.deleteMany();
  await prisma.game.deleteMany();
  await prisma.user.deleteMany();
});

after(async () => {
  if (app) {
    await app.close();
  }
});

test('join, me/games, and withdraw keep game state consistent', async () => {
  const fixtures = await seedFixtures();

  const joinResponse = await injectJson('POST', `/api/v1/games/${fixtures.autoGame.id}/join`, {
    headers: authHeaders(fixtures.autoJoiner),
    payload: {
      message: 'Happy to join.',
    },
  });

  assert.equal(joinResponse.statusCode, 201, JSON.stringify(joinResponse.json));
  assert.equal(joinResponse.json.joinRequest.status, 'APPROVED');
  assert.equal(joinResponse.json.game.availableSpots, 1);
  assert.equal(joinResponse.json.joinRequest.applicant.nickname, 'Auto Joiner');
  assert.equal(joinResponse.json.joinRequest.applicant.skillLevel, 'L3');

  const detailAfterJoin = await injectJson('GET', `/api/v1/games/${fixtures.autoGame.id}`, {
    headers: authHeaders(fixtures.autoJoiner),
  });

  assert.equal(detailAfterJoin.statusCode, 200);
  assert.equal(detailAfterJoin.json.joinSummary.currentUserStatus, 'APPROVED');
  assert.equal(detailAfterJoin.json.joinSummary.currentUserRequestId, joinResponse.json.joinRequest.id);
  assert.ok(detailAfterJoin.json.joinSummary.currentUserRequestedAt);

  const joinedGames = await injectJson('GET', '/api/v1/me/games/joined', {
    headers: authHeaders(fixtures.autoJoiner),
  });

  assert.equal(joinedGames.statusCode, 200);
  assert.equal(joinedGames.json.total, 1);
  assert.equal(joinedGames.json.items[0].id, fixtures.autoGame.id);

  const createdGames = await injectJson('GET', '/api/v1/me/games/created', {
    headers: authHeaders(fixtures.autoHost),
  });

  assert.equal(createdGames.statusCode, 200);
  assert.equal(createdGames.json.total, 1);
  assert.equal(createdGames.json.items[0].id, fixtures.autoGame.id);

  const withdrawResponse = await injectJson(
    'PATCH',
      `/api/v1/join-requests/${joinResponse.json.joinRequest.id}/withdraw`,
      {
      headers: authHeaders(fixtures.autoJoiner),
      }
  );

  assert.equal(withdrawResponse.statusCode, 200);
  assert.equal(withdrawResponse.json.status, 'WITHDRAWN');

  const detailAfterWithdraw = await injectJson('GET', `/api/v1/games/${fixtures.autoGame.id}`, {
    headers: authHeaders(fixtures.autoJoiner),
  });

  assert.equal(detailAfterWithdraw.statusCode, 200);
  assert.equal(detailAfterWithdraw.json.joinSummary.currentUserStatus, 'WITHDRAWN');
  assert.equal(
    detailAfterWithdraw.json.joinSummary.currentUserRequestId,
    joinResponse.json.joinRequest.id
  );
  assert.equal(detailAfterWithdraw.json.availableSpots, 2);

  const joinedGamesAfterWithdraw = await injectJson('GET', '/api/v1/me/games/joined', {
    headers: authHeaders(fixtures.autoJoiner),
  });

  assert.equal(joinedGamesAfterWithdraw.statusCode, 200);
  assert.equal(joinedGamesAfterWithdraw.json.total, 0);
  assert.equal(joinedGamesAfterWithdraw.json.items.length, 0);
});

test('manual join can be approved or rejected by the host', async () => {
  const fixtures = await seedFixtures();

  const pendingResponse = await injectJson('POST', `/api/v1/games/${fixtures.manualApproveGame.id}/join`, {
    headers: authHeaders(fixtures.manualApprover),
    payload: {
      message: 'Please let me join.',
    },
  });

  assert.equal(pendingResponse.statusCode, 201, JSON.stringify(pendingResponse.json));
  assert.equal(pendingResponse.json.joinRequest.status, 'PENDING');

  const hostJoinRequests = await injectJson(
    'GET',
    `/api/v1/games/${fixtures.manualApproveGame.id}/join-requests`,
    {
      headers: authHeaders(fixtures.manualHost),
    }
  );

  assert.equal(hostJoinRequests.statusCode, 200);
  assert.equal(hostJoinRequests.json.total, 1);
  assert.equal(hostJoinRequests.json.items[0].status, 'PENDING');
  assert.equal(hostJoinRequests.json.items[0].applicant.nickname, 'Manual Approver');
  assert.equal(hostJoinRequests.json.items[0].applicant.skillLevel, 'L3');

  const approveResponse = await injectJson(
    'PATCH',
    `/api/v1/join-requests/${pendingResponse.json.joinRequest.id}/approve`,
    {
      headers: authHeaders(fixtures.manualHost),
    }
  );

  assert.equal(approveResponse.statusCode, 200);
  assert.equal(approveResponse.json.status, 'APPROVED');
  assert.equal(approveResponse.json.applicant.nickname, 'Manual Approver');

  const approvedDetail = await injectJson('GET', `/api/v1/games/${fixtures.manualApproveGame.id}`, {
    headers: authHeaders(fixtures.manualApprover),
  });

  assert.equal(approvedDetail.statusCode, 200);
  assert.equal(approvedDetail.json.joinSummary.currentUserStatus, 'APPROVED');
  assert.equal(
    approvedDetail.json.joinSummary.currentUserRequestId,
    pendingResponse.json.joinRequest.id
  );
  assert.equal(approvedDetail.json.availableSpots, 1);

  const approvedJoinedGames = await injectJson('GET', '/api/v1/me/games/joined', {
    headers: authHeaders(fixtures.manualApprover),
  });

  assert.equal(approvedJoinedGames.statusCode, 200);
  assert.equal(approvedJoinedGames.json.total, 1);
  assert.equal(approvedJoinedGames.json.items[0].id, fixtures.manualApproveGame.id);

  const rejectResponse = await injectJson('POST', `/api/v1/games/${fixtures.manualRejectGame.id}/join`, {
    headers: authHeaders(fixtures.manualRejecter),
    payload: {
      message: 'I can bring shuttles.',
    },
  });

  assert.equal(rejectResponse.statusCode, 201);
  assert.equal(rejectResponse.json.joinRequest.status, 'PENDING');

  const rejected = await injectJson(
    'PATCH',
    `/api/v1/join-requests/${rejectResponse.json.joinRequest.id}/reject`,
    {
      headers: authHeaders(fixtures.manualRejectHost),
      payload: {
        reason: 'Slots are reserved for club members.',
      },
    }
  );

  assert.equal(rejected.statusCode, 200);
  assert.equal(rejected.json.status, 'REJECTED');
  assert.equal(rejected.json.rejectedReason, 'Slots are reserved for club members.');
  assert.equal(rejected.json.applicant.nickname, 'Manual Rejecter');

  const rejectedDetail = await injectJson('GET', `/api/v1/games/${fixtures.manualRejectGame.id}`, {
    headers: authHeaders(fixtures.manualRejecter),
  });

  assert.equal(rejectedDetail.statusCode, 200);
  assert.equal(rejectedDetail.json.joinSummary.currentUserStatus, 'REJECTED');
  assert.equal(
    rejectedDetail.json.joinSummary.currentUserRequestId,
    rejectResponse.json.joinRequest.id
  );
});

async function seedFixtures(): Promise<{
  autoHost: { id: string; email: string };
  autoJoiner: { id: string; email: string };
  manualHost: { id: string; email: string };
  manualApprover: { id: string; email: string };
  manualRejectHost: { id: string; email: string };
  manualRejecter: { id: string; email: string };
  autoGame: { id: string };
  manualApproveGame: { id: string };
  manualRejectGame: { id: string };
}> {
  const autoHost = await createUser('auto-host@example.com', 'Auto Host');
  const autoJoiner = await createUser('auto-joiner@example.com', 'Auto Joiner');
  const manualHost = await createUser('manual-host@example.com', 'Manual Host');
  const manualApprover = await createUser('manual-approver@example.com', 'Manual Approver');
  const manualRejectHost = await createUser('manual-reject-host@example.com', 'Manual Reject Host');
  const manualRejecter = await createUser('manual-rejecter@example.com', 'Manual Rejecter');

  const autoGame = await createGame({
    hostId: autoHost.id,
    title: 'Auto Join Game',
    approvalMode: 'AUTO',
    availableSpots: 2,
    capacity: 2,
    gameDate: new Date('2026-03-25T00:00:00.000Z'),
    startAt: new Date('2026-03-25T11:00:00.000Z'),
    endAt: new Date('2026-03-25T13:00:00.000Z'),
  });

  const manualApproveGame = await createGame({
    hostId: manualHost.id,
    title: 'Manual Approve Game',
    approvalMode: 'MANUAL',
    availableSpots: 2,
    capacity: 2,
    gameDate: new Date('2026-03-26T00:00:00.000Z'),
    startAt: new Date('2026-03-26T11:00:00.000Z'),
    endAt: new Date('2026-03-26T13:00:00.000Z'),
  });

  const manualRejectGame = await createGame({
    hostId: manualRejectHost.id,
    title: 'Manual Reject Game',
    approvalMode: 'MANUAL',
    availableSpots: 2,
    capacity: 2,
    gameDate: new Date('2026-03-27T00:00:00.000Z'),
    startAt: new Date('2026-03-27T11:00:00.000Z'),
    endAt: new Date('2026-03-27T13:00:00.000Z'),
  });

  return {
    autoHost,
    autoJoiner,
    manualHost,
    manualApprover,
    manualRejectHost,
    manualRejecter,
    autoGame,
    manualApproveGame,
    manualRejectGame,
  };
}

async function createUser(email: string, nickname: string): Promise<{ id: string; email: string }> {
  const user = await prisma.user.create({
    data: {
      email,
      nickname,
      skillLevel: 'L3',
    },
    select: {
      id: true,
      email: true,
    },
  });

  return {
    id: user.id,
    email: user.email ?? email,
  };
}

async function createGame(input: {
  hostId: string;
  title: string;
  approvalMode: 'AUTO' | 'MANUAL';
  availableSpots: number;
  capacity: number;
  gameDate: Date;
  startAt: Date;
  endAt: Date;
}): Promise<{ id: string }> {
  const game = await prisma.game.create({
    data: {
      hostId: input.hostId,
      title: input.title,
      city: 'Taipei City',
      district: "Da'an",
      venueName: 'NTU Sports Center',
      venueAddress: 'No. 1, Sec. 4, Roosevelt Rd.',
      gameDate: input.gameDate,
      startAt: input.startAt,
      endAt: input.endAt,
      skillLevelMin: 'L2',
      skillLevelMax: 'L4',
      fee: 200,
      capacity: input.capacity,
      availableSpots: input.availableSpots,
      courtCount: 2,
      shuttleType: 'FEATHER',
      approvalMode: input.approvalMode,
      status: 'OPEN',
    },
    select: {
      id: true,
    },
  });

  return {
    id: game.id,
  };
}

function authHeaders(user: { id: string; email: string }): Record<string, string> {
  const token = app.jwt.sign({
    sub: user.id,
    email: user.email,
  });

  return {
    authorization: `Bearer ${token}`,
  };
}

async function injectJson(
  method: 'GET' | 'POST' | 'PATCH',
  url: string,
  options: {
    headers?: Record<string, string>;
    payload?: unknown;
  } = {}
): Promise<{
  statusCode: number;
  json: any;
}> {
  const response = await app.inject({
    method,
    url,
    headers: options.headers,
    payload: options.payload,
  });

  return {
    statusCode: response.statusCode,
    json: response.body.length > 0 ? JSON.parse(response.body) : null,
  };
}
