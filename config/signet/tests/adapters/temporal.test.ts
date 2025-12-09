/**
 * Temporal Adapter Tests
 *
 * Tests for the Temporal implementation of the Workflow port.
 */
import { describe, expect, test } from 'vitest'
import { Effect, Layer } from 'effect'

describe('Temporal Adapter', () => {
  describe('TemporalLive Layer', () => {
    test('exports a layer factory', async () => {
      const { makeTemporalLive } = await import('@/adapters/temporal')
      expect(makeTemporalLive).toBeDefined()
      expect(typeof makeTemporalLive).toBe('function')
    })

    test('creates a layer with config', async () => {
      const { makeTemporalLive } = await import('@/adapters/temporal')
      const layer = makeTemporalLive({
        address: 'localhost:7233',
        namespace: 'default',
      })
      expect(Layer.isLayer(layer)).toBe(true)
    })
  })

  describe('Workflow Service Methods', () => {
    test('start returns Effect', async () => {
      const { makeTemporalLive } = await import('@/adapters/temporal')
      const { Workflow } = await import('@/ports/workflow')

      const layer = makeTemporalLive({
        address: 'localhost:7233',
        namespace: 'default',
      })

      const program = Effect.gen(function* () {
        const workflow = yield* Workflow
        return typeof workflow.start
      })

      const result = await Effect.runPromise(Effect.provide(program, layer))
      expect(result).toBe('function')
    })
  })
})
