---
name: api-contract
description: EmberApi SSOT with HttpApiBuilder and HttpApiClient patterns.
allowed-tools: Read, Write, Edit, Grep, Glob
token-budget: 500
version: 1.0.0
---

# API Contract Patterns

Single source of truth API definitions using @effect/platform.

## EmberApi SSOT

Define API contract once in shared package:

```typescript
// packages/domain/src/api.ts
import { HttpApi, HttpApiEndpoint, HttpApiGroup } from '@effect/platform';
import { Schema } from 'effect';

const UsersApi = HttpApiGroup.make('users').pipe(
  HttpApiGroup.add(
    HttpApiEndpoint.get('getUser', '/users/:id').pipe(
      HttpApiEndpoint.setSuccess(UserSchema),
      HttpApiEndpoint.setError(NotFoundError)
    )
  ),
  HttpApiGroup.add(
    HttpApiEndpoint.post('createUser', '/users').pipe(
      HttpApiEndpoint.setPayload(CreateUserSchema),
      HttpApiEndpoint.setSuccess(UserSchema)
    )
  )
);

export const EmberApi = HttpApi.make('ember').pipe(
  HttpApi.addGroup(UsersApi)
);
```

## HttpApiBuilder (Server)

```typescript
// apps/api/src/handlers/users.ts
import { HttpApiBuilder } from '@effect/platform';
import { EmberApi } from '@ember/domain';

export const UsersHandlers = HttpApiBuilder.group(EmberApi, 'users', (handlers) =>
  handlers
    .handle('getUser', ({ path }) =>
      UserService.findById(path.id).pipe(
        Effect.mapError(() => new NotFoundError())
      )
    )
    .handle('createUser', ({ payload }) =>
      UserService.create(payload)
    )
);
```

## HttpApiClient (Consumer)

```typescript
// apps/web/src/api/client.ts
import { HttpApiClient } from '@effect/platform';
import { EmberApi } from '@ember/domain';

const client = HttpApiClient.make(EmberApi, {
  baseUrl: 'https://api.ember.com',
});

// Fully typed!
const user = yield* client.users.getUser({ path: { id: '123' } });
```

## BetterAuth Boundary

Parse BetterAuth session at middleware boundary:

```typescript
const AuthSessionSchema = Schema.Struct({
  session: Schema.Struct({
    id: Schema.String,
    userId: Schema.String,
    token: Schema.String,
    expiresAt: Schema.DateFromSelf,
  }),
  user: Schema.Struct({
    id: Schema.String,
    email: Schema.String,
    phoneNumber: Schema.OptionFromNullOr(Schema.String),
  }),
});

export const requireSession = Effect.gen(function* () {
  const authService = yield* AuthService;
  const rawSession = yield* authService.requireAuth(header);

  // Parse at boundary - $Infer is compile-time only!
  return yield* Schema.decodeUnknown(AuthSessionSchema)(rawSession);
});
```

## Key Principles

1. **API in shared package** - EmberApi in @ember/domain
2. **Server implements** - HttpApiBuilder handlers
3. **Client consumes** - HttpApiClient with full types
4. **Parse at boundary** - Schema.decodeUnknown for external data
