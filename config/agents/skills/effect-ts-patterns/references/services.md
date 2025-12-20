# Effect-TS Service Patterns

## Context.Tag Pattern

```typescript
import { Context, Effect, Layer } from "effect";

// 1. Define the service interface as a class extending Context.Tag
class UserRepository extends Context.Tag("UserRepository")<
  UserRepository,
  {
    readonly findById: (id: string) => Effect.Effect<User, UserNotFoundError>;
    readonly save: (user: User) => Effect.Effect<void, DatabaseError>;
    readonly delete: (id: string) => Effect.Effect<void, DatabaseError>;
  }
>() {}

// 2. Use the service in effects - automatically tracked in R position
const getUser = (id: string) => Effect.gen(function* () {
  const repo = yield* UserRepository;
  return yield* repo.findById(id);
});
// Type: Effect<User, UserNotFoundError, UserRepository>
```

## Layer Construction

```typescript
// Layer.succeed - For services with no dependencies
const UserRepositoryLive = Layer.succeed(UserRepository, {
  findById: (id) => Effect.gen(function* () {
    const db = yield* DatabaseClient;
    const row = yield* db.query(`SELECT * FROM users WHERE id = $1`, [id]);
    if (!row) return yield* Effect.fail(new UserNotFoundError({ id }));
    return parseUser(row);
  }),
  save: (user) => Effect.gen(function* () {
    const db = yield* DatabaseClient;
    yield* db.execute(`INSERT INTO users ...`, [user.id, user.name]);
  }),
  delete: (id) => Effect.gen(function* () {
    const db = yield* DatabaseClient;
    yield* db.execute(`DELETE FROM users WHERE id = $1`, [id]);
  }),
});

// Layer.effect - For services that need initialization
const DatabaseClientLive = Layer.effect(
  DatabaseClient,
  Effect.gen(function* () {
    const config = yield* ConfigService;
    const pool = yield* Effect.tryPromise({
      try: () => createPool(config.dbUrl),
      catch: (e) => new DatabaseConnectionError({ cause: e }),
    });
    return { query: ..., execute: ... };
  })
);

// Layer.scoped - For services needing cleanup (resource management)
const ConnectionPoolLive = Layer.scoped(
  ConnectionPool,
  Effect.acquireRelease(
    Effect.tryPromise({
      try: () => createPool(),
      catch: (e) => new PoolError({ cause: e }),
    }),
    (pool) => Effect.promise(() => pool.close())
  )
);
```

## Layer Composition

```typescript
// Horizontal: merge independent layers
const InfraLayer = Layer.merge(LoggerLive, MetricsLive);

// Vertical: provide dependencies
const AppLayer = UserRepositoryLive.pipe(
  Layer.provide(DatabaseClientLive),
  Layer.provide(ConfigServiceLive)
);

// Full application layer
const MainLayer = Layer.mergeAll(
  UserRepositoryLive,
  AuthServiceLive,
  LoggerLive
).pipe(
  Layer.provide(DatabaseClientLive),
  Layer.provide(ConfigServiceLive)
);

// Provide to program
const runnable = program.pipe(Effect.provide(MainLayer));
// Type: Effect<Result, AppError, never>  ← R is never (all requirements satisfied)
```

## Service Dependencies

```typescript
// Service that depends on other services
class AuthService extends Context.Tag("AuthService")<
  AuthService,
  {
    readonly authenticate: (token: string) => Effect.Effect<User, AuthError>;
  }
>() {}

// Implementation depends on UserRepository and TokenValidator
const AuthServiceLive = Layer.effect(
  AuthService,
  Effect.gen(function* () {
    const userRepo = yield* UserRepository;
    const tokenValidator = yield* TokenValidator;

    return {
      authenticate: (token) => Effect.gen(function* () {
        const claims = yield* tokenValidator.validate(token);
        return yield* userRepo.findById(claims.userId);
      }),
    };
  })
);

// Layer declares its dependencies via Layer.provide
const AuthWithDeps = AuthServiceLive.pipe(
  Layer.provide(UserRepositoryLive),
  Layer.provide(TokenValidatorLive)
);
```

## Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Service class | PascalCase, noun | `UserRepository` |
| Tag identifier | Same as class | `"UserRepository"` |
| Live layer | `{Service}Live` | `UserRepositoryLive` |
| Test layer | `{Service}Test` | `UserRepositoryTest` |
| Effect functions | camelCase, verb | `findById`, `authenticate` |
