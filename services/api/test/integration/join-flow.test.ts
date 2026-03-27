import assert from 'node:assert/strict';
import { after, before, beforeEach, test } from 'node:test';

import type { FastifyInstance } from 'fastify';
import type { PrismaClient } from '@prisma/client';

import type { AppEnv } from '../../src/lib/config';

const TEST_POSTGRES_PORT = process.env.POSTGRES_PORT ?? '5433';
const TEST_DATABASE_URL = `postgresql://postgres:postgres@localhost:${TEST_POSTGRES_PORT}/bat_dating_app_test`;
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
  assert.equal(detailAfterJoin.json.canViewHostContact, true);
  assert.equal(detailAfterJoin.json.host.phoneNumber, '+886912345678');
  assert.equal(detailAfterJoin.json.host.lineId, 'auto-host-line');

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
  assert.equal(detailAfterWithdraw.json.canViewHostContact, false);
  assert.equal(detailAfterWithdraw.json.host.phoneNumber, undefined);
  assert.equal(detailAfterWithdraw.json.host.lineId, undefined);

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
  assert.equal(rejectedDetail.json.canViewHostContact, false);
  assert.equal(rejectedDetail.json.host.phoneNumber, undefined);
  assert.equal(rejectedDetail.json.host.lineId, undefined);
});

test('guest can browse game detail but cannot see host contact', async () => {
  const fixtures = await seedFixtures();

  const guestDetail = await injectJson('GET', `/api/v1/games/${fixtures.autoGame.id}`);

  assert.equal(guestDetail.statusCode, 200);
  assert.equal(guestDetail.json.status, 'OPEN');
  assert.equal(guestDetail.json.joinSummary.currentUserStatus, null);
  assert.equal(guestDetail.json.canViewHostContact, false);
  assert.equal(guestDetail.json.host.phoneNumber, undefined);
  assert.equal(guestDetail.json.host.lineId, undefined);
});

