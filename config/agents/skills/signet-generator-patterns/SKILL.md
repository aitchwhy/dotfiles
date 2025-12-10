---
name: signet-generator-patterns
description: Signet generator patterns for architecture-aware code scaffolding. Extend Signet with new generators.
allowed-tools: Read, Write, Edit, Bash
---

## Philosophy: Architecture-Aware Generation

Signet is the code generator for the Maximum Rigor stack.
Unlike generic tools, Signet understands hexagonal architecture, Effect-TS layers, and the SSOT version registry.

```
signet init/gen
      |
  Template + Schema
      |
  Generated Code with:
  - Hexagonal structure
  - Effect-TS services
  - Zod validation
  - Pinned versions from SSOT
```

## Available Generators

| Command | What You Get |
|---------|--------------|
| `signet init monorepo <name>` | Workspace + shared packages |
| `signet gen api <name>` | Hexagonal Hono API |
| `signet gen ui <name>` | React 19 + XState frontend |
| `signet gen library <name>` | TypeScript package |
| `signet gen infra <name>` | Pulumi + process-compose |

## Core Commands

### Initialize Monorepo

```bash
signet init monorepo ember

# Creates:
# ember/
# ├── apps/
# ├── packages/
# │   └── domain/       # Shared types
# ├── package.json      # Workspace config
# ├── biome.json        # Linting
# └── tsconfig.json     # TypeScript config
```

### Generate API

```bash
signet gen api users

# Creates:
# apps/users/
# ├── src/
# │   ├── types/        # TypeScript types (SOURCE OF TRUTH)
# │   ├── schemas/      # Zod schemas (satisfies types)
# │   ├── domain/       # Domain errors
# │   ├── ports/        # Context.Tag interfaces
# │   ├── services/     # Effect.gen business logic
# │   ├── adapters/
# │   │   ├── inbound/  # Hono routes
# │   │   └── outbound/ # Database, external APIs
# │   └── index.ts      # Entry point
# ├── tests/
# └── package.json      # Pinned versions from SSOT
```

### Generate UI

```bash
signet gen ui dashboard

# Creates:
# apps/dashboard/
# ├── src/
# │   ├── routes/       # TanStack Router pages
# │   ├── components/   # React components
# │   ├── machines/     # XState state machines
# │   ├── api/          # API client (from OpenAPI)
# │   └── main.tsx
# ├── vite.config.ts
# └── package.json
```

### Generate Library

```bash
signet gen library auth

# Creates:
# packages/auth/
# ├── src/
# │   ├── types.ts      # TypeScript types
# │   ├── schemas.ts    # Zod schemas
# │   ├── index.ts      # Public API
# │   └── internal/     # Private implementation
# ├── tests/
# └── package.json
```

## SSOT Version Integration

Signet reads versions from `config/signet/src/stack/versions.ts`:

```typescript
// config/signet/src/stack/versions.ts
export const STACK = {
  npm: {
    typescript: '5.9.3',
    effect: '3.19.9',
    zod: '4.1.13',
    hono: '4.10.7',
    react: '19.2.1',
    // ... all versions
  },
} as const;
```

Generated `package.json` uses exact versions:

```json
{
  "dependencies": {
    "effect": "3.19.9",
    "zod": "4.1.13",
    "hono": "4.10.7"
  }
}
```

## Generated Hexagonal Structure

### Types Layer (Source of Truth)

```typescript
// src/types/user.ts
type UserId = string & { readonly __brand: 'UserId' };

type User = {
  readonly id: UserId;
  readonly email: string;
  readonly name: string;
  readonly createdAt: Date;
};

type CreateUserInput = {
  readonly email: string;
  readonly name: string;
};
```

### Schemas Layer (Validates Types)

```typescript
// src/schemas/user.ts
import { z } from 'zod';
import type { User, CreateUserInput, UserId } from '../types/user';

const userIdSchema = z.string().uuid()
  .transform((id) => id as UserId) satisfies z.ZodType<UserId, z.ZodTypeDef, string>;

const userSchema = z.object({
  id: userIdSchema,
  email: z.string().email(),
  name: z.string().min(1),
  createdAt: z.coerce.date(),
}) satisfies z.ZodType<User>;

const createUserInputSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
}) satisfies z.ZodType<CreateUserInput>;
```

### Ports Layer (Interfaces)

```typescript
// src/ports/user-repository.ts
import { Context, Effect } from 'effect';
import type { User, UserId, CreateUserInput } from '../types/user';
import type { UserNotFoundError, DatabaseError } from '../domain/errors';

export class UserRepository extends Context.Tag('UserRepository')<
  UserRepository,
  {
    readonly findById: (id: UserId) => Effect.Effect<User | null, DatabaseError>;
    readonly findByEmail: (email: string) => Effect.Effect<User | null, DatabaseError>;
    readonly create: (input: CreateUserInput) => Effect.Effect<User, DatabaseError>;
    readonly delete: (id: UserId) => Effect.Effect<void, DatabaseError>;
  }
>() {}
```

### Services Layer (Business Logic)

