import crypto from 'node:crypto';
import type { FastifyPluginAsync, FastifyRequest } from 'fastify';
import { prisma } from '../../lib/prisma';
import { AppError } from '../../lib/errors';
import { z } from 'zod';

// Utility to create a secure random state string
function generateState(): string {
  return crypto.randomBytes(16).toString('hex');
}

type LineLoginState = {
  nonce: string;
  redirectTo?: string;
};

function encodeState(state: LineLoginState): string {
  return Buffer.from(JSON.stringify(state), 'utf8').toString('base64url');
}

function decodeState(value?: string): LineLoginState | null {
  if (!value) {
    return null;
  }

  try {
    const parsed = JSON.parse(Buffer.from(value, 'base64url').toString('utf8')) as LineLoginState;
    return parsed;
  } catch {
    return null;
  }
}

function getRequestBaseUrl(request: FastifyRequest): string {
  const forwardedProtoHeader = request.headers['x-forwarded-proto'];
  const forwardedHostHeader = request.headers['x-forwarded-host'];
  const forwardedProto = Array.isArray(forwardedProtoHeader)
    ? forwardedProtoHeader[0]
    : forwardedProtoHeader;
  const forwardedHost = Array.isArray(forwardedHostHeader)
    ? forwardedHostHeader[0]
    : forwardedHostHeader;
  const hostHeader = Array.isArray(request.headers.host)
    ? request.headers.host[0]
    : request.headers.host;

  const protocol = typeof forwardedProto === 'string' && forwardedProto.trim().length > 0
    ? forwardedProto.trim()
    : request.protocol;
  const host = typeof forwardedHost === 'string' && forwardedHost.trim().length > 0
    ? forwardedHost.trim()
    : hostHeader;

  if (!host) {
    return 'http://localhost:3000';
  }

  return `${protocol}://${host}`;
}

export const lineAuthRoutes: FastifyPluginAsync = async (app) => {
  // 1. Authorization Endpoint
  app.get('/line/login', async (request, reply) => {
    const clientId = process.env.LINE_CLIENT_ID;
    const querySchema = z.object({
      redirectTo: z.string().url().optional(),
    });
    const query = querySchema.parse(request.query);
    
    // Fallback if not configured
    if (!clientId || clientId === 'mock_client_id') {
      // In a real local dev environment without a LINE channel, 
      // you could return a mock error or simulated flow here.
      // But we will follow the real LINE v2.1 redirect instructions:
    }

    const apiBaseUrl = getRequestBaseUrl(request);
    const redirectUri = `${apiBaseUrl}/api/v1/auth/line/callback`;
    const state = encodeState({
      nonce: generateState(),
      redirectTo: query.redirectTo,
    });
    
    // We request profile, openid, and email scopes
    const authUrl = `https://access.line.me/oauth2/v2.1/authorize?response_type=code&client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri)}&state=${state}&scope=${encodeURIComponent('profile openid email')}`;
    
    return reply.redirect(authUrl);
  });

  // 2. Callback Endpoint
  app.get('/line/callback', async (request, reply) => {
    const querySchema = z.object({
      code: z.string().optional(),
      state: z.string().optional(),
      error: z.string().optional(),
      error_description: z.string().optional(),
    });

    const query = querySchema.parse(request.query);

    if (query.error || !query.code) {
      throw new AppError(400, 'LINE_AUTH_ERROR', `LINE Auth failed: ${query.error_description || 'No code provided'}`);
    }

    const clientId = process.env.LINE_CLIENT_ID!;
    const clientSecret = process.env.LINE_CLIENT_SECRET!;
    const apiBaseUrl = getRequestBaseUrl(request);
    const redirectUri = `${apiBaseUrl}/api/v1/auth/line/callback`;

    // Exchange code for Access/ID Token
    const tokenOptions = {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        code: query.code,
        redirect_uri: redirectUri,
        client_id: clientId,
        client_secret: clientSecret,
      }).toString()
    };

    const tokenResponse = await fetch('https://api.line.me/oauth2/v2.1/token', tokenOptions);
    const tokenData = await tokenResponse.json() as any;

    if (!tokenResponse.ok) {
      throw new AppError(400, 'LINE_TOKEN_ERROR', `Failed to exchange token: ${tokenData.error_description || tokenData.error}`);
    }

    // Verify ID Token to extract user info securely
    const verifyOptions = {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
          id_token: tokenData.id_token,
          client_id: clientId
        }).toString()
    };
    
    const verifyResponse = await fetch('https://api.line.me/oauth2/v2.1/verify', verifyOptions);
    const verifyData = await verifyResponse.json() as any;

    if (!verifyResponse.ok) {
        throw new AppError(400, 'LINE_VERIFY_ERROR', `Failed to verify ID token: ${verifyData.error_description || verifyData.error}`);
    }

    const { sub: lineProviderId, name, email, picture } = verifyData;

    if (!lineProviderId) {
        throw new AppError(400, 'LINE_DATA_ERROR', 'LINE profile missing sub identifier');
    }

    // Upsert User in Database
    let user = await prisma.user.findUnique({
        where: { lineProviderId }
    });

    if (!user) {
        // If no user found by LINE ID, check if email exists to link accounts
        if (email) {
            user = await prisma.user.findUnique({ where: { email } });
        }

        if (user) {
            // Link existing user account
            user = await prisma.user.update({
                where: { id: user.id },
                data: { lineProviderId }
            });
        } else {
            // Create brand new user
            user = await prisma.user.create({
                data: {
                    lineProviderId,
                    email: email || undefined,
                    nickname: name || 'LINE User',
                    avatarUrl: picture,
                    skillLevel: 'L1', // Default skill
                }
            });
        }
    }

    // Issue JWT Token
    const appToken = await reply.jwtSign({
      sub: user.id,
      email: user.email ?? undefined,
    });

    // Determine return URL (Frontend App)
    const state = decodeState(query.state);
    const frontendUrl = state?.redirectTo || process.env.FRONTEND_WEB_URL || 'http://localhost:8080';
    const callbackUrl = new URL('/auth/callback', frontendUrl);
    callbackUrl.searchParams.set('token', appToken);
    return reply.redirect(callbackUrl.toString());
  });
};
