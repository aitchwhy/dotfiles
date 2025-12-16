/**
 * Pattern Engine Tests
 *
 * Tests for the ast-grep based pattern matching service.
 * Following TDD: Red → Green → Refactor
 */
import { describe, expect, test } from 'bun:test';
import { Effect } from 'effect';
import {
  applyAllFixes,
  applyRule,
  applyRules,
  detectLanguage,
  findPattern,
  type PatternEngine,
  PatternEngineLive,
  type PatternMatch,
  type PatternRule,
  parseSource,
} from './patterns';

// =============================================================================
// Helper to run Effects with PatternEngineLive
// =============================================================================

const runWithEngine = <A, E>(effect: Effect.Effect<A, E, PatternEngine>) =>
  Effect.runPromise(Effect.provide(effect, PatternEngineLive));

// =============================================================================
// parseSource Tests
// =============================================================================

describe('parseSource', () => {
  test('parses TypeScript source code', async () => {
    const source = `const x: number = 42;`;

    const root = await runWithEngine(parseSource(source, 'TypeScript'));

    expect(root).toBeDefined();
    expect(root.root()).toBeDefined();
  });

  test('parses JavaScript source code', async () => {
    const source = `const x = 42;`;

    const root = await runWithEngine(parseSource(source, 'JavaScript'));

    expect(root).toBeDefined();
  });

  test('parses TSX source code', async () => {
    const source = `const App = () => <div>Hello</div>;`;

    const root = await runWithEngine(parseSource(source, 'Tsx'));

    expect(root).toBeDefined();
  });
});

// =============================================================================
// findPattern Tests
// =============================================================================

describe('findPattern', () => {
  test('finds console.log calls', async () => {
    const source = `
      console.log('hello');
      console.log('world');
      console.error('error');
    `;

    const root = await runWithEngine(parseSource(source, 'TypeScript'));
    const matches = await runWithEngine(findPattern(root, 'console.log($ARG)'));

    expect(matches.length).toBe(2);
  });

  test('finds function declarations', async () => {
    const source = `
      function foo() { return 1; }
      function bar() { return 2; }
      const baz = () => 3;
    `;

    const root = await runWithEngine(parseSource(source, 'TypeScript'));
    const matches = await runWithEngine(findPattern(root, 'function $NAME() { $$$BODY }'));

    expect(matches.length).toBe(2);
  });

  test('returns empty array when no matches', async () => {
    const source = `const x = 42;`;

    const root = await runWithEngine(parseSource(source, 'TypeScript'));
    const matches = await runWithEngine(findPattern(root, 'console.log($ARG)'));

    expect(matches.length).toBe(0);
  });
});

// =============================================================================
// applyRule Tests
// =============================================================================

describe('applyRule', () => {
  test('applies pattern-based rule and returns matches', async () => {
    const source = `
      createMachine({ id: 'test' });
    `;

    const rule: PatternRule = {
      id: 'xstate-require-setup',
      language: 'TypeScript',
      severity: 'error',
      message: 'Use setup().createMachine() instead',
      rule: {
        pattern: 'createMachine($CONFIG)',
      },
    };

    const root = await runWithEngine(parseSource(source, 'TypeScript'));
    const matches = await runWithEngine(applyRule(root, rule));

    expect(matches.length).toBe(1);
    expect(matches[0]?.rule).toBe('xstate-require-setup');
    expect(matches[0]?.severity).toBe('error');
    expect(matches[0]?.node.text).toContain('createMachine');
  });

  test('includes fix when rule has fix template', async () => {
    const source = `console.log('debug');`;

    const rule: PatternRule = {
      id: 'no-console-log',
      language: 'TypeScript',
      severity: 'warning',
      message: 'Use logger instead of console.log',
      rule: {
        pattern: 'console.log($ARG)',
      },
      fix: 'logger.debug($ARG)',
    };

    const root = await runWithEngine(parseSource(source, 'TypeScript'));
    const matches = await runWithEngine(applyRule(root, rule));

    expect(matches.length).toBe(1);
    expect(matches[0]?.fix).toBeDefined();
    expect(matches[0]?.fix?.replacement).toContain('logger.debug');
  });

  test('returns empty array when rule does not match', async () => {
    const source = `const x = 42;`;

    const rule: PatternRule = {
      id: 'no-console-log',
      language: 'TypeScript',
      severity: 'warning',
      message: 'Use logger instead of console.log',
      rule: {
        pattern: 'console.log($ARG)',
      },
    };

    const root = await runWithEngine(parseSource(source, 'TypeScript'));
    const matches = await runWithEngine(applyRule(root, rule));

    expect(matches.length).toBe(0);
  });
});

// =============================================================================
// applyRules Tests
// =============================================================================

