#!/usr/bin/env bun
/**
 * Stack Enforcer Hook
 *
 * Stop hook that validates stack compliance at session end.
 * Uses STACK from signet/src/stack as the single source of truth.
 *
 * Trigger: Stop event
 * Mode: STRICT (env STACK_ENFORCER_STRICT=true) blocks, default warns
 */

import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { z } from 'zod';

// Import STACK from signet (absolute path for Bun)
let STACK: { npm: Record<string, string>; meta: { ssotVersion: string } };
try {
  const stackModule = await import(
    join(process.env.HOME ?? '', 'dotfiles/config/signet/src/stack/versions.ts')
  );
  STACK = stackModule.STACK;
} catch {
  // Fallback to versions.json if STACK import fails
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
// Types
// =============================================================================

const HookInputSchema = z.object({
  hook_event_name: z.literal('Stop'),
  session_id: z.string(),
  cwd: z.string().optional(),
});

type HookInput = z.infer<typeof HookInputSchema>;

interface Violation {
  file: string;
  type: 'version_drift' | 'forbidden_dep' | 'forbidden_import';
  message: string;
  severity: 'high' | 'medium';
}

// =============================================================================
// Configuration
// =============================================================================

const STRICT_MODE = process.env.STACK_ENFORCER_STRICT === 'true';
const SSOT_PATH = 'signet/src/stack/versions.ts';

// Forbidden dependencies - these have better alternatives
const FORBIDDEN_DEPS: Record<string, string> = {
  // ❌ lodash → Use native methods or Effect
  lodash: 'Use native Array/Object methods or Effect utilities',
  'lodash-es': 'Use native Array/Object methods or Effect utilities',
  underscore: 'Use native Array/Object methods or Effect utilities',

  // ❌ express → Use Hono
  express: 'Use Hono instead (Web Standards, faster, smaller)',
  fastify: 'Use Hono instead (Web Standards, portable)',
  koa: 'Use Hono instead (Web Standards, portable)',

  // ❌ prisma → Use Drizzle
  prisma: 'Use Drizzle ORM instead (type-safe, SQL-first)',
  '@prisma/client': 'Use Drizzle ORM instead (type-safe, SQL-first)',

  // ❌ mongoose → Use Drizzle + PostgreSQL
  mongoose: 'Use Drizzle + PostgreSQL instead of MongoDB',

  // ❌ moment → Use native Date or Temporal
  moment: 'Use native Date API or Temporal (Stage 3)',
  'moment-timezone': 'Use native Date API or Temporal (Stage 3)',

  // ❌ axios → Use fetch (native)
  axios: 'Use native fetch() or Effect HttpClient',

  // ❌ jest → Use Vitest
  jest: 'Use Vitest instead (Vite-native, faster)',
  '@jest/globals': 'Use Vitest instead (Vite-native, faster)',

  // ❌ eslint → Use Biome or OXLint
  eslint: 'Use Biome or OXLint instead (faster, unified)',
  prettier: 'Use Biome instead (unified format + lint)',

  // ❌ redux → Use XState or Zustand
  redux: 'Use XState (state machines) or Zustand (simple state)',
  '@reduxjs/toolkit': 'Use XState (state machines) or Zustand (simple state)',

  // ❌ webpack → Use Vite
  webpack: 'Use Vite instead (ESM-native, faster)',
  'webpack-cli': 'Use Vite instead (ESM-native, faster)',
};

// Key packages that should be checked against versions.json
const ENFORCED_PACKAGES = [
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
// Main Logic
// =============================================================================

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

function checkVersionDrift(
  pkgPath: string,
  pkgDeps: Record<string, string>,
  npmVersions: Record<string, string>
): Violation[] {
  const violations: Violation[] = [];

  for (const name of ENFORCED_PACKAGES) {
    const expectedVersion = npmVersions[name];
    if (!expectedVersion) continue;

    const actualVersion = pkgDeps[name];
    if (actualVersion && !actualVersion.includes(expectedVersion)) {
      violations.push({
        file: pkgPath,
        type: 'version_drift',
        message: `${name}: expected ${expectedVersion}, got ${actualVersion}`,
        severity: 'medium',
      });
    }
  }

  return violations;
}

function checkForbiddenDeps(
  pkgPath: string,
  pkgDeps: Record<string, string>
): Violation[] {
  const violations: Violation[] = [];

  for (const [dep, reason] of Object.entries(FORBIDDEN_DEPS)) {
    if (pkgDeps[dep]) {
      violations.push({
        file: pkgPath,
        type: 'forbidden_dep',
        message: `${dep} is forbidden. ${reason}`,
        severity: 'high',
      });
    }
  }

  return violations;
}

function analyzePackageJson(
  pkgPath: string,
  npmVersions: Record<string, string>
): Violation[] {
  const violations: Violation[] = [];

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
    // Skip unreadable files
  }

  return violations;
}

async function main() {
  let rawInput: string;
  try {
    rawInput = await Bun.stdin.text();
  } catch {
    console.log(JSON.stringify({ continue: true }));
    return;
  }

  if (!rawInput.trim()) {
    console.log(JSON.stringify({ continue: true }));
    return;
  }

  let input: HookInput;
  try {
    input = HookInputSchema.parse(JSON.parse(rawInput));
  } catch {
    // Invalid input - allow continuation
    console.log(JSON.stringify({ continue: true }));
    return;
  }

  // Verify STACK is loaded
  if (!STACK.npm || Object.keys(STACK.npm).length === 0) {
    console.log(
      JSON.stringify({
        continue: true,
        warning: `⚠️  STACK not loaded. Check ${SSOT_PATH}.`,
      })
    );
    return;
  }

  // Find all package.json files in working directory
  const cwd = input.cwd ?? process.cwd();
  const packageJsonFiles = findPackageJsonFiles(cwd);

  if (packageJsonFiles.length === 0) {
    console.log(JSON.stringify({ continue: true }));
    return;
  }

  // Analyze each package.json
  const allViolations: Violation[] = [];
  for (const pkgPath of packageJsonFiles) {
    allViolations.push(...analyzePackageJson(pkgPath, STACK.npm));
  }

  if (allViolations.length === 0) {
    console.log(
      JSON.stringify({
        continue: true,
        additionalContext: `✅ Stack compliance check passed (${packageJsonFiles.length} package.json files)`,
      })
    );
    return;
  }

  // Separate by severity
  const highSeverity = allViolations.filter((v) => v.severity === 'high');
  const mediumSeverity = allViolations.filter((v) => v.severity === 'medium');

  // Format violation report
  const report = `Stack Compliance Issues (SSOT v${STACK.meta?.ssotVersion ?? 'unknown'}):

${highSeverity.length > 0 ? `❌ FORBIDDEN DEPENDENCIES (${highSeverity.length}):
${highSeverity.map((v) => `  • ${v.message}\n    in ${v.file}`).join('\n')}
` : ''}
${mediumSeverity.length > 0 ? `⚠️  VERSION DRIFT (${mediumSeverity.length}):
${mediumSeverity.map((v) => `  • ${v.message}\n    in ${v.file}`).join('\n')}
` : ''}
Source of truth: ${SSOT_PATH}`;

  // Block if high severity violations in STRICT mode
  if (highSeverity.length > 0 && STRICT_MODE) {
    console.error(`BLOCKED: Stack compliance violations\n\n${report}`);
    process.exit(2);
  }

  // Otherwise warn
  console.log(
    JSON.stringify({
      continue: true,
      warning: report,
    })
  );
}

main().catch((e) => {
  console.error('Stack Enforcer error:', e);
  console.log(JSON.stringify({ continue: true }));
  process.exit(0);
});
