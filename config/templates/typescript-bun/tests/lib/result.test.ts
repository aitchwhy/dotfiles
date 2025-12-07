/**
 * Result Type Tests
 *
 * Tests for the Result type utilities.
 */
import { describe, expect, test } from 'bun:test';
import { Err, Ok, all, andThen, isErr, isOk, map, tryCatch, unwrap, unwrapOr } from '@/lib/result';

describe('Result', () => {
  describe('Ok', () => {
    test('creates a success result', () => {
      const result = Ok(42);
      expect(result.ok).toBe(true);
      if (result.ok) {
        expect(result.data).toBe(42);
      }
    });
  });

  describe('Err', () => {
    test('creates an error result', () => {
      const result = Err('something went wrong');
      expect(result.ok).toBe(false);
      if (!result.ok) {
        expect(result.error).toBe('something went wrong');
      }
    });
  });

  describe('isOk', () => {
    test('returns true for Ok results', () => {
      expect(isOk(Ok(42))).toBe(true);
    });

    test('returns false for Err results', () => {
      expect(isOk(Err('error'))).toBe(false);
    });
  });

  describe('isErr', () => {
    test('returns false for Ok results', () => {
      expect(isErr(Ok(42))).toBe(false);
    });

    test('returns true for Err results', () => {
      expect(isErr(Err('error'))).toBe(true);
    });
  });

  describe('unwrap', () => {
    test('returns data for Ok results', () => {
      expect(unwrap(Ok(42))).toBe(42);
    });

    test('throws for Err results', () => {
      expect(() => unwrap(Err(new Error('fail')))).toThrow('fail');
    });
  });

  describe('unwrapOr', () => {
    test('returns data for Ok results', () => {
      expect(unwrapOr(Ok(42), 0)).toBe(42);
    });

    test('returns default for Err results', () => {
      expect(unwrapOr(Err('error'), 0)).toBe(0);
    });
  });

  describe('map', () => {
    test('transforms Ok values', () => {
      const result = map(Ok(2), (x) => x * 3);
      expect(result).toEqual(Ok(6));
    });

    test('passes through Err values', () => {
      const result = map(Err('error'), (x: number) => x * 3);
      expect(result).toEqual(Err('error'));
    });
  });

  describe('andThen', () => {
    test('chains Ok results', () => {
      const result = andThen(Ok(2), (x) => Ok(x * 3));
      expect(result).toEqual(Ok(6));
    });

    test('short-circuits on Err', () => {
      const result = andThen(Err('error'), (x: number) => Ok(x * 3));
      expect(result).toEqual(Err('error'));
    });
  });

  describe('tryCatch', () => {
    test('returns Ok for successful functions', () => {
      const result = tryCatch(() => 42);
      expect(result).toEqual(Ok(42));
    });

    test('returns Err for throwing functions', () => {
      const result = tryCatch(() => {
        throw new Error('boom');
      });
      expect(result.ok).toBe(false);
      if (!result.ok) {
        expect(result.error.message).toBe('boom');
      }
    });
  });

  describe('all', () => {
    test('combines Ok results', () => {
      const results = [Ok(1), Ok(2), Ok(3)];
      expect(all(results)).toEqual(Ok([1, 2, 3]));
    });

    test('returns first Err', () => {
      const results = [Ok(1), Err('error'), Ok(3)];
      expect(all(results)).toEqual(Err('error'));
    });
  });
});
