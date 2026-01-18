# HTTP API SSOT Pattern — Effect-TS

> **Single Source of Truth for all HTTP communication**
> Version: 2026.01.01 | Enforcement: AST-grep (hard block)

## Core Principle

**Every HTTP request in our codebase MUST be derived from an HttpApi contract.**

No exceptions. No "just this once." No manual HTTP clients.

## The Pattern

```
┌─────────────────────────────────────────────────────────────────────┐
│                    @yourpackage/contracts                           │
│                                                                     │
│  HttpApi.make('myapi')                                              │
│    .add(HttpApiGroup.make('users')                                  │
│      .add(HttpApiEndpoint.get('list', '/users')                     │
│        .addSuccess(Schema.Array(User))))                            │
│                                                                     │
│  ← SINGLE SOURCE OF TRUTH: types, paths, schemas                    │
└──────────────────────────┬───────────────────────────┬──────────────┘
                           │                           │
                           ▼                           ▼
┌─────────────────────────────────────┐  ┌─────────────────────────────┐
│           SERVER                     │  │          CLIENT             │
│                                      │  │                             │
│  HttpApiBuilder.group(MyApi,         │  │  HttpApiClient.make(MyApi,  │
│    'users',                          │  │    { baseUrl })             │
│    (h) => h.handle('list', () => {   │  │                             │
│      // implementation               │  │  client.users.list()        │
│    })                                │  │  // ← Fully typed!          │
│  )                                   │  │                             │
│  ← Implements contract               │  │  ← Derives from contract    │
└─────────────────────────────────────┘  └─────────────────────────────┘
```

## What Is BANNED

### ❌ Direct fetch()
```typescript
// VIOLATION
const response = await fetch('/api/users')
const data = await response.json()
```

### ❌ Manual HttpClientRequest
```typescript
// VIOLATION
const request = HttpClientRequest.get('/api/users')
const response = yield* client.execute(request)
```

### ❌ Third-party HTTP clients
```typescript
// VIOLATION
import axios from 'axios'
const { data } = await axios.get('/api/users')
```

### ❌ Hardcoded API URLs
```typescript
// VIOLATION
const url = `${baseUrl}/api/users/${userId}`
```

### ❌ Manual response parsing
```typescript
// VIOLATION
const users = yield* HttpClientResponse.schemaBodyJson(UsersSchema)(response)
```

## What Is REQUIRED

### ✅ Define contract first
```typescript
// packages/contracts/src/api.ts
import { HttpApi, HttpApiEndpoint, HttpApiGroup } from '@effect/platform'
import { Schema } from 'effect'

export const User = Schema.Struct({
  id: Schema.String,
  name: Schema.String,
})

export class UsersGroup extends HttpApiGroup.make('users')
  .add(HttpApiEndpoint.get('list', '/users').addSuccess(Schema.Array(User)))
  .add(HttpApiEndpoint.get('byId', '/users/:id')
    .setPath(Schema.Struct({ id: Schema.String }))
    .addSuccess(User))
  .add(HttpApiEndpoint.post('create', '/users')
    .setPayload(Schema.Struct({ name: Schema.String }))
    .addSuccess(User)) {}

export class MyApi extends HttpApi.make('myapi').add(UsersGroup) {}
```

### ✅ Implement server from contract
```typescript
// apps/server/src/handlers/users.ts
import { HttpApiBuilder } from '@effect/platform'
import { MyApi } from '@mypackage/contracts'
import { Effect } from 'effect'

export const UsersHandlers = HttpApiBuilder.group(MyApi, 'users', (handlers) =>
  handlers
    .handle('list', () => Effect.succeed([{ id: '1', name: 'Alice' }]))
    .handle('byId', ({ path }) => Effect.succeed({ id: path.id, name: 'Alice' }))
    .handle('create', ({ payload }) => Effect.succeed({ id: '2', name: payload.name }))
)
```

### ✅ Derive client from contract
```typescript
// apps/mobile/src/services/ApiClient.ts
import { FetchHttpClient, HttpApiClient } from '@effect/platform'
import { MyApi } from '@mypackage/contracts'
import { Context, Effect, Layer } from 'effect'

// Service Tag
export class ApiClient extends Context.Tag('ApiClient')<
  ApiClient,
  Effect.Effect.Success<ReturnType<typeof HttpApiClient.make<typeof MyApi>>>
>() {}

// Layer
export const ApiClientLive = Layer.effect(
  ApiClient,
  HttpApiClient.make(MyApi, { baseUrl: 'http://localhost:3000' })
).pipe(Layer.provide(FetchHttpClient.layer))
```

### ✅ Use derived client
```typescript
// apps/mobile/src/features/users.ts
import { ApiClient } from '../services/ApiClient'
import { Effect } from 'effect'

// All methods are derived from the contract!
// - Types are inferred
// - Paths are compile-time checked
// - No URL strings in application code

export const getUsers = Effect.gen(function* () {
  const client = yield* ApiClient
  return yield* client.users.list()
})

export const getUser = (id: string) => Effect.gen(function* () {
  const client = yield* ApiClient
  return yield* client.users.byId({ path: { id } })
})

export const createUser = (name: string) => Effect.gen(function* () {
  const client = yield* ApiClient
  return yield* client.users.create({ payload: { name } })
})
```

## Benefits

| Aspect | Manual HTTP | SSOT HttpApi |
|--------|-------------|--------------|
| URL typo | Runtime error | **Compile-time error** |
| Schema drift | Silent data corruption | **Compile-time error** |
| Add endpoint | Change 3+ files | Change contract, auto-propagates |
| Type safety | Manual annotations | **Full inference** |
| Testability | Mock fetch | Provide test Layer |

## Enforcement

These rules are enforced by AST-grep at:
- Pre-commit hook (blocks commit)
- CI pipeline (blocks merge)
- Editor integration (real-time warnings)

Rules location: `~/dotfiles/config/quality/rules/effect/http-ssot-*.yml`

### Running checks
```bash
# Single project
ast-grep scan --rule ~/dotfiles/config/quality/rules/effect/

# Or if rules are symlinked to project
ast-grep scan
```

## Exceptions

There are NO exceptions to this rule. If you think you need one:

1. You're wrong
2. Define a contract for your use case
3. Use HttpApiClient.make()

External APIs? Define a contract that matches their schema.
Third-party SDKs? Wrap them in an Effect Service, not raw HTTP.
