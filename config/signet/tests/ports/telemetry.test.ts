/**
 * Telemetry Port Tests
 *
 * Tests for the Telemetry port interface and schema definitions.
 */
import { describe, expect, test } from 'bun:test';
import { Schema } from 'effect';

describe('Telemetry Port', () => {
  describe('SpanKind Schema', () => {
    test('accepts valid span kinds', async () => {
      const { SpanKind } = await import('@/ports/telemetry');
      const validKinds = ['internal', 'server', 'client', 'producer', 'consumer'] as const;
      for (const kind of validKinds) {
        const result = Schema.decodeUnknownSync(SpanKind)(kind);
        expect(result).toBe(kind);
      }
    });

    test('rejects invalid span kind', async () => {
      const { SpanKind } = await import('@/ports/telemetry');
      expect(() => Schema.decodeUnknownSync(SpanKind)('invalid')).toThrow();
    });
  });

  describe('SpanContext Schema', () => {
    test('validates a valid span context', async () => {
      const { SpanContext } = await import('@/ports/telemetry');
      const validContext = {
        traceId: 'trace_123abc',
        spanId: 'span_456def',
        traceFlags: 1,
      };
      const result = Schema.decodeUnknownSync(SpanContext)(validContext);
      expect(result.traceId).toBe('trace_123abc');
      expect(result.spanId).toBe('span_456def');
    });
  });

  describe('AnalyticsEvent Schema', () => {
    test('validates a valid analytics event', async () => {
      const { AnalyticsEvent } = await import('@/ports/telemetry');
      const validEvent = {
        name: 'button_clicked',
        properties: { button_id: 'submit', page: 'checkout' },
        distinctId: 'user_123',
      };
      const result = Schema.decodeUnknownSync(AnalyticsEvent)(validEvent);
      expect(result.name).toBe('button_clicked');
    });

    test('allows minimal event with just name', async () => {
      const { AnalyticsEvent } = await import('@/ports/telemetry');
      const minimalEvent = { name: 'page_view' };
      const result = Schema.decodeUnknownSync(AnalyticsEvent)(minimalEvent);
      expect(result.name).toBe('page_view');
      expect(result.properties).toBeUndefined();
    });
  });

  describe('TelemetryError Schema', () => {
    test('creates tagged error with valid code', async () => {
      const { TelemetryError } = await import('@/ports/telemetry');
      const error = new TelemetryError({ code: 'EXPORT_FAILED', message: 'Failed to export' });
      expect(error._tag).toBe('TelemetryError');
      expect(error.code).toBe('EXPORT_FAILED');
    });
  });

  describe('Telemetry Context Tag', () => {
    test('Telemetry tag is defined', async () => {
      const { Telemetry } = await import('@/ports/telemetry');
      expect(Telemetry).toBeDefined();
      expect(Telemetry.key).toBe('Telemetry');
    });
  });
});
