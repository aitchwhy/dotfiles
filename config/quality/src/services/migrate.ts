/**
 * Migrate Service - Project Drift Detection
 *
 * Detects drift from STACK standards and suggests migrations.
 * Replaces auto-migrate.ts hook.
 */

import { existsSync, readdirSync, readFileSync, symlinkSync, unlinkSync } from 'node:fs';
import { basename, join, resolve } from 'node:path';
import { Effect } from 'effect';
import { STACK } from '@/stack/versions';

// =============================================================================
// Types (TypeScript first)
// =============================================================================

export type DriftItem = {
  readonly category: 'missing' | 'forbidden' | 'drift';
  readonly item: string;
  readonly suggestion: string;
  readonly fixable: boolean;
};

export type MigrateCheckResult = {
  readonly driftItems: readonly DriftItem[];
  readonly projectName: string;
  readonly passed: boolean;
};

export type MigrateFixResult = {
  readonly created: readonly string[];
  readonly removed: readonly string[];
  readonly skipped: readonly string[];
  readonly result: MigrateCheckResult;
};

// =============================================================================
// Configuration (extracted from auto-migrate.ts)
// =============================================================================

const HOME = process.env['HOME'];
if (!HOME) {
  throw new Error('HOME environment variable not set - required for drift detection');
}
const DOTFILES_PATH = resolve(HOME, 'dotfiles');
const AGENT_MD_PATH = join(DOTFILES_PATH, 'config/agents/AGENT.md');

/** Files that should not exist in STACK-compliant projects */
export const FORBIDDEN_FILES = [
  'package-lock.json',
  'yarn.lock',
  'pnpm-lock.yaml',
  '.eslintrc',
  '.eslintrc.js',
  '.eslintrc.json',
  '.eslintrc.cjs',
  '.eslintrc.mjs',
  'eslint.config.js',
  'eslint.config.mjs',
  '.prettierrc',
  '.prettierrc.js',
  '.prettierrc.json',
  'prettier.config.js',
  'jest.config.js',
  'jest.config.ts',
  'jest.config.mjs',
  'Dockerfile',
  'docker-compose.yml',
  'docker-compose.yaml',
  '.npmrc',
  '.yarnrc',
];

/** Forbidden dependencies (from stack service) */
export const FORBIDDEN_DEPS: Record<string, string> = {
  lodash: 'native methods or Effect',
  'lodash-es': 'native methods or Effect',
  underscore: 'native methods or Effect',
  express: 'Effect Platform HTTP (@effect/platform)',
  fastify: 'Effect Platform HTTP (@effect/platform)',
  koa: 'Effect Platform HTTP (@effect/platform)',
  hono: 'Effect Platform HTTP (@effect/platform)',
  prisma: 'Drizzle ORM',
  '@prisma/client': 'Drizzle ORM',
  mongoose: 'Drizzle + PostgreSQL',
  moment: 'native Date or Temporal',
  'moment-timezone': 'native Date or Temporal',
  axios: 'native fetch()',
  jest: 'Vitest',
  '@jest/globals': 'Vitest',
  eslint: 'Biome',
  prettier: 'Biome',
  redux: 'XState or Zustand',
  '@reduxjs/toolkit': 'XState or Zustand',
  webpack: 'Vite',
  'webpack-cli': 'Vite',
  dotenv: 'Bun native env',
};

/** Key packages to check for version drift */
const ENFORCED_PACKAGES = [
  'typescript',
  'zod',
  '@biomejs/biome',
  'effect',
  '@effect/platform',
  'drizzle-orm',
  'react',
  'react-dom',
  'vitest',
  '@playwright/test',
  'tailwindcss',
  'xstate',
] as const;

// =============================================================================
// Helper Functions
// =============================================================================

/**
 * Check if path is inside dotfiles (skip self-checking)
 */
function isInDotfiles(cwd: string): boolean {
  const resolved = resolve(cwd);
  return resolved.startsWith(DOTFILES_PATH);
}

