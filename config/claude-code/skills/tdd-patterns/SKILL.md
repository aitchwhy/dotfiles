---
name: tdd-patterns
description: Test-Driven Development patterns for Bun test runner. Red-Green-Refactor. E2E to Integration to Unit hierarchy.
allowed-tools: Read, Write, Edit, Bash
---

# TDD Patterns (December 2025)

## Testing Hierarchy

```
E2E Tests (few)         -> Test user journeys, API flows
Integration (moderate)  -> Test service interactions, DB queries
Unit Tests (many)       -> Test pure functions, isolated logic
```

## Red-Green-Refactor Cycle

1. **Red**: Write a failing test that defines the expected behavior
2. **Green**: Write the minimal code to make the test pass
3. **Refactor**: Improve the code while keeping tests green

## Project Structure

```
src/
├── services/
│   └── user.ts
└── lib/
    └── validation.ts

test/
├── e2e/
│   └── api.test.ts
├── integration/
│   └── services/
│       └── user.test.ts
└── unit/
    └── lib/
        └── validation.test.ts
```

## Unit Test Patterns

```typescript
// test/unit/lib/result.test.ts
import { describe, test, expect } from 'bun:test';
import { Ok, Err, map, flatMap, all } from '@/lib/result';

describe('Result', () => {
  describe('Ok', () => {
    test('creates success result', () => {
      const result = Ok(42);
      expect(result.ok).toBe(true);
      expect(result.data).toBe(42);
    });
  });

  describe('Err', () => {
    test('creates error result', () => {
      const result = Err('failed');
      expect(result.ok).toBe(false);
      expect(result.error).toBe('failed');
    });
  });

  describe('map', () => {
    test('transforms success value', () => {
      const result = map(Ok(2), (x) => x * 2);
      expect(result).toEqual(Ok(4));
    });

    test('passes through error', () => {
      const result = map(Err('error'), (x: number) => x * 2);
      expect(result).toEqual(Err('error'));
    });
  });

  describe('flatMap', () => {
    test('chains successful operations', () => {
      const divide = (n: number): Result<number, string> =>
        n === 0 ? Err('division by zero') : Ok(10 / n);

      const result = flatMap(Ok(5), divide);
      expect(result).toEqual(Ok(2));
    });

    test('short-circuits on first error', () => {
      const result = flatMap(Err('initial error'), () => Ok(42));
      expect(result).toEqual(Err('initial error'));
    });
  });

  describe('all', () => {
    test('collects all successes', () => {
      const results = [Ok(1), Ok(2), Ok(3)];
      expect(all(results)).toEqual(Ok([1, 2, 3]));
    });

    test('returns first error', () => {
      const results = [Ok(1), Err('fail'), Ok(3)];
      expect(all(results)).toEqual(Err('fail'));
    });
  });
});
```

## Integration Test Patterns

```typescript
// test/integration/services/user.test.ts
import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { createTestDb, resetDb } from '@/test/utils/db';
import { createUser, getUser, updateUser } from '@/services/user';

describe('UserService', () => {
  let db: TestDb;

  beforeEach(async () => {
    db = await createTestDb();
  });

  afterEach(async () => {
    await resetDb(db);
  });

  describe('createUser', () => {
    test('creates user with valid input', async () => {
      const input = {
        email: 'test@example.com',
        name: 'Test User',
      };

      const result = await createUser(db, input);

      expect(result.ok).toBe(true);
      if (result.ok) {
        expect(result.data.email).toBe(input.email);
        expect(result.data.name).toBe(input.name);
        expect(result.data.id).toBeDefined();
      }
    });

    test('fails with duplicate email', async () => {
      const input = { email: 'test@example.com', name: 'Test User' };
      await createUser(db, input);

      const result = await createUser(db, input);

      expect(result.ok).toBe(false);
      if (!result.ok) {
        expect(result.error.code).toBe('CONFLICT');
      }
    });
  });

  describe('getUser', () => {
    test('returns user when exists', async () => {
      const created = await createUser(db, {
        email: 'test@example.com',
        name: 'Test User',
      });
      if (!created.ok) throw new Error('Setup failed');

      const result = await getUser(db, created.data.id);

      expect(result.ok).toBe(true);
      if (result.ok) {
        expect(result.data.id).toBe(created.data.id);
      }
    });

    test('returns NOT_FOUND for missing user', async () => {
      const result = await getUser(db, 'nonexistent-id');

      expect(result.ok).toBe(false);
      if (!result.ok) {
        expect(result.error.code).toBe('NOT_FOUND');
      }
    });
  });
});
```

## E2E Test Patterns

```typescript
// test/e2e/api.test.ts
import { describe, test, expect, beforeAll, afterAll } from 'bun:test';
import { app } from '@/index';

describe('API E2E', () => {
  describe('User API', () => {
    test('POST /api/users -> GET /api/users/:id flow', async () => {
      // Create user
      const createRes = await app.request('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'e2e@example.com',
          name: 'E2E User',
        }),
      });

      expect(createRes.status).toBe(201);
      const { data: created } = await createRes.json();
      expect(created.id).toBeDefined();

      // Retrieve user
      const getRes = await app.request(`/api/users/${created.id}`);
      expect(getRes.status).toBe(200);
      const { data: retrieved } = await getRes.json();
      expect(retrieved.email).toBe('e2e@example.com');
    });

    test('validation errors return 400', async () => {
      const res = await app.request('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: 'invalid-email' }),
      });

      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error).toBeDefined();
    });
  });

  describe('Health Check', () => {
    test('GET /health returns 200', async () => {
      const res = await app.request('/health');
      expect(res.status).toBe(200);
    });
  });
});
```

## Test Utilities

```typescript
// test/utils/factories.ts
import { faker } from '@faker-js/faker';

export function createUserInput(overrides = {}) {
  return {
    email: faker.internet.email(),
    name: faker.person.fullName(),
    ...overrides,
  };
}

export function createOrderInput(userId: string, overrides = {}) {
  return {
    userId,
    items: [
      { productId: faker.string.uuid(), quantity: faker.number.int({ min: 1, max: 5 }) },
    ],
    ...overrides,
  };
}

// test/utils/assertions.ts
import { expect } from 'bun:test';
import type { Result } from '@/lib/result';

export function expectOk<T, E>(result: Result<T, E>): asserts result is { ok: true; data: T } {
  expect(result.ok).toBe(true);
}

export function expectErr<T, E>(result: Result<T, E>): asserts result is { ok: false; error: E } {
  expect(result.ok).toBe(false);
}
```

## Running Tests

```bash
# Run all tests
bun test

# Run with coverage
bun test --coverage

# Run specific pattern
bun test --pattern "UserService"

# Watch mode
bun test --watch

# Bail on first failure (CI mode)
bun test --bail
```
