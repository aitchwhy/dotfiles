---
name: typescript-patterns
description: Elite TypeScript patterns for December 2025. Parse don't validate. Make illegal states unrepresentable. Apply to ANY TypeScript project.
allowed-tools: Read, Write, Edit
---

## Branded Types for Type-Safe Identifiers

### Brand Infrastructure

Never use raw strings for identifiers. Compile-time safety for free:

```typescript
declare const __brand: unique symbol;
type Brand<T, B extends string> = T & { readonly [__brand]: B };

type UserId = Brand<string, 'UserId'>;
type OrderId = Brand<string, 'OrderId'>;

const UserId = (id: string): UserId => id as UserId;

function getUser(id: UserId): Promise<User> { ... }
getUser(orderId); // Type error! OrderId is not assignable to UserId
```

## Result Types for Fallible Operations

### Core Result Type

Never throw for expected failures. Make error handling explicit:

```typescript
type Result<T, E = Error> =
  | { readonly ok: true; readonly data: T }
  | { readonly ok: false; readonly error: E };

const Ok = <T>(data: T): Result<T, never> => ({ ok: true, data });
const Err = <E>(error: E): Result<never, E> => ({ ok: false, error });
```

> See `result-patterns` skill for comprehensive Result utilities including type guards and chaining.

## Discriminated Unions for State Machines

### Make Invalid States Unrepresentable

Each state has exactly the fields it needs:

```typescript
type Request =
  | { readonly status: 'idle' }
  | { readonly status: 'loading'; readonly startedAt: number }
  | { readonly status: 'success'; readonly data: ResponseData }
  | { readonly status: 'error'; readonly error: Error };
```

## Parse Don't Validate

### TypeScript Types as Source of Truth

Define the TypeScript type first. Schemas validate data matches that type.
See `zod-patterns` skill for full Zod examples.

```typescript
// 1. TypeScript type is source of truth
type User = {
  readonly id: string;
  readonly email: string;
  readonly role: 'admin' | 'user' | 'guest';
};

// 2. Schema satisfies the type (never use z.infer)
const userSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  role: z.enum(['admin', 'user', 'guest']),
}) satisfies z.ZodType<User>;
```

### Parse at Boundaries, Type Internally

Parse once at system boundary, fully typed internally:

```typescript
function processUser(data: unknown): Result<ProcessedUser, ValidationError> {
  const parsed = userSchema.safeParse(data);
  if (!parsed.success) {
    return Err({ code: 'VALIDATION_ERROR', issues: parsed.error.issues });
  }
  // parsed.data is fully typed as User
  return Ok(transformToProcessedUser(parsed.data));
}
```

## Const Assertions and Satisfies

### Literal Types and Type Checking

```typescript
const ROLES = ['admin', 'user', 'guest'] as const;
type Role = (typeof ROLES)[number];

const config = {
  apiUrl: 'https://api.example.com',
  timeout: 5000,
} satisfies Record<string, string | number>;
```
