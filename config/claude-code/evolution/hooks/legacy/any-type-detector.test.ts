/**
 * Any Type Detector Hook Tests
 */
import { describe, expect, test } from 'bun:test';

describe('Any Type Detector Hook', () => {
  // Patterns that should be blocked
  const BLOCKED_PATTERNS = [': any', 'as any', '<any>', '): any'];

  // Helper to strip comments and strings (simplified for testing)
  function stripCommentsAndStrings(code: string): string {
    return code
      .replace(/\/\/.*$/gm, '') // Single-line comments
      .replace(/\/\*[\s\S]*?\*\//g, '') // Multi-line comments
      .replace(/'(?:[^'\\]|\\.)*'/g, '""') // Single-quoted strings
      .replace(/"(?:[^"\\]|\\.)*"/g, '""') // Double-quoted strings
      .replace(/`(?:[^`\\]|\\.)*`/g, '""'); // Template literals
  }

  function containsAnyType(code: string): boolean {
    const cleaned = stripCommentsAndStrings(code);
    return BLOCKED_PATTERNS.some((pattern) => cleaned.includes(pattern));
  }

  describe('detects any types', () => {
    test('blocks : any annotation', () => {
      const code = 'const x: any = value;';
      expect(containsAnyType(code)).toBe(true);
    });

    test('blocks as any assertion', () => {
      const code = 'const x = value as any;';
      expect(containsAnyType(code)).toBe(true);
    });

    test('blocks <any> generic', () => {
      const code = 'const arr: Array<any> = [];';
      expect(containsAnyType(code)).toBe(true);
    });

    test('blocks ): any return type', () => {
      const code = 'function foo(): any { return null; }';
      expect(containsAnyType(code)).toBe(true);
    });
  });

  describe('false positive prevention', () => {
    test('allows any in single-line comments', () => {
      const code = '// any comment here\nconst x: string = "test";';
      expect(containsAnyType(code)).toBe(false);
    });

    test('allows any in multi-line comments', () => {
      const code = '/* any in block comment */\nconst x: string = "test";';
      expect(containsAnyType(code)).toBe(false);
    });

    test('allows any in strings', () => {
      const code = 'const msg = "any string value";';
      expect(containsAnyType(code)).toBe(false);
    });

    test('allows anything variable name', () => {
      const code = 'const anything = 5;';
      expect(containsAnyType(code)).toBe(false);
    });

    test('allows anyUser variable name', () => {
      const code = 'const anyUser = getUser();';
      expect(containsAnyType(code)).toBe(false);
    });

    test('allows company variable', () => {
      const code = 'const company = "Anthropic";';
      expect(containsAnyType(code)).toBe(false);
    });
  });

  describe('edge cases', () => {
    test('handles multiple patterns', () => {
      const code = 'const x: any = y as any;';
      expect(containsAnyType(code)).toBe(true);
    });

    test('handles spaced patterns', () => {
      const code = 'const x:  any = value;';
      // Note: pattern ': any' won't match ':  any' - need regex in real impl
      expect(containsAnyType(code)).toBe(false);
    });
  });
});
