/**
 * Example Schema Tests
 *
 * Tests for Zod schema validation.
 */
import { describe, expect, test } from 'bun:test';
import { CreateUserSchema, UserSchema, parseUser, safeParseUser } from '@/schemas/example';

describe('UserSchema', () => {
  const validUser = {
    id: '550e8400-e29b-41d4-a716-446655440000',
    email: 'test@example.com',
    name: 'Test User',
    role: 'user',
    createdAt: '2024-01-01T00:00:00Z',
  };

  describe('parseUser', () => {
    test('parses valid user data', () => {
      const user = parseUser(validUser);
      expect(user.email).toBe('test@example.com');
      expect(user.name).toBe('Test User');
      expect(user.role).toBe('user');
    });

    test('throws on invalid email', () => {
      expect(() => parseUser({ ...validUser, email: 'invalid' })).toThrow();
    });

    test('throws on missing required fields', () => {
      expect(() => parseUser({ email: 'test@example.com' })).toThrow();
    });

    test('throws on invalid role', () => {
      expect(() => parseUser({ ...validUser, role: 'superadmin' })).toThrow();
    });
  });

  describe('safeParseUser', () => {
    test('returns success for valid data', () => {
      const result = safeParseUser(validUser);
      expect(result.success).toBe(true);
    });

    test('returns error for invalid data', () => {
      const result = safeParseUser({ email: 'invalid' });
      expect(result.success).toBe(false);
    });
  });

  describe('CreateUserSchema', () => {
    test('validates creation input without id/createdAt', () => {
      const input = {
        email: 'new@example.com',
        name: 'New User',
        role: 'user',
      };
      const result = CreateUserSchema.safeParse(input);
      expect(result.success).toBe(true);
    });

    test('rejects empty name', () => {
      const input = {
        email: 'new@example.com',
        name: '',
        role: 'user',
      };
      const result = CreateUserSchema.safeParse(input);
      expect(result.success).toBe(false);
    });
  });

  describe('branded types', () => {
    test('UserId is branded string', () => {
      const user = parseUser(validUser);
      // TypeScript ensures this is a branded UserId, not just string
      const id: string = user.id; // Valid assignment
      expect(typeof id).toBe('string');
    });
  });
});
