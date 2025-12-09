/**
 * Better-Auth Adapter Tests
 *
 * Tests for the Better-Auth implementation of the Auth port.
 */
import { describe, expect, test } from 'vitest'
import { Effect, Layer } from 'effect'

describe('Better-Auth Adapter', () => {
  describe('BetterAuthLive Layer', () => {
    test('exports a layer factory', async () => {
      const { makeBetterAuthLive } = await import('@/adapters/better-auth')
      expect(makeBetterAuthLive).toBeDefined()
      expect(typeof makeBetterAuthLive).toBe('function')
    })

    test('creates a layer with config', async () => {
      const { makeBetterAuthLive } = await import('@/adapters/better-auth')
      const layer = makeBetterAuthLive({
        baseUrl: 'http://localhost:3000',
        secret: 'test-secret',
      })
      expect(Layer.isLayer(layer)).toBe(true)
    })
  })

  describe('Auth Service Methods', () => {
    test('validateSession returns Effect', async () => {
      const { makeBetterAuthLive } = await import('@/adapters/better-auth')
      const { Auth } = await import('@/ports/auth')

      const layer = makeBetterAuthLive({
        baseUrl: 'http://localhost:3000',
        secret: 'test-secret',
      })

      const program = Effect.gen(function* () {
        const auth = yield* Auth
        return typeof auth.validateSession
      })

      const result = await Effect.runPromise(Effect.provide(program, layer))
      expect(result).toBe('function')
    })
  })
})
