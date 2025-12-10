/**
 * Cache Port Tests
 *
 * Tests for the Cache port interface and schema definitions.
 */
import { describe, expect, test } from 'bun:test';
import { Schema } from 'effect';

describe('Cache Port', () => {
  describe('CacheOptions Schema', () => {
    test('validates options with ttl', async () => {
      const { CacheOptions } = await import('@/ports/cache');
      const validOptions = {
        ttlSeconds: 3600,
        namespace: 'sessions',
      };
      const result = Schema.decodeUnknownSync(CacheOptions)(validOptions);
      expect(result.ttlSeconds).toBe(3600);
      expect(result.namespace).toBe('sessions');
    });

    test('allows empty options', async () => {
      const { CacheOptions } = await import('@/ports/cache');
      const emptyOptions = {};
      const result = Schema.decodeUnknownSync(CacheOptions)(emptyOptions);
      expect(result.ttlSeconds).toBeUndefined();
    });
  });

  describe('CacheError Schema', () => {
    test('creates tagged error with valid code', async () => {
      const { CacheError } = await import('@/ports/cache');
      const error = new CacheError({
        code: 'KEY_NOT_FOUND',
        message: 'Key not found',
        key: 'user:123',
      });
      expect(error._tag).toBe('CacheError');
      expect(error.code).toBe('KEY_NOT_FOUND');
      expect(error.key).toBe('user:123');
    });

    test('accepts all valid error codes', async () => {
      const { CacheError } = await import('@/ports/cache');
      const codes = [
        'KEY_NOT_FOUND',
        'SERIALIZATION_ERROR',
        'CONNECTION_ERROR',
        'TIMEOUT',
        'INTERNAL_ERROR',
      ] as const;

      for (const code of codes) {
        const error = new CacheError({ code, message: 'Test' });
        expect(error.code).toBe(code);
      }
    });
  });

  describe('Cache Context Tag', () => {
    test('Cache tag is defined', async () => {
      const { Cache } = await import('@/ports/cache');
      expect(Cache).toBeDefined();
      expect(Cache.key).toBe('Cache');
    });
  });
});
