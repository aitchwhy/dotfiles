/**
 * Tier 2: Formal Verification (Stubbed)
 *
 * Future implementation will include:
 * - Contract validation (preconditions, postconditions)
 * - Property-based test detection
 * - Branded type verification
 * - Effect Schema conformance checks
 */

import { readdir, readFile } from 'node:fs/promises';
import { extname, join } from 'node:path';
import { Effect } from 'effect';
import type { TierResult, VerificationOptions } from '../index.js';

// =============================================================================
// Basic Checks (Placeholder)
// =============================================================================

/**
 * Check for common formal verification patterns
 */
const checkFormalPatterns = (content: string): { found: string[]; missing: string[] } => {
  const found: string[] = [];
  const missing: string[] = [];

  // Check for branded types
  if (content.includes('Brand<') || content.includes('& { readonly __brand')) {
    found.push('branded-types');
  }

  // Check for satisfies pattern (TypeScript-first Zod)
  if (content.includes('satisfies z.ZodType') || content.includes('satisfies Schema.Schema')) {
    found.push('satisfies-pattern');
  }

  // Check for property-based tests
  if (
    content.includes('test.prop') ||
    content.includes('fc.assert') ||
    content.includes('fc.property')
  ) {
    found.push('property-tests');
  }

  // Check for Effect-TS error handling
  if (content.includes('Effect.fail(') || content.includes('Effect.catchAll(')) {
    found.push('effect-errors');
  }

  // Check for Result types
  if (content.includes('Result<') || content.includes(': Result')) {
    found.push('result-types');
  }

  return { found, missing };
};

/**
 * Find TypeScript files
 */
const findTsFiles = async (dir: string): Promise<string[]> => {
  const files: string[] = [];

  try {
    const entries = await readdir(dir, { withFileTypes: true });

    for (const entry of entries) {
      const name = entry.name;
      const fullPath = join(dir, name);

      if (name.startsWith('.') || name === 'node_modules') {
        continue;
      }

      if (entry.isDirectory()) {
        files.push(...(await findTsFiles(fullPath)));
      } else {
        const ext = extname(name);
        if (['.ts', '.tsx'].includes(ext)) {
          files.push(fullPath);
        }
      }
    }
  } catch {
    // Directory doesn't exist
  }

  return files;
};

// =============================================================================
// Tier Implementation
// =============================================================================

/**
 * Run Tier 2: Formal Verification
 *
 * Currently provides basic pattern detection.
 * Full implementation planned for future versions.
 */
export const runFormalTier = (opts: VerificationOptions): Effect.Effect<TierResult, Error> =>
  Effect.gen(function* () {
    const startTime = Date.now();
    const details: string[] = [];
    let totalWarnings = 0;

    const srcPath = join(opts.path, 'src');
    const files = yield* Effect.tryPromise({
      try: () => findTsFiles(srcPath),
      catch: () => new Error('Failed to find files'),
    }).pipe(Effect.catchAll(() => Effect.succeed([] as string[])));

    if (files.length === 0) {
      details.push('No source files found');
      return {
        tier: 'formal' as const,
        passed: true,
        errors: 0,
        warnings: 0,
        details,
        duration: Date.now() - startTime,
      };
    }

    // Aggregate pattern usage across codebase
    const allFound = new Set<string>();

    for (const file of files.slice(0, 100)) {
      // Limit for performance
      const content = yield* Effect.tryPromise({
        try: () => readFile(file, 'utf-8'),
        catch: () => new Error('Failed to read file'),
      }).pipe(Effect.catchAll(() => Effect.succeed('')));

      if (content) {
        const { found } = checkFormalPatterns(content);
        found.forEach((p) => allFound.add(p));
      }
    }

    // Report what was found
    if (allFound.size > 0) {
      details.push(`Formal patterns detected: ${Array.from(allFound).join(', ')}`);
    } else {
      details.push('No formal verification patterns detected');
      details.push('Consider adding: branded types, satisfies pattern, property tests');
      totalWarnings = 1;
    }

    // This tier is informational - doesn't block
    return {
      tier: 'formal' as const,
      passed: true, // Always passes (informational only)
      errors: 0,
      warnings: totalWarnings,
      details,
      duration: Date.now() - startTime,
    };
  });
