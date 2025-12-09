/**
 * PostHog Adapter
 *
 * Implements the Telemetry port for analytics using PostHog.
 * Provides product analytics and event tracking.
 */
import { Effect, Layer } from 'effect'
import {
  Telemetry,
  type TelemetryService,
  TelemetryError,
  type SpanOptions,
  type AnalyticsEvent,
} from '@/ports/telemetry'

// ============================================================================
// CONFIG
// ============================================================================

export interface PostHogConfig {
  readonly apiKey: string
  readonly host?: string
  readonly flushAt?: number
  readonly flushInterval?: number
}

// ============================================================================
// ADAPTER IMPLEMENTATION
// ============================================================================

const makeTelemetryService = (config: PostHogConfig): TelemetryService => {
  const pendingEvents: AnalyticsEvent[] = []
  let identifiedUser: { distinctId: string; properties?: Record<string, unknown> } | null = null

  return {
    // PostHog doesn't do tracing - these are no-ops
    startSpan: (_name: string, _options?: SpanOptions) =>
      Effect.fail(
        new TelemetryError({
          code: 'INVALID_SPAN',
          message: 'PostHog adapter does not support tracing. Use OpenTelemetry.',
        }),
      ),

    withSpan: <A, E, R>(_name: string, effect: Effect.Effect<A, E, R>, _options?: SpanOptions) =>
      effect, // Pass through - PostHog doesn't do tracing

    capture: (event: AnalyticsEvent) =>
      Effect.tryPromise({
        try: async () => {
          // PostHog event capture
          // Placeholder - actual implementation would use posthog-node
          pendingEvents.push(event)

          if (pendingEvents.length >= (config.flushAt ?? 20)) {
            await flushEvents()
          }
        },
        catch: (error) =>
          new TelemetryError({
            code: 'INTERNAL_ERROR',
            message: error instanceof Error ? error.message : 'Unknown error',
          }),
      }),

    identify: (distinctId: string, properties?: Record<string, unknown>) =>
      Effect.tryPromise({
        try: async () => {
          identifiedUser = { distinctId, ...(properties && { properties }) }
          // PostHog identify call
          // Placeholder implementation
        },
        catch: (error) =>
          new TelemetryError({
            code: 'INTERNAL_ERROR',
            message: error instanceof Error ? error.message : 'Unknown error',
          }),
      }),

    flush: () =>
      Effect.tryPromise({
        try: flushEvents,
        catch: (error) =>
          new TelemetryError({
            code: 'EXPORT_FAILED',
            message: error instanceof Error ? error.message : 'Unknown error',
          }),
      }),
  }

  async function flushEvents(): Promise<void> {
    if (pendingEvents.length === 0) return

    const events = [...pendingEvents]
    pendingEvents.length = 0

    // Send to PostHog API
    // Placeholder - actual implementation would batch send to PostHog
    const host = config.host ?? 'https://app.posthog.com'
    await fetch(`${host}/batch`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        api_key: config.apiKey,
        batch: events.map((e) => ({
          event: e.name,
          properties: e.properties,
          distinct_id: e.distinctId ?? identifiedUser?.distinctId ?? 'anonymous',
          timestamp: e.timestamp?.toISOString(),
        })),
      }),
    })
  }
}

// ============================================================================
// LAYER FACTORY
// ============================================================================

export const makePostHogLive = (config: PostHogConfig): Layer.Layer<Telemetry> =>
  Layer.succeed(Telemetry, makeTelemetryService(config))
