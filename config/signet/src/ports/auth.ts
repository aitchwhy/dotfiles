/**
 * Auth Port - Authentication Service Interface
 *
 * Defines the contract for authentication operations.
 * Implemented by adapters like BetterAuth.
 *
 * Pattern: TypeScript types are source of truth, schemas satisfy types.
 */
import { Context, Effect, Schema } from 'effect';

// ============================================================================
// TYPESCRIPT TYPES (Source of Truth)
// ============================================================================

/**
 * User session
 */
export type Session = {
  readonly id: string;
  readonly userId: string;
  readonly expiresAt: Date;
  readonly createdAt: Date;
};

/**
 * User account
 */
export type User = {
  readonly id: string;
  readonly email: string;
  readonly name?: string | undefined;
  readonly emailVerified: boolean;
  readonly createdAt: Date;
  readonly updatedAt: Date;
};

/**
 * Authentication error codes
 */
export type AuthErrorCode =
  | 'INVALID_CREDENTIALS'
  | 'SESSION_EXPIRED'
  | 'SESSION_NOT_FOUND'
  | 'USER_NOT_FOUND'
  | 'RATE_LIMITED'
  | 'INTERNAL_ERROR';

// ============================================================================
// EFFECT SCHEMAS
// ============================================================================

// Note: Schema.Date encodes to string for wire format, so we can't use
// `satisfies Schema.Schema<Session>` directly. The Type property will still
// match our TypeScript types at runtime.

export const sessionSchema = Schema.Struct({
  id: Schema.String,
  userId: Schema.String,
  expiresAt: Schema.Date,
  createdAt: Schema.Date,
});

export const userSchema = Schema.Struct({
  id: Schema.String,
  email: Schema.String,
  name: Schema.optional(Schema.String),
  emailVerified: Schema.Boolean,
  createdAt: Schema.Date,
  updatedAt: Schema.Date,
});

// Legacy exports for backwards compatibility
export const Session = sessionSchema;
export const User = userSchema;

// ============================================================================
// ERRORS
// ============================================================================

export class AuthError extends Schema.TaggedError<AuthError>()('AuthError', {
  code: Schema.Literal(
    'INVALID_CREDENTIALS',
    'SESSION_EXPIRED',
    'SESSION_NOT_FOUND',
    'USER_NOT_FOUND',
    'RATE_LIMITED',
    'INTERNAL_ERROR'
  ),
  message: Schema.String,
}) {}

// ============================================================================
// PORT INTERFACE
// ============================================================================

export interface AuthService {
  readonly validateSession: (token: string) => Effect.Effect<Session, AuthError>;
  readonly getUser: (userId: string) => Effect.Effect<User, AuthError>;
  readonly createSession: (userId: string) => Effect.Effect<Session, AuthError>;
  readonly revokeSession: (sessionId: string) => Effect.Effect<void, AuthError>;
}

export class Auth extends Context.Tag('Auth')<Auth, AuthService>() {}
