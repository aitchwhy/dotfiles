/**
 * TDD Patterns Skill Definition
 *
 * Test-Driven Development patterns for Bun test runner.
 * Migrated from: config/claude-code/skills/tdd-patterns/SKILL.md
 */
import type { SystemSkill } from '@/schema'

export const tddPatternsSkill: SystemSkill = {
  name: 'tdd-patterns' as SystemSkill['name'],
  description:
    'Test-Driven Development patterns for Bun test runner. Red-Green-Refactor. E2E to Integration to Unit hierarchy.',
  allowedTools: ['Read', 'Write', 'Edit', 'Bash'] as SystemSkill['allowedTools'],

  sections: [
    {
      title: 'Testing Hierarchy',
      patterns: [
        {
          title: 'Test Pyramid',
          annotation: 'info',
          language: 'text',
          code: `E2E Tests (few)         -> Test user journeys, API flows
Integration (moderate)  -> Test service interactions, DB queries
Unit Tests (many)       -> Test pure functions, isolated logic`,
        },
      ],
    },
    {
      title: 'Red-Green-Refactor Cycle',
      content: `1. **Red**: Write a failing test that defines the expected behavior
2. **Green**: Write the minimal code to make the test pass
3. **Refactor**: Improve the code while keeping tests green`,
    },
    {
      title: 'Unit Test Patterns',
      patterns: [
        {
          title: 'Bun Test Structure',
          annotation: 'do',
          language: 'typescript',
          code: `import { describe, test, expect } from 'bun:test';
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
});`,
        },
      ],
    },
    {
      title: 'Integration Test Patterns',
      patterns: [
        {
          title: 'Service Tests with Setup/Teardown',
          annotation: 'do',
          language: 'typescript',
          code: `import { describe, test, expect, beforeEach, afterEach } from 'bun:test';

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
});`,
        },
      ],
    },
    {
      title: 'Running Tests',
      patterns: [
        {
          title: 'Bun Test Commands',
          annotation: 'info',
          language: 'bash',
          code: `bun test                      # Run all tests
bun test --coverage           # With coverage
bun test --grep "UserService" # Pattern match
bun test --watch              # Watch mode
bun test --bail               # Stop on first failure`,
        },
      ],
    },
  ],
}