test('cancelled games cascade active requests and stop future joins', async () => {
  const fixtures = await seedFixtures();

  const approvedJoinResponse = await injectJson('POST', `/api/v1/games/${fixtures.autoGame.id}/join`, {
    headers: authHeaders(fixtures.autoJoiner),
    payload: {
      message: 'I am in.',
    },
  });

  assert.equal(approvedJoinResponse.statusCode, 201, JSON.stringify(approvedJoinResponse.json));
  assert.equal(approvedJoinResponse.json.joinRequest.status, 'APPROVED');

  const pendingJoinResponse = await injectJson(
    'POST',
    `/api/v1/games/${fixtures.manualApproveGame.id}/join`,
    {
      headers: authHeaders(fixtures.manualApprover),
      payload: {
        message: 'Waiting for approval.',
      },
    }
  );

  assert.equal(pendingJoinResponse.statusCode, 201, JSON.stringify(pendingJoinResponse.json));
  assert.equal(pendingJoinResponse.json.joinRequest.status, 'PENDING');

  const cancelResponse = await injectJson(
    'PATCH',
    `/api/v1/games/${fixtures.manualApproveGame.id}/status`,
    {
      headers: authHeaders(fixtures.manualHost),
      payload: {
        status: 'CANCELLED',
      },
    }
  );

  assert.equal(cancelResponse.statusCode, 200, JSON.stringify(cancelResponse.json));
  assert.equal(cancelResponse.json.status, 'CANCELLED');
  assert.equal(cancelResponse.json.availableSpots, 0);

  const cancelApprovedGameResponse = await injectJson(
    'PATCH',
    `/api/v1/games/${fixtures.autoGame.id}/status`,
    {
      headers: authHeaders(fixtures.autoHost),
      payload: {
        status: 'CANCELLED',
      },
    }
  );

  assert.equal(cancelApprovedGameResponse.statusCode, 200, JSON.stringify(cancelApprovedGameResponse.json));
  assert.equal(cancelApprovedGameResponse.json.status, 'CANCELLED');

  const cancelledAutoHostDetail = await injectJson('GET', `/api/v1/games/${fixtures.autoGame.id}`, {
    headers: authHeaders(fixtures.autoHost),
  });

  assert.equal(cancelledAutoHostDetail.statusCode, 200);
  assert.equal(cancelledAutoHostDetail.json.status, 'CANCELLED');
  assert.equal(cancelledAutoHostDetail.json.canViewHostContact, true);
  assert.equal(cancelledAutoHostDetail.json.host.phoneNumber, '+886912345678');
  assert.equal(cancelledAutoHostDetail.json.host.lineId, 'auto-host-line');

  const cancelledAutoHostJoinRequests = await injectJson(
    'GET',
    `/api/v1/games/${fixtures.autoGame.id}/join-requests`,
    {
      headers: authHeaders(fixtures.autoHost),
    }
  );

  assert.equal(cancelledAutoHostJoinRequests.statusCode, 200);
  assert.equal(cancelledAutoHostJoinRequests.json.total, 1);
  assert.equal(cancelledAutoHostJoinRequests.json.items[0].status, 'CANCELLED');

  const autoJoinerJoinedGamesAfterCancel = await injectJson('GET', '/api/v1/me/games/joined', {
    headers: authHeaders(fixtures.autoJoiner),
  });

  assert.equal(autoJoinerJoinedGamesAfterCancel.statusCode, 200);
  assert.equal(autoJoinerJoinedGamesAfterCancel.json.total, 0);
  assert.equal(autoJoinerJoinedGamesAfterCancel.json.items.length, 0);

  const hostJoinRequests = await injectJson(
    'GET',
    `/api/v1/games/${fixtures.manualApproveGame.id}/join-requests`,
    {
      headers: authHeaders(fixtures.manualHost),
    }
  );

  assert.equal(hostJoinRequests.statusCode, 200);
  assert.equal(hostJoinRequests.json.total, 1);
  assert.equal(hostJoinRequests.json.items[0].status, 'CANCELLED');

  const rejectCancelledRequest = await injectJson(
    'PATCH',
    `/api/v1/join-requests/${pendingJoinResponse.json.joinRequest.id}/reject`,
    {
      headers: authHeaders(fixtures.manualHost),
      payload: {
        reason: 'Game is already cancelled.',
      },
    }
  );

  assert.equal(rejectCancelledRequest.statusCode, 409, JSON.stringify(rejectCancelledRequest.json));
  assert.equal(rejectCancelledRequest.json.error, 'GAME_NOT_EDITABLE');

  const cancelledDetail = await injectJson('GET', `/api/v1/games/${fixtures.manualApproveGame.id}`, {
    headers: authHeaders(fixtures.manualApprover),
  });

  assert.equal(cancelledDetail.statusCode, 200);
  assert.equal(cancelledDetail.json.status, 'CANCELLED');
  assert.equal(cancelledDetail.json.joinSummary.currentUserStatus, 'CANCELLED');
  assert.equal(cancelledDetail.json.canViewHostContact, false);
  assert.equal(cancelledDetail.json.host.phoneNumber, undefined);
  assert.equal(cancelledDetail.json.host.lineId, undefined);

  const joinCancelledGame = await injectJson('POST', `/api/v1/games/${fixtures.manualApproveGame.id}/join`, {
    headers: authHeaders(fixtures.manualRejecter),
    payload: {
      message: 'Can I still join?',
    },
  });

  assert.equal(joinCancelledGame.statusCode, 409);
  assert.equal(joinCancelledGame.json.error, 'GAME_NOT_JOINABLE');
});

