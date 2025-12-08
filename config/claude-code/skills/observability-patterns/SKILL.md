---
name: observability-patterns
description: OpenTelemetry integration patterns for tracing, metrics, and logging. Structured logs with trace context.
allowed-tools: Read, Write, Edit
---

## Core Principles

1. **Trace Everything Important**: Every external call, database query, and significant operation
2. **Structured Logging**: JSON logs with trace context
3. **Meaningful Spans**: Name spans after what they DO, not where they ARE
4. **Low Overhead**: Sample appropriately, don't trace every request in production

## OpenTelemetry Setup

### Initialize Tracer

```typescript
import { trace } from '@opentelemetry/api';
import { NodeTracerProvider } from '@opentelemetry/sdk-trace-node';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';

const provider = new NodeTracerProvider();
provider.addSpanProcessor(
  new BatchSpanProcessor(
    new OTLPTraceExporter({ url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT })
  )
);
provider.register();

const tracer = trace.getTracer('my-service', '1.0.0');
```

## Span Patterns

### Wrapping Async Operations

```typescript
async function fetchUser(userId: string): Promise<User> {
  return tracer.startActiveSpan('user.fetch', async (span) => {
    try {
      span.setAttribute('user.id', userId);
      const user = await db.users.findUnique({ where: { id: userId } });
      span.setStatus({ code: SpanStatusCode.OK });
      return user;
    } catch (error) {
      span.recordException(error as Error);
      span.setStatus({ code: SpanStatusCode.ERROR });
      throw error;
    } finally {
      span.end();
    }
  });
}
```

## Span Naming Conventions

| Pattern | Example | When to Use |
|---------|---------|-------------|
| `{resource}.{action}` | `user.create` | CRUD operations |
| `{service}.{method}` | `payment.charge` | External service calls |
| `db.{operation}` | `db.query` | Database operations |
| `http.{method}` | `http.get` | HTTP requests |

## Structured Logging with Trace Context

### Log with Trace IDs

```typescript
import { trace } from '@opentelemetry/api';

function log(level: string, message: string, data?: object) {
  const span = trace.getActiveSpan();
  const spanContext = span?.spanContext();

  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    level,
    message,
    traceId: spanContext?.traceId,
    spanId: spanContext?.spanId,
    ...data,
  }));
}
```

## Metrics Patterns

### Counter and Histogram

```typescript
const meter = metrics.getMeter('my-service');

// Counter - things that only go up
const requestCounter = meter.createCounter('http.requests.total');
requestCounter.add(1, { method: 'GET', path: '/api/users' });

// Histogram - distribution of values
const latencyHistogram = meter.createHistogram('http.request.duration', {
  unit: 'ms',
});
latencyHistogram.record(125, { method: 'GET', path: '/api/users' });
```
