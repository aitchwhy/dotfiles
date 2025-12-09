---
name: tdd-patterns
description: Test-Driven Development patterns for Bun test runner. Red-Green-Refactor. E2E to Integration to Unit hierarchy.
allowed-tools: Read, Write, Edit, Bash
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

### Bun Test Structure

```typescript
import { describe, test, expect } from 'bun:test';
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
import { describe, test, expect, beforeEach, afterEach } from 'bun:test';

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

### Bun Test Commands

```bash
bun test                      # Run all tests
bun test --coverage           # With coverage
bun test --grep "UserService" # Pattern match
bun test --watch              # Watch mode
bun test --bail               # Stop on first failure
```
