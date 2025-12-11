---
name: observability-patterns
description: Datadog + OpenTelemetry SDK 2.x patterns for traces, metrics, logs. PostHog for analytics. DevCycle for feature flags.
allowed-tools: Read, Write, Edit
---

# Observability Patterns (December 2025)

## The Stack

| Layer | Tool | Purpose |
|-------|------|---------|
| **Tracing** | OpenTelemetry SDK 2.x → Datadog | Distributed traces |
| **Metrics** | OpenTelemetry SDK 2.x → Datadog | RED metrics, business metrics |
| **Logging** | Structured JSON → Datadog | Logs with trace correlation |
| **Analytics** | PostHog | Session replay, product events |
| **Feature Flags** | DevCycle | Edge evaluation (<1ms) |

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────┐
│   Application   │────▶│  Datadog Agent   │────▶│   Datadog   │
│  (OTEL SDK 2.x) │     │  (OTLP Receiver) │     │   Backend   │
└─────────────────┘     └──────────────────┘     └─────────────┘
        │
        │ (direct)
        ▼
┌─────────────────┐
│    PostHog      │
│  (Analytics)    │
└─────────────────┘
```

## CRITICAL: Instrumentation Entry Point

**MUST be the FIRST import in your server entry file.**

```typescript
// src/instrumentation.ts
/**
 * OpenTelemetry SDK 2.x instrumentation for Datadog.
 * IMPORT THIS BEFORE ALL OTHER MODULES.
 */

import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-proto';
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-proto';
import { PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-node';
import { resourceFromAttributes } from '@opentelemetry/resources';
import {
  ATTR_SERVICE_NAME,
  ATTR_SERVICE_VERSION,
  ATTR_DEPLOYMENT_ENVIRONMENT,
} from '@opentelemetry/semantic-conventions';

const isProduction = process.env.NODE_ENV === 'production';
const serviceName = process.env.DD_SERVICE || 'my-service';
const serviceVersion = process.env.DD_VERSION || '0.0.0';
const environment = process.env.DD_ENV || 'development';

// Datadog Agent OTLP endpoint (sidecar in Cloud Run)
const otlpEndpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318';

const resource = resourceFromAttributes({
  [ATTR_SERVICE_NAME]: serviceName,
  [ATTR_SERVICE_VERSION]: serviceVersion,
  [ATTR_DEPLOYMENT_ENVIRONMENT]: environment,
  'dd.service': serviceName,
  'dd.version': serviceVersion,
  'dd.env': environment,
});

const traceExporter = new OTLPTraceExporter({
  url: `${otlpEndpoint}/v1/traces`,
});

const metricExporter = new OTLPMetricExporter({
  url: `${otlpEndpoint}/v1/metrics`,
});

const sdk = new NodeSDK({
  resource,
  spanProcessors: [
    new BatchSpanProcessor(traceExporter, {
      maxQueueSize: 2048,
      maxExportBatchSize: 512,
      scheduledDelayMillis: isProduction ? 5000 : 1000,
    }),
  ],
  metricReader: new PeriodicExportingMetricReader({
    exporter: metricExporter,
    exportIntervalMillis: isProduction ? 60000 : 10000,
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-fs': { enabled: false },
      '@opentelemetry/instrumentation-http': {
        ignoreIncomingRequestHook: (req) =>
          req.url === '/health' || req.url === '/ready',
      },
      '@opentelemetry/instrumentation-pg': {
        enhancedDatabaseReporting: true,
      },
    }),
  ],
});

sdk.start();
console.log(`[OTEL] Initialized: service=${serviceName} env=${environment}`);

process.on('SIGTERM', async () => {
  await sdk.shutdown();
  process.exit(0);
});

export { sdk };
```

## Server Entry Point

```typescript
// src/server.ts
// CRITICAL: Import instrumentation FIRST
import './instrumentation.js';

// Now import everything else
import { app } from './app.js';
// ...
```

## Custom Metrics (RED + Business)

```typescript
// src/lib/telemetry/metrics.ts
import { metrics } from '@opentelemetry/api';

const meter = metrics.getMeter('my-service', '1.0.0');

// RED Metrics
export const httpRequestsTotal = meter.createCounter('http.requests.total');
export const httpRequestDuration = meter.createHistogram('http.request.duration', {
  unit: 'ms',
  advice: {
    explicitBucketBoundaries: [5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000],
  },
});
export const httpErrorsTotal = meter.createCounter('http.errors.total');

// Business Metrics (customize per project)
export const ordersCreated = meter.createCounter('business.orders.created');
export const revenueTotal = meter.createCounter('business.revenue.total', { unit: 'usd' });

// Helper
export function recordHttpRequest(method: string, route: string, status: number, durationMs: number) {
  const attrs = { method, route, status: status.toString() };
  httpRequestsTotal.add(1, attrs);
  httpRequestDuration.record(durationMs, attrs);
  if (status >= 400) httpErrorsTotal.add(1, { ...attrs, error_type: status >= 500 ? 'server' : 'client' });
}
```

## Structured Logging with Trace Correlation

```typescript
// src/lib/telemetry/logger.ts
import { trace } from '@opentelemetry/api';

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

function log(level: LogLevel, message: string, data?: object) {
  const span = trace.getActiveSpan();
  const ctx = span?.spanContext();

  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    level,
    message,
    service: process.env.DD_SERVICE,
    dd: ctx ? { trace_id: ctx.traceId, span_id: ctx.spanId } : undefined,
    ...data,
  }));
}