/**
 * Check for CLAUDE.md presence
 */
function checkClaudeMd(cwd: string): DriftItem | null {
  const paths = [join(cwd, 'CLAUDE.md'), join(cwd, '.claude', 'CLAUDE.md')];

  for (const p of paths) {
    if (existsSync(p)) return null;
  }

  return {
    category: 'missing',
    item: 'CLAUDE.md',
    suggestion: 'ln -sf ~/dotfiles/config/agents/AGENT.md ./CLAUDE.md',
    fixable: true,
  };
}

/**
 * Check for forbidden files
 */
function checkForbiddenFiles(cwd: string): DriftItem[] {
  const drift: DriftItem[] = [];

  try {
    const files = readdirSync(cwd);
    for (const file of files) {
      if (FORBIDDEN_FILES.includes(file)) {
        drift.push({
          category: 'forbidden',
          item: file,
          suggestion:
            file === 'package-lock.json' ? 'rm package-lock.json && bun install' : `rm ${file}`,
          fixable: true,
        });
      }
    }
  } catch {
    // Directory not readable - skip
  }

  return drift;
}

/**
 * Check package.json for forbidden deps and version drift
 */
function checkPackageJson(cwd: string): DriftItem[] {
  const drift: DriftItem[] = [];
  const pkgPath = join(cwd, 'package.json');

  if (!existsSync(pkgPath)) return drift;

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

    // Check forbidden deps
    for (const [dep, alternative] of Object.entries(FORBIDDEN_DEPS)) {
      if (allDeps[dep]) {
        drift.push({
          category: 'forbidden',
          item: dep,
          suggestion: `Use ${alternative} instead`,
          fixable: false,
        });
      }
    }

    // Check version drift (major.minor comparison)
    for (const name of ENFORCED_PACKAGES) {
      const expected = STACK.npm[name];
      const actual = allDeps[name];

      if (expected && actual) {
        // Strip semver prefixes (^, ~, etc.)
        const actualClean = actual.replace(/^[\^~>=<]+/, '');
        const [expMajor, expMinor] = expected.split('.');
        const [actMajor, actMinor] = actualClean.split('.');

        // Drift if major or minor version differs
        if (expMajor !== actMajor || expMinor !== actMinor) {
          drift.push({
            category: 'drift',
            item: `${name}@${actual}`,
            suggestion: `Update to ${name}@^${expected}`,
            fixable: false, // Use sig-stack for fixing
          });
        }
      }
    }
  } catch {
    // Invalid package.json - skip
  }

  return drift;
}

// =============================================================================
// Service Functions (Effect-based)
// =============================================================================

/**
 * Check project for drift from STACK standards
 */
export const checkProject = (path: string): Effect.Effect<MigrateCheckResult, Error> =>
  Effect.sync(() => {
    const cwd = resolve(path);
    const projectName = basename(cwd);

    // Skip if in dotfiles (don't self-check)
    if (isInDotfiles(cwd)) {
      return {
        driftItems: [] as readonly DriftItem[],
        projectName,
        passed: true,
      };
    }

    // Collect all drift items
    const driftItems: DriftItem[] = [];

    const claudeMdDrift = checkClaudeMd(cwd);
    if (claudeMdDrift) driftItems.push(claudeMdDrift);

    driftItems.push(...checkForbiddenFiles(cwd));
    driftItems.push(...checkPackageJson(cwd));

    return {
      driftItems,
      projectName,
      passed: driftItems.length === 0,
    };
  });

/**
 * Fix project drift (create CLAUDE.md, remove forbidden files)
 */
