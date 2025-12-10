---
name: effect-ts-patterns
description: Effect-TS patterns for typed effects, errors, and dependencies. Effect<A,E,R> type system, Layers, Services.
allowed-tools: Read, Write, Edit
---

## Philosophy: Make Effects Explicit

Effect-TS makes effects, errors, and dependencies explicit in the type system.
The type signature `Effect<A, E, R>` tells you EVERYTHING about a computation:

```
Effect<Success, Error, Requirements>
       ↓        ↓           ↓
    "Returns" "Can fail"  "Needs these services"
```

## Core Concept: Effect<A, E, R>

```typescript
import { Effect, Console } from "effect";

// Success - no error, no requirements
const succeed = Effect.succeed(42);
// Type: Effect<number, never, never>

// Failure - typed error
const fail = Effect.fail(new Error("boom"));
// Type: Effect<never, Error, never>

// From Promise with error handling
const fromPromise = Effect.tryPromise({
  try: () => fetch("/api/users"),
  catch: (e) => new NetworkError(e),
});
// Type: Effect<Response, NetworkError, never>

// Synchronous side effect
const log = Effect.sync(() => console.log("hello"));
// Type: Effect<void, never, never>
```

## Generator Syntax (Recommended)

Use `Effect.gen` for readable sequential code:

```typescript
import { Effect } from "effect";

const program = Effect.gen(function* () {
  // yield* "unwraps" effects, like await for promises
  const config = yield* getConfig();
  const db = yield* connectDatabase(config.dbUrl);
  const users = yield* db.query("SELECT * FROM users");

  yield* Console.log(`Found ${users.length} users`);

  return users;
});
// Type: Effect<User[], ConfigError | DbError, ConfigService>
```

## Service Pattern (Dependency Injection)

### Define Service with Context.Tag

```typescript
import { Context, Effect, Layer } from "effect";

// 1. Define service interface with Context.Tag
class HttpClient extends Context.Tag("HttpClient")<
  HttpClient,
  {
    readonly get: (url: string) => Effect.Effect<Response, HttpError>;
    readonly post: (url: string, body: unknown) => Effect.Effect<Response, HttpError>;
  }
>() {}

// 2. Use service in your code
const fetchUsers = Effect.gen(function* () {
  const http = yield* HttpClient;
  const response = yield* http.get("/api/users");
  const data = yield* Effect.tryPromise(() => response.json());
  return data as User[];
});
// Type: Effect<User[], HttpError, HttpClient>
//                                 ^^^^^^^^^^
//                                 Requirement tracked!
```

### Implement Service with Layer

```typescript
// 3. Create implementation layer
const HttpClientLive = Layer.succeed(
  HttpClient,
  {
    get: (url) => Effect.tryPromise({
      try: () => fetch(url),
      catch: (e) => new HttpError("GET", url, e),
    }),
    post: (url, body) => Effect.tryPromise({
      try: () => fetch(url, {
        method: "POST",
        body: JSON.stringify(body),
        headers: { "Content-Type": "application/json" },
      }),
      catch: (e) => new HttpError("POST", url, e),
    }),
  }
);

// 4. Provide layer and run
const program = fetchUsers.pipe(
  Effect.provide(HttpClientLive),
);
// Type: Effect<User[], HttpError, never>
//                                 ^^^^^
//                                 Requirements satisfied!

Effect.runPromise(program);
```

### Layer Composition

```typescript
// Compose multiple layers
const AppLayer = Layer.mergeAll(
  HttpClientLive,
  DatabaseLive,
  LoggerLive,
);

// Layers can depend on other layers
const ConfigLive = Layer.effect(
  ConfigService,
  Effect.gen(function* () {
    const env = yield* EnvService;
    return {
      dbUrl: env.get("DATABASE_URL"),
      apiKey: env.get("API_KEY"),
    };
  })
);
```

## Typed Errors with Data.TaggedError

```typescript
import { Data, Effect } from "effect";

// Define error types
class UserNotFoundError extends Data.TaggedError("UserNotFoundError")<{
  readonly userId: string;
}> {}

class ValidationError extends Data.TaggedError("ValidationError")<{
  readonly field: string;
  readonly message: string;
}> {}

class DatabaseError extends Data.TaggedError("DatabaseError")<{
  readonly query: string;
  readonly cause: unknown;
}> {}

// Use in effects
const getUser = (id: string): Effect.Effect<User, UserNotFoundError | DatabaseError, Database> =>
  Effect.gen(function* () {
    const db = yield* Database;
    const user = yield* db.findById(id);

    if (!user) {
      return yield* Effect.fail(new UserNotFoundError({ userId: id }));
    }

    return user;
  });
```

## Error Recovery

```typescript
const program = getUser("123").pipe(
  // Catch specific error by tag
  Effect.catchTag("UserNotFoundError", (e) =>
    Effect.succeed({ id: e.userId, name: "Guest", role: "guest" as const })
  ),

  // Catch all errors
  Effect.catchAll((e) => Effect.succeed(defaultUser)),

  // Map errors to different type
  Effect.mapError((e) => new ApiError(e.message)),

  // Tap errors for logging (doesn't change error)
  Effect.tapError((e) => Console.error(`Error: ${e._tag}`)),
);
```

## Retry with Schedule

