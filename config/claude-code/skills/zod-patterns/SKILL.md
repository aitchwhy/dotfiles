---
name: zod-patterns
description: Schema-first development with Zod v4. Schema is source of truth. Types are derived. Apply to any TypeScript project.
allowed-tools: Read, Write, Edit
---

# Zod v4 Patterns (December 2025)

## Schema First, Type Second

The schema is the source of truth. Types are always derived:

```typescript
import { z } from 'zod';

// Schema first
export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['admin', 'user', 'guest']),
  createdAt: z.coerce.date(),
});

// Type derived from schema
export type User = z.infer<typeof UserSchema>;

// Input type for creation (without generated fields)
export const CreateUserSchema = UserSchema.omit({ id: true, createdAt: true });
export type CreateUser = z.infer<typeof CreateUserSchema>;

// Partial type for updates
export const UpdateUserSchema = CreateUserSchema.partial();
export type UpdateUser = z.infer<typeof UpdateUserSchema>;
```

## Branded Types with Zod

Combine Zod validation with branded types:

```typescript
import { z } from 'zod';

// Branded type infrastructure
declare const __brand: unique symbol;
type Brand<T, B extends string> = T & { readonly [__brand]: B };

// Branded ID schema
const brandedId = <B extends string>(brand: B) =>
  z.string().uuid().transform((id) => id as Brand<string, B>);

// Usage
export const UserIdSchema = brandedId('UserId');
export type UserId = z.infer<typeof UserIdSchema>;

export const OrderIdSchema = brandedId('OrderId');
export type OrderId = z.infer<typeof OrderIdSchema>;

// In parent schemas
export const OrderSchema = z.object({
  id: OrderIdSchema,
  userId: UserIdSchema,
  total: z.number().positive(),
});
```

## Result Type Integration

Wrap Zod parsing in Result types:

```typescript
import { z } from 'zod';

type Result<T, E = Error> =
  | { ok: true; data: T }
  | { ok: false; error: E };

type ValidationError = {
  code: 'VALIDATION_ERROR';
  issues: z.ZodIssue[];
  formatted: string;
};

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
    error: {
      code: 'VALIDATION_ERROR',
      issues: result.error.issues,
      formatted: result.error.message,
    },
  };
}

// Usage
const result = parseWithResult(UserSchema, requestBody);
if (!result.ok) {
  return json({ error: result.error.formatted }, 400);
}
const user = result.data; // Fully typed User
```

## API Request/Response Schemas

```typescript
// Request schemas
export const CreateOrderRequestSchema = z.object({
  userId: UserIdSchema,
  items: z.array(OrderItemSchema).min(1),
  shippingAddress: AddressSchema,
});

// Response schemas with discriminated unions
export const ApiResponseSchema = <T extends z.ZodType>(dataSchema: T) =>
  z.discriminatedUnion('success', [
    z.object({
      success: z.literal(true),
      data: dataSchema,
    }),
    z.object({
      success: z.literal(false),
      error: z.object({
        code: z.string(),
        message: z.string(),
        details: z.unknown().optional(),
      }),
    }),
  ]);

// Paginated response
export const PaginatedSchema = <T extends z.ZodType>(itemSchema: T) =>
  z.object({
    items: z.array(itemSchema),
    pagination: z.object({
      total: z.number().int().nonnegative(),
      page: z.number().int().positive(),
      pageSize: z.number().int().positive(),
      hasMore: z.boolean(),
    }),
  });
```

## Transforms and Refinements

```typescript
// Coercion for form inputs
export const FormSchema = z.object({
  age: z.coerce.number().int().min(0).max(150),
  birthDate: z.coerce.date(),
  acceptedTerms: z.coerce.boolean(),
});

// Custom refinements
export const PasswordSchema = z
  .string()
  .min(8)
  .refine((pw) => /[A-Z]/.test(pw), 'Must contain uppercase')
  .refine((pw) => /[a-z]/.test(pw), 'Must contain lowercase')
  .refine((pw) => /[0-9]/.test(pw), 'Must contain number')
  .refine((pw) => /[^A-Za-z0-9]/.test(pw), 'Must contain special character');

// Cross-field validation
export const DateRangeSchema = z
  .object({
    startDate: z.coerce.date(),
    endDate: z.coerce.date(),
  })
  .refine((data) => data.endDate > data.startDate, {
    message: 'End date must be after start date',
    path: ['endDate'],
  });
```

## Environment Variables

```typescript
// Type-safe env vars
export const EnvSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']),
  DATABASE_URL: z.string().url(),
  API_KEY: z.string().min(32),
  PORT: z.coerce.number().int().positive().default(3000),
  DEBUG: z.coerce.boolean().default(false),
});

// Parse at startup
export const env = EnvSchema.parse(process.env);
```

## Error Formatting

```typescript
import { z } from 'zod';

// Custom error map
const customErrorMap: z.ZodErrorMap = (issue, ctx) => {
  switch (issue.code) {
    case z.ZodIssueCode.invalid_type:
      return { message: `Expected ${issue.expected}, got ${issue.received}` };
    case z.ZodIssueCode.too_small:
      return { message: `Must be at least ${issue.minimum}` };
    case z.ZodIssueCode.too_big:
      return { message: `Must be at most ${issue.maximum}` };
    default:
      return { message: ctx.defaultError };
  }
};

z.setErrorMap(customErrorMap);

// Flatten errors for API responses
function formatZodErrors(error: z.ZodError): Record<string, string[]> {
  return error.flatten().fieldErrors as Record<string, string[]>;
}
```