export const fixProject = (path: string): Effect.Effect<MigrateFixResult, Error> =>
  Effect.gen(function* () {
    const cwd = resolve(path);
    const created: string[] = [];
    const removed: string[] = [];
    const skipped: string[] = [];

    // Skip if in dotfiles
    if (isInDotfiles(cwd)) {
      return {
        created: [],
        removed: [],
        skipped: [],
        result: {
          driftItems: [],
          projectName: basename(cwd),
          passed: true,
        },
      };
    }

    // Fix missing CLAUDE.md
    const claudeMdPath = join(cwd, 'CLAUDE.md');
    if (!existsSync(claudeMdPath) && existsSync(AGENT_MD_PATH)) {
      try {
        symlinkSync(AGENT_MD_PATH, claudeMdPath);
        created.push('CLAUDE.md (symlink to AGENT.md)');
      } catch {
        skipped.push('CLAUDE.md (could not create symlink)');
      }
    }

    // Remove forbidden files
    for (const file of FORBIDDEN_FILES) {
      const filePath = join(cwd, file);
      if (existsSync(filePath)) {
        try {
          unlinkSync(filePath);
          removed.push(file);
        } catch {
          skipped.push(`${file} (could not remove)`);
        }
      }
    }

    // Re-check after fixes
    const result = yield* checkProject(path);

    return {
      created,
      removed,
      skipped,
      result,
    };
  });

// =============================================================================
// Formatting
// =============================================================================

/**
 * Format migrate check result for MCP output
 */
export function formatMigrateResult(result: MigrateCheckResult | MigrateFixResult): string {
  const isFixResult = 'created' in result;
  const checkResult = isFixResult
    ? (result as MigrateFixResult).result
    : (result as MigrateCheckResult);

  const lines: string[] = [];
  lines.push('━'.repeat(50));
  lines.push('  SIGNET PROJECT MIGRATION');
  lines.push('━'.repeat(50));
  lines.push('');
  lines.push(`Project: ${checkResult.projectName}`);
  lines.push(`Status: ${checkResult.passed ? '✅ COMPLIANT' : '⚠️  DRIFT DETECTED'}`);
  lines.push('');

  if (isFixResult) {
    const fixResult = result as MigrateFixResult;
    if (fixResult.created.length > 0) {
      lines.push('📝 Created:');
      for (const item of fixResult.created) {
        lines.push(`  • ${item}`);
      }
      lines.push('');
    }
    if (fixResult.removed.length > 0) {
      lines.push('🗑️  Removed:');
      for (const item of fixResult.removed) {
        lines.push(`  • ${item}`);
      }
      lines.push('');
    }
    if (fixResult.skipped.length > 0) {
      lines.push('⏭️  Skipped:');
      for (const item of fixResult.skipped) {
        lines.push(`  • ${item}`);
      }
      lines.push('');
    }
  }

  if (checkResult.driftItems.length > 0) {
    const missing = checkResult.driftItems.filter((i) => i.category === 'missing');
    const forbidden = checkResult.driftItems.filter((i) => i.category === 'forbidden');
    const drift = checkResult.driftItems.filter((i) => i.category === 'drift');

    if (missing.length > 0) {
      lines.push('❌ MISSING:');
      for (const item of missing) {
        lines.push(`  • ${item.item}`);
        lines.push(`    Fix: ${item.suggestion}`);
      }
      lines.push('');
    }

    if (forbidden.length > 0) {
      lines.push('🚫 FORBIDDEN:');
      for (const item of forbidden.slice(0, 5)) {
        lines.push(`  • ${item.item}`);
        lines.push(`    Fix: ${item.suggestion}`);
      }
      if (forbidden.length > 5) {
        lines.push(`  ... and ${forbidden.length - 5} more`);
      }
      lines.push('');
    }

    if (drift.length > 0) {
      lines.push('📉 VERSION DRIFT:');
      for (const item of drift.slice(0, 5)) {
        lines.push(`  • ${item.item}`);
        lines.push(`    Fix: ${item.suggestion}`);
      }
      if (drift.length > 5) {
        lines.push(`  ... and ${drift.length - 5} more`);
      }
      lines.push('');
    }
  }

  lines.push(`SSOT: signet/src/stack/versions.ts (v${STACK.meta?.ssotVersion ?? 'unknown'})`);

  return lines.join('\n');
}
