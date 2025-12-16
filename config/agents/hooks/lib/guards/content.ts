/**
 * Content Guards - Pattern-based content validation
 *
 * Guards 4-7, 13-14, 26, 32-39 using fast regex patterns.
 * Full AST analysis happens at git commit via pre-commit hooks.
 */

import { isExcludedPath, isTypeScriptFile, type GuardResult } from '../types';

// =============================================================================
// Shared Utilities
// =============================================================================

function stripCommentsAndStrings(code: string): string {
  return code
    .replace(/\/\/.*$/gm, '')
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/'(?:[^'\\]|\\.)*'/g, "''")
    .replace(/"(?:[^"\\]|\\.)*"/g, '""')
    .replace(/`(?:[^`\\]|\\.)*`/g, '``');
}

function stripComments(code: string): string {
  return code.replace(/\/\/.*$/gm, '').replace(/\/\*[\s\S]*?\*\//g, '');
}

// =============================================================================
// Guard 4: Forbidden Imports
// =============================================================================

const FORBIDDEN_IMPORTS = [
  { pattern: /from\s+['"]express['"]/, pkg: 'express', alt: '@effect/platform' },
  { pattern: /from\s+['"]fastify['"]/, pkg: 'fastify', alt: '@effect/platform' },
  { pattern: /from\s+['"]hono['"]/, pkg: 'hono', alt: '@effect/platform' },
  { pattern: /from\s+['"]@prisma\/client['"]/, pkg: '@prisma/client', alt: 'drizzle-orm' },
  { pattern: /from\s+['"]zod\/v3['"]/, pkg: 'zod/v3', alt: 'zod (v4)' },
  { pattern: /["']dd-trace["']/, pkg: 'dd-trace', alt: 'OpenTelemetry SDK' },
];

function checkForbiddenImports(content: string): GuardResult {
  const clean = stripComments(content);
  for (const { pattern, pkg, alt } of FORBIDDEN_IMPORTS) {
    if (pattern.test(clean)) {
      return { ok: false, error: `Guard 4: Forbidden import '${pkg}'. Use ${alt} instead.` };
    }
  }
  return { ok: true };
}

// =============================================================================
// Guard 5: Any Type
// =============================================================================

const ANY_PATTERNS = [/:\s*any\b/, /as\s+any\b/, /<any>/, /<any,/];

function checkAnyType(content: string): GuardResult {
  const clean = stripCommentsAndStrings(content);
  for (const pattern of ANY_PATTERNS) {
    if (pattern.test(clean)) {
      return { ok: false, error: `Guard 5: 'any' type detected. Use 'unknown' with type guards.` };
    }
  }
  return { ok: true };
}

// =============================================================================
// Guard 6: z.infer
// =============================================================================

const ZINFER_PATTERNS = [/z\.infer</, /z\.input</, /z\.output</];

function checkZodInfer(content: string): GuardResult {
  const clean = stripCommentsAndStrings(content);
  for (const pattern of ZINFER_PATTERNS) {
    if (pattern.test(clean)) {
      return { ok: false, error: `Guard 6: z.infer<> detected. Define TypeScript type first, use 'satisfies z.ZodType<T>'.` };
    }
  }
  return { ok: true };
}

// =============================================================================
// Guard 7: No Mocks
// =============================================================================

const MOCK_PATTERNS = [/jest\.mock\(/, /vi\.mock\(/, /Mock[A-Z][a-zA-Z]*Live/];

function checkNoMocks(content: string): GuardResult {
  const clean = stripCommentsAndStrings(content);
  for (const pattern of MOCK_PATTERNS) {
    if (pattern.test(clean)) {
      return { ok: false, error: `Guard 7: Mock pattern detected. Use real adapters with Layer.succeed() for DI.` };
    }
  }
  return { ok: true };
}

// =============================================================================
// Guard 13: Assumption Language
// =============================================================================

const ASSUMPTION_PATTERNS = [
  /\bshould\s+(now\s+)?work/i,
  /\bshould\s+fix/i,
  /\bprobably\s+(works|fixed|correct)/i,
  /\bI\s+think\s+(this|it)/i,
  /\bmight\s+(work|fix|solve)/i,
];

function checkAssumptionLanguage(content: string): GuardResult {
  // Check in comments and strings
  const commentMatches = content.match(/\/\/.*$|\/\*[\s\S]*?\*\/|`[^`]*`|"[^"]*"|'[^']*'/gm);
  const textToCheck = commentMatches?.join(' ') ?? '';

  for (const pattern of ASSUMPTION_PATTERNS) {
    if (pattern.test(textToCheck)) {
      return {
        ok: false,
        error: `Guard 13: Assumption language detected. Replace with evidence-based statements.`,
      };
    }
  }
  return { ok: true };
}

// =============================================================================
// Guard 14: Throw Patterns
// =============================================================================

const INVARIANT_CONTEXTS = [/invariant/i, /unreachable/i, /assert/i, /exhaustive/i, /impossible/i, /never/i];

function checkThrowPatterns(content: string): GuardResult {
  const lines = content.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] ?? '';
    if (!/\bthrow\s+new\s+(Error|\w+Error)\s*\(/.test(line)) continue;

    // Check context (2 lines before and after)
    const context = [lines[i - 2], lines[i - 1], line, lines[i + 1], lines[i + 2]].join(' ');

    const isInvariant = INVARIANT_CONTEXTS.some((p) => p.test(context));
    if (!isInvariant) {
      return {
        ok: false,
        error: `Guard 14: throw detected (line ${i + 1}). Use Effect.fail() or Result types for expected failures.`,
      };
    }
  }

  return { ok: true };
}

// =============================================================================
// Guard 26: Console
// =============================================================================

const CONSOLE_PATTERNS = [/console\.log\(/, /console\.error\(/, /console\.warn\(/, /console\.debug\(/, /console\.info\(/];

function checkConsole(content: string): GuardResult {
  const clean = stripCommentsAndStrings(content);
  for (const pattern of CONSOLE_PATTERNS) {
    if (pattern.test(clean)) {
      return { ok: false, error: `Guard 26: console.* detected. Use Effect logging instead.` };
    }
  }
  return { ok: true };
}

// =============================================================================
// Guards 32-39: Parse-at-Boundary (Advisory - handled by pre-commit hooks)
// =============================================================================

// These are advisory and full AST analysis happens at git commit time.
// We skip them here for performance.

// =============================================================================
// Main Entry Point
// =============================================================================

export async function runContentGuards(content: string | undefined, filePath: string | undefined): Promise<GuardResult> {
  if (!content || !filePath) return { ok: true };
  if (!isTypeScriptFile(filePath)) return { ok: true };
  if (isExcludedPath(filePath)) return { ok: true };

  // Run all content guards
  const guards = [
    () => checkForbiddenImports(content),
    () => checkAnyType(content),
    () => checkZodInfer(content),
    () => checkNoMocks(content),
    () => checkAssumptionLanguage(content),
    () => checkThrowPatterns(content),
    () => checkConsole(content),
  ];

  for (const guard of guards) {
    const result = guard();
    if (!result.ok) return result;
  }

  return { ok: true };
}
