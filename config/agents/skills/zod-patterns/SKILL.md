---
name: zod-patterns
description: TypeScript-first Zod patterns. TS types are source of truth. Never use z.infer. Use satisfies z.ZodType<T>.
allowed-tools: Read, Write, Edit
token-budget: 1500
---

## Philosophy: TypeScript Types as Source of Truth

Never derive types from schemas. TypeScript types define the contract,
Zod schemas validate that runtime data matches that contract.

### Why This Pattern?

1. **TypeScript controls the API contract** - Schema drift caught at compile time
2. **IDE-first experience** - Full autocomplete from TS type definition
3. **Explicit over implicit** - Types are readable, not buried in schema DSL
4. **Zod v4 compatible** - `z.ZodType<Output, Input>` simplified generics

## The Core Pattern

### Naming Convention

- TypeScript type: `Thing` (PascalCase)
- Zod schema: `thingSchema` (camelCase)

### Example

```typescript
import { z } from 'zod';

// 1. TypeScript type is source of truth
type User = {
  readonly id: string;
  readonly email: string;
  readonly name: string;
  readonly role: 'admin' | 'user' | 'guest';
  readonly createdAt: Date;
};

// 2. Zod schema satisfies the TS type
const userSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['admin', 'user', 'guest']),
  createdAt: z.coerce.date(),
}) satisfies z.ZodType<User>;

// 3. Partial types follow same pattern
type CreateUser = Omit<User, 'id' | 'createdAt'>;

const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['admin', 'user', 'guest']),
}) satisfies z.ZodType<CreateUser>;
```

## Branded Types (TS-First)

```typescript
// 1. Define brand infrastructure
declare const __brand: unique symbol;
type Brand<T, B extends string> = T & { readonly [__brand]: B };

// 2. TypeScript branded types
type UserId = Brand<string, 'UserId'>;
type OrderId = Brand<string, 'OrderId'>;

// 3. Constructor functions
const UserId = (id: string): UserId => id as UserId;
const OrderId = (id: string): OrderId => id as OrderId;

// 4. Zod schemas with brand transform
const userIdSchema = z.string().uuid()
  .transform((id) => id as UserId) satisfies z.ZodType<UserId, z.ZodTypeDef, string>;

const orderIdSchema = z.string().uuid()
  .transform((id) => id as OrderId) satisfies z.ZodType<OrderId, z.ZodTypeDef, string>;

// Type safety: can't mix IDs
function getUser(id: UserId): Promise<User> { /* ... */ }
getUser(orderId); // Type error! OrderId is not assignable to UserId
```

## Nested Types

```typescript
type Address = {
  readonly street: string;
  readonly city: string;
  readonly country: string;
  readonly postalCode: string;
};

type Customer = {
  readonly id: string;
  readonly name: string;
  readonly billingAddress: Address;
  readonly shippingAddress: Address | null;
};

const addressSchema = z.object({
  street: z.string(),
  city: z.string(),
  country: z.string(),
  postalCode: z.string(),
}) satisfies z.ZodType<Address>;

const customerSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  billingAddress: addressSchema,
  shippingAddress: addressSchema.nullable(),
}) satisfies z.ZodType<Customer>;
```

## With Transforms and Refinements

TS type represents the **parsed output**. Input transformations are internal:

```typescript
// Output type only - input shape is internal to schema
type Port = number;

const portSchema = z.coerce.number()
  .int()
  .min(1024)
  .max(65535) satisfies z.ZodType<Port>;

// For transforms with different input/output, specify both generics
type NormalizedEmail = string;

const emailSchema = z.string()
  .email()
  .transform((e) => e.toLowerCase().trim())
  satisfies z.ZodType<NormalizedEmail, z.ZodTypeDef, string>;
```

### Refinements

```typescript
type Password = string;

const passwordSchema = z.string()
  .min(8)
  .refine((pw) => /[A-Z]/.test(pw), 'Must contain uppercase')
  .refine((pw) => /[0-9]/.test(pw), 'Must contain number')
  .refine((pw) => /[^A-Za-z0-9]/.test(pw), 'Must contain special char')
  satisfies z.ZodType<Password>;

type DateRange = {
  readonly startDate: Date;
  readonly endDate: Date;
};

const dateRangeSchema = z.object({
  startDate: z.coerce.date(),
  endDate: z.coerce.date(),
}).refine(
  (d) => d.endDate > d.startDate,
  { message: 'End date must be after start date' }
) satisfies z.ZodType<DateRange>;
```

## Environment Variables

```typescript
type Env = {
  readonly NODE_ENV: 'development' | 'production' | 'test';
  readonly DATABASE_URL: string;
  readonly PORT: number;
  readonly API_KEY: string;
};

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']),
  DATABASE_URL: z.string().url(),
  PORT: z.coerce.number().int().positive().default(3000),
  API_KEY: z.string().min(32),
}) satisfies z.ZodType<Env>;

export const env = envSchema.parse(process.env);
```

## Result Type Integration

> See `result-patterns` skill for comprehensive Result utilities including type guards and chaining.

