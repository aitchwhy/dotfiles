/**
 * Stack Service - Stack Compliance Checking
 *
 * Validates package.json files against STACK SSOT.
 * Replaces stack-enforcer.ts and enforce-versions.ts hooks.
 */

import { existsSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { Effect } from 'effect';
import { STACK } from '@/stack/versions';

// =============================================================================
// Types (TypeScript first)
// =============================================================================

export type StackViolation = {
  readonly file: string;
  readonly type: 'forbidden_dep' | 'version_drift';
  readonly package: string;
  readonly message: string;
  readonly severity: 'high' | 'medium';
  readonly suggestion?: string;
};

export type StackCheckResult = {
  readonly violations: readonly StackViolation[];
  readonly filesChecked: number;
  readonly passed: boolean;
};

export type StackFixResult = {
  readonly fixed: readonly string[];
  readonly skipped: readonly string[];
  readonly result: StackCheckResult;
};

// =============================================================================
// Configuration (extracted from stack-enforcer.ts)
// =============================================================================

/** Forbidden dependencies - these have better alternatives */
export const FORBIDDEN_DEPS: Record<string, string> = {
  // lodash -> Use native methods or Effect
  lodash: 'Use native Array/Object methods or Effect utilities',
  'lodash-es': 'Use native Array/Object methods or Effect utilities',
  underscore: 'Use native Array/Object methods or Effect utilities',

  // express -> Use Hono
  express: 'Use Hono instead (Web Standards, faster, smaller)',
  fastify: 'Use Hono instead (Web Standards, portable)',
  koa: 'Use Hono instead (Web Standards, portable)',

  // prisma -> Use Drizzle
  prisma: 'Use Drizzle ORM instead (type-safe, SQL-first)',
  '@prisma/client': 'Use Drizzle ORM instead (type-safe, SQL-first)',

  // mongoose -> Use Drizzle + PostgreSQL
  mongoose: 'Use Drizzle + PostgreSQL instead of MongoDB',

  // moment -> Use native Date or Temporal
  moment: 'Use native Date API or Temporal (Stage 3)',
  'moment-timezone': 'Use native Date API or Temporal (Stage 3)',

  // axios -> Use fetch (native)
  axios: 'Use native fetch() or Effect HttpClient',

  // jest -> Use Vitest
  jest: 'Use Vitest instead (Vite-native, faster)',
  '@jest/globals': 'Use Vitest instead (Vite-native, faster)',

  // eslint -> Use Biome or OXLint
  eslint: 'Use Biome or OXLint instead (faster, unified)',
  prettier: 'Use Biome instead (unified format + lint)',

  // redux -> Use XState or Zustand
  redux: 'Use XState (state machines) or Zustand (simple state)',
  '@reduxjs/toolkit': 'Use XState (state machines) or Zustand (simple state)',

  // webpack -> Use Vite
  webpack: 'Use Vite instead (ESM-native, faster)',
  'webpack-cli': 'Use Vite instead (ESM-native, faster)',
};

/** Key packages that should be checked against STACK.npm */
export const ENFORCED_PACKAGES = [
  'zod',
  'typescript',
  '@biomejs/biome',
  '@types/bun',
  'effect',
  '@effect/cli',
  '@effect/platform',
  '@effect/platform-node',
  'hono',
  'drizzle-orm',
  'drizzle-kit',
  'react',
  'react-dom',
  '@tanstack/react-router',
  'tailwindcss',
  'xstate',
  '@xstate/react',
  'vitest',
  '@playwright/test',
  'better-auth',
] as const;

// =============================================================================
// Helper Functions
// =============================================================================

/**
 * Find all package.json files recursively, skipping node_modules and hidden dirs
 */
function findPackageJsonFiles(dir: string, maxDepth = 3): string[] {
  const files: string[] = [];

  function walk(currentDir: string, depth: number) {
    if (depth > maxDepth) return;

    try {
      const entries = readdirSync(currentDir);
      for (const entry of entries) {
        // Skip node_modules and hidden directories
        if (entry === 'node_modules' || entry.startsWith('.')) continue;

        const fullPath = join(currentDir, entry);
        try {
          const stat = statSync(fullPath);
          if (stat.isDirectory()) {
            walk(fullPath, depth + 1);
          } else if (entry === 'package.json') {
            files.push(fullPath);
          }
        } catch {
          // Skip inaccessible files
        }
      }
    } catch {
      // Skip inaccessible directories
    }
  }

  walk(dir, 0);
  return files;
}

/**
 * Check for forbidden dependencies in a package.json
 */
function checkForbiddenDeps(pkgPath: string, pkgDeps: Record<string, string>): StackViolation[] {
  const violations: StackViolation[] = [];

  for (const [dep, reason] of Object.entries(FORBIDDEN_DEPS)) {
    if (pkgDeps[dep]) {
      violations.push({
        file: pkgPath,
        type: 'forbidden_dep',
        package: dep,
        message: `${dep} is forbidden. ${reason}`,
        severity: 'high',
        suggestion: reason,
      });
    }
  }

  return violations;
}

/**
 * Check for version drift against STACK.npm
 */
function checkVersionDrift(
  pkgPath: string,
  pkgDeps: Record<string, string>,
  npmVersions: Record<string, string>
): StackViolation[] {
  const violations: StackViolation[] = [];

  for (const name of ENFORCED_PACKAGES) {
    const expectedVersion = npmVersions[name];
    if (!expectedVersion) continue;

    const actualVersion = pkgDeps[name];
    if (actualVersion && !actualVersion.includes(expectedVersion)) {
      violations.push({
        file: pkgPath,
        type: 'version_drift',
        package: name,
        message: `${name}: expected ${expectedVersion}, got ${actualVersion}`,
        severity: 'medium',
        suggestion: `Update to ^${expectedVersion}`,
      });
    }
  }

  return violations;
}

/**
 * Analyze a single package.json file
 */
function analyzePackageJson(
  pkgPath: string,
  npmVersions: Record<string, string>
): StackViolation[] {
  const violations: StackViolation[] = [];

  try {
    const content = readFileSync(pkgPath, 'utf-8');
    const pkg = JSON.parse(content) as {
      dependencies?: Record<string, string>;
      devDependencies?: Record<string, string>;
    };

    const allDeps = {
      ...(pkg.dependencies ?? {}),
      ...(pkg.devDependencies ?? {}),
    };

    violations.push(...checkForbiddenDeps(pkgPath, allDeps));
    violations.push(...checkVersionDrift(pkgPath, allDeps, npmVersions));
  } catch {
    // Skip unreadable/unparseable files
  }

  return violations;
}

/**
 * Fix version drift in a package.json file
 */
function fixPackageJsonVersions(pkgPath: string, npmVersions: Record<string, string>): string[] {
  const fixed: string[] = [];

  try {
    const content = readFileSync(pkgPath, 'utf-8');
    const pkg = JSON.parse(content) as {
      dependencies?: Record<string, string>;
      devDependencies?: Record<string, string>;
    };

    let modified = false;

    // Fix dependencies
    if (pkg.dependencies) {
      for (const name of Object.keys(pkg.dependencies)) {
        const expected = npmVersions[name];
        const current = pkg.dependencies[name];
        if (expected && current && !current.includes(expected)) {
          pkg.dependencies[name] = `^${expected}`;
          fixed.push(`${name}: ${current} -> ^${expected}`);
          modified = true;
        }
      }
    }

    // Fix devDependencies
    if (pkg.devDependencies) {
      for (const name of Object.keys(pkg.devDependencies)) {
        const expected = npmVersions[name];
        const current = pkg.devDependencies[name];
        if (expected && current && !current.includes(expected)) {
          pkg.devDependencies[name] = `^${expected}`;
          fixed.push(`${name}: ${current} -> ^${expected}`);
          modified = true;
        }
      }
    }

    if (modified) {
      writeFileSync(pkgPath, `${JSON.stringify(pkg, null, 2)}\n`, 'utf-8');
    }
  } catch {
    // Skip unreadable/unparseable files
  }

  return fixed;
}

// =============================================================================
// Service Functions (Effect-based)
// =============================================================================

/**
 * Check all package.json files for stack compliance
 */
export const checkAll = (path: string, maxDepth = 3): Effect.Effect<StackCheckResult, Error> =>
  Effect.gen(function* () {
    // Verify STACK is loaded
    if (!STACK.npm || Object.keys(STACK.npm).length === 0) {
      return yield* Effect.fail(new Error('STACK.npm not loaded'));
    }

    const packageJsonFiles = findPackageJsonFiles(path, maxDepth);

    if (packageJsonFiles.length === 0) {
      return {
        violations: [],
        filesChecked: 0,
        passed: true,
      };
    }

    const allViolations: StackViolation[] = [];
    for (const pkgPath of packageJsonFiles) {
      allViolations.push(...analyzePackageJson(pkgPath, STACK.npm));
    }

    return {
      violations: allViolations,
      filesChecked: packageJsonFiles.length,
      passed: allViolations.length === 0,
    };
  });

/**
 * Fix version drift in all package.json files
 */
export const fixVersions = (path: string, maxDepth = 3): Effect.Effect<StackFixResult, Error> =>
  Effect.gen(function* () {
    // Verify STACK is loaded
    if (!STACK.npm || Object.keys(STACK.npm).length === 0) {
      return yield* Effect.fail(new Error('STACK.npm not loaded'));
    }

    const packageJsonFiles = findPackageJsonFiles(path, maxDepth);
    const allFixed: string[] = [];
    const skipped: string[] = [];

    for (const pkgPath of packageJsonFiles) {
      if (!existsSync(pkgPath)) {
        skipped.push(pkgPath);
        continue;
      }

      const fixedItems = fixPackageJsonVersions(pkgPath, STACK.npm);
      allFixed.push(...fixedItems.map((item) => `${pkgPath}: ${item}`));
    }

    // Re-check after fixes
    const checkResult = yield* checkAll(path, maxDepth);

    return {
      fixed: allFixed,
      skipped,
      result: checkResult,
    };
  });

// =============================================================================
// Formatting
// =============================================================================

/**
 * Format stack check result for MCP output
 */
export function formatStackResult(result: StackCheckResult | StackFixResult): string {
  const isFixResult = 'fixed' in result;
  const checkResult = isFixResult
    ? (result as StackFixResult).result
    : (result as StackCheckResult);

  const lines: string[] = [];
  lines.push('━'.repeat(50));
  lines.push('  SIGNET STACK COMPLIANCE');
  lines.push('━'.repeat(50));
  lines.push('');

  if (isFixResult) {
    const fixResult = result as StackFixResult;
    if (fixResult.fixed.length > 0) {
      lines.push('📦 Fixed versions:');
      for (const fix of fixResult.fixed.slice(0, 10)) {
        lines.push(`  • ${fix}`);
      }
      if (fixResult.fixed.length > 10) {
        lines.push(`  ... and ${fixResult.fixed.length - 10} more`);
      }
      lines.push('');
    }
  }

  lines.push(`Files checked: ${checkResult.filesChecked}`);
  lines.push(`Status: ${checkResult.passed ? '✅ PASS' : '❌ FAIL'}`);
  lines.push('');

  if (checkResult.violations.length > 0) {
    const high = checkResult.violations.filter((v) => v.severity === 'high');
    const medium = checkResult.violations.filter((v) => v.severity === 'medium');

    if (high.length > 0) {
      lines.push(`❌ FORBIDDEN DEPENDENCIES (${high.length}):`);
      for (const v of high.slice(0, 5)) {
        lines.push(`  • ${v.message}`);
        lines.push(`    in ${v.file}`);
      }
      if (high.length > 5) {
        lines.push(`  ... and ${high.length - 5} more`);
      }
      lines.push('');
    }

    if (medium.length > 0) {
      lines.push(`⚠️  VERSION DRIFT (${medium.length}):`);
      for (const v of medium.slice(0, 5)) {
        lines.push(`  • ${v.message}`);
        lines.push(`    in ${v.file}`);
      }
      if (medium.length > 5) {
        lines.push(`  ... and ${medium.length - 5} more`);
      }
      lines.push('');
    }
  }

  const ssotVersion = STACK.meta?.ssotVersion ?? 'unknown';
  lines.push(`SSOT: signet/src/stack/versions.ts (v${ssotVersion})`);

  return lines.join('\n');
}
