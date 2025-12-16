/**
 * OpenTelemetry Adapter Tests
 *
 * Tests for the OpenTelemetry implementation of the Telemetry port (tracing).
 */
import { describe, expect, test } from 'bun:test';
import { Effect, Layer } from 'effect';

describe('OpenTelemetry Adapter', () => {
  describe('OpenTelemetryLive Layer', () => {
    test('exports a layer factory', async () => {
      const { makeOpenTelemetryLive } = await import('@/adapters/opentelemetry');
      expect(makeOpenTelemetryLive).toBeDefined();
      expect(typeof makeOpenTelemetryLive).toBe('function');
    });

    test('creates a layer with config', async () => {
      const { makeOpenTelemetryLive } = await import('@/adapters/opentelemetry');
      const layer = makeOpenTelemetryLive({
        serviceName: 'test-service',
        serviceVersion: '1.0.0',
        environment: 'test',
        otlpEndpoint: 'http://localhost:4318',
      });
      expect(Layer.isLayer(layer)).toBe(true);
    });
  });

  describe('Telemetry Service Methods', () => {
    test('startSpan returns Effect', async () => {
      const { makeOpenTelemetryLive } = await import('@/adapters/opentelemetry');
      const { Telemetry } = await import('@/ports/telemetry');

      const layer = makeOpenTelemetryLive({
        serviceName: 'test-service',
        serviceVersion: '1.0.0',
        environment: 'test',
        otlpEndpoint: 'http://localhost:4318',
      });

      const program = Effect.gen(function* () {
        const telemetry = yield* Telemetry;
        return typeof telemetry.startSpan;
      });

      const result = await Effect.runPromise(Effect.provide(program, layer));
      expect(result).toBe('function');
    });
  });
});
