---
description: Add OpenTelemetry tracing to code
allowed-tools: Read, Write
---

# Add Tracing: $ARGUMENTS

Add OpenTelemetry instrumentation to the specified code.

## TypeScript Pattern

```typescript
import { trace, SpanStatusCode } from '@opentelemetry/api';

const tracer = trace.getTracer('service-name');

export async function operationName(params: Params): Promise<Result> {
  return tracer.startActiveSpan('operation.name', async (span) => {
    try {
      span.setAttribute('param.key', params.value);

      const result = await doOperation(params);

      span.setAttribute('result.status', 'success');
      return result;
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

## Span Naming

- Use dot notation: `service.operation`
- Be specific: `user.create` not just `create`
- Include important attributes

## Required Attributes

- Input parameters (non-sensitive)
- Result status
- Error details if failed
