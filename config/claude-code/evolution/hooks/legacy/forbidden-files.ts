#!/usr/bin/env bun
/**
 * Forbidden Files Hook - BLOCKS creation of banned config files
 *
 * Trigger: PreToolUse on Write
 * Mode: Strict (Block)
 *
 * Prevents creation of:
 * - package-lock.json, yarn.lock, pnpm-lock.yaml (use Bun)
 * - .eslintrc*, eslint.config.* (use Biome)
 * - .prettierrc*, prettier.config.* (use Biome)
 * - jest.config.* (use bun test)
 * - prisma/schema.prisma (use Drizzle)
 */

import { z } from 'zod';

// Hook input schema
const HookInputSchema = z.object({
  hook_event_name: z.literal('PreToolUse'),
  session_id: z.string(),
  tool_name: z.string(),
  tool_input: z
    .object({
      file_path: z.string().optional(),
    })
    .passthrough(),
});

// ============================================================================
// Forbidden Files Configuration
// ============================================================================

interface ForbiddenFile {
  pattern: string | RegExp;
  reason: string;
  alternative: string;
}

const FORBIDDEN_FILES: ForbiddenFile[] = [
  // Lockfiles - Use Bun
  { pattern: 'package-lock.json', reason: 'Use Bun', alternative: 'bun install' },
  { pattern: 'yarn.lock', reason: 'Use Bun', alternative: 'bun install' },
  { pattern: 'pnpm-lock.yaml', reason: 'Use Bun', alternative: 'bun install' },

  // ESLint - Use Biome
  { pattern: /\.eslintrc(\.(js|cjs|mjs|json|yaml|yml))?$/, reason: 'Use Biome', alternative: 'biome.json' },
  { pattern: /eslint\.config\.(js|cjs|mjs|ts)$/, reason: 'Use Biome', alternative: 'biome.json' },

  // Prettier - Use Biome
  { pattern: /\.prettierrc(\.(js|cjs|mjs|json|yaml|yml))?$/, reason: 'Use Biome', alternative: 'biome.json' },
  { pattern: /prettier\.config\.(js|cjs|mjs|ts)$/, reason: 'Use Biome', alternative: 'biome.json' },

  // Jest - Use Bun test
  { pattern: /jest\.config\.(js|cjs|mjs|ts|json)$/, reason: 'Use Bun test', alternative: 'bun test' },
  { pattern: 'jest.setup.js', reason: 'Use Bun test', alternative: 'bun test' },
  { pattern: 'jest.setup.ts', reason: 'Use Bun test', alternative: 'bun test' },

  // Prisma - Use Drizzle
  { pattern: /prisma\/schema\.prisma$/, reason: 'Use Drizzle', alternative: 'drizzle.config.ts' },
];

// ============================================================================
// Detection Functions
// ============================================================================

function matchesForbidden(filePath: string): ForbiddenFile | null {
  const fileName = filePath.split('/').pop() || '';

  for (const forbidden of FORBIDDEN_FILES) {
    if (typeof forbidden.pattern === 'string') {
      if (fileName === forbidden.pattern || filePath.endsWith(forbidden.pattern)) {
        return forbidden;
      }
    } else {
      if (forbidden.pattern.test(fileName) || forbidden.pattern.test(filePath)) {
        return forbidden;
      }
    }
  }
  return null;
}

// ============================================================================
// Main Hook Logic
// ============================================================================

async function main() {
  let rawInput: string;
  try {
    rawInput = await Bun.stdin.text();
  } catch {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  let input: z.infer<typeof HookInputSchema>;
  try {
    input = HookInputSchema.parse(JSON.parse(rawInput));
  } catch {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // Only check Write tool
  if (input.tool_name !== 'Write') {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  const filePath = input.tool_input.file_path;
  if (!filePath) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  const forbidden = matchesForbidden(filePath);
  if (!forbidden) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // BLOCK: Forbidden file
  const fileName = filePath.split('/').pop() || filePath;
  console.log(
    JSON.stringify({
      decision: 'block',
      reason: `FORBIDDEN FILE: ${fileName}

Reason: ${forbidden.reason} instead of this file
Alternative: ${forbidden.alternative}

This file type is blocked by stack standards.
See VERSIONS.md for approved tools.`,
    })
  );
}

main().catch((e) => {
  console.error('Forbidden Files error:', e);
  console.log(JSON.stringify({ decision: 'allow' }));
});