```typescript
import { Effect, Schedule } from "effect";

const fetchWithRetry = fetchUsers.pipe(
  // Exponential backoff: 100ms, 200ms, 400ms, 800ms, 1600ms
  Effect.retry(
    Schedule.exponential("100 millis").pipe(
      Schedule.compose(Schedule.recurs(5)), // Max 5 retries
      Schedule.whileInput((e) => e._tag === "NetworkError"), // Only retry network errors
    )
  ),
);
```

## Timeouts

```typescript
const withTimeout = fetchUsers.pipe(
  Effect.timeout("5 seconds"),
  Effect.catchTag("TimeoutException", () =>
    Effect.fail(new Error("Request timed out"))
  ),
);
```

## Parallel Execution

```typescript
// Run all in parallel, fail fast
const parallel = Effect.all([
  fetchUsers,
  fetchProducts,
  fetchOrders,
], { concurrency: "unbounded" });

// Run all, collect all results (even failures)
const allSettled = Effect.allSettled([
  fetchUsers,
  fetchProducts,
  fetchOrders,
]);

// Race: first success wins
const race = Effect.race(
  fetchFromPrimary,
  fetchFromSecondary,
);
```

## Resource Management

```typescript
import { Effect, Scope } from "effect";

// Acquire/release pattern
const withDatabase = Effect.acquireRelease(
  // Acquire
  Effect.tryPromise(() => createConnection()),
  // Release (runs even on error)
  (conn) => Effect.sync(() => conn.close()),
);

// Use scoped resource
const program = Effect.scoped(
  Effect.gen(function* () {
    const db = yield* withDatabase;
    return yield* db.query("SELECT * FROM users");
  })
);
```

## Integration with Hono

```typescript
import { Hono } from "hono";
import { Effect, Layer } from "effect";

const app = new Hono();

// Helper to run effects in routes
const runEffect = <A, E>(
  effect: Effect.Effect<A, E, AppServices>,
  appLayer: Layer.Layer<AppServices>,
) => Effect.runPromise(effect.pipe(Effect.provide(appLayer)));

app.get("/users", async (c) => {
  const result = await runEffect(
    Effect.gen(function* () {
      const userService = yield* UserService;
      return yield* userService.list();
    }),
    AppLayer,
  );

  return c.json(result);
});
```

## Testing with Mock Layers

```typescript
import { Effect, Layer } from "effect";
import { describe, it, expect } from "vitest";

// Create test layer
const HttpClientTest = Layer.succeed(
  HttpClient,
  {
    get: (url) => {
      if (url === "/api/users") {
        return Effect.succeed(new Response(JSON.stringify([{ id: "1", name: "Test" }])));
      }
      return Effect.fail(new HttpError("GET", url, "Not found"));
    },
    post: () => Effect.fail(new HttpError("POST", "", "Not implemented")),
  }
);

describe("fetchUsers", () => {
  it("returns users", async () => {
    const result = await Effect.runPromise(
      fetchUsers.pipe(Effect.provide(HttpClientTest))
    );
    expect(result).toHaveLength(1);
  });
});
```

## When to Use Effect-TS

| Use Case | Effect-TS | Plain TypeScript |
|----------|-----------|------------------|
| Complex error handling | Use Effect | try/catch is untyped |
| Dependency injection | Use Layers | Manual or framework |
| Retries with backoff | Use Schedule | Manual implementation |
| Resource cleanup | Use acquireRelease | try/finally |
| Concurrent operations | Use Fiber runtime | Promise.all |
| Type-safe services | Use Context.Tag | Interface + manual DI |
| Simple utility functions | Overkill | Use plain TS |

## Anti-Patterns (BANNED)

```typescript
// WRONG: Throwing for expected failures
const getUser = (id: string) => {
  const user = db.find(id);
  if (!user) throw new Error("Not found"); // NEVER
  return user;
};

// CORRECT: Typed failure
const getUser = (id: string): Effect.Effect<User, UserNotFoundError, Database> =>
  Effect.gen(function* () {
    const db = yield* Database;
    const user = yield* db.findById(id);
    if (!user) return yield* Effect.fail(new UserNotFoundError({ userId: id }));
    return user;
  });
```

```typescript
// WRONG: Untyped dependencies
const fetchData = async () => {
  const response = await httpClient.get("/api"); // Where does httpClient come from?
  return response.json();
};

// CORRECT: Dependencies in type signature
const fetchData = Effect.gen(function* () {
  const http = yield* HttpClient; // Tracked in R position
  const response = yield* http.get("/api");
  return yield* Effect.tryPromise(() => response.json());
});
// Type: Effect<Data, HttpError, HttpClient>
```

## Quick Reference

| Operation | Code |
|-----------|------|
| Create success | `Effect.succeed(value)` |
| Create failure | `Effect.fail(error)` |
| From promise | `Effect.tryPromise({ try, catch })` |
| Sync side effect | `Effect.sync(() => ...)` |
| Generator | `Effect.gen(function* () { ... })` |
| Provide service | `effect.pipe(Effect.provide(layer))` |
| Catch by tag | `Effect.catchTag("Tag", handler)` |
| Retry | `Effect.retry(schedule)` |
| Timeout | `Effect.timeout(duration)` |
| Run | `Effect.runPromise(effect)` |
