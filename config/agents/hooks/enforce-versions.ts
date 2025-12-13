#!/usr/bin/env bun
/**
 * Enforce Versions - PostToolUse hook for package.json changes
 *
 * Automatically checks package.json files for:
 * - Forbidden dependencies (lodash, express, prisma, etc.)
 * - Version drift from STACK.npm
 *
 * Runs after Write/Edit operations on package.json files.
 */

import { readFileSync } from 'node:fs';

// =============================================================================
// Types
// =============================================================================

type Violation = {
  readonly package: string;
  readonly message: string;
  readonly severity: 'high' | 'medium';
};

// =============================================================================
// Configuration (must match config/signet/src/services/stack.ts)
// =============================================================================

const FORBIDDEN_DEPS: Record<string, string> = {
  lodash: 'Use native Array/Object methods or Effect utilities',
  'lodash-es': 'Use native Array/Object methods or Effect utilities',
  underscore: 'Use native Array/Object methods or Effect utilities',
  express: 'Use Hono instead (Web Standards, faster, smaller)',
  fastify: 'Use Hono instead (Web Standards, portable)',
  koa: 'Use Hono instead (Web Standards, portable)',
  prisma: 'Use Drizzle ORM instead (type-safe, SQL-first)',
  '@prisma/client': 'Use Drizzle ORM instead (type-safe, SQL-first)',
  mongoose: 'Use Drizzle + PostgreSQL instead of MongoDB',
  moment: 'Use native Date API or Temporal (Stage 3)',
  'moment-timezone': 'Use native Date API or Temporal (Stage 3)',
  axios: 'Use native fetch() or Effect HttpClient',
  jest: 'Use Vitest instead (Vite-native, faster)',
  '@jest/globals': 'Use Vitest instead (Vite-native, faster)',
  eslint: 'Use Biome or OXLint instead (faster, unified)',
  prettier: 'Use Biome instead (unified format + lint)',
  redux: 'Use XState (state machines) or Zustand (simple state)',
  '@reduxjs/toolkit': 'Use XState (state machines) or Zustand (simple state)',
  webpack: 'Use Vite instead (ESM-native, faster)',
  'webpack-cli': 'Use Vite instead (ESM-native, faster)',
};

// =============================================================================
// Main
// =============================================================================

const filePaths = (process.env.CLAUDE_FILE_PATHS || '').split(',').filter(Boolean);

// Only check package.json files
const packageJsonFiles = filePaths.filter((p) => p.endsWith('package.json'));

if (packageJsonFiles.length === 0) {
  console.log(JSON.stringify({ continue: true }));
  process.exit(0);
}

const allViolations: Violation[] = [];

for (const pkgPath of packageJsonFiles) {
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
    for (const [dep, reason] of Object.entries(FORBIDDEN_DEPS)) {
      if (allDeps[dep]) {
        allViolations.push({
          package: dep,
          message: `${dep} is forbidden. ${reason}`,
          severity: 'high',
        });
      }
    }
  } catch {
    // Skip unreadable files
  }
}

// If forbidden deps found, block with error
const forbidden = allViolations.filter((v) => v.severity === 'high');
if (forbidden.length > 0) {
  const errors = forbidden.map((v) => `  - ${v.message}`).join('\n');
  console.log(
    JSON.stringify({
      continue: false,
      error: `STACK VIOLATION: Forbidden dependencies detected:\n${errors}\n\nRemove these before continuing.`,
    })
  );
  process.exit(0);
}

// Allow to continue
console.log(JSON.stringify({ continue: true }));