```typescript
type ValidationError = {
  readonly code: 'VALIDATION_ERROR';
  readonly issues: z.ZodIssue[];
};

type Result<T, E = Error> =
  | { readonly ok: true; readonly data: T }
  | { readonly ok: false; readonly error: E };

function parseWithResult<T>(
  schema: z.ZodType<T>,
  data: unknown
): Result<T, ValidationError> {
  const result = schema.safeParse(data);
  if (result.success) {
    return { ok: true, data: result.data };
  }
  return {
    ok: false,
    error: { code: 'VALIDATION_ERROR', issues: result.error.issues },
  };
}

// Usage
const result = parseWithResult(userSchema, unknownData);
if (result.ok) {
  console.log(result.data.email); // Fully typed
} else {
  console.error(result.error.issues);
}
```

## Discriminated Unions

```typescript
type ApiResponse =
  | { readonly status: 'success'; readonly data: User }
  | { readonly status: 'error'; readonly message: string; readonly code: number };

const apiResponseSchema = z.discriminatedUnion('status', [
  z.object({
    status: z.literal('success'),
    data: userSchema,
  }),
  z.object({
    status: z.literal('error'),
    message: z.string(),
    code: z.number().int(),
  }),
]) satisfies z.ZodType<ApiResponse>;
```

## Anti-Patterns (BANNED)

### NEVER use z.infer

```typescript
// WRONG - schema defines type
const userSchema = z.object({ ... });
type User = z.infer<typeof userSchema>;

// CORRECT - type defines contract
type User = { ... };
const userSchema = z.object({ ... }) satisfies z.ZodType<User>;
```

### NEVER omit satisfies clause

```typescript
// WRONG - no compile-time validation of schema
const userSchema = z.object({
  id: z.string(),
  // Typo: 'emial' instead of 'email' - won't be caught!
  emial: z.string().email(),
});

// CORRECT - satisfies catches the typo
const userSchema = z.object({
  id: z.string(),
  emial: z.string().email(), // Type error: 'emial' doesn't exist in User
}) satisfies z.ZodType<User>;
```

### NEVER let schema determine API shape

```typescript
// WRONG - API contract is implicit in schema
export const createUser = (data: z.infer<typeof createUserSchema>) => { ... };

// CORRECT - API contract is explicit in type
export const createUser = (data: CreateUser) => { ... };
```

---

## Zod v4 New Features (December 2025)

### Template Literal Types

```typescript
// CSS units - previously impossible
const CSSLength = z.templateLiteral([z.number(), z.literal('px')]);
// Type: `${number}px`

const CSSUnit = z.templateLiteral([
  z.number(),
  z.union([z.literal('px'), z.literal('em'), z.literal('rem'), z.literal('%')]),
]);
// Type: `${number}px` | `${number}em` | `${number}rem` | `${number}%`
```

### Built-in JSON Schema Conversion

```typescript
import * as z from "zod/v4";

const ApiResponseSchema = z.object({
  data: z.array(userSchema),
  pagination: z.object({
    page: z.number().int().min(1),
    pageSize: z.number().int().min(1).max(100),
    total: z.number().int().min(0),
  }),
});

// Direct conversion - no third-party library needed
const jsonSchema = ApiResponseSchema.toJSONSchema();
// Use for OpenAPI, form generation, etc.
```

### Zod Mini for Edge Functions

```typescript
import * as zm from "@zod/mini";

// ~1.9KB gzipped - perfect for edge/serverless
const LightweightSchema = zm.object({
  id: zm.pipe(zm.string(), zm.check(zm.uuid())),
  name: zm.pipe(zm.string(), zm.check(zm.minLength(1))),
});
```

### Global Schema Registry

```typescript
// Register schemas for large apps
z.globalRegistry.register("User", userSchema);
z.globalRegistry.register("ApiResponse", apiResponseSchema);

// Retrieve by name
const retrieved = z.globalRegistry.get("User");

// List all registered schemas
for (const [key, schema] of z.globalRegistry.entries()) {
  console.log(`${key}: ${schema.toJSONSchema()}`);
}
```

### Pretty Error Messages

```typescript
const result = userSchema.safeParse(invalidData);
if (!result.success) {
  // Built-in pretty printing
  const formatted = z.prettifyError(result.error);
  console.error(formatted);
  // Output:
  // ✖ Invalid email at "email"
  // ✖ Invalid enum value at "role". Expected 'admin' | 'user' | 'guest'
}
```

### File Validation

```typescript
const UploadSchema = z.file()
  .maxSize(5_000_000) // 5MB
  .mimeType(["image/png", "image/jpeg", "application/pdf"]);

// Use with FormData
const formData = await request.formData();
const file = formData.get("document");
const result = UploadSchema.safeParse(file);
```

### Performance (Zod v4 vs v3)

| Operation | Zod 3 | Zod 4 | Improvement |
|-----------|-------|-------|-------------|
| String parsing | 805 µs | 57 µs | **14x faster** |
| Array parsing | 1200 µs | 171 µs | **7x faster** |
| Object parsing | 805 µs | 124 µs | **6.5x faster** |
| Type instantiations | 25,000 | ~175 | **143x fewer** |
| Bundle size | 57KB | 24KB | **57% smaller** |

### Import Migration

```typescript
// v3 import
import { z } from "zod";

// v4 import (same API, just faster)
import * as z from "zod/v4";

// v4 mini (for edge)
import * as z from "@zod/mini";
```