test('approve, reject, withdraw, and cancel enforce ownership and state guards', async () => {
  const fixtures = await seedFixtures();

  const pendingResponse = await injectJson('POST', `/api/v1/games/${fixtures.manualApproveGame.id}/join`, {
    headers: authHeaders(fixtures.manualApprover),
    payload: {
      message: 'Let me in.',
    },
  });

  assert.equal(pendingResponse.statusCode, 201, JSON.stringify(pendingResponse.json));

  const nonHostApprove = await injectJson(
    'PATCH',
    `/api/v1/join-requests/${pendingResponse.json.joinRequest.id}/approve`,
    {
      headers: authHeaders(fixtures.manualRejecter),
    }
  );

  assert.equal(nonHostApprove.statusCode, 403);
  assert.equal(nonHostApprove.json.error, 'FORBIDDEN');

  const approvedResponse = await injectJson(
    'PATCH',
    `/api/v1/join-requests/${pendingResponse.json.joinRequest.id}/approve`,
    {
      headers: authHeaders(fixtures.manualHost),
    }
  );

  assert.equal(approvedResponse.statusCode, 200);
  assert.equal(approvedResponse.json.status, 'APPROVED');

  const rejectApproved = await injectJson(
    'PATCH',
    `/api/v1/join-requests/${pendingResponse.json.joinRequest.id}/reject`,
    {
      headers: authHeaders(fixtures.manualHost),
      payload: {
        reason: 'Too late.',
      },
    }
  );

  assert.equal(rejectApproved.statusCode, 409);
  assert.equal(rejectApproved.json.error, 'INVALID_JOIN_REQUEST_STATE');

  const nonOwnerWithdraw = await injectJson(
    'PATCH',
    `/api/v1/join-requests/${pendingResponse.json.joinRequest.id}/withdraw`,
    {
      headers: authHeaders(fixtures.manualRejecter),
    }
  );

  assert.equal(nonOwnerWithdraw.statusCode, 403);
  assert.equal(nonOwnerWithdraw.json.error, 'FORBIDDEN');

  const withdrawnResponse = await injectJson(
    'PATCH',
    `/api/v1/join-requests/${pendingResponse.json.joinRequest.id}/withdraw`,
    {
      headers: authHeaders(fixtures.manualApprover),
    }
  );

  assert.equal(withdrawnResponse.statusCode, 200);
  assert.equal(withdrawnResponse.json.status, 'WITHDRAWN');

  const withdrawAgain = await injectJson(
    'PATCH',
    `/api/v1/join-requests/${pendingResponse.json.joinRequest.id}/withdraw`,
    {
      headers: authHeaders(fixtures.manualApprover),
    }
  );

  assert.equal(withdrawAgain.statusCode, 409);
  assert.equal(withdrawAgain.json.error, 'INVALID_JOIN_REQUEST_STATE');

  const nonHostCancel = await injectJson(
    'PATCH',
    `/api/v1/games/${fixtures.manualRejectGame.id}/status`,
    {
      headers: authHeaders(fixtures.manualRejecter),
      payload: {
        status: 'CANCELLED',
      },
    }
  );

  assert.equal(nonHostCancel.statusCode, 403);
  assert.equal(nonHostCancel.json.error, 'FORBIDDEN');
});

test('only the host can access the participant list', async () => {
  const fixtures = await seedFixtures();

  const nonHostJoinRequests = await injectJson(
    'GET',
    `/api/v1/games/${fixtures.manualApproveGame.id}/join-requests`,
    {
      headers: authHeaders(fixtures.manualApprover),
    }
  );

  assert.equal(nonHostJoinRequests.statusCode, 403);
  assert.equal(nonHostJoinRequests.json.error, 'FORBIDDEN');
});

