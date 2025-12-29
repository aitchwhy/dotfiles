---
name: parse-boundary
description: Parse external data at boundaries, trust internal types
allowed-tools: Read, Write, Edit, Grep
token-budget: 300
---

# parse-boundary

## The Principle

**Parse, don't validate.**

External data (API requests, file reads, env vars) is `unknown`.
Parse it ONCE at the boundary into typed data.
Internal code trusts the types completely.

## Boundary Examples

```typescript
// HTTP request boundary
const handleRequest = (req: Request) =>
  Effect.gen(function* () {
    const body = yield* Effect.tryPromise(() => req.json());
    const data = yield* Schema.decodeUnknown(CreateUserSchema)(body);
    return yield* createUser(data); // data is typed
  });

// Environment boundary
const Config = Effect.gen(function* () {
  const raw = { apiKey: process.env.API_KEY, port: process.env.PORT };
  return yield* Schema.decodeUnknown(ConfigSchema)(raw);
});

// File read boundary
const loadConfig = (path: string) =>
  Effect.gen(function* () {
    const content = yield* readFile(path);
    const json = yield* Effect.try(() => JSON.parse(content));
    return yield* Schema.decodeUnknown(ConfigSchema)(json);
  });
```

## Internal Code

```typescript
// Internal function - trusts types, no parsing
const createUser = (data: CreateUserData) =>
  Effect.gen(function* () {
    const repo = yield* UserRepository;
    const id = yield* generateId();
    return yield* repo.save({ ...data, id });
  });
```

No Schema.decode inside business logic - types are trusted.