export const logger = {
  debug: (msg: string, data?: object) => log('debug', msg, data),
  info: (msg: string, data?: object) => log('info', msg, data),
  warn: (msg: string, data?: object) => log('warn', msg, data),
  error: (msg: string, err?: Error, data?: object) =>
    log('error', msg, { error: err ? { name: err.name, message: err.message, stack: err.stack } : undefined, ...data }),
};
```

## Hono Middleware

```typescript
// src/middleware/tracing.ts
import { SpanKind, SpanStatusCode, context, trace, propagation } from '@opentelemetry/api';
import type { Context, Next } from 'hono';
import { recordHttpRequest } from '../lib/telemetry/metrics.js';
import { logger } from '../lib/telemetry/logger.js';

const tracer = trace.getTracer('my-service');

export function tracingMiddleware() {
  return async (c: Context, next: Next) => {
    const start = performance.now();
    const method = c.req.method;
    const path = c.req.path;

    // Skip health checks
    if (path === '/health' || path === '/ready') return next();

    // Extract trace context from incoming request
    const parentContext = propagation.extract(context.active(), c.req.raw.headers, {
      get: (h, k) => h instanceof Headers ? h.get(k) ?? undefined : undefined,
      keys: (h) => h instanceof Headers ? [...h.keys()] : [],
    });

    const span = tracer.startSpan(`${method} ${path}`, { kind: SpanKind.SERVER }, parentContext);

    let status = 500;
    try {
      await context.with(trace.setSpan(parentContext, span), () => next());
      status = c.res.status;
      span.setStatus({ code: status >= 400 ? SpanStatusCode.ERROR : SpanStatusCode.OK });
    } catch (e) {
      span.recordException(e instanceof Error ? e : new Error(String(e)));
      span.setStatus({ code: SpanStatusCode.ERROR });
      throw e;
    } finally {
      const duration = performance.now() - start;
      span.setAttribute('http.status_code', status);
      span.end();
      recordHttpRequest(method, path, status, duration);
      logger.info(`${method} ${path} ${status}`, { durationMs: Math.round(duration) });
    }
  };
}
```

## PostHog (Browser)

```typescript
// src/lib/posthog.ts
import posthog from 'posthog-js';

export function initPostHog() {
  const key = import.meta.env.VITE_POSTHOG_KEY;
  if (!key) return;

  posthog.init(key, {
    api_host: 'https://us.i.posthog.com',
    session_recording: { maskAllInputs: true },
    capture_pageview: true,
    respect_dnt: true,
  });
}

export function identify(userId: string, props?: object) {
  posthog.identify(userId, props);
}

export function track(event: string, props?: object) {
  posthog.capture(event, props);
}
```

## DevCycle Feature Flags (Server)

```typescript
// src/lib/feature-flags.ts
import { trace } from '@opentelemetry/api';

let client: ReturnType<typeof import('@devcycle/nodejs-server-sdk').initializeDevCycle> | null = null;

export const FLAGS = {
  NEW_FEATURE: 'new-feature',
  BETA_MODE: 'beta-mode',
} as const;

export async function initFeatureFlags() {
  const key = process.env.DEVCYCLE_SERVER_SDK_KEY;
  if (!key) return;

  const { initializeDevCycle } = await import('@devcycle/nodejs-server-sdk');
  client = await initializeDevCycle(key, { enableCloudBucketing: false }).onClientInitialized();
}

export function isEnabled(flag: string, user: { userId: string }): boolean {
  if (!client) return false;

  const value = client.variableValue({ user_id: user.userId }, flag, false);

  // Record in span for Datadog correlation
  const span = trace.getActiveSpan();
  span?.setAttribute(`feature_flag.${flag}`, value);

  return value;
}
```

## Environment Variables

```bash
# Datadog service identification
DD_SERVICE=my-service
DD_ENV=production
DD_VERSION=1.0.0

# OTLP endpoint (Datadog Agent)
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318

# PostHog
VITE_POSTHOG_KEY=phc_xxx
POSTHOG_API_KEY=phc_xxx

# DevCycle (optional)
DEVCYCLE_SERVER_SDK_KEY=dvc_server_xxx
VITE_DEVCYCLE_CLIENT_KEY=dvc_client_xxx
```

## BANNED Patterns (Enforced by unified-guard.ts)

| Pattern | Reason | Alternative |
|---------|--------|-------------|
| `@google-cloud/opentelemetry-cloud-trace-exporter` | Split-brain | OTLP → Datadog |
| `@google-cloud/opentelemetry-cloud-monitoring-exporter` | Split-brain | OTLP → Datadog |
| `@opentelemetry/exporter-trace-otlp-http` | Proto is better | `exporter-trace-otlp-proto` |
| `@opentelemetry/exporter-metrics-otlp-http` | Proto is better | `exporter-metrics-otlp-proto` |
| `dd-trace` | Doesn't work with Bun | OTEL SDK |
| `console.log` for observability | No structure | `logger.info()` |
| Multiple tracing configs | Split-brain | Single `instrumentation.ts` |

## Checklist for Every Project

- [ ] `instrumentation.ts` is first import in server entry
- [ ] DD_SERVICE, DD_ENV, DD_VERSION env vars set
- [ ] Custom metrics defined in `lib/telemetry/metrics.ts`
- [ ] Structured logger in `lib/telemetry/logger.ts`
- [ ] Tracing middleware in Hono app
- [ ] PostHog initialized in web entry (if frontend)
- [ ] No banned packages in package.json
- [ ] Health endpoints excluded from tracing
