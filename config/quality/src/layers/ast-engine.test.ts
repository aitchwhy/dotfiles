/**
 * AST Engine Tests
 *
 * Tests for the OXC based AST Engine layer.
 */
import { describe, expect, test } from 'bun:test';
import { Effect } from 'effect';
import { AstEngineLive, createSourceFile, detectDrift, type PatternConfig } from './ast-engine';

describe('AstEngine', () => {
  describe('createSourceFile', () => {
    test('creates a source file from content', async () => {
      const program = createSourceFile('test.ts', 'const x: number = 42;').pipe(
        Effect.map((source) => source.content),
        Effect.provide(AstEngineLive)
      );

      const result = await Effect.runPromise(program);
      expect(result).toBe('const x: number = 42;');
    });

    test('parses imports correctly', async () => {
      const content = `import { Effect } from 'effect';
import { z } from 'zod';

export const schema = z.string();`;

      const program = createSourceFile('test.ts', content).pipe(
        Effect.map(
          (source) => source.program.body.filter((s) => s.type === 'ImportDeclaration').length
        ),
        Effect.provide(AstEngineLive)
      );

      const result = await Effect.runPromise(program);
      expect(result).toBe(2);
    });
  });

  describe('detectDrift', () => {
    test('detects missing Zod import in file with z. usage', async () => {
      const content = `export const schema = z.object({ name: z.string() });`;

      const patterns: PatternConfig = {
        requireZodImport: true,
        requireResultType: false,
        requireExplicitExports: false,
      };

      const program = createSourceFile('schema.ts', content).pipe(
        Effect.flatMap((source) => detectDrift(source, patterns)),
        Effect.provide(AstEngineLive)
      );

      const result = await Effect.runPromise(program);
      expect(result.issues.length).toBeGreaterThan(0);
      expect(result.issues.some((i) => i.type === 'missing-import')).toBe(true);
    });

    test('no drift when Zod is properly imported', async () => {
      const content = `import { z } from 'zod';

export const schema = z.object({ name: z.string() });`;

      const patterns: PatternConfig = {
        requireZodImport: true,
        requireResultType: false,
        requireExplicitExports: false,
      };

      const program = createSourceFile('schema.ts', content).pipe(
        Effect.flatMap((source) => detectDrift(source, patterns)),
        Effect.provide(AstEngineLive)
      );

      const result = await Effect.runPromise(program);
      const zodIssues = result.issues.filter((i) => i.message.includes('zod'));
      expect(zodIssues.length).toBe(0);
    });

    test('detects missing Result type in handler function', async () => {
      const content = `export async function handleRequest(req: Request): Promise<Response> {
  const data = await fetchData();
  return new Response(JSON.stringify(data));
}`;

      const patterns: PatternConfig = {
        requireZodImport: false,
        requireResultType: true,
        requireExplicitExports: false,
      };

      const program = createSourceFile('handler.ts', content).pipe(
        Effect.flatMap((source) => detectDrift(source, patterns)),
        Effect.provide(AstEngineLive)
      );

      const result = await Effect.runPromise(program);
      // Handler functions that could fail should return Result
      expect(result.issues.some((i) => i.type === 'missing-result-type')).toBe(true);
    });

    test('no drift when Result type is used', async () => {
      const content = `import type { Result } from './result';

export function parseUser(input: unknown): Result<User, Error> {
  // parsing logic
  return { ok: true, data: user };
}`;

      const patterns: PatternConfig = {
        requireZodImport: false,
        requireResultType: true,
        requireExplicitExports: false,
      };

      const program = createSourceFile('parser.ts', content).pipe(
        Effect.flatMap((source) => detectDrift(source, patterns)),
        Effect.provide(AstEngineLive)
      );

      const result = await Effect.runPromise(program);
      const resultIssues = result.issues.filter((i) => i.type === 'missing-result-type');
      expect(resultIssues.length).toBe(0);
    });
  });

  describe('DriftReport', () => {
    test('includes file path in report', async () => {
      const content = `const x = 1;`;

      const patterns: PatternConfig = {
        requireZodImport: false,
        requireResultType: false,
        requireExplicitExports: false,
      };

      const program = createSourceFile('myfile.ts', content).pipe(
        Effect.flatMap((source) => detectDrift(source, patterns)),
        Effect.provide(AstEngineLive)
      );

      const result = await Effect.runPromise(program);
      expect(result.filePath).toContain('myfile.ts');
    });

    test('categorizes issues by severity', async () => {
      const content = `export const schema = z.string();`; // Missing import

      const patterns: PatternConfig = {
        requireZodImport: true,
        requireResultType: false,
        requireExplicitExports: false,
      };

      const program = createSourceFile('test.ts', content).pipe(
        Effect.flatMap((source) => detectDrift(source, patterns)),
        Effect.provide(AstEngineLive)
      );

      const result = await Effect.runPromise(program);
      expect(result.issues.every((i) => i.severity === 'error' || i.severity === 'warning')).toBe(
        true
      );
    });
  });
});
