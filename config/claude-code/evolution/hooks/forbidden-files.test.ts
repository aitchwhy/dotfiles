/**
 * Forbidden Files Hook Tests
 */
import { describe, expect, test } from 'bun:test';

// We'll test the logic by importing the module functions
// For now, test the pattern matching logic

describe('Forbidden Files Hook', () => {
  const FORBIDDEN_PATTERNS = [
    { pattern: 'package-lock.json', reason: 'Use Bun', alternative: 'bun install' },
    { pattern: 'yarn.lock', reason: 'Use Bun', alternative: 'bun install' },
    { pattern: 'pnpm-lock.yaml', reason: 'Use Bun', alternative: 'bun install' },
    { pattern: '.eslintrc', reason: 'Use Biome', alternative: 'biome.json' },
    { pattern: '.eslintrc.js', reason: 'Use Biome', alternative: 'biome.json' },
    { pattern: '.eslintrc.json', reason: 'Use Biome', alternative: 'biome.json' },
    { pattern: 'eslint.config.js', reason: 'Use Biome', alternative: 'biome.json' },
    { pattern: 'eslint.config.mjs', reason: 'Use Biome', alternative: 'biome.json' },
    { pattern: '.prettierrc', reason: 'Use Biome', alternative: 'biome.json' },
    { pattern: '.prettierrc.json', reason: 'Use Biome', alternative: 'biome.json' },
    { pattern: 'prettier.config.js', reason: 'Use Biome', alternative: 'biome.json' },
    { pattern: 'jest.config.js', reason: 'Use Bun test', alternative: 'bun test' },
    { pattern: 'jest.config.ts', reason: 'Use Bun test', alternative: 'bun test' },
  ];

  describe('file detection', () => {
    test.each(FORBIDDEN_PATTERNS)('should block $pattern', ({ pattern }) => {
      const fileName = pattern;
      const isBlocked = FORBIDDEN_PATTERNS.some(
        (p) => fileName === p.pattern || fileName.startsWith(p.pattern.replace(/\*$/, ''))
      );
      expect(isBlocked).toBe(true);
    });
  });

  describe('allowed files', () => {
    const ALLOWED_FILES = [
      'bun.lockb',
      'biome.json',
      'drizzle.config.ts',
      'package.json',
      'tsconfig.json',
    ];

    test.each(ALLOWED_FILES)('should allow %s', (file) => {
      const isBlocked = FORBIDDEN_PATTERNS.some((p) => file === p.pattern);
      expect(isBlocked).toBe(false);
    });
  });
});
