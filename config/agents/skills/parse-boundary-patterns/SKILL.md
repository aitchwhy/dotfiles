---
name: parse-boundary-patterns
description: "Parse don't validate" enforcement. Parse ONCE at boundaries, typed internally. No optional chaining or null checks in domain code.
allowed-tools: Read, Write, Edit
token-budget: 2500
version: 1.0.0
---

# Parse-at-Boundary Patterns

> "Parse, don't validate" — Alexis King

## Philosophy

**Parsing** transforms untrusted data into trusted, typed data ONCE at the boundary.
**Validation** checks data repeatedly throughout code, indicating unparsed data.

If you see `?.`, `??`, or `if (x === null)` in non-boundary code, the architecture is wrong.

## The Pattern

```
External Data (untrusted)
    |
    v Schema.decodeUnknownSync (PARSE HERE)
    |
Internal Data (trusted, fully typed)
    |
    v No null checks, no optional chaining
    |
Domain Logic
```

## Boundaries (Where Parsing Happens)

| Boundary | Parse With |
|----------|-----------|
| HTTP request body | `Schema.decodeUnknownSync(RequestSchema)` |
| HTTP response | `Schema.decodeUnknownSync(ResponseSchema)` |
| Environment variables | `Schema.decodeUnknownSync(EnvSchema)` |
| User input (forms) | `Schema.decodeUnknownSync(InputSchema)` |
| Database results | `Schema.decodeUnknownSync(RowSchema)` |
| External API responses | `Schema.decodeUnknownSync(ApiSchema)` |
| XState event payloads | `Schema.decodeUnknownSync(EventSchema)` |
| localStorage/sessionStorage | `Schema.decodeUnknownSync(StoredSchema)` |

## Effect Schema Parsing

### Basic Boundary Parse

```typescript
import { Schema } from "effect"

// Define schema with all validations
const UserInput = Schema.Struct({
  email: Schema.String.pipe(Schema.pattern(/@/)),
  age: Schema.Number.pipe(Schema.greaterThan(0)),
  role: Schema.Literal("admin", "user"),
})

type UserInput = typeof UserInput.Type

// Parse at boundary - throws on invalid
const parseUserInput = Schema.decodeUnknownSync(UserInput)

// Usage at boundary
function handleRequest(rawBody: unknown): UserInput {
  return parseUserInput(rawBody)  // Parse ONCE
}

// After parsing - NO null checks needed
function processUser(user: UserInput) {
  user.email   // string, not string | undefined
  user.age     // number, not number | undefined
  user.role    // "admin" | "user", not string
}
```

### With Defaults (Still at Boundary)

```typescript
const Config = Schema.Struct({
  port: Schema.optional(Schema.Number, { default: () => 3000 }),
  host: Schema.optional(Schema.String, { default: () => "localhost" }),
  debug: Schema.optional(Schema.Boolean, { default: () => false }),
})

type Config = typeof Config.Type
// { port: number; host: string; debug: boolean }
// All required after parsing - defaults applied AT PARSE TIME

const parseConfig = Schema.decodeUnknownSync(Config)
const config = parseConfig({})  // { port: 3000, host: "localhost", debug: false }
// No optionality after parsing
```

### Transform at Boundary

```typescript
// External API returns snake_case
const ExternalUser = Schema.Struct({
  user_id: Schema.String,
  email_address: Schema.String,
})

// Internal uses camelCase
const InternalUser = Schema.Struct({
  userId: Schema.String,
  email: Schema.String,
})

// Transform at parse time
const UserFromExternal = Schema.transform(
  ExternalUser,
  InternalUser,
  {
    strict: true,
    decode: ({ user_id, email_address }) => ({
      userId: user_id,
      email: email_address,
    }),
    encode: ({ userId, email }) => ({
      user_id: userId,
      email_address: email,
    }),
  }
)

// Parse + transform in one step
const parseExternalUser = Schema.decodeUnknownSync(UserFromExternal)
```

## XState: Discriminated Union Context

Each state should have EXACTLY the data it needs - no nullable fields checked later.

### WRONG: Nullable Fields Checked Everywhere

