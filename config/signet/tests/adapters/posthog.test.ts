/**
 * PostHog Adapter Tests
 *
 * Tests for the PostHog implementation of analytics (part of Telemetry port).
 */
import { describe, expect, test } from 'vitest'
import { Effect, Layer } from 'effect'

describe('PostHog Adapter', () => {
  describe('PostHogLive Layer', () => {
    test('exports a layer factory', async () => {
      const { makePostHogLive } = await import('@/adapters/posthog')
      expect(makePostHogLive).toBeDefined()
      expect(typeof makePostHogLive).toBe('function')
    })

    test('creates a layer with config', async () => {
      const { makePostHogLive } = await import('@/adapters/posthog')
      const layer = makePostHogLive({
        apiKey: 'phc_test_key',
        host: 'https://app.posthog.com',
      })
      expect(Layer.isLayer(layer)).toBe(true)
    })
  })

  describe('Analytics Service Methods', () => {
    test('capture returns Effect', async () => {
      const { makePostHogLive } = await import('@/adapters/posthog')
      const { Telemetry } = await import('@/ports/telemetry')

      const layer = makePostHogLive({
        apiKey: 'phc_test_key',
        host: 'https://app.posthog.com',
      })

      const program = Effect.gen(function* () {
        const telemetry = yield* Telemetry
        return typeof telemetry.capture
      })

      const result = await Effect.runPromise(Effect.provide(program, layer))
      expect(result).toBe('function')
    })
  })
})
