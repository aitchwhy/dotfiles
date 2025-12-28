---
name: effect-clock-patterns
description: Effect Clock for injectable, testable time. Never use new Date() directly.
allowed-tools: Read, Write, Edit
token-budget: 800
---

# effect-clock-patterns

## Overview

# Effect Clock Patterns

## Why Not new Date()?

```typescript
// UNTESTABLE
const createdAt = new Date();
```

## Clock Service

```typescript
import { Clock, Effect } from "effect";

// Helper (put in lib/clock.ts)
export const currentTimestamp = Effect.map(
  Clock.currentTimeMillis,
  (ms) => new Date(ms)
);

// Usage
const program = Effect.gen(function* () {
  const now = yield* currentTimestamp;
  yield* db.update(records).set({ updatedAt: now });
});
```

## Testing

```typescript
import { TestClock, Effect } from "effect";

const test = Effect.gen(function* () {
  yield* TestClock.setTime(new Date("2024-06-15").getTime());
  const result = yield* myTimeDependentCode;
  yield* TestClock.adjust("1 hour");
});

Effect.runPromise(test.pipe(Effect.provide(TestClock.layer)));
```

## Migration

| Before | After |
|--------|-------|
| `new Date()` | `yield* currentTimestamp` |
| `Date.now()` | `yield* Clock.currentTimeMillis` |
