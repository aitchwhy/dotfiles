# Effect-TS Testing Patterns

## Mock Layers for Testing

```typescript
import { Effect, Layer } from "effect";
import { describe, it, expect } from "vitest";

// Production service
class UserRepository extends Context.Tag("UserRepository")<
  UserRepository,
  {
    readonly findById: (id: string) => Effect.Effect<User, UserNotFoundError>;
    readonly save: (user: User) => Effect.Effect<void, DatabaseError>;
  }
>() {}

// Test layer - returns controlled values
const UserRepositoryTest = Layer.succeed(UserRepository, {
  findById: (id) => id === "existing"
    ? Effect.succeed({ id, name: "Test User", email: "test@example.com" })
    : Effect.fail(new UserNotFoundError({ userId: id })),
  save: () => Effect.void,
});

// Test using the mock layer
describe("UserService", () => {
  const runTest = <A, E>(effect: Effect.Effect<A, E, UserRepository>) =>
    Effect.runPromise(effect.pipe(Effect.provide(UserRepositoryTest)));

  it("finds existing user", async () => {
    const result = await runTest(getUser("existing"));
    expect(result.name).toBe("Test User");
  });

  it("fails for missing user", async () => {
    await expect(runTest(getUser("missing"))).rejects.toThrow();
  });
});
```

## Test Layer Factories

```typescript
// Factory for customizable test layers
const makeUserRepositoryTest = (options: {
  users?: Map<string, User>;
  shouldFailSave?: boolean;
}) => Layer.succeed(UserRepository, {
  findById: (id) => {
    const user = options.users?.get(id);
    return user
      ? Effect.succeed(user)
      : Effect.fail(new UserNotFoundError({ userId: id }));
  },
  save: () => options.shouldFailSave
    ? Effect.fail(new DatabaseError({ operation: "save", cause: "Test failure" }))
    : Effect.void,
});

// Usage in tests
it("handles save failure", async () => {
  const TestLayer = makeUserRepositoryTest({ shouldFailSave: true });
  const result = await Effect.runPromise(
    createUser({ name: "Test" }).pipe(
      Effect.provide(TestLayer),
      Effect.either
    )
  );
  expect(result._tag).toBe("Left");
});
```

## Testing with Effect.either

```typescript
// Either returns Left(error) or Right(success)
it("returns error for invalid input", async () => {
  const result = await Effect.runPromise(
    validateUser(invalidInput).pipe(Effect.either)
  );

  expect(result._tag).toBe("Left");
  if (result._tag === "Left") {
    expect(result.left._tag).toBe("ValidationError");
  }
});

it("returns success for valid input", async () => {
  const result = await Effect.runPromise(
    validateUser(validInput).pipe(Effect.either)
  );

  expect(result._tag).toBe("Right");
  if (result._tag === "Right") {
    expect(result.right.name).toBe("Valid User");
  }
});
```

## Testing with Exit

```typescript
import { Exit } from "effect";

it("captures full exit information", async () => {
  const exit = await Effect.runPromiseExit(program);

  if (Exit.isSuccess(exit)) {
    expect(exit.value).toEqual(expectedResult);
  } else if (Exit.isFailure(exit)) {
    const cause = exit.cause;
    // Can inspect cause for failures, defects, interruptions
  }
});
```

## Composing Test Layers

```typescript
// Multiple service mocks
const TestServices = Layer.mergeAll(
  UserRepositoryTest,
  EmailServiceTest,
  LoggerTest,
);

// With shared test config
const TestConfig = Layer.succeed(Config, {
  apiUrl: "http://test.local",
  timeout: 1000,
});

const FullTestLayer = TestServices.pipe(
  Layer.provide(TestConfig)
);

// Reuse across test suites
const runWithTestEnv = <A, E, R extends TestServices>(
  effect: Effect.Effect<A, E, R>
) => Effect.runPromise(effect.pipe(Effect.provide(FullTestLayer)));
```

## Clock and Time Testing

```typescript
import { TestClock, TestContext } from "effect";

it("handles timeout correctly", async () => {
  await Effect.runPromise(
    Effect.gen(function* () {
      const fiber = yield* Effect.fork(
        operationWithTimeout.pipe(Effect.timeout("5 seconds"))
      );

      // Advance test clock
      yield* TestClock.adjust("6 seconds");

      const result = yield* Fiber.join(fiber).pipe(Effect.either);
      expect(result._tag).toBe("Left");
    }).pipe(Effect.provide(TestContext.TestContext))
  );
});
```

## Property-Based Testing

```typescript
import * as fc from "fast-check";
import { Schema } from "effect";

// Generate valid inputs from schema
const userArbitrary = fc.record({
  name: fc.string({ minLength: 1, maxLength: 100 }),
  email: fc.emailAddress(),
  age: fc.integer({ min: 0, max: 150 }),
});

it("roundtrips through encode/decode", () => {
  fc.assert(
    fc.property(userArbitrary, (input) => {
      const encoded = Schema.encodeSync(User)(input);
      const decoded = Schema.decodeSync(User)(encoded);
      expect(decoded).toEqual(input);
    })
  );
});
```

## Integration Test Pattern

```typescript
// Use real layers for integration tests
describe("Integration: User Registration", () => {
  // Real database layer with test database
  const TestDbLayer = DatabaseClientLive.pipe(
    Layer.provide(Layer.succeed(Config, { dbUrl: TEST_DB_URL }))
  );

  const IntegrationLayer = Layer.mergeAll(
    UserRepositoryLive,
    EmailServiceLive, // Real email service (to test mailbox)
  ).pipe(Layer.provide(TestDbLayer));

  beforeEach(async () => {
    await Effect.runPromise(clearTestDb.pipe(Effect.provide(TestDbLayer)));
  });

  it("creates user and sends welcome email", async () => {
    const result = await Effect.runPromise(
      registerUser({ name: "Test", email: "test@example.com" })
        .pipe(Effect.provide(IntegrationLayer))
    );

    expect(result.id).toBeDefined();
    // Assert email was sent to test mailbox
  });
});
```
