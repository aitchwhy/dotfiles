/**
 * Result Type Tests
 *
 * Tests for the Result type utilities used throughout the quality system.
 */
import { describe, expect, it } from 'vitest'
import { Err, flatMap, isErr, isOk, map, Ok, tryCatch, tryCatchAsync, unwrapOr } from '../../src/lib/result'

describe('Result', () => {
  describe('Ok', () => {
    it('creates a success result', () => {
      const result = Ok(42)
      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.data).toBe(42)
      }
    })

    it('works with complex types', () => {
      const result = Ok({ name: 'test', value: 123 })
      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.data).toEqual({ name: 'test', value: 123 })
      }
    })
  })

  describe('Err', () => {
    it('creates a failure result', () => {
      const error = new Error('test error')
      const result = Err(error)
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toBe(error)
      }
    })

    it('works with custom error types', () => {
      const result = Err({ code: 'NOT_FOUND', message: 'Not found' })
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toEqual({ code: 'NOT_FOUND', message: 'Not found' })
      }
    })
  })

  describe('isOk', () => {
    it('returns true for Ok results', () => {
      expect(isOk(Ok(42))).toBe(true)
    })

    it('returns false for Err results', () => {
      expect(isOk(Err(new Error('test')))).toBe(false)
    })
  })

  describe('isErr', () => {
    it('returns true for Err results', () => {
      expect(isErr(Err(new Error('test')))).toBe(true)
    })

    it('returns false for Ok results', () => {
      expect(isErr(Ok(42))).toBe(false)
    })
  })

  describe('map', () => {
    it('transforms Ok value', () => {
      const result = map(Ok(2), (x) => x * 3)
      expect(result).toEqual(Ok(6))
    })

    it('passes through Err unchanged', () => {
      const error = new Error('test')
      const result = map(Err(error), (x: number) => x * 3)
      expect(result).toEqual(Err(error))
    })
  })

  describe('flatMap', () => {
    it('chains Ok results', () => {
      const result = flatMap(Ok(2), (x) => Ok(x * 3))
      expect(result).toEqual(Ok(6))
    })

    it('short-circuits on first Err', () => {
      const error = new Error('first')
      const result = flatMap(Err(error), () => Ok(42))
      expect(result).toEqual(Err(error))
    })

    it('returns Err from inner function', () => {
      const error = new Error('inner')
      const result = flatMap(Ok(2), () => Err(error))
      expect(result).toEqual(Err(error))
    })
  })

  describe('unwrapOr', () => {
    it('returns Ok value', () => {
      expect(unwrapOr(Ok(42), 0)).toBe(42)
    })

    it('returns default for Err', () => {
      expect(unwrapOr(Err(new Error('test')), 0)).toBe(0)
    })
  })

  describe('tryCatch', () => {
    it('returns Ok for successful function', () => {
      const result = tryCatch(() => 42)
      expect(result).toEqual(Ok(42))
    })

    it('returns Err for throwing function', () => {
      const result = tryCatch(() => {
        throw new Error('test error')
      })
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error.message).toBe('test error')
      }
    })

    it('wraps non-Error throws in Error', () => {
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
    it('returns Ok for successful async function', async () => {
      const result = await tryCatchAsync(async () => 42)
      expect(result).toEqual(Ok(42))
    })

    it('returns Err for rejecting async function', async () => {
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
