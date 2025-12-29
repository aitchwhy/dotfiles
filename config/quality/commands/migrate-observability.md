---
name: migrate-observability
description: Migrates a project to the standard Datadog + OTEL observability stack
tools: Read, Write, Edit, Bash, Glob, Grep
model: opus
---

# Migrate Project to Standard Observability

You are migrating a project to use the standard Datadog + OpenTelemetry observability stack.

## Overview

This migration ensures consistent observability across all projects:
- **Tracing**: OpenTelemetry SDK 2.x → Datadog via OTLP
- **Metrics**: OpenTelemetry SDK 2.x → Datadog via OTLP
- **Logging**: Structured JSON with trace correlation
- **Analytics**: PostHog (optional)
- **Feature Flags**: DevCycle (optional)

## Migration Steps

### 1. Audit Current State

Find existing observability code:

```bash
# Find observability-related files
rg -l "opentelemetry|@google-cloud.*trace|dd-trace|sentry|newrelic" --type ts

# Find raw console.log usage (should use structured logger)
rg "console\.(log|error|warn|info)" --type ts src/
```

### 2. Remove Banned Packages

Check package.json for banned packages and remove them:

| Package | Status | Alternative |
|---------|--------|-------------|
| `@google-cloud/opentelemetry-cloud-trace-exporter` | BANNED | `@opentelemetry/exporter-trace-otlp-proto` |
| `@google-cloud/opentelemetry-cloud-monitoring-exporter` | BANNED | `@opentelemetry/exporter-metrics-otlp-proto` |
| `@opentelemetry/exporter-trace-otlp-http` | BANNED | `@opentelemetry/exporter-trace-otlp-proto` |
| `@opentelemetry/exporter-metrics-otlp-http` | BANNED | `@opentelemetry/exporter-metrics-otlp-proto` |
| `dd-trace` | BANNED | OTEL SDK (dd-trace doesn't work with Bun) |
| `@sentry/node` | BANNED | Datadog Error Tracking |

### 3. Add Required Packages

```bash
bun add @opentelemetry/api@1.9.0 \
  @opentelemetry/sdk-node@0.200.0 \
  @opentelemetry/sdk-trace-node@2.0.0 \
  @opentelemetry/sdk-metrics@2.0.0 \
  @opentelemetry/resources@2.0.0 \
  @opentelemetry/semantic-conventions@1.30.0 \
  @opentelemetry/exporter-trace-otlp-proto@0.200.0 \
  @opentelemetry/exporter-metrics-otlp-proto@0.200.0 \
  @opentelemetry/auto-instrumentations-node@0.56.0
```

### 4. Create/Update Files

Create these files following the patterns in the observability-patterns skill:

#### 4.1. `src/instrumentation.ts` (OTEL SDK setup)

```typescript
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
const otlpEndpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318';

const resource = resourceFromAttributes({
  [ATTR_SERVICE_NAME]: serviceName,
  [ATTR_SERVICE_VERSION]: serviceVersion,
  [ATTR_DEPLOYMENT_ENVIRONMENT]: environment,
  'dd.service': serviceName,
  'dd.version': serviceVersion,
  'dd.env': environment,
});

const sdk = new NodeSDK({
  resource,
  spanProcessors: [
    new BatchSpanProcessor(
      new OTLPTraceExporter({ url: `${otlpEndpoint}/v1/traces` }),
      { maxQueueSize: 2048, scheduledDelayMillis: isProduction ? 5000 : 1000 }
    ),
  ],
  metricReader: new PeriodicExportingMetricReader({
    exporter: new OTLPMetricExporter({ url: `${otlpEndpoint}/v1/metrics` }),
    exportIntervalMillis: isProduction ? 60000 : 10000,
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-fs': { enabled: false },
      '@opentelemetry/instrumentation-http': {
        ignoreIncomingRequestHook: (req) => req.url === '/health',
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

#### 4.2. `src/lib/telemetry/logger.ts` (Structured logging)

```typescript
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
    log('error', msg, {
      error: err ? { name: err.name, message: err.message, stack: err.stack } : undefined,
      ...data,
    }),
};
```

### 5. Update Server Entry Point

Ensure `instrumentation.ts` is the **FIRST import** in your server entry file:

```typescript
// src/server.ts
// CRITICAL: Import instrumentation FIRST
import './instrumentation.js';

// Now import everything else
import { Hono } from 'hono';
import { logger } from './lib/telemetry/logger.js';
// ...
```

### 6. Remove Old Telemetry Files

Delete any files that configure GCP-specific or split-brain telemetry:
- `src/lib/tracing.ts` (if GCP-specific)
- `src/lib/telemetry/index.ts` (if GCP-specific)
- Any duplicate OTEL configuration files

### 7. Update Environment Variables

Add to `.env.example`:
```bash
DD_SERVICE=your-service
DD_ENV=development
DD_VERSION=0.0.0
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
```

### 8. Replace console.log with logger

Find and replace raw console.log calls with structured logger:

```typescript
// Before
console.log('User created:', userId);

// After
import { logger } from './lib/telemetry/logger.js';
logger.info('User created', { userId });
```

### 9. Verify

```bash
# Run tests
bun test

# Start server and check OTEL initialization
bun run dev
# Should see: [OTEL] Initialized: service=xxx env=xxx
```

## Checklist

- [ ] Banned packages removed from package.json
- [ ] Required OTEL packages added with correct versions
- [ ] `instrumentation.ts` created
- [ ] `instrumentation.ts` is first import in server entry
- [ ] `lib/telemetry/logger.ts` created
- [ ] Old GCP-specific telemetry files deleted
- [ ] `console.log` calls replaced with `logger.*`
- [ ] Environment variables documented in `.env.example`
- [ ] DD_SERVICE, DD_ENV, DD_VERSION set
- [ ] Tests pass
- [ ] Server starts with OTEL initialization message
