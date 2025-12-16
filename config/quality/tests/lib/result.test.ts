/**
 * Result Type Tests
 *
 * Tests for the Result type utilities used throughout the Factory.
 */
import { describe, expect, test } from 'bun:test';
import {
  Err,
  flatMap,
  isErr,
  isOk,
  map,
  Ok,
  tryCatch,
  tryCatchAsync,
  unwrapOr,
} from '@/lib/result';

describe('Result', () => {
  describe('Ok', () => {
    test('creates a success result', () => {
      const result = Ok(42);
      expect(result.ok).toBe(true);
      if (result.ok) {
        expect(result.data).toBe(42);
      }
    });

    test('works with complex types', () => {
      const result = Ok({ name: 'test', value: 123 });
      expect(result.ok).toBe(true);
      if (result.ok) {
        expect(result.data).toEqual({ name: 'test', value: 123 });
      }
    });
  });

  describe('Err', () => {
    test('creates a failure result', () => {
      const error = new Error('test error');
      const result = Err(error);
      expect(result.ok).toBe(false);
      if (!result.ok) {
        expect(result.error).toBe(error);
      }
    });

    test('works with custom error types', () => {
      const result = Err({ code: 'NOT_FOUND', message: 'Not found' });
      expect(result.ok).toBe(false);
      if (!result.ok) {
        expect(result.error).toEqual({ code: 'NOT_FOUND', message: 'Not found' });
      }
    });
  });

  describe('isOk', () => {
    test('returns true for Ok results', () => {
      expect(isOk(Ok(42))).toBe(true);
    });

    test('returns false for Err results', () => {
      expect(isOk(Err(new Error('test')))).toBe(false);
    });
  });

  describe('isErr', () => {
    test('returns true for Err results', () => {
      expect(isErr(Err(new Error('test')))).toBe(true);
    });

    test('returns false for Ok results', () => {
      expect(isErr(Ok(42))).toBe(false);
    });
  });

  describe('map', () => {
    test('transforms Ok value', () => {
      const result = map(Ok(2), (x) => x * 3);
      expect(result).toEqual(Ok(6));
    });

    test('passes through Err unchanged', () => {
      const error = new Error('test');
      const result = map(Err(error), (x: number) => x * 3);
      expect(result).toEqual(Err(error));
    });
  });

  describe('flatMap', () => {
    test('chains Ok results', () => {
      const result = flatMap(Ok(2), (x) => Ok(x * 3));
      expect(result).toEqual(Ok(6));
    });

    test('short-circuits on first Err', () => {
      const error = new Error('first');
      const result = flatMap(Err(error), () => Ok(42));
      expect(result).toEqual(Err(error));
    });

    test('returns Err from inner function', () => {
      const error = new Error('inner');
      const result = flatMap(Ok(2), () => Err(error));
      expect(result).toEqual(Err(error));
    });
  });

  describe('unwrapOr', () => {
    test('returns Ok value', () => {
      expect(unwrapOr(Ok(42), 0)).toBe(42);
    });

    test('returns default for Err', () => {
      expect(unwrapOr(Err(new Error('test')), 0)).toBe(0);
    });
  });

  describe('tryCatch', () => {
    test('returns Ok for successful function', () => {
      const result = tryCatch(() => 42);
      expect(result).toEqual(Ok(42));
    });

    test('returns Err for throwing function', () => {
      const result = tryCatch(() => {
        throw new Error('test error');
      });
      expect(result.ok).toBe(false);
      if (!result.ok) {
        expect(result.error.message).toBe('test error');
      }
    });

    test('wraps non-Error throws in Error', () => {
      const result = tryCatch(() => {
        throw 'string error';
      });
      expect(result.ok).toBe(false);
      if (!result.ok) {
        expect(result.error.message).toBe('string error');
      }
    });
  });

  describe('tryCatchAsync', () => {
    test('returns Ok for successful async function', async () => {
      const result = await tryCatchAsync(async () => 42);
      expect(result).toEqual(Ok(42));
    });

    test('returns Err for rejecting async function', async () => {
      const result = await tryCatchAsync(async () => {
        throw new Error('async error');
      });
      expect(result.ok).toBe(false);
      if (!result.ok) {
        expect(result.error.message).toBe('async error');
      }
    });
  });
});