test('completed games stay out of my games and hide host contact', async () => {
  const fixtures = await seedFixtures();

  const pendingResponse = await injectJson('POST', `/api/v1/games/${fixtures.manualApproveGame.id}/join`, {
    headers: authHeaders(fixtures.manualApprover),
    payload: {
      message: 'Waiting for the result.',
    },
  });

  assert.equal(pendingResponse.statusCode, 201, JSON.stringify(pendingResponse.json));
  assert.equal(pendingResponse.json.joinRequest.status, 'PENDING');

  const approvedJoinResponse = await injectJson('POST', `/api/v1/games/${fixtures.autoGame.id}/join`, {
    headers: authHeaders(fixtures.autoJoiner),
    payload: {
      message: 'Ready to play.',
    },
  });

  assert.equal(approvedJoinResponse.statusCode, 201, JSON.stringify(approvedJoinResponse.json));
  assert.equal(approvedJoinResponse.json.joinRequest.status, 'APPROVED');

  const completedResponse = await injectJson(
    'PATCH',
    `/api/v1/games/${fixtures.autoGame.id}/status`,
    {
      headers: authHeaders(fixtures.autoHost),
      payload: {
        status: 'COMPLETED',
      },
    }
  );

  assert.equal(completedResponse.statusCode, 200, JSON.stringify(completedResponse.json));
  assert.equal(completedResponse.json.status, 'COMPLETED');

  const completedDetail = await injectJson('GET', `/api/v1/games/${fixtures.autoGame.id}`, {
    headers: authHeaders(fixtures.autoJoiner),
  });

  assert.equal(completedDetail.statusCode, 200);
  assert.equal(completedDetail.json.status, 'COMPLETED');
  assert.equal(completedDetail.json.joinSummary.currentUserStatus, 'APPROVED');
  assert.equal(completedDetail.json.canViewHostContact, false);
  assert.equal(completedDetail.json.host.phoneNumber, undefined);
  assert.equal(completedDetail.json.host.lineId, undefined);

  const completedHostDetail = await injectJson('GET', `/api/v1/games/${fixtures.autoGame.id}`, {
    headers: authHeaders(fixtures.autoHost),
  });

  assert.equal(completedHostDetail.statusCode, 200);
  assert.equal(completedHostDetail.json.status, 'COMPLETED');
  assert.equal(completedHostDetail.json.canViewHostContact, true);
  assert.equal(completedHostDetail.json.host.phoneNumber, '+886912345678');
  assert.equal(completedHostDetail.json.host.lineId, 'auto-host-line');

  const completedHostJoinRequests = await injectJson(
    'GET',
    `/api/v1/games/${fixtures.autoGame.id}/join-requests`,
    {
      headers: authHeaders(fixtures.autoHost),
    }
  );

  assert.equal(completedHostJoinRequests.statusCode, 200);
  assert.equal(completedHostJoinRequests.json.total, 1);
  assert.equal(completedHostJoinRequests.json.items[0].status, 'APPROVED');

  const completedManualGameResponse = await injectJson(
    'PATCH',
    `/api/v1/games/${fixtures.manualApproveGame.id}/status`,
    {
      headers: authHeaders(fixtures.manualHost),
      payload: {
        status: 'COMPLETED',
      },
    }
  );

  assert.equal(completedManualGameResponse.statusCode, 200, JSON.stringify(completedManualGameResponse.json));
  assert.equal(completedManualGameResponse.json.status, 'COMPLETED');

  const completedManualHostJoinRequests = await injectJson(
    'GET',
    `/api/v1/games/${fixtures.manualApproveGame.id}/join-requests`,
    {
      headers: authHeaders(fixtures.manualHost),
    }
  );

  assert.equal(completedManualHostJoinRequests.statusCode, 200);
  assert.equal(completedManualHostJoinRequests.json.total, 1);
  assert.equal(completedManualHostJoinRequests.json.items[0].status, 'PENDING');

  const rejectCompletedGame = await injectJson(
    'PATCH',
    `/api/v1/join-requests/${pendingResponse.json.joinRequest.id}/reject`,
    {
      headers: authHeaders(fixtures.manualHost),
      payload: {
        reason: 'Game is already completed.',
      },
    }
  );

  assert.equal(rejectCompletedGame.statusCode, 409, JSON.stringify(rejectCompletedGame.json));
  assert.equal(rejectCompletedGame.json.error, 'GAME_NOT_EDITABLE');

  const approveCompletedGame = await injectJson(
    'PATCH',
    `/api/v1/join-requests/${pendingResponse.json.joinRequest.id}/approve`,
    {
      headers: authHeaders(fixtures.manualHost),
    }
  );

  assert.equal(approveCompletedGame.statusCode, 409, JSON.stringify(approveCompletedGame.json));
  assert.equal(approveCompletedGame.json.error, 'GAME_NOT_EDITABLE');

  const withdrawCompletedGame = await injectJson(
    'PATCH',
    `/api/v1/join-requests/${approvedJoinResponse.json.joinRequest.id}/withdraw`,
    {
      headers: authHeaders(fixtures.autoJoiner),
    }
  );

  assert.equal(withdrawCompletedGame.statusCode, 409, JSON.stringify(withdrawCompletedGame.json));
  assert.equal(withdrawCompletedGame.json.error, 'GAME_NOT_WITHDRAWABLE');

  const joinedGamesAfterCompletion = await injectJson('GET', '/api/v1/me/games/joined', {
    headers: authHeaders(fixtures.autoJoiner),
  });

  assert.equal(joinedGamesAfterCompletion.statusCode, 200);
  assert.equal(joinedGamesAfterCompletion.json.total, 0);
  assert.equal(joinedGamesAfterCompletion.json.items.length, 0);

  const createdGames = await injectJson('GET', '/api/v1/me/games/created', {
    headers: authHeaders(fixtures.autoHost),
  });

  assert.equal(createdGames.statusCode, 200);
  assert.equal(createdGames.json.items.some((item: { id: string }) => item.id === fixtures.autoGame.id), false);
});

