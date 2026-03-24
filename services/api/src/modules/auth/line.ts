import crypto from 'node:crypto';
import type { FastifyPluginAsync } from 'fastify';
import { prisma } from '../../lib/prisma';
import { AppError } from '../../lib/errors';
import { z } from 'zod';

// Utility to create a secure random state string
function generateState(): string {
  return crypto.randomBytes(16).toString('hex');
}

export const lineAuthRoutes: FastifyPluginAsync = async (app) => {
  // 1. Authorization Endpoint
  app.get('/line/login', async (request, reply) => {
    const clientId = process.env.LINE_CLIENT_ID;
    
    // Fallback if not configured
    if (!clientId || clientId === 'mock_client_id') {
      // In a real local dev environment without a LINE channel, 
      // you could return a mock error or simulated flow here.
      // But we will follow the real LINE v2.1 redirect instructions:
    }

    const redirectUri = `${process.env.API_BASE_URL || 'http://localhost:3000'}/api/v1/auth/line/callback`;
    const state = generateState();
    
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
    const redirectUri = `${process.env.API_BASE_URL || 'http://localhost:3000'}/api/v1/auth/line/callback`;

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
    const frontendUrl = process.env.FRONTEND_WEB_URL || 'http://localhost:8080';
    return reply.redirect(`${frontendUrl}/profile?token=${appToken}`);
  });
};