```typescript
// ANTI-PATTERN - blocked by Guard 32-36
type Context = {
  phone: string | null
  code: string | null
  user: User | null
}

// Then in every state:
if (context.phone === null) throw new Error("...")
if (context.code === null) throw new Error("...")
```

### CORRECT: Discriminated Union by Phase

```typescript
// Each state has exactly what it needs
type Context =
  | { phase: "idle" }
  | { phase: "enteringPhone" }
  | { phase: "sendingOtp"; phone: string }
  | { phase: "awaitingOtp"; phone: string }
  | { phase: "verifying"; phone: string; code: string }
  | { phase: "authenticated"; user: User }

// In verifying state, phone AND code are guaranteed
input: ({ context }) => {
  if (context.phase !== "verifying") throw new Error("Invalid state")
  // TypeScript now knows: context.phone: string, context.code: string
  return { phone: context.phone, code: context.code }
}
```

### State Transitions Parse at Boundary

```typescript
on: {
  SUBMIT_PHONE: {
    target: "sendingOtp",
    actions: assign(({ event }) => {
      // PARSE at event boundary
      const { phone } = Schema.decodeUnknownSync(PhoneInput)(event)
      return { phase: "sendingOtp" as const, phone }
    }),
  },
}
```

## Where Optional Chaining IS Allowed

Only at actual boundaries with external data:

```typescript
// ALLOWED: Parsing external API response
const user = response?.data?.user  // External data, unparsed
const parsed = parseUser(user)     // Parse immediately
// After this: NO more optional chaining on parsed

// ALLOWED: Error message construction
const message = error?.message ?? "Unknown error"

// ALLOWED: Optional UI display (JSX)
{user?.name && <span>{user.name}</span>}
```

## Where Optional Chaining is BANNED

```typescript
// BANNED (Guard 32): After parsing, data should be typed
const phone = context.phone?.trim()  // Why is phone optional here?

// BANNED (Guard 32): In domain logic
function processOrder(order: Order) {
  const total = order.items?.reduce(...)  // items should be required
}

// BANNED (Guard 36): In state machine actors
async ({ input }) => {
  const result = await api.call(input.userId!)  // Why the assertion?
}
```

## Code Smell Detection

| Smell | Indicates | Fix |
|-------|-----------|-----|
| `x?.y?.z` chains | Unparsed nested data | Parse at boundary with nested schema |
| `x ?? defaultValue` | Nullable that should be required | Schema with default, or discriminated union |
| `if (x === null) throw` | Validation, not parsing | Move check to parse-time schema |
| `x!` after null check | Type system not trusted | Let types flow from parsing |
| `as SomeType` | Unparsed data forced to type | Parse instead of assert |

## Quick Reference

```typescript
// At boundary: PARSE
const data = Schema.decodeUnknownSync(MySchema)(untrusted)

// After boundary: TYPED (no checks needed)
processData(data.field)  // field is guaranteed to exist and be correct type

// State machines: DISCRIMINATED UNION
type Ctx =
  | { phase: "a" }
  | { phase: "b"; requiredField: string }

// Type narrowing via phase check
if (ctx.phase === "b") {
  ctx.requiredField  // TypeScript knows this exists
}
```

## PARAGON Guards (Blocking)

| Guard | Pattern | Blocks |
|-------|---------|--------|
| 32 | Optional chaining in non-boundary | `x?.y` in domain code |
| 33 | Nullish coalescing in non-boundary | `x ?? y` in domain code |
| 34 | Null check then access | `if (x === null) ... x!` |
| 35 | Type assertions | `x as Type` without parsing (warning) |
| 36 | Non-null assertion | `x!` without type narrowing |

## Boundary Files (Guards Skip These)

| Pattern | Description |
|---------|-------------|
| `*/api/*.ts` | API route handlers |
| `*/lib/*-client.ts` | API clients |
| `*.schema.ts` | Schema definitions |
| `*/schemas/*` | Schema directories |
| `*/parsers/*` | Parser directories |
| `*.test.ts`, `*.spec.ts` | Test files |

## See Also

- `typescript-patterns` - Result types, branded types
- `effect-ts-patterns` - Effect Schema, typed errors
- `zod-patterns` - TypeScript-first Zod (use Effect Schema for new code)
- `state-machine-patterns` - XState discriminated unions
