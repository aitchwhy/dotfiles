/**
 * Tier 1: Pattern Knowledge
 *
 * AST-based drift detection and code smell analysis:
 * - Loads YAML rules from rules/ directory
 * - Applies patterns via ast-grep
 * - Checks for common anti-patterns (any, ts-ignore, etc.)
 */

import { readdir, readFile } from 'node:fs/promises';
import { extname, join } from 'node:path';
import { Effect } from 'effect';
import {
  applyRules,
  detectLanguage,
  loadRulesFromDirectory,
  PatternEngineLive,
} from '../../layers/patterns.js';
import type { TierResult, VerificationOptions } from '../index.js';

// =============================================================================
// Quick Checks (Regex-based for speed)
// =============================================================================

type QuickCheck = {
  readonly name: string;
  readonly pattern: RegExp;
  readonly severity: 'error' | 'warning';
  readonly message: string;
};

const QUICK_CHECKS: readonly QuickCheck[] = [
  {
    name: 'any-type',
    pattern: /:\s*any\b|as\s+any\b/g,
    severity: 'error',
    message: 'Avoid using `any` type - use `unknown` with type guards',
  },
  {
    name: 'ts-ignore',
    pattern: /@ts-ignore|@ts-expect-error/g,
    severity: 'warning',
    message: 'Avoid @ts-ignore - fix the underlying type issue',
  },
  {
    name: 'console-log',
    pattern: /console\.(log|warn|error)\(/g,
    severity: 'warning',
    message: 'Remove console statements before committing',
  },
  {
    name: 'debugger',
    pattern: /\bdebugger\b/g,
    severity: 'error',
    message: 'Remove debugger statements',
  },
  {
    name: 'throw-string',
    pattern: /throw\s+['"`]/g,
    severity: 'error',
    message: 'Throw Error objects, not strings',
  },
  {
    name: 'empty-catch',
    pattern: /catch\s*\([^)]*\)\s*\{\s*\}/g,
    severity: 'error',
    message: 'Empty catch blocks swallow errors',
  },
];

// =============================================================================
// Helpers
// =============================================================================

/**
 * Recursively find all TypeScript files
 */
const findTsFiles = async (dir: string): Promise<string[]> => {
  const files: string[] = [];

  try {
    const entries = await readdir(dir, { withFileTypes: true });

    for (const entry of entries) {
      const name = entry.name;
      const fullPath = join(dir, name);

      // Skip node_modules and hidden directories
      if (name.startsWith('.') || name === 'node_modules') {
        continue;
      }

      if (entry.isDirectory()) {
        files.push(...(await findTsFiles(fullPath)));
      } else {
        const ext = extname(name);
        if (['.ts', '.tsx', '.js', '.jsx'].includes(ext)) {
          files.push(fullPath);
        }
      }
    }
  } catch {
    // Directory doesn't exist or not readable
  }

  return files;
};

/**
 * Run quick regex checks on a file
 */
const runQuickChecks = (
  content: string,
  filePath: string
): { errors: number; warnings: number; details: string[] } => {
  let errors = 0;
  let warnings = 0;
  const details: string[] = [];

  for (const check of QUICK_CHECKS) {
    const matches = content.match(check.pattern);
    if (matches && matches.length > 0) {
      if (check.severity === 'error') {
        errors += matches.length;
      } else {
        warnings += matches.length;
      }
      details.push(`${filePath}: ${check.name} (${matches.length} occurrences) - ${check.message}`);
    }
  }

  return { errors, warnings, details };
};

// =============================================================================
// Tier Implementation
// =============================================================================

/**
 * Run Tier 1: Pattern Knowledge
 */
export const runPatternsTier = (opts: VerificationOptions): Effect.Effect<TierResult, Error> =>
  Effect.gen(function* () {
    const startTime = Date.now();
    const details: string[] = [];
    let totalErrors = 0;
    let totalWarnings = 0;

    // Find all TypeScript files
    const srcPath = join(opts.path, 'src');
    const files = yield* Effect.tryPromise({
      try: () => findTsFiles(srcPath),
      catch: () => new Error('Failed to find files'),
    }).pipe(Effect.catchAll(() => Effect.succeed([] as string[])));

    if (files.length === 0) {
      details.push('No source files found in src/');
      return {
        tier: 'patterns' as const,
        passed: true,
        errors: 0,
        warnings: 0,
        details,
        duration: Date.now() - startTime,
      };
    }

    details.push(`Scanning ${files.length} files...`);

    // Run quick checks on each file
    for (const file of files) {
      const content = yield* Effect.tryPromise({
        try: () => readFile(file, 'utf-8'),
        catch: () => new Error('Failed to read file'),
      }).pipe(Effect.catchAll(() => Effect.succeed('')));

      if (content) {
        const result = runQuickChecks(content, file.replace(opts.path + '/', ''));
        totalErrors += result.errors;
        totalWarnings += result.warnings;
        details.push(...result.details);
      }
    }

    // Try to load and apply YAML rules if rules/ directory exists
    const rulesPath = join(opts.path, 'rules');
    const rulesExist = yield* Effect.tryPromise({
      try: async () => {
        await readdir(rulesPath);
        return true;
      },
      catch: () => new Error('Rules directory not found'),
    }).pipe(Effect.catchAll(() => Effect.succeed(false)));

    if (rulesExist) {
      const loadRulesEffect = loadRulesFromDirectory(rulesPath).pipe(
        Effect.provide(PatternEngineLive)
      );

      const rules = yield* loadRulesEffect.pipe(Effect.catchAll(() => Effect.succeed([] as const)));

      if (rules.length > 0) {
        details.push(`Loaded ${rules.length} pattern rules`);

        // Apply rules to each file
        for (const file of files.slice(0, 50)) {
          // Limit to first 50 files for performance
          const content = yield* Effect.tryPromise({
            try: () => readFile(file, 'utf-8'),
            catch: () => new Error('Failed to read file'),
          }).pipe(Effect.catchAll(() => Effect.succeed('')));

          if (content) {
            const language = detectLanguage(file);
            const applyResult = yield* applyRules(content, language, rules, file).pipe(
              Effect.provide(PatternEngineLive),
              Effect.catchAll(() =>
                Effect.succeed({
                  filePath: file,
                  matches: [],
                  hasErrors: false,
                  hasWarnings: false,
                })
              )
            );

            if (applyResult.hasErrors) {
              totalErrors += applyResult.matches.filter((m) => m.severity === 'error').length;
            }
            if (applyResult.hasWarnings) {
              totalWarnings += applyResult.matches.filter((m) => m.severity === 'warning').length;
            }

            for (const match of applyResult.matches.slice(0, 3)) {
              details.push(`${file}:${match.node.range.start.line}: ${match.message}`);
            }
          }
        }
      }
    }

    return {
      tier: 'patterns' as const,
      passed: totalErrors === 0,
      errors: totalErrors,
      warnings: totalWarnings,
      details: details.slice(0, 20), // Limit output
      duration: Date.now() - startTime,
    };
  });
