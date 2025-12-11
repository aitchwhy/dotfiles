/**
 * PostHog Adapter
 *
 * Implements the Telemetry port for product analytics using PostHog.
 * Used alongside OpenTelemetry (which handles tracing/metrics).
 *
 * PostHog handles:
 * - Product analytics events
 * - User identification
 * - Session replay (browser SDK)
 *
 * Environment Variables:
 * - POSTHOG_API_KEY: PostHog project API key
 * - POSTHOG_HOST: PostHog host (defaults to https://us.i.posthog.com)
 */
import { Effect, Layer } from 'effect';
import {
  type AnalyticsEvent,
  type SpanOptions,
  Telemetry,
  TelemetryError,
  type TelemetryService,
} from '@/ports/telemetry';

// ============================================================================
// CONFIG
// ============================================================================

export interface PostHogConfig {
  /** PostHog project API key */
  readonly apiKey: string;
  /** PostHog host (defaults to US cloud) */
  readonly host?: string;
  /** Number of events to batch before flushing */
  readonly flushAt?: number;
  /** Flush interval in milliseconds */
  readonly flushInterval?: number;
}

// ============================================================================
// DEFAULT CONFIG (from environment)
// ============================================================================

export function getDefaultConfig(): PostHogConfig | null {
  const apiKey = process.env['POSTHOG_API_KEY'];
  if (!apiKey) return null;

  return {
    apiKey,
    host: process.env['POSTHOG_HOST'] || 'https://us.i.posthog.com',
    flushAt: 20,
    flushInterval: 10000,
  };
}

// ============================================================================
// ADAPTER IMPLEMENTATION
// ============================================================================

const makeTelemetryService = (config: PostHogConfig): TelemetryService => {
  const pendingEvents: AnalyticsEvent[] = [];
  let identifiedUser: { distinctId: string; properties?: Record<string, unknown> } | null = null;

  async function flushEvents(): Promise<void> {
    if (pendingEvents.length === 0) return;

    const events = [...pendingEvents];
    pendingEvents.length = 0;

    const host = config.host ?? 'https://us.i.posthog.com';
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
    });
  }

  return {
    // PostHog doesn't do tracing - these are pass-through
    startSpan: (_name: string, _options?: SpanOptions) =>
      Effect.fail(
        new TelemetryError({
          code: 'INVALID_SPAN',
          message: 'PostHog adapter does not support tracing. Use OpenTelemetry.',
        })
      ),

    withSpan: <A, E, R>(_name: string, effect: Effect.Effect<A, E, R>, _options?: SpanOptions) =>
      effect, // Pass through - PostHog doesn't do tracing

    capture: (event: AnalyticsEvent) =>
      Effect.tryPromise({
        try: async () => {
          pendingEvents.push(event);

          if (pendingEvents.length >= (config.flushAt ?? 20)) {
            await flushEvents();
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
          identifiedUser = { distinctId, ...(properties && { properties }) };
          // Also send identify call to PostHog
          const host = config.host ?? 'https://us.i.posthog.com';
          await fetch(`${host}/capture`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              api_key: config.apiKey,
              event: '$identify',
              distinct_id: distinctId,
              properties: { $set: properties },
            }),
          });
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
  };
};

// ============================================================================
// NO-OP SERVICE (when PostHog is not configured)
// ============================================================================

const makeNoOpService = (): TelemetryService => ({
  startSpan: () =>
    Effect.fail(
      new TelemetryError({
        code: 'INVALID_SPAN',
        message: 'PostHog not configured. Set POSTHOG_API_KEY.',
      })
    ),
  withSpan: (_, effect) => effect,
  capture: () => Effect.succeed(undefined),
  identify: () => Effect.succeed(undefined),
  flush: () => Effect.succeed(undefined),
});

// ============================================================================
// LAYER FACTORY
// ============================================================================

/**
 * Create PostHog layer with custom config
 */
export const makePostHogLive = (config: PostHogConfig): Layer.Layer<Telemetry> =>
  Layer.succeed(Telemetry, makeTelemetryService(config));

/**
 * Live layer using environment variables.
 * Returns a no-op layer if POSTHOG_API_KEY is not set.
 */
export const PostHogLive = (() => {
  const config = getDefaultConfig();
  if (!config) {
    return Layer.succeed(Telemetry, makeNoOpService());
  }
  return makePostHogLive(config);
})();
