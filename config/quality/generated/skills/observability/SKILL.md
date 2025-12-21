---
name: observability
description: OpenTelemetry + Effect logging for distributed tracing
allowed-tools: Read, Write, Edit, Grep
token-budget: 350
---

# observability

## Effect Logging

```typescript
import { Effect } from "effect";

const program = Effect.gen(function* () {
  yield* Effect.log("Starting process");
  yield* Effect.logDebug("Debug info", { userId: "123" });

  const result = yield* doWork();

  yield* Effect.logInfo("Process complete", { result });
  return result;
}).pipe(
  Effect.withSpan("processOrder", { attributes: { orderId } })
);
```

## Structured Spans

```typescript
import { Effect } from "effect";

const processOrder = (orderId: string) =>
  Effect.gen(function* () {
    yield* validateOrder(orderId).pipe(Effect.withSpan("validate"));
    yield* chargePayment(orderId).pipe(Effect.withSpan("charge"));
    yield* sendConfirmation(orderId).pipe(Effect.withSpan("notify"));
  }).pipe(Effect.withSpan("processOrder"));
```

Spans are automatically nested and exported to OTEL collectors.

## OTEL Integration

```typescript
import { NodeSdk } from "@effect/opentelemetry";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-proto";

const OtelLive = NodeSdk.layer(() => ({
  resource: { serviceName: "my-service" },
  spanProcessor: new BatchSpanProcessor(new OTLPTraceExporter()),
}));

// Provide to your program
const main = program.pipe(Effect.provide(OtelLive));
```

## Anti-Patterns

- **console.log** → Use Effect.log (structured, traced)
- **console.error** → Use Effect.logError (with stack traces)
- **Custom logger** → Use Effect's built-in (integrates with OTEL)
