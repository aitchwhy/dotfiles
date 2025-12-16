/**
 * Better-Auth Adapter
 *
 * Implements the Auth port using Better-Auth library.
 * Provides session validation, user management, and authentication.
 */
import { Effect, Layer } from 'effect';
import { Auth, AuthError, type AuthService, type Session, type User } from '@/ports/auth';

// ============================================================================
// CONFIG
// ============================================================================

export interface BetterAuthConfig {
  readonly baseUrl: string;
  readonly secret: string;
  readonly sessionCookieName?: string;
}

// ============================================================================
// ADAPTER IMPLEMENTATION
// ============================================================================

const makeAuthService = (config: BetterAuthConfig): AuthService => ({
  validateSession: (token: string) =>
    Effect.tryPromise({
      try: async () => {
        // Better-Auth session validation logic
        // This is a placeholder - actual implementation would use better-auth client
        const response = await fetch(`${config.baseUrl}/api/auth/session`, {
          headers: { Authorization: `Bearer ${token}` },
        });

        if (!response.ok) {
          throw new AuthError({
            code: response.status === 401 ? 'SESSION_EXPIRED' : 'INTERNAL_ERROR',
            message: 'Session validation failed',
          });
        }

        const data = await response.json();
        return data as Session;
      },
      catch: (error) =>
        new AuthError({
          code: 'INTERNAL_ERROR',
          message: error instanceof Error ? error.message : 'Unknown error',
        }),
    }),

  getUser: (userId: string) =>
    Effect.tryPromise({
      try: async () => {
        const response = await fetch(`${config.baseUrl}/api/auth/user/${userId}`);

        if (!response.ok) {
          throw new AuthError({
            code: response.status === 404 ? 'USER_NOT_FOUND' : 'INTERNAL_ERROR',
            message: 'User fetch failed',
          });
        }

        const data = await response.json();
        return data as User;
      },
      catch: (error) =>
        new AuthError({
          code: 'INTERNAL_ERROR',
          message: error instanceof Error ? error.message : 'Unknown error',
        }),
    }),

  createSession: (userId: string) =>
    Effect.tryPromise({
      try: async () => {
        const response = await fetch(`${config.baseUrl}/api/auth/session`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ userId }),
        });

        if (!response.ok) {
          throw new AuthError({
            code: 'INTERNAL_ERROR',
            message: 'Session creation failed',
          });
        }

        const data = await response.json();
        return data as Session;
      },
      catch: (error) =>
        new AuthError({
          code: 'INTERNAL_ERROR',
          message: error instanceof Error ? error.message : 'Unknown error',
        }),
    }),

  revokeSession: (sessionId: string) =>
    Effect.tryPromise({
      try: async () => {
        const response = await fetch(`${config.baseUrl}/api/auth/session/${sessionId}`, {
          method: 'DELETE',
        });

        if (!response.ok) {
          throw new AuthError({
            code: response.status === 404 ? 'SESSION_NOT_FOUND' : 'INTERNAL_ERROR',
            message: 'Session revocation failed',
          });
        }
      },
      catch: (error) =>
        new AuthError({
          code: 'INTERNAL_ERROR',
          message: error instanceof Error ? error.message : 'Unknown error',
        }),
    }),
});

// ============================================================================
// LAYER FACTORY
// ============================================================================

export const makeBetterAuthLive = (config: BetterAuthConfig): Layer.Layer<Auth> =>
  Layer.succeed(Auth, makeAuthService(config));