```typescript
// src/services/user.ts
import { Effect } from 'effect';
import { UserRepository } from '../ports/user-repository';
import { UserNotFoundError } from '../domain/errors';
import type { User, UserId, CreateUserInput } from '../types/user';

export const getUser = (id: UserId): Effect.Effect<User, UserNotFoundError, UserRepository> =>
  Effect.gen(function* () {
    const repo = yield* UserRepository;
    const user = yield* repo.findById(id);

    if (!user) {
      return yield* Effect.fail(new UserNotFoundError({ userId: id }));
    }

    return user;
  });

export const createUser = (input: CreateUserInput): Effect.Effect<User, never, UserRepository> =>
  Effect.gen(function* () {
    const repo = yield* UserRepository;
    return yield* repo.create(input);
  });
```

### Adapters Layer (Implementation)

```typescript
// src/adapters/outbound/turso-user-repository.ts
import { Layer, Effect } from 'effect';
import { UserRepository } from '../../ports/user-repository';
import type { LibsqlClient } from '@libsql/client';

export const TursoUserRepository = (client: LibsqlClient) =>
  Layer.succeed(UserRepository, {
    findById: (id) => Effect.tryPromise({
      try: () => client.execute({ sql: 'SELECT * FROM users WHERE id = ?', args: [id] }),
      catch: (e) => new DatabaseError({ cause: e }),
    }).pipe(Effect.map((r) => r.rows[0] as User | null)),

    // ... other methods
  });
```

## Extending Signet

### Add New Generator

```typescript
// config/signet/src/generators/workflow.ts
import { Effect } from 'effect';
import type { GeneratorConfig } from '../types';

export const workflowGenerator: GeneratorConfig = {
  name: 'workflow',
  description: 'Generate Temporal workflow',
  schema: z.object({
    name: z.string().min(1),
    activities: z.array(z.string()).default([]),
  }),

  async generate(config) {
    const files = [
      {
        path: `src/workflows/${config.name}.workflow.ts`,
        content: generateWorkflowFile(config),
      },
      {
        path: `src/workflows/${config.name}.activities.ts`,
        content: generateActivitiesFile(config),
      },
      {
        path: `tests/${config.name}.workflow.test.ts`,
        content: generateTestFile(config),
      },
    ];

    return files;
  },
};
```

### Register Generator

```typescript
// config/signet/src/generators/index.ts
import { apiGenerator } from './api';
import { uiGenerator } from './ui';
import { libraryGenerator } from './library';
import { workflowGenerator } from './workflow';

export const generators = {
  api: apiGenerator,
  ui: uiGenerator,
  library: libraryGenerator,
  workflow: workflowGenerator,
};
```

### Use Custom Generator

```bash
signet gen workflow payment

# Creates:
# src/workflows/payment.workflow.ts
# src/workflows/payment.activities.ts
# tests/payment.workflow.test.ts
```

## Validation Commands

```bash
# Check generated structure
signet validate

# Enforce architecture rules
signet enforce

# Full validation
bun validate  # typecheck + lint + test
```

## Architecture Rules Enforced

| Rule | What It Checks |
|------|----------------|
| No cross-layer imports | Services don't import adapters directly |
| Types are source of truth | No `z.infer<>` in codebase |
| Ports use Context.Tag | All dependencies via Effect services |
| Schemas satisfy types | All schemas have `satisfies z.ZodType<T>` |
| Versions from SSOT | package.json matches versions.ts |

## Quick Reference

| Command | Purpose |
|---------|---------|
| `signet init monorepo <name>` | New workspace |
| `signet gen api <name>` | Hexagonal API |
| `signet gen ui <name>` | React frontend |
| `signet gen library <name>` | Shared package |
| `signet gen infra <name>` | Infrastructure |
| `signet validate` | Check structure |
| `signet enforce` | Architecture rules |
| `just sig-doctor` | Version alignment |

## File Structure

```
config/signet/
├── src/
│   ├── stack/
│   │   ├── versions.ts     # SSOT for all versions
│   │   └── schema.ts       # Version schema
│   ├── generators/
│   │   ├── api.ts          # API generator
│   │   ├── ui.ts           # UI generator
│   │   ├── library.ts      # Library generator
│   │   └── index.ts        # Registry
│   ├── templates/
│   │   ├── api/            # API templates
│   │   ├── ui/             # UI templates
│   │   └── library/        # Library templates
│   └── cli.ts              # CLI entry point
└── package.json
```

## Anti-Patterns (BANNED)

```bash
# WRONG: Manual project setup
mkdir my-api
npm init -y
# Manually copy files...

# CORRECT: Use Signet
signet gen api my-api
```

```typescript
// WRONG: Import adapters in services
import { TursoClient } from '../adapters/outbound/turso';

// CORRECT: Import ports only
import { UserRepository } from '../ports/user-repository';
```

```json
// WRONG: Random versions
{
  "dependencies": {
    "effect": "^3.0.0"  // Not pinned!
  }
}

// CORRECT: Versions from SSOT
{
  "dependencies": {
    "effect": "3.19.9"  // Exact, from versions.ts
  }
}
```
