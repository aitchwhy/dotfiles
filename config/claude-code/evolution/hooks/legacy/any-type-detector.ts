#!/usr/bin/env bun
/**
 * Any Type Detector Hook - BLOCKS usage of `any` type in TypeScript
 *
 * Trigger: PreToolUse on Write/Edit for TS/TSX files
 * Mode: Strict (Block)
 *
 * Enforces zero `any` policy by detecting:
 * - : any type annotations
 * - as any assertions
 * - <any> generics
 * - ): any return types
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
// Detection Patterns
// ============================================================================

// Patterns that indicate `any` type usage (with word boundaries)
const ANY_TYPE_PATTERNS = [
  /:\s*any\b/, // : any
  /\bas\s+any\b/, // as any
  /<any\s*>/, // <any>
  /<any\s*,/, // <any, ...>
  /,\s*any\s*>/, // <..., any>
  /\):\s*any\b/, // ): any return type
];

// ============================================================================
// Utility Functions
// ============================================================================

function stripCommentsAndStrings(code: string): string {
  // Remove single-line comments
  code = code.replace(/\/\/.*$/gm, '');
  // Remove multi-line comments
  code = code.replace(/\/\*[\s\S]*?\*\//g, '');
  // Replace string contents with empty strings (preserve structure)
  code = code.replace(/'(?:[^'\\]|\\.)*'/g, "''");
  code = code.replace(/"(?:[^"\\]|\\.)*"/g, '""');
  code = code.replace(/`(?:[^`\\]|\\.)*`/g, '``');
  return code;
}

function detectAnyType(content: string): { found: boolean; match?: string; line?: number } {
  const cleanContent = stripCommentsAndStrings(content);
  const lines = cleanContent.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line) continue;

    for (const pattern of ANY_TYPE_PATTERNS) {
      if (pattern.test(line)) {
        // Extract the matching portion for the error message
        const match = line.match(pattern);
        return {
          found: true,
          match: match?.[0]?.trim(),
          line: i + 1,
        };
      }
    }
  }
  return { found: false };
}

function isExcludedPath(filePath: string): boolean {
  const excludedPatterns = ['/node_modules/', '/.git/', '/dist/', '/build/'];
  return excludedPatterns.some((p) => filePath.includes(p));
}

function isTypeDeclaration(filePath: string): boolean {
  // Type declarations may legitimately use `any` for compatibility
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

  // Only check TypeScript files
  if (!/\.tsx?$/.test(filePath)) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // Skip excluded paths
  if (isExcludedPath(filePath)) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // Skip type declarations (.d.ts files)
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

  const result = detectAnyType(content);
  if (!result.found) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // BLOCK: Any type detected
  console.log(
    JSON.stringify({
      decision: 'block',
      reason: `ANY TYPE VIOLATION: '${result.match}' detected${result.line ? ` (line ~${result.line})` : ''}

Use \`unknown\` + Zod parsing instead:

  const data: unknown = await fetch(...);
  const parsed = MySchema.parse(data);

Or use type guards:

  if (isUser(data)) {
    // data is now typed as User
  }

Zero \`any\` policy - see CLAUDE.md TypeScript Standards.`,
    })
  );
}

main().catch((e) => {
  console.error('Any Type Detector error:', e);
  console.log(JSON.stringify({ decision: 'allow' }));
});
