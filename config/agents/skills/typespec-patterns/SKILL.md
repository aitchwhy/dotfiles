---
name: typespec-patterns
description: TypeSpec API-first patterns. TypeSpec to OpenAPI to TypeScript codegen pipeline.
allowed-tools: Read, Write, Edit, Bash
token-budget: 1800
---

## Philosophy: API-First Design

TypeSpec is the single source of truth for API contracts.
Everything else is generated from it.

```
TypeSpec Definition (SOURCE)
        |
   tsp compile
        |
+-------+-------+
|       |       |
v       v       v
OpenAPI  Client  Server
 3.1    Types   Stubs
```

## Project Setup

```bash
# Initialize TypeSpec project
npm init -y
npm install @typespec/compiler @typespec/http @typespec/rest @typespec/openapi3

# Create tspconfig.yaml
cat > tspconfig.yaml << 'YAML'
emit:
  - "@typespec/openapi3"
options:
  "@typespec/openapi3":
    output-file: openapi.yaml
    emitter-output-dir: "{output-dir}/openapi"
YAML
```

## Basic TypeSpec

```typespec
// main.tsp
import "@typespec/http";
import "@typespec/rest";
import "@typespec/openapi3";

using TypeSpec.Http;
using TypeSpec.Rest;

@service({
  title: "My API",
  version: "1.0.0",
})
@server("https://api.example.dev", "Production")
@server("http://localhost:3000", "Development")
namespace MyAPI;
```

## Models

```typespec
// Models with validation decorators
@doc("A user in the system")
model User {
  @key
  @visibility("read")
  id: string;

  @minLength(1)
  @maxLength(100)
  name: string;

  @format("email")
  email: string;

  role: UserRole;

  @visibility("read")
  createdAt: utcDateTime;

  @visibility("read")
  updatedAt: utcDateTime;
}

@doc("User roles in the system")
enum UserRole {
  admin,
  user,
  guest,
}

@doc("Input for creating a user")
model CreateUserInput {
  @minLength(1)
  @maxLength(100)
  name: string;

  @format("email")
  email: string;

  role?: UserRole = UserRole.user;
}

@doc("Input for updating a user")
model UpdateUserInput {
  @minLength(1)
  @maxLength(100)
  name?: string;

  role?: UserRole;
}
```

## Error Types

```typespec
@error
model NotFoundError {
  @statusCode statusCode: 404;
  code: "NOT_FOUND";
  message: string;
}

@error
model ValidationError {
  @statusCode statusCode: 400;
  code: "VALIDATION_ERROR";
  message: string;
  details: ValidationDetail[];
}

model ValidationDetail {
  field: string;
  message: string;
}

@error
model UnauthorizedError {
  @statusCode statusCode: 401;
  code: "UNAUTHORIZED";
  message: string;
}
```

## Routes (Interfaces)

```typespec
@route("/users")
@tag("Users")
interface Users {
  @doc("List all users")
  @get
  list(
    @query limit?: int32 = 20,
    @query offset?: int32 = 0,
  ): User[] | UnauthorizedError;

  @doc("Get a user by ID")
  @get
  read(@path id: string): User | NotFoundError | UnauthorizedError;

  @doc("Create a new user")
  @post
  create(@body user: CreateUserInput): {
    @statusCode statusCode: 201;
    @body user: User;
  } | ValidationError | UnauthorizedError;

  @doc("Update a user")
  @put
  update(
    @path id: string,
    @body user: UpdateUserInput,
  ): User | NotFoundError | ValidationError | UnauthorizedError;

  @doc("Delete a user")
  @delete
  delete(@path id: string): {
    @statusCode statusCode: 204;
  } | NotFoundError | UnauthorizedError;
}
```

## Authentication Routes

```typespec
@route("/auth")
@tag("Authentication")
interface Auth {
  @doc("Request OTP for phone number")
  @post
  @route("/otp/request")
  requestOtp(@body input: OtpRequestInput): {
    @statusCode statusCode: 200;
    @body result: OtpRequestResult;
  } | ValidationError;

  @doc("Verify OTP and get tokens")
  @post
  @route("/otp/verify")
  verifyOtp(@body input: OtpVerifyInput): {
    @statusCode statusCode: 200;
    @body result: AuthTokens;
  } | ValidationError | UnauthorizedError;

  @doc("Refresh access token")
  @post
  @route("/refresh")
  refresh(@body input: RefreshInput): {
    @statusCode statusCode: 200;
    @body result: AuthTokens;
  } | UnauthorizedError;
}

model OtpRequestInput {
  @pattern("^\\+?[1-9]\\d{1,14}$")
  phone: string;
}

model OtpRequestResult {
  success: boolean;
  expiresAt: utcDateTime;
}

model OtpVerifyInput {
  @pattern("^\\+?[1-9]\\d{1,14}$")
  phone: string;

  @minLength(6)
  @maxLength(6)
  code: string;
}

model AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresAt: utcDateTime;
}

model RefreshInput {
  refreshToken: string;
}
```

## Compile to OpenAPI

```bash
npx tsp compile main.tsp

# Output: tsp-output/openapi/openapi.yaml
```

## Generate TypeScript Types

