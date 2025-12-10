/**
 * Auth Port Tests
 *
 * Tests for the Auth port interface and schema definitions.
 */
import { describe, expect, test } from 'bun:test';
import { Schema } from 'effect';

// Schema tests - these will pass once we implement the port
describe('Auth Port', () => {
  describe('Session Schema', () => {
    test('validates a valid session', async () => {
      const { Session } = await import('@/ports/auth');
      const validSession = {
        id: 'sess_123',
        userId: 'user_456',
        expiresAt: '2025-12-31T00:00:00.000Z',
        createdAt: '2025-12-01T00:00:00.000Z',
      };
      const result = Schema.decodeUnknownSync(Session)(validSession);
      expect(result.id).toBe('sess_123');
      expect(result.userId).toBe('user_456');
    });

    test('rejects session with missing fields', async () => {
      const { Session } = await import('@/ports/auth');
      const invalidSession = { id: 'sess_123' };
      expect(() => Schema.decodeUnknownSync(Session)(invalidSession)).toThrow();
    });
  });

  describe('User Schema', () => {
    test('validates a valid user', async () => {
      const { User } = await import('@/ports/auth');
      const validUser = {
        id: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        emailVerified: true,
        createdAt: '2025-01-01T00:00:00.000Z',
        updatedAt: '2025-12-01T00:00:00.000Z',
      };
      const result = Schema.decodeUnknownSync(User)(validUser);
      expect(result.email).toBe('test@example.com');
    });

    test('allows optional name field', async () => {
      const { User } = await import('@/ports/auth');
      const userWithoutName = {
        id: 'user_123',
        email: 'test@example.com',
        emailVerified: false,
        createdAt: '2025-01-01T00:00:00.000Z',
        updatedAt: '2025-12-01T00:00:00.000Z',
      };
      const result = Schema.decodeUnknownSync(User)(userWithoutName);
      expect(result.name).toBeUndefined();
    });
  });

  describe('AuthError Schema', () => {
    test('creates tagged error with valid code', async () => {
      const { AuthError } = await import('@/ports/auth');
      const error = new AuthError({ code: 'INVALID_CREDENTIALS', message: 'Bad password' });
      expect(error._tag).toBe('AuthError');
      expect(error.code).toBe('INVALID_CREDENTIALS');
    });
  });

  describe('Auth Context Tag', () => {
    test('Auth tag is defined', async () => {
      const { Auth } = await import('@/ports/auth');
      expect(Auth).toBeDefined();
      expect(Auth.key).toBe('Auth');
    });
  });
});
