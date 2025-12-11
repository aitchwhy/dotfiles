/**
 * Structured logging with trace correlation for Datadog.
 */
import { trace } from '@opentelemetry/api';

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

function log(level: LogLevel, message: string, data?: object) {
  const span = trace.getActiveSpan();
  const ctx = span?.spanContext();

  console.log(
    JSON.stringify({
      timestamp: new Date().toISOString(),
      level,
      message,
      service: process.env.DD_SERVICE || 'PROJECT_NAME',
      dd: ctx ? { trace_id: ctx.traceId, span_id: ctx.spanId } : undefined,
      ...data,
    })
  );
}

export const logger = {
  debug: (msg: string, data?: object) => log('debug', msg, data),
  info: (msg: string, data?: object) => log('info', msg, data),
  warn: (msg: string, data?: object) => log('warn', msg, data),
  error: (msg: string, err?: Error, data?: object) =>
    log('error', msg, {
      error: err ? { name: err.name, message: err.message, stack: err.stack } : undefined,
      ...data,
    }),
};
