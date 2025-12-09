---
name: signet-patterns
description: Patterns for using Signet to generate formally consistent software systems with hexagonal architecture.
allowed-tools: Read, Write, Edit, Bash
---

## When to Use This Skill

- Creating new projects with `signet init`
- Adding workspaces to existing monorepos with `signet gen`
- Understanding hexagonal architecture patterns
- Working with Effect-TS layers and ports/adapters

## Hexagonal Architecture (Ports and Adapters)

### Directory Structure

```
src/
├── types/           # TypeScript types (SOURCE OF TRUTH)
│   ├── user.ts      # User, UserId, CreateUserInput
│   ├── order.ts     # Order domain types
│   └── events.ts    # Event types
├── schemas/         # Zod/Effect schemas (satisfies TS types)
│   ├── user.ts      # userSchema, createUserInputSchema
│   └── events.ts    # Event validation schemas
├── domain/          # Domain layer
│   └── errors/      # Tagged errors (Data.TaggedError)
├── ports/           # Port interfaces (Context.Tag)
│   └── database.ts  # Context.Tag<Database, DatabaseService>
├── services/        # Use cases / application services
│   └── user.ts      # Effect.gen functions composing ports
├── adapters/        # Adapter implementations (Layers)
│   ├── inbound/
│   │   ├── http/    # Hono routes
│   │   ├── trpc/    # tRPC procedures
│   │   └── pubsub/  # Event handlers
│   └── outbound/
│       ├── turso.ts # Layer.succeed(Database, TursoService)
│       └── d1.ts    # Layer.succeed(Database, D1Service)
├── db/              # Database schema and migrations
│   ├── schema.ts    # Drizzle schema
│   └── migrations/  # Migration files
├── lib/             # Infrastructure utilities
└── index.ts         # Application entry point
```

## Effect Layer Pattern

### Port and Adapter

```typescript
// Port (Interface)
export class Database extends Context.Tag('Database')<
  Database,
  DatabaseService
>() {}

// Adapter (Implementation)
const makeService = (client: LibsqlClient): DatabaseService => ({
  query: (sql) => Effect.tryPromise(() => client.execute(sql)),
})

export const TursoLive = (url: string, token: string) =>
  Layer.succeed(Database, makeService(createClient({ url, authToken: token })))

// Usage - inject adapter at composition root
const program = myBusinessLogic.pipe(
  Effect.provide(TursoLive(process.env.DATABASE_URL, process.env.DATABASE_TOKEN))
)
```

## TypeScript-First Effect Schema

Same philosophy as `zod-patterns`: TypeScript types are source of truth.
Effect Schema validates runtime data matches the type contract.

### Naming Convention

- TypeScript type: `Thing` (PascalCase)
- Effect Schema: `thingSchema` (camelCase)

### Core Pattern

```typescript
import { Schema } from 'effect';

// 1. TypeScript type is source of truth
type Session = {
  readonly id: string;
  readonly userId: string;
  readonly expiresAt: Date;
  readonly createdAt: Date;
};

// 2. Effect Schema satisfies the TS type
const sessionSchema = Schema.Struct({
  id: Schema.String,
  userId: Schema.String,
  expiresAt: Schema.Date,
  createdAt: Schema.Date,
}) satisfies Schema.Schema<Session>;

// BANNED - never derive types from schemas
type Session = Schema.Schema.Type<typeof sessionSchema>; // NEVER DO THIS
```

### Branded Types (TS-First)

```typescript
import { Schema } from 'effect';

// 1. TypeScript branded type
declare const __brand: unique symbol;
type Brand<T, B extends string> = T & { readonly [__brand]: B };
type ProjectName = Brand<string, 'ProjectName'>;

// 2. Constructor function
const ProjectName = (name: string): ProjectName => name as ProjectName;

// 3. Effect Schema with brand
const projectNameSchema = Schema.String.pipe(
  Schema.pattern(/^[a-z][a-z0-9-]*$/),
  Schema.transform(
    Schema.String as Schema.Schema<ProjectName>,
    { decode: (s) => s as ProjectName, encode: (s) => s }
  )
);
```

### Port Data Contracts

```typescript
import { Schema, Context, Effect, Layer } from 'effect';

// 1. TypeScript types for data contracts
type User = {
  readonly id: string;
  readonly email: string;
  readonly name: string | undefined;
  readonly emailVerified: boolean;
  readonly createdAt: Date;
  readonly updatedAt: Date;
};

type AuthErrorCode =
  | 'INVALID_CREDENTIALS'
  | 'SESSION_EXPIRED'
  | 'SESSION_NOT_FOUND'
  | 'USER_NOT_FOUND'
  | 'RATE_LIMITED'
  | 'INTERNAL_ERROR';

// 2. Effect Schemas satisfy the types
const userSchema = Schema.Struct({
  id: Schema.String,
  email: Schema.String,
  name: Schema.optional(Schema.String),
  emailVerified: Schema.Boolean,
  createdAt: Schema.Date,
  updatedAt: Schema.Date,
}) satisfies Schema.Schema<User>;

// 3. Tagged Error with TS-first pattern
type AuthError = {
  readonly _tag: 'AuthError';
  readonly code: AuthErrorCode;
  readonly message: string;
};

class AuthError extends Schema.TaggedError<AuthError>()('AuthError', {
  code: Schema.Literal(
    'INVALID_CREDENTIALS',
    'SESSION_EXPIRED',
    'SESSION_NOT_FOUND',
    'USER_NOT_FOUND',
    'RATE_LIMITED',
    'INTERNAL_ERROR',
  ),
  message: Schema.String,
}) {}
```

### Decode/Encode Helpers

```typescript
// Parse unknown data with Result-like API
const decodeUser = Schema.decodeUnknown(userSchema);
const encodeUser = Schema.encode(userSchema);
const isUser = Schema.is(userSchema);

// Usage in Effect pipeline
const program = Effect.gen(function* () {
  const rawData = yield* fetchUserData();
  const user = yield* decodeUser(rawData);
  return user; // Fully typed as User
});
```

## Generator Selection

| Need | Command | What You Get |
|------|---------|--------------|
| New platform | `signet init monorepo <name>` | Workspace + shared pkg |
| Backend API | `signet gen api <name>` | Hexagonal Hono |
| Frontend | `signet gen ui <name>` | React 19 + XState |
| Library | `signet gen library <name>` | TypeScript package |
| Deployment | `signet gen infra <name>` | Pulumi + process-compose |

> **Version Matrix**: See `lib/versions.nix` for exact pinned versions (Bun, TypeScript, Effect, React, Hono, etc.)

## Anti-Patterns to Avoid

1. **App importing adapters directly** - Use ports
2. **Circular dependencies** - Extract shared code
3. **Mixed layer imports** - Follow layer ordering
4. **Skipping process-compose** - Always include for observability
5. **Manual project setup** - Use Signet generators

## Validation

### Always Validate

```bash
signet validate     # Check structure
signet enforce      # Check architecture
bun validate        # Typecheck + lint + test
```
