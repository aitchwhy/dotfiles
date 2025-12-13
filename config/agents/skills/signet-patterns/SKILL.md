---
name: signet-patterns
description: Patterns for using Signet to generate formally consistent software systems with hexagonal architecture.
allowed-tools: Read, Write, Edit, Bash
token-budget: 800
---

## Signet CLI

### Commands

| Command | Purpose |
|---------|---------|
| `signet init monorepo <name>` | New workspace |
| `signet gen api <name>` | Hexagonal Hono API |
| `signet gen ui <name>` | React 19 + XState frontend |
| `signet gen library <name>` | TypeScript package |
| `signet gen infra <name>` | Pulumi + process-compose |
| `signet validate` | Check structure |
| `signet enforce` | Architecture rules |
| `just sig-doctor` | Version alignment |

### Examples

```bash
# Initialize monorepo
signet init monorepo ember-platform
cd ember-platform

# Add services
signet gen api voice-service
signet gen ui web-app
signet gen library auth

# Validate
signet validate
signet enforce
bun validate
```

## SSOT Version Integration

All versions come from `config/signet/src/stack/versions.ts`:

```typescript
export const STACK = {
  npm: {
    typescript: '5.9.3',
    effect: '3.19.9',
    zod: '4.1.13',
    hono: '4.10.7',
    react: '19.2.1',
  },
} as const;
```

Generated `package.json` uses exact versions (no `^` or `~`).

Run `just sig-doctor` to check alignment.

## Hexagonal Architecture

### Directory Structure

```
src/
├── types/           # TypeScript types (SOURCE OF TRUTH)
├── schemas/         # Zod/Effect schemas (satisfies TS types)
├── domain/errors/   # Tagged errors (Data.TaggedError)
├── ports/           # Port interfaces (Context.Tag)
├── services/        # Effect.gen business logic
├── adapters/
│   ├── inbound/     # Hono routes, tRPC, pubsub
│   └── outbound/    # Turso, D1, external APIs
├── db/              # Drizzle schema + migrations
└── index.ts
```

### Layer Pattern

```typescript
// Port (Interface)
export class Database extends Context.Tag('Database')<Database, DatabaseService>() {}

// Adapter (Implementation)
export const TursoLive = (url: string, token: string) =>
  Layer.succeed(Database, makeService(createClient({ url, authToken: token })))

// Usage - inject at composition root
const program = myBusinessLogic.pipe(Effect.provide(TursoLive(url, token)))
```

### Types → Schemas Pattern

```typescript
// 1. TypeScript type is SOURCE OF TRUTH
type User = {
  readonly id: UserId;
  readonly email: string;
  readonly name: string;
};

// 2. Zod schema SATISFIES the type (NEVER use z.infer)
const userSchema = z.object({
  id: userIdSchema,
  email: z.string().email(),
  name: z.string().min(1),
}) satisfies z.ZodType<User>;
```

### Branded Types

```typescript
// TypeScript branded type
type UserId = string & { readonly __brand: 'UserId' };

// Schema with brand
const userIdSchema = z.string().uuid()
  .transform((id) => id as UserId) satisfies z.ZodType<UserId, z.ZodTypeDef, string>;
```

### Effect Schema (Alternative)

```typescript
import { Schema } from 'effect';

// TypeScript type
type Session = {
  readonly id: string;
  readonly userId: string;
  readonly expiresAt: Date;
};

// Effect Schema satisfies type
const sessionSchema = Schema.Struct({
  id: Schema.String,
  userId: Schema.String,
  expiresAt: Schema.Date,
}) satisfies Schema.Schema<Session>;
```

## Extending Signet

### Add New Generator

```typescript
// config/signet/src/generators/workflow.ts
export const workflowGenerator: GeneratorConfig = {
  name: 'workflow',
  description: 'Generate Temporal workflow',
  schema: z.object({
    name: z.string().min(1),
    activities: z.array(z.string()).default([]),
  }),

  async generate(config) {
    return [
      { path: `src/workflows/${config.name}.workflow.ts`, content: ... },
      { path: `src/workflows/${config.name}.activities.ts`, content: ... },
      { path: `tests/${config.name}.workflow.test.ts`, content: ... },
    ];
  },
};
```

### Register in `generators/index.ts`

```typescript
import { workflowGenerator } from './workflow';
export const generators = { ...existing, workflow: workflowGenerator };
```

### Use: `signet gen workflow payment`

## Architecture Rules Enforced

| Rule | What It Checks |
|------|----------------|
| No cross-layer imports | Services don't import adapters |
| Types are source of truth | No `z.infer<>` |
| Ports use Context.Tag | All deps via Effect services |
| Schemas satisfy types | All have `satisfies z.ZodType<T>` |
| Versions from SSOT | package.json matches versions.ts |

## Anti-Patterns (BANNED)

```bash
# Manual project setup
mkdir my-api && npm init -y  # WRONG
signet gen api my-api        # CORRECT
```

```typescript
// Import adapters in services
import { TursoClient } from '../adapters/outbound/turso';  // WRONG
import { UserRepository } from '../ports/user-repository'; // CORRECT
```

```json
// Random versions
{ "effect": "^3.0.0" }  // WRONG - not pinned
{ "effect": "3.19.9" }  // CORRECT - exact from SSOT
```
