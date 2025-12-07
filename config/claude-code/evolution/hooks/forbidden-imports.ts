#!/usr/bin/env bun
/**
 * Forbidden Imports Hook - BLOCKS imports of banned packages
 *
 * Trigger: PreToolUse on Write/Edit for TS/JS files
 * Mode: Strict (Block)
 *
 * Prevents imports of:
 * - express → use Hono
 * - @prisma/client → use Drizzle
 * - fastify → use Hono
 * - zod/v3 → use zod (v4)
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
      content: z.string().optional(), // Write
      new_string: z.string().optional(), // Edit
    })
    .passthrough(),
});

// ============================================================================
// Forbidden Imports Configuration
// ============================================================================

interface ForbiddenImport {
  patterns: RegExp[];
  package: string;
  alternative: string;
  docs?: string;
}

const FORBIDDEN_IMPORTS: ForbiddenImport[] = [
  {
    patterns: [/from\s+['"]express['"]/, /require\s*\(\s*['"]express['"]\s*\)/],
    package: 'express',
    alternative: 'hono',
    docs: 'https://hono.dev',
  },
  {
    patterns: [/from\s+['"]fastify['"]/, /require\s*\(\s*['"]fastify['"]\s*\)/],
    package: 'fastify',
    alternative: 'hono',
    docs: 'https://hono.dev',
  },
  {
    patterns: [/from\s+['"]@prisma\/client['"]/, /require\s*\(\s*['"]@prisma\/client['"]\s*\)/],
    package: '@prisma/client',
    alternative: 'drizzle-orm',
    docs: 'https://orm.drizzle.team',
  },
  {
    patterns: [/from\s+['"]zod\/v3['"]/],
    package: 'zod/v3',
    alternative: 'zod (v4 is the default now)',
    docs: 'https://zod.dev',
  },
];

// ============================================================================
// Detection Functions
// ============================================================================

function stripComments(code: string): string {
  // Remove single-line comments
  code = code.replace(/\/\/.*$/gm, '');
  // Remove multi-line comments
  code = code.replace(/\/\*[\s\S]*?\*\//g, '');
  return code;
}

function detectForbiddenImport(content: string): ForbiddenImport | null {
  const cleanContent = stripComments(content);

  for (const forbidden of FORBIDDEN_IMPORTS) {
    for (const pattern of forbidden.patterns) {
      if (pattern.test(cleanContent)) {
        return forbidden;
      }
    }
  }
  return null;
}

function isExcludedPath(filePath: string): boolean {
  const excludedPatterns = ['/node_modules/', '/.git/', '/dist/', '/build/'];
  return excludedPatterns.some((p) => filePath.includes(p));
}

function isTypeDeclaration(filePath: string): boolean {
  return filePath.endsWith('.d.ts');
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

  // Only check Write and Edit tools
  if (!['Write', 'Edit'].includes(input.tool_name)) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  const filePath = input.tool_input.file_path;
  if (!filePath) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // Only check TS/JS files
  if (!/\.[jt]sx?$/.test(filePath)) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // Skip excluded paths
  if (isExcludedPath(filePath)) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // Skip type declarations
  if (isTypeDeclaration(filePath)) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // Get content to check
  const content = input.tool_input.content || input.tool_input.new_string || '';
  if (!content) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  const forbidden = detectForbiddenImport(content);
  if (!forbidden) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // BLOCK: Forbidden import
  console.log(
    JSON.stringify({
      decision: 'block',
      reason: `FORBIDDEN IMPORT: '${forbidden.package}' detected

Use ${forbidden.alternative} instead.
${forbidden.docs ? `Docs: ${forbidden.docs}` : ''}

This package is blocked by stack standards.
See VERSIONS.md for approved packages.`,
    })
  );
}

main().catch((e) => {
  console.error('Forbidden Imports error:', e);
  console.log(JSON.stringify({ decision: 'allow' }));
});
