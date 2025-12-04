---
name: typescript-patterns
description: Elite TypeScript patterns for December 2025. Parse don't validate. Make illegal states unrepresentable. Apply to ANY TypeScript project.
allowed-tools: Read, Write, Edit
---

# TypeScript Patterns (December 2025)

## Branded Types for Type-Safe Identifiers

Never use raw strings for identifiers. Compile-time safety for free:

```typescript
// Brand infrastructure
declare const __brand: unique symbol;
type Brand<T, B extends string> = T & { readonly [__brand]: B };

// Domain types
type UserId = Brand<string, 'UserId'>;
type OrderId = Brand<string, 'OrderId'>;
type Email = Brand<string, 'Email'>;

// Smart constructors with validation
const UserId = (id: string): UserId => id as UserId;
const OrderId = (id: string): OrderId => id as OrderId;

// With runtime validation
const Email = (input: string): Result<Email, string> => {
  if (!input.includes('@') || !input.includes('.')) {
    return Err('Invalid email format');
  }
  return Ok(input as Email);
};

// Type safety in action
function getUser(id: UserId): Promise<User> { ... }
getUser(orderId); // Type error! OrderId is not assignable to UserId
```

## Result Types for Fallible Operations

Never throw for expected failures. Make error handling explicit:

```typescript
// Core Result type
type Result<T, E = Error> =
  | { readonly ok: true; readonly data: T }
  | { readonly ok: false; readonly error: E };

// Constructors
const Ok = <T>(data: T): Result<T, never> => ({ ok: true, data });
const Err = <E>(error: E): Result<never, E> => ({ ok: false, error });

// Type guards
const isOk = <T, E>(r: Result<T, E>): r is { ok: true; data: T } => r.ok;
const isErr = <T, E>(r: Result<T, E>): r is { ok: false; error: E } => !r.ok;

// Utility functions
function map<T, U, E>(result: Result<T, E>, fn: (t: T) => U): Result<U, E> {
  return result.ok ? Ok(fn(result.data)) : result;
}

function flatMap<T, U, E>(result: Result<T, E>, fn: (t: T) => Result<U, E>): Result<U, E> {
  return result.ok ? fn(result.data) : result;
}

function unwrapOr<T, E>(result: Result<T, E>, defaultValue: T): T {
  return result.ok ? result.data : defaultValue;
}

// Async wrapper
async function tryCatch<T>(fn: () => Promise<T>): Promise<Result<T, Error>> {
  try {
    return Ok(await fn());
  } catch (e) {
    return Err(e instanceof Error ? e : new Error(String(e)));
  }
}
```

## Discriminated Unions for State Machines

Make invalid states unrepresentable at the type level:

```typescript
// Bad: allows invalid combinations
type BadRequest = {
  status: 'idle' | 'loading' | 'success' | 'error';
  data?: ResponseData;
  error?: Error;
};

// Good: each state has exactly the fields it needs
type Request =
  | { readonly status: 'idle' }
  | { readonly status: 'loading'; readonly startedAt: number }
  | { readonly status: 'success'; readonly data: ResponseData }
  | { readonly status: 'error'; readonly error: Error; readonly retriesLeft: number };

// Exhaustive switch
function render(request: Request): JSX.Element {
  switch (request.status) {
    case 'idle':
      return <IdleState />;
    case 'loading':
      return <LoadingSpinner startedAt={request.startedAt} />;
    case 'success':
      return <DataView data={request.data} />;
    case 'error':
      return <ErrorView error={request.error} retriesLeft={request.retriesLeft} />;
    // No default needed - TypeScript ensures exhaustiveness
  }
}
```

## Parse Don't Validate

Validate at boundaries, trust internally:

```typescript
// Bad: validates repeatedly, still has unknown type
function processUserBad(data: unknown) {
  if (!isValidUser(data)) throw new Error('Invalid');
  // data is still unknown here - defensive checks everywhere
}

// Good: parse once at boundary, fully typed internally
function processUser(data: unknown): Result<ProcessedUser, ValidationError> {
  const parsed = UserSchema.safeParse(data);
  if (!parsed.success) {
    return Err({ code: 'VALIDATION_ERROR', issues: parsed.error.issues });
  }
  // parsed.data is fully typed User - no more checks needed
  return Ok(transformToProcessedUser(parsed.data));
}
```

## Const Assertions and Satisfies

```typescript
// Const assertion for literal types
const ROLES = ['admin', 'user', 'guest'] as const;
type Role = (typeof ROLES)[number]; // 'admin' | 'user' | 'guest'

// Satisfies for type checking without widening
const config = {
  apiUrl: 'https://api.example.com',
  timeout: 5000,
  retries: 3,
} satisfies Record<string, string | number>;
// config.apiUrl is string (not string | number)

// Object freeze with const
const ENDPOINTS = Object.freeze({
  users: '/api/users',
  orders: '/api/orders',
} as const);
```

## Strict Function Types

```typescript
// Require explicit return types for public functions
export function calculateTotal(items: OrderItem[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

// Use readonly for immutable parameters
function processItems(items: readonly Item[]): ProcessedItem[] {
  // items.push(x); // Error: cannot modify readonly array
  return items.map(transform);
}

// Explicit generic constraints
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}
```

## Utility Types

```typescript
// DeepReadonly for immutable nested objects
type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object ? DeepReadonly<T[P]> : T[P];
};

// NonNullable fields
type RequiredFields<T, K extends keyof T> = T & { [P in K]-?: NonNullable<T[P]> };

// Pick with required
type PickRequired<T, K extends keyof T> = Required<Pick<T, K>>;
```
