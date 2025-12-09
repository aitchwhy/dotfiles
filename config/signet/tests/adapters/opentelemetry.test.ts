/**
 * OpenTelemetry Adapter Tests
 *
 * Tests for the OpenTelemetry implementation of the Telemetry port (tracing).
 */
import { describe, expect, test } from 'vitest'
import { Effect, Layer } from 'effect'

describe('OpenTelemetry Adapter', () => {
  describe('OpenTelemetryLive Layer', () => {
    test('exports a layer factory', async () => {
      const { makeOpenTelemetryLive } = await import('@/adapters/opentelemetry')
      expect(makeOpenTelemetryLive).toBeDefined()
      expect(typeof makeOpenTelemetryLive).toBe('function')
    })

    test('creates a layer with config', async () => {
      const { makeOpenTelemetryLive } = await import('@/adapters/opentelemetry')
      const layer = makeOpenTelemetryLive({
        serviceName: 'test-service',
        exporterUrl: 'http://localhost:4318/v1/traces',
      })
      expect(Layer.isLayer(layer)).toBe(true)
    })
  })

  describe('Telemetry Service Methods', () => {
    test('startSpan returns Effect', async () => {
      const { makeOpenTelemetryLive } = await import('@/adapters/opentelemetry')
      const { Telemetry } = await import('@/ports/telemetry')

      const layer = makeOpenTelemetryLive({
        serviceName: 'test-service',
        exporterUrl: 'http://localhost:4318/v1/traces',
      })

      const program = Effect.gen(function* () {
        const telemetry = yield* Telemetry
        return typeof telemetry.startSpan
      })

      const result = await Effect.runPromise(Effect.provide(program, layer))
      expect(result).toBe('function')
    })
  })
})
