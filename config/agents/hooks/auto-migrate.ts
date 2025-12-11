#!/usr/bin/env bun
/**
 * Auto-Migrate Hook - Universal Project Factory
 *
 * Detects drift in ANY project Claude Code touches and suggests migration.
 *
 * Trigger: SessionStart
 * Mode: Non-blocking (outputs suggestions to stderr)
 *
 * Checks:
 * 1. CLAUDE.md presence
 * 2. Forbidden files (package-lock.json, .eslintrc, etc.)
 * 3. Forbidden dependencies (express, prisma, lodash, etc.)
 * 4. Version drift from STACK.npm
 */

import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { basename, join, resolve } from 'node:path';
import { z } from 'zod';

// =============================================================================
// Types (TypeScript first, schema satisfies type)
// =============================================================================

type HookInput = {
  readonly hook_event_name: 'SessionStart';
  readonly session_id: string;
  readonly cwd?: string;
};

const HookInputSchema = z.object({
  hook_event_name: z.literal('SessionStart'),
  session_id: z.string(),
  cwd: z.string().optional(),
}) satisfies z.ZodType<HookInput>;

type DriftItem = {
  readonly category: 'missing' | 'forbidden' | 'drift';
  readonly item: string;
  readonly suggestion?: string;
};

// =============================================================================
// STACK Import (from signet SSOT)
// =============================================================================

let STACK: { npm: Record<string, string>; meta: { ssotVersion: string } };
try {
  const stackModule = await import(
    join(process.env.HOME ?? '', 'dotfiles/config/signet/src/stack/versions.ts')
  );
  STACK = stackModule.STACK;
} catch {
  // Fallback to versions.json
  const versionsPath = join(
    process.env.HOME ?? '',
    'dotfiles/config/signet/versions.json'
  );
  if (existsSync(versionsPath)) {
    STACK = JSON.parse(readFileSync(versionsPath, 'utf-8'));
  } else {
    STACK = { npm: {}, meta: { ssotVersion: 'unknown' } };
  }
}

// =============================================================================
// Configuration
// =============================================================================

const DOTFILES_PATH = resolve(process.env.HOME ?? '', 'dotfiles');

// Files that should not exist in STACK-compliant projects
const FORBIDDEN_FILES = [
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

// Forbidden dependencies (reuse from stack-enforcer)
const FORBIDDEN_DEPS: Record<string, string> = {
  lodash: 'native methods or Effect',
  'lodash-es': 'native methods or Effect',
  underscore: 'native methods or Effect',
  express: 'Hono',
  fastify: 'Hono',
  koa: 'Hono',
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

// Key packages to check for version drift
const ENFORCED_PACKAGES = [
  'typescript',
  'zod',
  '@biomejs/biome',
  'effect',
  'hono',
  'drizzle-orm',
  'react',
  'react-dom',
  'vitest',
  '@playwright/test',
  'tailwindcss',
  'xstate',
] as const;

// =============================================================================
// Detection Functions
// =============================================================================

function isInDotfiles(cwd: string): boolean {
  const resolved = resolve(cwd);
  return resolved.startsWith(DOTFILES_PATH);
}

function checkClaudeMd(cwd: string): DriftItem | null {
  const paths = [
    join(cwd, 'CLAUDE.md'),
    join(cwd, '.claude', 'CLAUDE.md'),
  ];

  for (const p of paths) {
    if (existsSync(p)) return null;
  }

  return {
    category: 'missing',
    item: 'CLAUDE.md',
    suggestion: 'ln -sf ~/dotfiles/config/agents/AGENT.md ./CLAUDE.md',
  };
}

function checkForbiddenFiles(cwd: string): DriftItem[] {
  const drift: DriftItem[] = [];

  try {
    const files = readdirSync(cwd);
    for (const file of files) {
      if (FORBIDDEN_FILES.includes(file)) {
        drift.push({
          category: 'forbidden',
          item: file,
          suggestion: file === 'package-lock.json' ? 'rm package-lock.json && bun install' : `rm ${file}`,
        });
      }
    }
  } catch (e) {
    // Directory not readable - log for debugging
    if (process.env.DEBUG) {
      console.error(`[auto-migrate] Could not read ${cwd}: ${e instanceof Error ? e.message : String(e)}`);
    }
  }

  return drift;
}

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
            suggestion: `Update to ${name}@${expected}`,
          });
        }
      }
    }
  } catch (e) {
    // Invalid package.json - log for debugging
    if (process.env.DEBUG) {
      console.error(`[auto-migrate] Could not parse ${pkgPath}: ${e instanceof Error ? e.message : String(e)}`);
    }
  }

  return drift;
}

// =============================================================================
// Output Formatting
// =============================================================================

function formatDrift(cwd: string, items: DriftItem[]): string {
  const projectName = basename(cwd);

  const missing = items.filter(i => i.category === 'missing');
  const forbidden = items.filter(i => i.category === 'forbidden');
  const drift = items.filter(i => i.category === 'drift');

  const lines: string[] = [
    ``,
    `[Universal Factory] Project drift detected in ${projectName}:`,
  ];

  if (missing.length > 0) {
    lines.push(`  Missing: ${missing.map(i => i.item).join(', ')}`);
  }

  if (forbidden.length > 0) {
    lines.push(`  Forbidden: ${forbidden.map(i => i.item).join(', ')}`);
  }

  if (drift.length > 0) {
    lines.push(`  Version drift: ${drift.map(i => i.item).join(', ')}`);
  }

  lines.push(``);
  lines.push(`  Run: signet migrate --dry-run`);
  lines.push(``);

  return lines.join('\n');
}

// =============================================================================
// Main
// =============================================================================

async function main() {
  let rawInput: string;
  try {
    rawInput = await Bun.stdin.text();
  } catch {
    process.exit(0);
  }

  if (!rawInput.trim()) {
    process.exit(0);
  }

  let input: HookInput;
  try {
    input = HookInputSchema.parse(JSON.parse(rawInput));
  } catch {
    // Not a SessionStart event, skip
    process.exit(0);
  }

  const cwd = input.cwd ?? process.cwd();

  // Skip if in dotfiles (don't self-check)
  if (isInDotfiles(cwd)) {
    process.exit(0);
  }

  // Collect all drift items
  const driftItems: DriftItem[] = [];

  const claudeMdDrift = checkClaudeMd(cwd);
  if (claudeMdDrift) driftItems.push(claudeMdDrift);

  driftItems.push(...checkForbiddenFiles(cwd));
  driftItems.push(...checkPackageJson(cwd));

  // If no drift, exit silently
  if (driftItems.length === 0) {
    process.exit(0);
  }

  // Output drift report to stderr (visible but non-blocking)
  console.error(formatDrift(cwd, driftItems));

  process.exit(0);
}

main().catch(() => {
  process.exit(0);
});
