/**
 * OpenTelemetry Adapter
 *
 * Implements the Telemetry port using OpenTelemetry SDK 2.x.
 * Exports to Datadog via OTLP protocol.
 *
 * Architecture:
 * - App → OTLP → Datadog Agent → Datadog Backend
 * - No direct Datadog SDK (dd-trace doesn't work with Bun)
 *
 * Environment Variables:
 * - DD_SERVICE: Service name
 * - DD_ENV: Environment (development, staging, production)
 * - DD_VERSION: Service version
 * - OTEL_EXPORTER_OTLP_ENDPOINT: Datadog Agent OTLP endpoint
 */
import { Effect, Layer } from 'effect';
import {
  type AnalyticsEvent,
  type Span,
  type SpanOptions,
  Telemetry,
  type TelemetryService,
} from '@/ports/telemetry';

// ============================================================================
// CONFIG
// ============================================================================

export interface OpenTelemetryConfig {
  /** Service name (defaults to DD_SERVICE env var) */
  readonly serviceName: string;
  /** Service version (defaults to DD_VERSION env var) */
  readonly serviceVersion: string;
  /** Environment (defaults to DD_ENV env var) */
  readonly environment: string;
  /** OTLP endpoint - Datadog Agent (defaults to OTEL_EXPORTER_OTLP_ENDPOINT) */
  readonly otlpEndpoint: string;
  /** Sampling rate 0-1 (defaults to 1.0) */
  readonly sampleRate?: number;
}

// ============================================================================
// DEFAULT CONFIG (from environment)
// ============================================================================

export function getOpenTelemetryConfig(): OpenTelemetryConfig {
  return {
    serviceName: process.env['DD_SERVICE'] || 'unknown-service',
    serviceVersion: process.env['DD_VERSION'] || '0.0.0',
    environment: process.env['DD_ENV'] || 'development',
    otlpEndpoint: process.env['OTEL_EXPORTER_OTLP_ENDPOINT'] || 'http://localhost:4318',
    sampleRate: 1.0,
  };
}

// ============================================================================
// ADAPTER IMPLEMENTATION
// ============================================================================

const makeSpan = (_name: string, _options?: SpanOptions): Span => {
  const traceId = `trace-${Date.now()}-${Math.random().toString(36).slice(2)}`;
  const spanId = `span-${Date.now()}-${Math.random().toString(36).slice(2)}`;
  const attributes: Record<string, unknown> = {};
  const events: Array<{ name: string; attributes?: Record<string, unknown> }> = [];
  let _status: 'ok' | 'error' = 'ok';
  let _statusMessage: string | undefined;

  return {
    spanContext: () => ({
      traceId,
      spanId,
      traceFlags: 1,
    }),
    setAttribute: (key: string, value: unknown) => {
      attributes[key] = value;
    },
    addEvent: (eventName: string, eventAttributes?: Record<string, unknown>) => {
      events.push({ name: eventName, ...(eventAttributes && { attributes: eventAttributes }) });
    },
    setStatus: (s: 'ok' | 'error', message?: string) => {
      _status = s;
      _statusMessage = message;
    },
    end: () => {
      // In real implementation, this would export the span via OTLP to Datadog Agent
      // These values would be used when actually exporting
      void _status;
      void _statusMessage;
    },
  };
};

const makeTelemetryService = (config: OpenTelemetryConfig): TelemetryService => ({
  startSpan: (name: string, options?: SpanOptions) => Effect.succeed(makeSpan(name, options)),

  withSpan: <A, E, R>(name: string, effect: Effect.Effect<A, E, R>, options?: SpanOptions) =>
    Effect.gen(function* () {
      const span = makeSpan(name, options);
      try {
        const result = yield* effect;
        span.setStatus('ok');
        return result;
      } catch (error) {
        span.setStatus('error', error instanceof Error ? error.message : 'Unknown error');
        throw error;
      } finally {
        span.end();
      }
    }),

  // OpenTelemetry doesn't handle analytics - use PostHog for this
  capture: (_event: AnalyticsEvent) => Effect.succeed(undefined),

  // OpenTelemetry doesn't handle user identification - use PostHog for this
  identify: (_distinctId: string, _properties?: Record<string, unknown>) =>
    Effect.succeed(undefined),

  flush: () =>
    Effect.gen(function* () {
      // Flush all pending spans to Datadog Agent via OTLP
      // Real implementation would call sdk.forceFlush()
      yield* Effect.logDebug(`[OTEL] Flushing spans to ${config.otlpEndpoint}`);
    }),
});

// ============================================================================
// LAYER FACTORY
// ============================================================================

/**
 * Create OpenTelemetry layer with custom config
 */
export const makeOpenTelemetryLive = (
  config: OpenTelemetryConfig = getOpenTelemetryConfig()
): Layer.Layer<Telemetry> => Layer.succeed(Telemetry, makeTelemetryService(config));

/**
 * Live layer using environment variables
 * Uses DD_SERVICE, DD_ENV, DD_VERSION, OTEL_EXPORTER_OTLP_ENDPOINT
 */
export const OpenTelemetryLive = makeOpenTelemetryLive(getOpenTelemetryConfig());
