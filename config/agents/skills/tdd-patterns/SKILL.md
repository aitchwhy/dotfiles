---
name: tdd-patterns
description: Test-Driven Development patterns for Vitest. Red-Green-Refactor. E2E to Integration to Unit hierarchy.
allowed-tools: Read, Write, Edit, Bash
token-budget: 400
---

## Testing Hierarchy

### Test Pyramid

```
E2E Tests (few)         -> Test user journeys, API flows
Integration (moderate)  -> Test service interactions, DB queries
Unit Tests (many)       -> Test pure functions, isolated logic
```

## Red-Green-Refactor Cycle

1. **Red**: Write a failing test that defines the expected behavior
2. **Green**: Write the minimal code to make the test pass
3. **Refactor**: Improve the code while keeping tests green

## Unit Test Patterns

### Vitest Test Structure

```typescript
import { describe, test, expect } from 'vitest';
import { Ok, Err, map, all } from '@/lib/result';

describe('Result', () => {
  describe('Ok', () => {
    test('creates success result', () => {
      const result = Ok(42);
      expect(result.ok).toBe(true);
      expect(result.data).toBe(42);
    });
  });

  describe('map', () => {
    test('transforms success value', () => {
      const result = map(Ok(2), (x) => x * 2);
      expect(result).toEqual(Ok(4));
    });
  });
});
```

## Integration Test Patterns

### Service Tests with Setup/Teardown

```typescript
import { describe, test, expect, beforeEach, afterEach } from 'vitest';

describe('UserService', () => {
  let db: TestDb;

  beforeEach(async () => {
    db = await createTestDb();
  });

  afterEach(async () => {
    await resetDb(db);
  });

  test('creates user with valid input', async () => {
    const result = await createUser(db, { email: 'test@example.com', name: 'Test' });
    expect(result.ok).toBe(true);
  });
});
```

## Running Tests

### Vitest Commands

```bash
pnpm test                       # Run all tests (via vitest)
vitest                          # Run all tests directly
vitest --coverage               # With coverage
vitest --watch                  # Watch mode
vitest run src/api.test.ts      # Run specific test file
vitest --run --grep "UserService"  # Pattern match
```
