import assert from 'node:assert/strict';
import { after, before, beforeEach, test } from 'node:test';

import type { FastifyInstance } from 'fastify';
import type { PrismaClient } from '@prisma/client';

import type { AppEnv } from '../../src/lib/config';
import { hashPassword } from '../../src/modules/auth/password';

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

test('register, login, auth/me, and users/me update the profile', async () => {
  const registerResponse = await injectJson('POST', '/api/v1/auth/register', {
    payload: {
      email: 'new-player@example.com',
      password: 'password123',
      nickname: 'New Player',
      skillLevel: 'L2',
    },
  });

  assert.equal(registerResponse.statusCode, 201, JSON.stringify(registerResponse.json));
  assert.equal(registerResponse.json.user.nickname, 'New Player');
  assert.equal(registerResponse.json.user.skillLevel, 'L2');
  assert.match(registerResponse.json.token, /^[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+$/);

  const duplicateRegister = await injectJson('POST', '/api/v1/auth/register', {
    payload: {
      email: 'new-player@example.com',
      password: 'password123',
      nickname: 'New Player 2',
      skillLevel: 'L3',
    },
  });

  assert.equal(duplicateRegister.statusCode, 409);
  assert.equal(duplicateRegister.json.error, 'USER_ALREADY_EXISTS');

  const loginResponse = await injectJson('POST', '/api/v1/auth/login', {
    payload: {
      emailOrPhone: 'new-player@example.com',
      password: 'password123',
    },
  });

  assert.equal(loginResponse.statusCode, 200);
  assert.equal(loginResponse.json.user.id, registerResponse.json.user.id);

  const authMe = await injectJson('GET', '/api/v1/auth/me', {
    headers: authHeaders(loginResponse.json.token),
  });

  assert.equal(authMe.statusCode, 200);
  assert.equal(authMe.json.user.id, registerResponse.json.user.id);

  const updated = await injectJson('PATCH', '/api/v1/users/me', {
    headers: authHeaders(loginResponse.json.token),
    payload: {
      nickname: 'Updated Player',
      avatarUrl: 'https://example.com/avatar.png',
      gender: 'OTHER',
      skillLevel: 'L3',
      preferredCity: 'Taipei City',
      preferredDistrict: 'Da\'an',
    },
  });

  assert.equal(updated.statusCode, 200);
  assert.equal(updated.json.user.nickname, 'Updated Player');
  assert.equal(updated.json.user.avatarUrl, 'https://example.com/avatar.png');
  assert.equal(updated.json.user.gender, 'OTHER');
  assert.equal(updated.json.user.skillLevel, 'L3');
  assert.equal(updated.json.user.preferredCity, 'Taipei City');
  assert.equal(updated.json.user.preferredDistrict, 'Da\'an');

  const refreshed = await injectJson('GET', '/api/v1/auth/me', {
    headers: authHeaders(loginResponse.json.token),
  });

  assert.equal(refreshed.statusCode, 200);
  assert.equal(refreshed.json.user.nickname, 'Updated Player');
});

test('login rejects an invalid password', async () => {
  await prisma.user.create({
    data: {
      email: 'existing-player@example.com',
      passwordHash: hashPassword('correct-password'),
      nickname: 'Existing Player',
      skillLevel: 'L3',
    },
  });

  const response = await injectJson('POST', '/api/v1/auth/login', {
    payload: {
      emailOrPhone: 'existing-player@example.com',
      password: 'wrong-password',
    },
  });

  assert.equal(response.statusCode, 401);
  assert.equal(response.json.error, 'INVALID_CREDENTIALS');
});

async function injectJson(
  method: string,
  url: string,
  options: {
    headers?: Record<string, string>;
    payload?: unknown;
  } = {}
): Promise<{ statusCode: number; json: any }> {
  const response = await app.inject({
    method,
    url,
    headers: {
      'content-type': 'application/json',
      ...(options.headers ?? {}),
    },
    payload: options.payload,
  });

  return {
    statusCode: response.statusCode,
    json: response.json(),
  };
}

function authHeaders(token: string): Record<string, string> {
  return {
    authorization: `Bearer ${token}`,
  };
}
