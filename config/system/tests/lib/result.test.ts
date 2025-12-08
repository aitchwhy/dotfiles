/**
 * Result Type Tests
 *
 * Tests for type-safe error handling utilities.
 */
import { describe, expect, test } from 'bun:test'

// These imports will fail until we implement the module (RED phase)
import { andThen, Err, map, mapErr, Ok, type Result, tryCatch, tryCatchAsync } from '@/lib/result'

describe('Result Type', () => {
  describe('Ok', () => {
    test('creates a success result', () => {
      const result = Ok(42)
      expect(result.ok).toBe(true)
      expect(result.data).toBe(42)
    })

    test('works with different types', () => {
      const stringResult = Ok('hello')
      expect(stringResult.ok).toBe(true)
      expect(stringResult.data).toBe('hello')

      const objectResult = Ok({ name: 'test' })
      expect(objectResult.ok).toBe(true)
      expect(objectResult.data).toEqual({ name: 'test' })
    })
  })

  describe('Err', () => {
    test('creates an error result', () => {
      const error = new Error('test error')
      const result = Err(error)
      expect(result.ok).toBe(false)
      expect(result.error).toBe(error)
    })

    test('works with custom error types', () => {
      const result = Err({ code: 'NOT_FOUND', message: 'Not found' })
      expect(result.ok).toBe(false)
      expect(result.error).toEqual({ code: 'NOT_FOUND', message: 'Not found' })
    })
  })

  describe('map', () => {
    test('transforms success value', () => {
      const result = Ok(10)
      const mapped = map(result, (x) => x * 2)
      expect(mapped.ok).toBe(true)
      if (mapped.ok) {
        expect(mapped.data).toBe(20)
      }
    })

    test('passes through error unchanged', () => {
      const error = new Error('original')
      const result: Result<number, Error> = Err(error)
      const mapped = map(result, (x) => x * 2)
      expect(mapped.ok).toBe(false)
      if (!mapped.ok) {
        expect(mapped.error).toBe(error)
      }
    })
  })

  describe('mapErr', () => {
    test('transforms error value', () => {
      const result: Result<number, string> = Err('original')
      const mapped = mapErr(result, (e) => new Error(e))
      expect(mapped.ok).toBe(false)
      if (!mapped.ok) {
        expect(mapped.error.message).toBe('original')
      }
    })

    test('passes through success unchanged', () => {
      const result: Result<number, string> = Ok(42)
      const mapped = mapErr(result, (e) => new Error(e))
      expect(mapped.ok).toBe(true)
      if (mapped.ok) {
        expect(mapped.data).toBe(42)
      }
    })
  })

  describe('andThen', () => {
    test('chains successful results', () => {
      const result = Ok(10)
      const chained = andThen(result, (x) => Ok(x * 2))
      expect(chained.ok).toBe(true)
      if (chained.ok) {
        expect(chained.data).toBe(20)
      }
    })

    test('short-circuits on error', () => {
      const error = new Error('failed')
      const result: Result<number, Error> = Err(error)
      const chained = andThen(result, (x) => Ok(x * 2))
      expect(chained.ok).toBe(false)
      if (!chained.ok) {
        expect(chained.error).toBe(error)
      }
    })

    test('propagates error from chained function', () => {
      const result = Ok(10)
      const chained = andThen(result, () => Err(new Error('chain failed')))
      expect(chained.ok).toBe(false)
      if (!chained.ok) {
        expect(chained.error.message).toBe('chain failed')
      }
    })
  })

  describe('tryCatch', () => {
    test('returns Ok for successful function', () => {
      const result = tryCatch(() => 42)
      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.data).toBe(42)
      }
    })

    test('returns Err for thrown Error', () => {
      const result = tryCatch(() => {
        throw new Error('test error')
      })
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error.message).toBe('test error')
      }
    })

    test('wraps non-Error throws in Error', () => {
      const result = tryCatch(() => {
        throw 'string error'
      })
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error.message).toBe('string error')
      }
    })
  })

  describe('tryCatchAsync', () => {
    test('returns Ok for successful async function', async () => {
      const result = await tryCatchAsync(async () => 42)
      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.data).toBe(42)
      }
    })

    test('returns Err for rejected promise', async () => {
      const result = await tryCatchAsync(async () => {
        throw new Error('async error')
      })
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error.message).toBe('async error')
      }
    })
  })
})