### Using openapi-typescript

```bash
npm install -D openapi-typescript

# Generate types from OpenAPI
npx openapi-typescript ./tsp-output/openapi/openapi.yaml -o ./src/api/types.ts
```

### Using @hey-api/openapi-ts

```bash
npm install -D @hey-api/openapi-ts

# Generate full client
npx @hey-api/openapi-ts \
  -i ./tsp-output/openapi/openapi.yaml \
  -o ./src/api/client \
  -c @hey-api/client-fetch
```

## Integration with Hono

### Type-Safe Routes

```typescript
// src/api/routes/users.ts
import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import * as z from "zod/v4";
import type { User, CreateUserInput, UpdateUserInput } from "../types";

// TypeScript types from TypeSpec -> openapi-typescript
// Zod schemas satisfy those types
const CreateUserSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.email(),
  role: z.enum(["admin", "user", "guest"]).default("user"),
}) satisfies z.ZodType<CreateUserInput>;

const UpdateUserSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  role: z.enum(["admin", "user", "guest"]).optional(),
}) satisfies z.ZodType<UpdateUserInput>;

const users = new Hono();

users.get("/", async (c) => {
  const limit = Number(c.req.query("limit") ?? 20);
  const offset = Number(c.req.query("offset") ?? 0);

  const result = await userService.list({ limit, offset });
  return c.json(result);
});

users.get("/:id", async (c) => {
  const id = c.req.param("id");
  const user = await userService.findById(id);

  if (!user) {
    return c.json({ code: "NOT_FOUND", message: `User ${id} not found` }, 404);
  }

  return c.json(user);
});

users.post("/", zValidator("json", CreateUserSchema), async (c) => {
  const input = c.req.valid("json");
  const user = await userService.create(input);
  return c.json(user, 201);
});

export { users };
```

## Build Pipeline

```json
// package.json
{
  "scripts": {
    "api:compile": "tsp compile main.tsp",
    "api:types": "openapi-typescript ./tsp-output/openapi/openapi.yaml -o ./src/api/types.ts",
    "api:client": "hey-api -i ./tsp-output/openapi/openapi.yaml -o ./src/api/client",
    "api:generate": "npm run api:compile && npm run api:types && npm run api:client",
    "api:watch": "tsp compile main.tsp --watch"
  }
}
```

## CI Validation

```yaml
# .github/workflows/api.yml
name: API Validation

on:
  push:
    paths:
      - "api/**/*.tsp"
      - "tspconfig.yaml"

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: "23"

      - name: Install dependencies
        run: npm ci

      - name: Compile TypeSpec
        run: npm run api:compile

      - name: Validate OpenAPI
        run: npx @redocly/cli lint ./tsp-output/openapi/openapi.yaml

      - name: Generate types
        run: npm run api:types

      - name: Type check
        run: npx tsc --noEmit
```

## Breaking Change Detection

```bash
# Install oasdiff
brew install oasdiff

# Compare OpenAPI specs
oasdiff breaking old-openapi.yaml new-openapi.yaml

# In CI, fail on breaking changes
oasdiff breaking --fail-on ERR old-openapi.yaml new-openapi.yaml
```

## Decorators Reference

| Decorator | Purpose | Example |
|-----------|---------|---------|
| `@service` | Define API metadata | `@service({ title: "My API" })` |
| `@server` | Define server URLs | `@server("https://api.example.com")` |
| `@route` | Define route prefix | `@route("/users")` |
| `@tag` | Group operations | `@tag("Users")` |
| `@doc` | Documentation | `@doc("Description")` |
| `@get`, `@post`, etc. | HTTP methods | `@get read()` |
| `@path` | Path parameter | `@path id: string` |
| `@query` | Query parameter | `@query limit?: int32` |
| `@body` | Request body | `@body user: User` |
| `@header` | Header parameter | `@header auth: string` |
| `@statusCode` | Response status | `@statusCode statusCode: 201` |
| `@error` | Error response | `@error model NotFound` |
| `@key` | Primary key field | `@key id: string` |
| `@visibility` | Field visibility | `@visibility("read")` |
| `@minLength`, `@maxLength` | String length | `@minLength(1)` |
| `@pattern` | Regex pattern | `@pattern("^[a-z]+$")` |
| `@format` | String format | `@format("email")` |

## Anti-Patterns (BANNED)

```typespec
// WRONG: Hand-written OpenAPI
// Never write OpenAPI YAML directly - always generate from TypeSpec

// WRONG: Types without validation
model User {
  name: string;  // No length constraints
  email: string; // No format validation
}

// CORRECT: Types with validation
model User {
  @minLength(1)
  @maxLength(100)
  name: string;

  @format("email")
  email: string;
}
```

## File Structure

```
api/
├── main.tsp           # Entry point
├── models/
│   ├── user.tsp       # User models
│   ├── auth.tsp       # Auth models
│   └── errors.tsp     # Error models
├── routes/
│   ├── users.tsp      # User routes
│   └── auth.tsp       # Auth routes
├── tspconfig.yaml     # TypeSpec config
└── tsp-output/        # Generated output
    └── openapi/
        └── openapi.yaml
```
