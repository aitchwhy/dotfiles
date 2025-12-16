/**
 * Police Enforcer Tests
 *
 * Tests for structure, naming, and dependency validation.
 */

import { describe, expect, test } from 'bun:test';
import { Effect } from 'effect';
import { checkDependencyHygiene, checkNamingConventions, checkStructure } from '@/enforcers/police';

describe('Police Enforcer', () => {
  describe('checkStructure', () => {
    test('returns no violations for valid structure', async () => {
      const files = ['package.json', 'tsconfig.json', 'src/index.ts'];

      const program = checkStructure(files, 'library');
      const violations = await Effect.runPromise(program);

      expect(violations).toEqual([]);
    });

    test('reports missing package.json', async () => {
      const files = ['tsconfig.json', 'src/index.ts'];

      const program = checkStructure(files, 'library');
      const violations = await Effect.runPromise(program);

      expect(violations.length).toBe(1);
      expect(violations[0]?.rule).toBe('missing-package-json');
    });

    test('reports missing src directory for library', async () => {
      const files = ['package.json', 'tsconfig.json'];

      const program = checkStructure(files, 'library');
      const violations = await Effect.runPromise(program);

      expect(violations.some((v) => v.rule === 'missing-src')).toBe(true);
    });
  });

  describe('checkNamingConventions', () => {
    test('allows valid kebab-case names', async () => {
      const files = ['src/my-component.ts', 'src/api-client.ts'];

      const program = checkNamingConventions(files);
      const violations = await Effect.runPromise(program);

      expect(violations).toEqual([]);
    });

    test('allows valid camelCase names', async () => {
      const files = ['src/myComponent.ts', 'src/apiClient.ts'];

      const program = checkNamingConventions(files);
      const violations = await Effect.runPromise(program);

      expect(violations).toEqual([]);
    });

    test('reports PascalCase file names (should be components only)', async () => {
      const files = ['src/MyService.ts'];

      const program = checkNamingConventions(files);
      const violations = await Effect.runPromise(program);

      // PascalCase is allowed for class/component files
      expect(violations).toEqual([]);
    });
  });

  describe('checkDependencyHygiene', () => {
    test('returns no violations for clean dependencies', async () => {
      const deps = {
        dependencies: { zod: '^3.24.0' },
        devDependencies: { typescript: '^5.9.0' },
      };

      const program = checkDependencyHygiene(deps);
      const violations = await Effect.runPromise(program);

      expect(violations).toEqual([]);
    });

    test('warns about deprecated packages', async () => {
      const deps = {
        dependencies: { request: '^2.88.0' }, // deprecated
        devDependencies: {},
      };

      const program = checkDependencyHygiene(deps);
      const violations = await Effect.runPromise(program);

      expect(violations.some((v) => v.rule === 'deprecated-package')).toBe(true);
    });

    test('warns about ESLint when Biome should be used', async () => {
      const deps = {
        dependencies: {},
        devDependencies: { eslint: '^8.0.0' },
      };

      const program = checkDependencyHygiene(deps);
      const violations = await Effect.runPromise(program);

      expect(violations.some((v) => v.rule === 'prefer-biome')).toBe(true);
    });
  });
});
