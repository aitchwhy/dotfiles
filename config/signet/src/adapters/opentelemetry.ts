/**
 * OpenTelemetry Adapter
 *
 * Implements the Telemetry port for tracing using OpenTelemetry SDK.
 * Provides distributed tracing capabilities.
 */
import { Effect, Layer } from 'effect'
import {
  Telemetry,
  type TelemetryService,
  TelemetryError,
  type Span,
  type SpanOptions,
  type AnalyticsEvent,
} from '@/ports/telemetry'

// ============================================================================
// CONFIG
// ============================================================================

export interface OpenTelemetryConfig {
  readonly serviceName: string
  readonly exporterUrl: string
  readonly sampleRate?: number
}

// ============================================================================
// ADAPTER IMPLEMENTATION
// ============================================================================

const makeSpan = (_name: string): Span => {
  const traceId = `trace-${Date.now()}-${Math.random().toString(36).slice(2)}`
  const spanId = `span-${Date.now()}-${Math.random().toString(36).slice(2)}`
  const attributes: Record<string, unknown> = {}
  const events: Array<{ name: string; attributes?: Record<string, unknown> }> = []
  let _status: 'ok' | 'error' = 'ok'
  let _statusMessage: string | undefined

  return {
    spanContext: () => ({
      traceId,
      spanId,
      traceFlags: 1,
    }),
    setAttribute: (key: string, value: unknown) => {
      attributes[key] = value
    },
    addEvent: (eventName: string, eventAttributes?: Record<string, unknown>) => {
      events.push({ name: eventName, ...(eventAttributes && { attributes: eventAttributes }) })
    },
    setStatus: (s: 'ok' | 'error', message?: string) => {
      _status = s
      _statusMessage = message
    },
    end: () => {
      // In real implementation, this would export the span
      // These would be used when actually exporting
      void _status
      void _statusMessage
    },
  }
}

const makeTelemetryService = (_config: OpenTelemetryConfig): TelemetryService => ({
  startSpan: (name: string, _options?: SpanOptions) =>
    Effect.succeed(makeSpan(name)),

  withSpan: <A, E, R>(name: string, effect: Effect.Effect<A, E, R>, _options?: SpanOptions) =>
    Effect.gen(function* () {
      const span = makeSpan(name)
      try {
        const result = yield* effect
        span.setStatus('ok')
        return result
      } catch (error) {
        span.setStatus('error', error instanceof Error ? error.message : 'Unknown error')
        throw error
      } finally {
        span.end()
      }
    }),

  capture: (_event: AnalyticsEvent) =>
    Effect.succeed(undefined), // OpenTelemetry doesn't handle analytics - use PostHog

  identify: (_distinctId: string, _properties?: Record<string, unknown>) =>
    Effect.succeed(undefined), // OpenTelemetry doesn't handle analytics - use PostHog

  flush: () =>
    Effect.tryPromise({
      try: async () => {
        // Flush all pending spans to exporter
        // Placeholder implementation
      },
      catch: (error) =>
        new TelemetryError({
          code: 'EXPORT_FAILED',
          message: error instanceof Error ? error.message : 'Unknown error',
        }),
    }),
})

// ============================================================================
// LAYER FACTORY
// ============================================================================

export const makeOpenTelemetryLive = (config: OpenTelemetryConfig): Layer.Layer<Telemetry> =>
  Layer.succeed(Telemetry, makeTelemetryService(config))
