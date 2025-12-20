---
name: effect-ts-patterns
description: Effect-TS patterns for typed effects, errors, and dependencies. Effect<A,E,R> type system.
allowed-tools: Read, Write, Edit
token-budget: 400
references:
  - references/services.md: "Service patterns with Context.Tag and Layer"
  - references/errors.md: "Error handling with Data.TaggedError"
  - references/http-api.md: "HTTP API patterns with HttpApiBuilder"
  - references/testing.md: "Testing patterns with mock Layers"
---

# Effect-TS Patterns

> Read specific reference files based on your task.

## Core Concept: Effect<A, E, R>

```
Effect<Success, Error, Requirements>
       ↓        ↓           ↓
    "Returns" "Can fail"  "Needs these services"
```

## Generator Syntax (Recommended)

```typescript
import { Effect } from "effect";

const program = Effect.gen(function* () {
  const config = yield* getConfig();           // yield* unwraps effects
  const db = yield* connectDatabase(config.dbUrl);
  const users = yield* db.query("SELECT * FROM users");
  return users;
});
// Type: Effect<User[], ConfigError | DbError, ConfigService>
```

## Service Pattern Summary

```typescript
import { Context, Effect, Layer } from "effect";

// 1. Define service with Context.Tag
class HttpClient extends Context.Tag("HttpClient")<
  HttpClient,
  { readonly get: (url: string) => Effect.Effect<Response, HttpError> }
>() {}

// 2. Use in effects (tracked in R position)
const fetchUsers = Effect.gen(function* () {
  const http = yield* HttpClient;
  return yield* http.get("/api/users");
});
// Type: Effect<Response, HttpError, HttpClient>

// 3. Provide layer to satisfy requirements
const HttpClientLive = Layer.succeed(HttpClient, { get: ... });
const program = fetchUsers.pipe(Effect.provide(HttpClientLive));
// Type: Effect<Response, HttpError, never>  ← Requirements satisfied!
```

## Typed Errors

```typescript
import { Data, Effect } from "effect";

class UserNotFoundError extends Data.TaggedError("UserNotFoundError")<{
  readonly userId: string;
}> {}

const getUser = (id: string) => Effect.gen(function* () {
  const user = yield* findUser(id);
  if (!user) return yield* Effect.fail(new UserNotFoundError({ userId: id }));
  return user;
});

// Catch by tag
getUser("123").pipe(
  Effect.catchTag("UserNotFoundError", (e) => Effect.succeed(guestUser))
);
```

## Quick Reference

| Operation | Code |
|-----------|------|
| Create success | `Effect.succeed(value)` |
| Create failure | `Effect.fail(error)` |
| From promise | `Effect.tryPromise({ try, catch })` |
| Generator | `Effect.gen(function* () { ... })` |
| Provide service | `effect.pipe(Effect.provide(layer))` |
| Catch by tag | `Effect.catchTag("Tag", handler)` |
| Retry | `Effect.retry(schedule)` |
| Timeout | `Effect.timeout(duration)` |

## When to Read Reference Files

| Task | Read |
|------|------|
| Creating services | `references/services.md` |
| Error handling | `references/errors.md` |
| HTTP APIs | `references/http-api.md` |
| Writing tests | `references/testing.md` |

## Anti-Patterns (BANNED)

- **throw for expected failures** → Use `Effect.fail(error)`
- **raw fetch()** → Use `HttpClient` (Guard 44)
- **new Date()** → Use `Clock.currentTimeMillis` (Guard 42)
- **console.log** → Use `Effect.log` (Guard 26)
- **T | null** → Use `Option<T>` (Guard 41)