describe('applyRules', () => {
  test('applies multiple rules to source', async () => {
    const source = `
      console.log('hello');
      throw new Error('oops');
    `;

    const rules: PatternRule[] = [
      {
        id: 'no-console-log',
        language: 'TypeScript',
        severity: 'warning',
        message: 'Use logger',
        rule: { pattern: 'console.log($ARG)' },
      },
      {
        id: 'no-throw',
        language: 'TypeScript',
        severity: 'error',
        message: 'Use Result type',
        rule: { pattern: 'throw new Error($MSG)' },
      },
    ];

    const result = await runWithEngine(applyRules(source, 'TypeScript', rules));

    expect(result.matches.length).toBe(2);
    expect(result.hasErrors).toBe(true);
    expect(result.hasWarnings).toBe(true);
  });

  test('skips rules for different languages', async () => {
    const source = `console.log('hello');`;

    const rules: PatternRule[] = [
      {
        id: 'ts-rule',
        language: 'TypeScript',
        severity: 'warning',
        message: 'TS warning',
        rule: { pattern: 'console.log($ARG)' },
      },
      {
        id: 'js-rule',
        language: 'JavaScript',
        severity: 'error',
        message: 'JS error',
        rule: { pattern: 'console.log($ARG)' },
      },
    ];

    const result = await runWithEngine(applyRules(source, 'TypeScript', rules));

    // Only TypeScript rule should match
    expect(result.matches.length).toBe(1);
    expect(result.matches[0]?.rule).toBe('ts-rule');
  });
});

// =============================================================================
// applyAllFixes Tests
// =============================================================================

describe('applyAllFixes', () => {
  test('applies fixes in correct order (reverse position)', async () => {
    const source = `console.log('a'); console.log('b');`;

    const matches: PatternMatch[] = [
      {
        rule: 'test',
        severity: 'warning',
        message: 'test',
        node: {
          text: "console.log('a')",
          range: {
            start: { line: 0, column: 0, index: 0 },
            end: { line: 0, column: 16, index: 16 },
          },
          kind: 'call_expression',
        },
        captures: {},
        fix: { replacement: "logger.debug('a')", description: 'test' },
      },
      {
        rule: 'test',
        severity: 'warning',
        message: 'test',
        node: {
          text: "console.log('b')",
          range: {
            start: { line: 0, column: 18, index: 18 },
            end: { line: 0, column: 34, index: 34 },
          },
          kind: 'call_expression',
        },
        captures: {},
        fix: { replacement: "logger.debug('b')", description: 'test' },
      },
    ];

    const result = await runWithEngine(applyAllFixes(source, matches));

    expect(result).toContain("logger.debug('a')");
    expect(result).toContain("logger.debug('b')");
    expect(result).not.toContain('console.log');
  });

  test('skips matches without fixes', async () => {
    const source = `console.log('a');`;

    const matches: PatternMatch[] = [
      {
        rule: 'test',
        severity: 'warning',
        message: 'test',
        node: {
          text: "console.log('a')",
          range: {
            start: { line: 0, column: 0, index: 0 },
            end: { line: 0, column: 16, index: 16 },
          },
          kind: 'call_expression',
        },
        captures: {},
        // No fix provided
      },
    ];

    const result = await runWithEngine(applyAllFixes(source, matches));

    // Should remain unchanged
    expect(result).toBe(source);
  });
});

// =============================================================================
// detectLanguage Tests
// =============================================================================

describe('detectLanguage', () => {
  test('detects TypeScript from .ts extension', () => {
    expect(detectLanguage('file.ts')).toBe('TypeScript');
  });

  test('detects Tsx from .tsx extension', () => {
    expect(detectLanguage('file.tsx')).toBe('Tsx');
  });

  test('detects JavaScript from .js extension', () => {
    expect(detectLanguage('file.js')).toBe('JavaScript');
  });

  test('detects JavaScript from .mjs extension', () => {
    expect(detectLanguage('file.mjs')).toBe('JavaScript');
  });

  test('defaults to TypeScript for unknown extensions', () => {
    expect(detectLanguage('file.unknown')).toBe('TypeScript');
  });
});

// =============================================================================
// Integration Tests
// =============================================================================

describe('PatternEngine Integration', () => {
  test('full workflow: parse → apply rules → get matches', async () => {
    const source = `
      import { createMachine } from 'xstate';

      const machine = createMachine({
        id: 'counter',
        initial: 'idle',
      });
    `;

    const rules: PatternRule[] = [
      {
        id: 'xstate-v5-setup',
        language: 'TypeScript',
        severity: 'error',
        message: 'XState v5: Use setup().createMachine()',
        rule: { pattern: 'createMachine($CONFIG)' },
        fix: 'setup({}).createMachine($CONFIG)',
      },
    ];

    const result = await runWithEngine(applyRules(source, 'TypeScript', rules));

    expect(result.hasErrors).toBe(true);
    expect(result.matches.length).toBe(1);
    expect(result.matches[0]?.fix?.replacement).toContain('setup({})');
  });

  test('detects Hono routes without zValidator', async () => {
    const source = `
      app.post('/users', async (c) => {
        const body = await c.req.json();
        return c.json({ ok: true });
      });
    `;

    const rules: PatternRule[] = [
      {
        id: 'hono-require-zvalidator',
        language: 'TypeScript',
        severity: 'error',
        message: 'POST routes must use zValidator()',
        rule: { pattern: 'app.post($PATH, async ($CTX) => { $$$BODY })' },
      },
    ];

    const result = await runWithEngine(applyRules(source, 'TypeScript', rules));

    expect(result.hasErrors).toBe(true);
    expect(result.matches[0]?.rule).toBe('hono-require-zvalidator');
  });
});