test('games feed defaults to upcoming open or full games and created games exclude past sessions', async () => {
  const fixtures = await seedFixtures();
  const now = new Date();
  const futureWindow = createFutureWindow(5);
  const pastWindow = createFutureWindow(-3);

  await createGame({
    hostId: fixtures.autoHost.id,
    title: 'Past Hosted Game',
    approvalMode: 'AUTO',
    availableSpots: 4,
    capacity: 4,
    ...pastWindow,
  });

  await createGame({
    hostId: fixtures.autoHost.id,
    title: 'Future Full Game',
    approvalMode: 'AUTO',
    availableSpots: 0,
    capacity: 4,
    status: 'FULL',
    ...futureWindow,
  });

  await createGame({
    hostId: fixtures.autoHost.id,
    title: 'Future Cancelled Game',
    approvalMode: 'AUTO',
    availableSpots: 0,
    capacity: 4,
    status: 'CANCELLED',
    gameDate: futureWindow.gameDate,
    startAt: new Date(futureWindow.startAt.getTime() + 3 * 60 * 60 * 1000),
    endAt: new Date(futureWindow.endAt.getTime() + 3 * 60 * 60 * 1000),
  });

  const feedResponse = await injectJson('GET', '/api/v1/games');

  assert.equal(feedResponse.statusCode, 200);
  assert.ok(feedResponse.json.total >= 3);
  assert.ok(
    feedResponse.json.items.every((item: { startAt: string; status: string }) => {
      return new Date(item.startAt) >= now && (item.status === 'OPEN' || item.status === 'FULL');
    })
  );
  assert.equal(
    feedResponse.json.items.some((item: { title: string }) => item.title === 'Past Hosted Game'),
    false
  );
  assert.equal(
    feedResponse.json.items.some((item: { title: string }) => item.title === 'Future Cancelled Game'),
    false
  );

  const createdGames = await injectJson('GET', '/api/v1/me/games/created', {
    headers: authHeaders(fixtures.autoHost),
  });

  assert.equal(createdGames.statusCode, 200);
  assert.equal(
    createdGames.json.items.some((item: { title: string }) => item.title === 'Past Hosted Game'),
    false
  );
  assert.equal(
    createdGames.json.items.some((item: { title: string }) => item.title === 'Future Cancelled Game'),
    true
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
  const autoHost = await createUser('auto-host@example.com', 'Auto Host', {
    phoneNumber: '+886912345678',
    lineId: 'auto-host-line',
  });
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
    ...createFutureWindow(1),
  });

  const manualApproveGame = await createGame({
    hostId: manualHost.id,
    title: 'Manual Approve Game',
    approvalMode: 'MANUAL',
    availableSpots: 2,
    capacity: 2,
    ...createFutureWindow(2),
  });

  const manualRejectGame = await createGame({
    hostId: manualRejectHost.id,
    title: 'Manual Reject Game',
    approvalMode: 'MANUAL',
    availableSpots: 2,
    capacity: 2,
    ...createFutureWindow(3),
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

async function createUser(
  email: string,
  nickname: string,
  input: {
    phoneNumber?: string;
    lineId?: string;
  } = {}
): Promise<{ id: string; email: string }> {
  const user = await prisma.user.create({
    data: {
      email,
      ...(input.phoneNumber ? { phoneNumber: input.phoneNumber } : {}),
      ...(input.lineId ? { lineId: input.lineId } : {}),
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
  status?: 'OPEN' | 'FULL' | 'CANCELLED' | 'COMPLETED';
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
      status: input.status ?? 'OPEN',
    },
    select: {
      id: true,
    },
  });

  return {
    id: game.id,
  };
}

function createFutureWindow(daysFromNow: number): {
  gameDate: Date;
  startAt: Date;
  endAt: Date;
} {
  const startAt = new Date();
  startAt.setUTCDate(startAt.getUTCDate() + daysFromNow);
  startAt.setUTCHours(11, 0, 0, 0);

  const endAt = new Date(startAt.getTime() + 2 * 60 * 60 * 1000);
  const gameDate = new Date(startAt.getTime());
  gameDate.setUTCHours(0, 0, 0, 0);

  return {
    gameDate,
    startAt,
    endAt,
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
