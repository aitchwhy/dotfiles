---
name: type-safety
description: Branded types, Effect Schema, type-first development
allowed-tools: Read, Write, Edit, Grep
token-budget: 400
---

# type-safety

## Branded Types

Prevent mixing incompatible values at compile time:

```typescript
import { Brand } from "effect";

type UserId = string & Brand.Brand<"UserId">;
type OrderId = string & Brand.Brand<"OrderId">;

const UserId = Brand.nominal<UserId>();
const OrderId = Brand.nominal<OrderId>();

const userId = UserId("user-123");
const orderId = OrderId("order-456");

// Compile error: Type 'OrderId' is not assignable to type 'UserId'
getUser(orderId);
```

## TypeScript Types as SSOT

Define types FIRST, then create schemas that satisfy them:

```typescript
import { Schema } from "effect";

// 1. Type is source of truth
type User = {
  readonly id: UserId;
  readonly name: string;
  readonly email: string;
};

// 2. Schema satisfies the type
const UserSchema = Schema.Struct({
  id: Schema.String.pipe(Schema.brand("UserId")),
  name: Schema.String,
  email: Schema.String.pipe(Schema.pattern(/@/)),
}) satisfies Schema.Schema<User, unknown>;
```

NEVER use `typeof Schema.Type` - that inverts the relationship.

## Parse at Boundaries

```typescript
// API boundary - parse incoming data
const handler = Effect.gen(function* () {
  const raw = yield* readRequestBody();
  const user = yield* Schema.decodeUnknown(UserSchema)(raw);
  // user is now fully typed
  return yield* saveUser(user);
});
```

Internal code trusts the types - no runtime checks needed.

## Anti-Patterns

- **any** → Use unknown + type guards
- **z.infer<typeof Schema>** → TypeScript type is SSOT
- **Plain string IDs** → Use branded types
- **Runtime checks everywhere** → Parse at boundary only
