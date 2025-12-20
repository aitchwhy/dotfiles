---
name: effect-resilience
description: Effect-TS patterns for retry, timeout, polling, and XState integration.
allowed-tools: Read, Write, Edit, Grep, Glob
token-budget: 400
version: 1.0.0
---

# Effect Resilience Patterns

Retry, timeout, and polling using Effect primitives.

## Effect.retry + Schedule

```typescript
import { Effect, Schedule } from 'effect';

// Exponential backoff with jitter
const policy = Schedule.exponential('100 millis').pipe(
  Schedule.jittered,
  Schedule.compose(Schedule.recurs(5))
);

const resilient = Effect.retry(fetchData, policy);
```

## Effect.timeout

```typescript
// Timeout with typed error
const withTimeout = Effect.timeout(fetchData, '30 seconds');
// Returns Effect<A, E | TimeoutException, R>
```

## Effect.repeat (Polling)

```typescript
// Poll every 5 seconds until condition
const poll = Effect.repeat(
  checkStatus,
  Schedule.spaced('5 seconds').pipe(
    Schedule.whileOutput((status) => status !== 'complete')
  )
);
```

## XState v5 Integration

Use `fromPromise` to wrap Effect programs:

```typescript
import { fromPromise } from 'xstate';
import { Effect } from 'effect';

const fetchActor = fromPromise(async ({ input }: { input: { id: string } }) => {
  return Effect.runPromise(
    fetchUser(input.id).pipe(
      Effect.retry(Schedule.exponential('100 millis').pipe(Schedule.recurs(3))),
      Effect.timeout('30 seconds'),
      Effect.provide(HttpClientLive)
    )
  );
});
```

## Anti-patterns

```typescript
// BAD - manual retry loop
let retries = 3;
while (retries > 0) { ... }

// BAD - setTimeout polling
setInterval(() => checkStatus(), 5000);

// GOOD - Effect primitives
Effect.retry(op, Schedule.exponential('100 millis'));
Effect.repeat(op, Schedule.spaced('5 seconds'));
```
