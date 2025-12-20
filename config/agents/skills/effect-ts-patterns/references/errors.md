# Effect-TS Error Handling Patterns

## Data.TaggedError

```typescript
import { Data, Effect } from "effect";

// Define typed errors with TaggedError
class UserNotFoundError extends Data.TaggedError("UserNotFoundError")<{
  readonly userId: string;
}> {}

class ValidationError extends Data.TaggedError("ValidationError")<{
  readonly field: string;
  readonly message: string;
}> {}

class DatabaseError extends Data.TaggedError("DatabaseError")<{
  readonly operation: string;
  readonly cause: unknown;
}> {}

// Errors automatically get: _tag, toString, equals, hash
const err = new UserNotFoundError({ userId: "123" });
console.log(err._tag);  // "UserNotFoundError"
console.log(err.userId); // "123"
```

## Failing Effects

```typescript
// Create failing effect
const failWithError = Effect.fail(new UserNotFoundError({ userId: "123" }));

// Fail within generator
const getUser = (id: string) => Effect.gen(function* () {
  const user = yield* findInDatabase(id);
  if (!user) {
    return yield* Effect.fail(new UserNotFoundError({ userId: id }));
  }
  return user;
});
```

## Catching Errors

```typescript
// Catch by tag (most common)
getUser("123").pipe(
  Effect.catchTag("UserNotFoundError", (e) =>
    Effect.succeed(createGuestUser(e.userId))
  )
);

// Catch multiple tags
program.pipe(
  Effect.catchTags({
    UserNotFoundError: (e) => Effect.succeed(guestUser),
    ValidationError: (e) => Effect.fail(new BadRequestError({ field: e.field })),
  })
);

// Catch all errors (typed)
program.pipe(
  Effect.catchAll((e) => {
    // e is union of all possible errors
    return Effect.succeed(fallbackValue);
  })
);

// Map errors (transform error type)
program.pipe(
  Effect.mapError((e) => new ApiError({ cause: e }))
);
```

## Error Hierarchies

```typescript
// Base error for domain
class DomainError extends Data.TaggedError("DomainError")<{
  readonly message: string;
}> {}

// Specific errors
class NotFoundError extends Data.TaggedError("NotFoundError")<{
  readonly resource: string;
  readonly id: string;
}> {}

class ConflictError extends Data.TaggedError("ConflictError")<{
  readonly resource: string;
  readonly existingId: string;
}> {}

// Union type for API boundary
type ApiError = NotFoundError | ConflictError | ValidationError;

// Handle at boundary
const handleApiError = (error: ApiError): Response => {
  switch (error._tag) {
    case "NotFoundError": return new Response(null, { status: 404 });
    case "ConflictError": return new Response(null, { status: 409 });
    case "ValidationError": return new Response(error.message, { status: 400 });
  }
};
```

## tryPromise for External Calls

```typescript
// Wrap promise-based APIs
const fetchUser = (id: string) => Effect.tryPromise({
  try: () => fetch(`/api/users/${id}`).then(r => r.json()),
  catch: (error) => new NetworkError({
    operation: "fetchUser",
    cause: error
  }),
});

// Wrap sync code that might throw
const parseJson = (str: string) => Effect.try({
  try: () => JSON.parse(str),
  catch: (error) => new ParseError({
    input: str,
    cause: error
  }),
});
```

## orElse and Recovery

```typescript
// Try alternative on failure
const getUserWithFallback = getUser(id).pipe(
  Effect.orElse(() => getFromCache(id)),
  Effect.orElse(() => Effect.succeed(defaultUser))
);

// Retry with schedule
import { Schedule } from "effect";

const reliableGet = getUser(id).pipe(
  Effect.retry(
    Schedule.exponential("100 millis").pipe(
      Schedule.compose(Schedule.recurs(3))
    )
  )
);
```

## Die vs Fail

```typescript
// Fail: Expected/recoverable errors (in E position)
Effect.fail(new UserNotFoundError({ userId: "123" }));
// Type: Effect<never, UserNotFoundError, never>

// Die: Unexpected/unrecoverable defects (not in type)
Effect.die(new Error("Invariant violated"));
// Type: Effect<never, never, never>

// Rule: Use Fail for domain errors, Die for programming bugs
```
