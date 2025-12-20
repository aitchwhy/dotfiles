# Effect-TS HTTP API Patterns

## HttpApiBuilder Pattern

```typescript
import { HttpApi, HttpApiBuilder, HttpApiEndpoint, HttpApiGroup } from "@effect/platform";
import { Schema } from "effect";

// 1. Define schemas
const UserId = Schema.String.pipe(Schema.brand("UserId"));
const User = Schema.Struct({
  id: UserId,
  name: Schema.String,
  email: Schema.String,
});

// 2. Define error schemas
const NotFoundError = Schema.Struct({
  _tag: Schema.Literal("NotFoundError"),
  message: Schema.String,
});

// 3. Define endpoints
const getUser = HttpApiEndpoint.get("getUser", "/users/:id")
  .pipe(
    HttpApiEndpoint.setPath(Schema.Struct({ id: UserId })),
    HttpApiEndpoint.setSuccess(User),
    HttpApiEndpoint.addError(NotFoundError, { status: 404 }),
  );

const createUser = HttpApiEndpoint.post("createUser", "/users")
  .pipe(
    HttpApiEndpoint.setPayload(Schema.Struct({
      name: Schema.String,
      email: Schema.String,
    })),
    HttpApiEndpoint.setSuccess(User, { status: 201 }),
  );

// 4. Group endpoints
const usersApi = HttpApiGroup.make("users")
  .pipe(
    HttpApiGroup.add(getUser),
    HttpApiGroup.add(createUser),
  );

// 5. Create API
const api = HttpApi.make("MyApi")
  .pipe(HttpApi.addGroup(usersApi));
```

## Implementing Handlers

```typescript
import { HttpApiBuilder } from "@effect/platform";

const UsersApiLive = HttpApiBuilder.group(api, "users", (handlers) =>
  handlers
    .handle("getUser", ({ path }) =>
      Effect.gen(function* () {
        const repo = yield* UserRepository;
        return yield* repo.findById(path.id);
      })
    )
    .handle("createUser", ({ payload }) =>
      Effect.gen(function* () {
        const repo = yield* UserRepository;
        const id = yield* generateId();
        const user = { id, ...payload };
        yield* repo.save(user);
        return user;
      })
    )
);

// Combine all group handlers
const ApiLive = HttpApiBuilder.api(api).pipe(
  Layer.provide(UsersApiLive),
  Layer.provide(UserRepositoryLive),
);
```

## HttpClient for Outbound Requests

```typescript
import { HttpClient, HttpClientRequest, HttpClientResponse } from "@effect/platform";

// Define client service
class ExternalApi extends Context.Tag("ExternalApi")<
  ExternalApi,
  {
    readonly getUser: (id: string) => Effect.Effect<ExternalUser, ApiError>;
  }
>() {}

const ExternalApiLive = Layer.effect(
  ExternalApi,
  Effect.gen(function* () {
    const client = yield* HttpClient.HttpClient;
    const baseUrl = yield* Config.string("EXTERNAL_API_URL");

    return {
      getUser: (id) => Effect.gen(function* () {
        const request = HttpClientRequest.get(`${baseUrl}/users/${id}`);
        const response = yield* client.execute(request);

        if (response.status === 404) {
          return yield* Effect.fail(new UserNotFoundError({ id }));
        }

        return yield* HttpClientResponse.schemaBodyJson(ExternalUser)(response);
      }),
    };
  })
);
```

## Request/Response Schemas

```typescript
// Request body schema
const CreateUserRequest = Schema.Struct({
  name: Schema.String.pipe(Schema.minLength(1)),
  email: Schema.String.pipe(Schema.pattern(/@/)),
  role: Schema.optional(Schema.Literal("admin", "user")),
});

// Response schema with transform
const UserResponse = Schema.Struct({
  id: Schema.String,
  name: Schema.String,
  email: Schema.String,
  createdAt: Schema.DateFromString,  // Auto-transforms ISO string to Date
});

// Paginated response
const PaginatedUsers = Schema.Struct({
  items: Schema.Array(UserResponse),
  total: Schema.Number,
  page: Schema.Number,
  pageSize: Schema.Number,
});
```

## Error Handling at API Boundary

```typescript
// Map domain errors to HTTP errors
const withErrorMapping = <A, E, R>(effect: Effect.Effect<A, E, R>) =>
  effect.pipe(
    Effect.catchTags({
      UserNotFoundError: (e) =>
        HttpApiBuilder.fail({
          _tag: "NotFoundError",
          message: `User ${e.userId} not found`
        }),
      ValidationError: (e) =>
        HttpApiBuilder.fail({
          _tag: "BadRequestError",
          message: e.message,
        }),
    })
  );
```

## Middleware

```typescript
import { HttpMiddleware, HttpServerRequest } from "@effect/platform";

// Logging middleware
const LoggingMiddleware = HttpMiddleware.make((app) =>
  Effect.gen(function* () {
    const request = yield* HttpServerRequest.HttpServerRequest;
    const start = yield* Clock.currentTimeMillis;

    const response = yield* app;

    const duration = (yield* Clock.currentTimeMillis) - start;
    yield* Effect.log(`${request.method} ${request.url} - ${duration}ms`);

    return response;
  })
);

// Auth middleware
const AuthMiddleware = HttpMiddleware.make((app) =>
  Effect.gen(function* () {
    const request = yield* HttpServerRequest.HttpServerRequest;
    const token = request.headers["authorization"];

    if (!token) {
      return yield* HttpServerResponse.json(
        { error: "Unauthorized" },
        { status: 401 }
      );
    }

    const user = yield* validateToken(token);
    return yield* app.pipe(Effect.provideService(CurrentUser, user));
  })
);
```
