# Observability Patterns

OpenTelemetry integration patterns for tracing, metrics, and logging.

## Core Principles

1. **Trace Everything Important**: Every external call, database query, and significant operation
2. **Structured Logging**: JSON logs with trace context
3. **Meaningful Spans**: Name spans after what they DO, not where they ARE
4. **Low Overhead**: Sample appropriately, don't trace every request in production

## OpenTelemetry Setup (TypeScript/Bun)

```typescript
import { trace, metrics, context, SpanStatusCode } from '@opentelemetry/api';
import { NodeTracerProvider } from '@opentelemetry/sdk-trace-node';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';

// Initialize once at app startup
const provider = new NodeTracerProvider();
provider.addSpanProcessor(
  new BatchSpanProcessor(
    new OTLPTraceExporter({ url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT })
  )
);
provider.register();

// Get tracer for your service
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

      if (!user) {
        span.setStatus({ code: SpanStatusCode.ERROR, message: 'User not found' });
        throw new Error(`User ${userId} not found`);
      }

      span.setStatus({ code: SpanStatusCode.OK });
      return user;
    } catch (error) {
      span.recordException(error as Error);
      span.setStatus({ code: SpanStatusCode.ERROR, message: (error as Error).message });
      throw error;
    } finally {
      span.end();
    }
  });
}
```

### Automatic Span Wrapper (Higher-Order Function)

```typescript
function traced<T extends (...args: any[]) => Promise<any>>(
  name: string,
  fn: T,
  attributes?: Record<string, string | number | boolean>
): T {
  return (async (...args: Parameters<T>) => {
    return tracer.startActiveSpan(name, async (span) => {
      try {
        if (attributes) {
          Object.entries(attributes).forEach(([k, v]) => span.setAttribute(k, v));
        }
        const result = await fn(...args);
        span.setStatus({ code: SpanStatusCode.OK });
        return result;
      } catch (error) {
        span.recordException(error as Error);
        span.setStatus({ code: SpanStatusCode.ERROR });
        throw error;
      } finally {
        span.end();
      }
    });
  }) as T;
}

// Usage
const tracedFetchUser = traced('user.fetch', fetchUser, { 'operation.type': 'read' });
```

## Span Naming Conventions

| Pattern | Example | When to Use |
|---------|---------|-------------|
| `{resource}.{action}` | `user.create`, `order.submit` | CRUD operations |
| `{service}.{method}` | `payment.charge`, `email.send` | External service calls |
| `db.{operation}` | `db.query`, `db.transaction` | Database operations |
| `http.{method}` | `http.get`, `http.post` | HTTP requests |
| `queue.{action}` | `queue.publish`, `queue.consume` | Message queue operations |

## Attribute Standards

### Required Attributes

```typescript
// Service identification
span.setAttribute('service.name', 'my-service');
span.setAttribute('service.version', '1.0.0');

// Request context
span.setAttribute('http.method', 'POST');
span.setAttribute('http.url', '/api/users');
span.setAttribute('http.status_code', 201);

// User context (if authenticated)
span.setAttribute('user.id', userId);
span.setAttribute('user.role', 'admin');
```

### Semantic Conventions

Follow OpenTelemetry semantic conventions:
- `db.system`: "postgresql", "redis", "mongodb"
- `db.statement`: Sanitized query (no PII)
- `messaging.system`: "kafka", "rabbitmq"
- `rpc.system`: "grpc", "http"

## Metrics Patterns

```typescript
const meter = metrics.getMeter('my-service');

// Counter - things that only go up
const requestCounter = meter.createCounter('http.requests.total', {
  description: 'Total HTTP requests',
});
requestCounter.add(1, { method: 'GET', path: '/api/users' });

// Histogram - distribution of values
const latencyHistogram = meter.createHistogram('http.request.duration', {
  description: 'Request latency in milliseconds',
  unit: 'ms',
});
latencyHistogram.record(125, { method: 'GET', path: '/api/users' });

// Gauge - current value (use ObservableGauge)
meter.createObservableGauge('connections.active', {
  description: 'Active database connections',
}, (result) => {
  result.observe(pool.activeConnections);
});
```

## Structured Logging with Trace Context

```typescript
import { context, trace } from '@opentelemetry/api';

function log(level: 'debug' | 'info' | 'warn' | 'error', message: string, data?: object) {
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

// Usage
log('info', 'User created', { userId: '123', email: 'user@example.com' });
// Output: {"timestamp":"...","level":"info","message":"User created","traceId":"abc123","spanId":"def456","userId":"123","email":"user@example.com"}
```

## Hono Middleware (Cloudflare Workers)

```typescript
import { Hono } from 'hono';
import { trace } from '@opentelemetry/api';

const tracingMiddleware = () => {
  return async (c: Context, next: Next) => {
    const tracer = trace.getTracer('hono-service');

    return tracer.startActiveSpan(`${c.req.method} ${c.req.path}`, async (span) => {
      span.setAttribute('http.method', c.req.method);
      span.setAttribute('http.url', c.req.url);
      span.setAttribute('http.target', c.req.path);

      try {
        await next();
        span.setAttribute('http.status_code', c.res.status);
        span.setStatus({ code: SpanStatusCode.OK });
      } catch (error) {
        span.recordException(error as Error);
        span.setStatus({ code: SpanStatusCode.ERROR });
        throw error;
      } finally {
        span.end();
      }
    });
  };
};

const app = new Hono();
app.use('*', tracingMiddleware());
```

## Sampling Strategies

```typescript
import { ParentBasedSampler, TraceIdRatioBasedSampler } from '@opentelemetry/sdk-trace-base';

// Sample 10% of traces in production
const sampler = new ParentBasedSampler({
  root: new TraceIdRatioBasedSampler(0.1),
});

// Always sample errors
const alwaysSampleErrors = {
  shouldSample(context, traceId, spanName, spanKind, attributes) {
    if (attributes?.['error'] === true) {
      return { decision: SamplingDecision.RECORD_AND_SAMPLED };
    }
    return baseSampler.shouldSample(context, traceId, spanName, spanKind, attributes);
  },
};
```

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Tracing everything | High overhead, noisy data | Sample appropriately |
| PII in spans | Security/compliance risk | Sanitize or omit |
| Span per line | Creates millions of spans | One span per logical operation |
| Ignoring errors | Lost debugging context | Always recordException() |
| Missing context propagation | Broken traces | Use context.with() |

## Integration Checklist

- [ ] OTEL collector or exporter configured
- [ ] Service name and version set
- [ ] HTTP middleware instrumented
- [ ] Database calls traced
- [ ] External API calls traced
- [ ] Error handling includes span updates
- [ ] Sampling configured for production
- [ ] Logs include trace context
