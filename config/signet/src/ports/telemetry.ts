/**
 * Telemetry Port - Observability Service Interface
 *
 * Defines the contract for tracing, metrics, and analytics.
 * Implemented by adapters like OpenTelemetry and PostHog.
 */
import { Context, Effect, Schema } from 'effect'

// ============================================================================
// SCHEMAS
// ============================================================================

export const SpanKind = Schema.Literal('internal', 'server', 'client', 'producer', 'consumer')

export type SpanKind = Schema.Schema.Type<typeof SpanKind>

export const SpanContext = Schema.Struct({
  traceId: Schema.String,
  spanId: Schema.String,
  traceFlags: Schema.Number,
})

export type SpanContext = Schema.Schema.Type<typeof SpanContext>

export const SpanOptions = Schema.Struct({
  kind: Schema.optional(SpanKind),
  attributes: Schema.optional(Schema.Record({ key: Schema.String, value: Schema.Unknown })),
  links: Schema.optional(Schema.Array(SpanContext)),
})

export type SpanOptions = Schema.Schema.Type<typeof SpanOptions>

export const AnalyticsEvent = Schema.Struct({
  name: Schema.String,
  properties: Schema.optional(Schema.Record({ key: Schema.String, value: Schema.Unknown })),
  distinctId: Schema.optional(Schema.String),
  timestamp: Schema.optional(Schema.Date),
})

export type AnalyticsEvent = Schema.Schema.Type<typeof AnalyticsEvent>

// ============================================================================
// ERRORS
// ============================================================================

export class TelemetryError extends Schema.TaggedError<TelemetryError>()('TelemetryError', {
  code: Schema.Literal('EXPORT_FAILED', 'INVALID_SPAN', 'CONNECTION_ERROR', 'INTERNAL_ERROR'),
  message: Schema.String,
}) {}

// ============================================================================
// PORT INTERFACE
// ============================================================================

export interface Span {
  readonly spanContext: () => SpanContext
  readonly setAttribute: (key: string, value: unknown) => void
  readonly addEvent: (name: string, attributes?: Record<string, unknown>) => void
  readonly setStatus: (status: 'ok' | 'error', message?: string) => void
  readonly end: () => void
}

export interface TelemetryService {
  readonly startSpan: (name: string, options?: SpanOptions) => Effect.Effect<Span, TelemetryError>

  readonly withSpan: <A, E, R>(
    name: string,
    effect: Effect.Effect<A, E, R>,
    options?: SpanOptions,
  ) => Effect.Effect<A, E | TelemetryError, R>

  readonly capture: (event: AnalyticsEvent) => Effect.Effect<void, TelemetryError>

  readonly identify: (
    distinctId: string,
    properties?: Record<string, unknown>,
  ) => Effect.Effect<void, TelemetryError>

  readonly flush: () => Effect.Effect<void, TelemetryError>
}

export class Telemetry extends Context.Tag('Telemetry')<Telemetry, TelemetryService>() {}
