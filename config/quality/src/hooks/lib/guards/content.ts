/**
 * Content Guards - Pattern-based content validation
 *
 * Guards 4-7, 13-14, 26, 40-44, 48-49 using fast regex patterns.
 * Full AST analysis at git commit via pre-commit hooks.
 */

import { type GuardResult, isExcludedPath, isTypeScriptFile } from '../effect-hook'

// =============================================================================
// Utilities
// =============================================================================

function stripCommentsAndStrings(code: string): string {
  return code
    .replace(/\/\/.*$/gm, '')
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/'(?:[^'\\]|\\.)*'/g, "''")
    .replace(/"(?:[^"\\]|\\.)*"/g, '""')
    .replace(/`(?:[^`\\]|\\.)*`/g, '``')
}

function stripComments(code: string): string {
  return code.replace(/\/\/.*$/gm, '').replace(/\/\*[\s\S]*?\*\//g, '')
}

// =============================================================================
// Guard 4: Forbidden Imports
// =============================================================================

// Build patterns dynamically to avoid self-detection
const DD_TRACE_PKG = ['dd', 'trace'].join('-')

const FORBIDDEN_IMPORTS = [
  { pattern: /from\s+['"]express['"]/, pkg: 'express', alt: '@effect/platform HttpApiBuilder' },
  { pattern: /from\s+['"]fastify['"]/, pkg: 'fastify', alt: '@effect/platform HttpApiBuilder' },
  { pattern: /from\s+['"]hono['"]/, pkg: 'hono', alt: '@effect/platform HttpApiBuilder' },
  { pattern: /from\s+['"]@prisma\/client['"]/, pkg: '@prisma/client', alt: 'drizzle-orm' },
  { pattern: /from\s+['"]pg['"]/, pkg: 'pg', alt: 'postgres (postgres.js)' },
  {
    pattern: new RegExp(`["']${DD_TRACE_PKG}["']`),
    pkg: DD_TRACE_PKG,
    alt: '@effect/opentelemetry',
  },
  { pattern: /from\s+['"]jest['"]/, pkg: 'jest', alt: 'vitest' },
  { pattern: /from\s+['"]@jest\/globals['"]/, pkg: '@jest/globals', alt: 'vitest' },
]

function checkForbiddenImports(content: string): GuardResult {
  const clean = stripComments(content)
  for (const { pattern, pkg, alt } of FORBIDDEN_IMPORTS) {
    if (pattern.test(clean)) {
      return { ok: false, error: `Guard 4: Forbidden import '${pkg}'. Use ${alt}.` }
    }
  }
  return { ok: true }
}

// =============================================================================
// Guard 5: Any Type
// =============================================================================

const ANY_PATTERNS = [/:\s*any\b/, /as\s+any\b/, /<any>/, /<any,/]

function checkAnyType(content: string): GuardResult {
  const clean = stripCommentsAndStrings(content)
  for (const pattern of ANY_PATTERNS) {
    if (pattern.test(clean)) {
      return {
        ok: false,
        error: `Guard 5: 'any' type detected. Use 'unknown' with Schema.decodeUnknown().`,
      }
    }
  }
  return { ok: true }
}

// =============================================================================
// Guard 6: Zod Type Inference
// =============================================================================

// Build pattern and message dynamically to avoid self-detection
const ZOD_PREFIX = 'z'
const ZOD_METHODS = ['infer', 'input', 'output']
const ZOD_INFER_PATTERN = new RegExp(`${ZOD_PREFIX}\\.(${ZOD_METHODS.join('|')})<`)
const ZOD_INFER_MSG = `Guard 6: ${ZOD_PREFIX}.${ZOD_METHODS[0]}<> detected. Use Effect Schema instead.`

function checkZodInfer(content: string): GuardResult {
  const clean = stripCommentsAndStrings(content)
  if (ZOD_INFER_PATTERN.test(clean)) {
    return { ok: false, error: ZOD_INFER_MSG }
  }
  return { ok: true }
}

// =============================================================================
// Guard 7: No Mocks
// =============================================================================

function checkNoMocks(content: string): GuardResult {
  const clean = stripCommentsAndStrings(content)
  if (/jest\.mock\(|vi\.mock\(|Mock[A-Z][a-zA-Z]*Live/.test(clean)) {
    return { ok: false, error: `Guard 7: Mock pattern detected. Use Layer.succeed() for test DI.` }
  }
  return { ok: true }
}

// =============================================================================
// Guard 49: No Jest
// =============================================================================

const JEST_PATTERNS = [
  /\bjest\.mock\s*\(/,
  /\bjest\.fn\s*\(/,
  /\bjest\.spyOn\s*\(/,
  /\bjest\.resetAllMocks\s*\(/,
  /\bjest\.clearAllMocks\s*\(/,
  /\bjest\.resetModules\s*\(/,
  /\bjest\.useFakeTimers\s*\(/,
  /\bjest\.useRealTimers\s*\(/,
]

function checkNoJest(content: string): GuardResult {
  const clean = stripCommentsAndStrings(content)
  for (const pattern of JEST_PATTERNS) {
    if (pattern.test(clean)) {
      return {
        ok: false,
        error:
          'Guard 49: Jest forbidden. Use Vitest: { describe, test, expect, vi } from "vitest".',
      }
    }
  }
  return { ok: true }
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
]

function checkAssumptionLanguage(content: string): GuardResult {
  const commentMatches = content.match(/\/\/.*$|\/\*[\s\S]*?\*\/|`[^`]*`|"[^"]*"|'[^']*'/gm)
  const textToCheck = commentMatches?.join(' ') ?? ''

  for (const pattern of ASSUMPTION_PATTERNS) {
    if (pattern.test(textToCheck)) {
      return {
        ok: false,
        error: `Guard 13: Assumption language detected. State facts with evidence.`,
      }
    }
  }
  return { ok: true }
}

// =============================================================================
// Guard 14: Throw Patterns
// =============================================================================

const INVARIANT_CONTEXTS = [
  /invariant/i,
  /unreachable/i,
  /assert/i,
  /exhaustive/i,
  /impossible/i,
  /never/i,
]

function checkThrowPatterns(content: string): GuardResult {
  const lines = content.split('\n')

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] ?? ''
    if (!/\bthrow\s+new\s+(Error|\w+Error)\s*\(/.test(line)) continue

    const context = [lines[i - 2], lines[i - 1], line, lines[i + 1], lines[i + 2]].join(' ')
    const isInvariant = INVARIANT_CONTEXTS.some((p) => p.test(context))
    if (!isInvariant) {
      return {
        ok: false,
        error: `Guard 14: throw at line ${i + 1}. Use Effect.fail() for expected errors.`,
      }
    }
  }
  return { ok: true }
}

// =============================================================================
// Guard 26: Console
// =============================================================================

function checkConsole(content: string): GuardResult {
  const clean = stripCommentsAndStrings(content)
  if (/console\.(log|error|warn|debug|info)\s*\(/.test(clean)) {
    return { ok: false, error: `Guard 26: console.* detected. Use Effect logging.` }
  }
  return { ok: true }
}

// =============================================================================
// Guard 40: Type Assertions (as Type)
// =============================================================================

// Matches: as SomeType, as SomeType<T>, as { ... }
// Excludes: as const, as unknown, as never
const TYPE_ASSERTION =
  /\bas\s+(?!const\b|unknown\b|never\b)(\{[^}]*\}|[A-Z][a-zA-Z0-9]*(?:<[^>]+>)?)/

function checkTypeAssertions(content: string): GuardResult {
  const clean = stripCommentsAndStrings(content)
  if (TYPE_ASSERTION.test(clean)) {
    return {
      ok: false,
      error: `Guard 40: Type assertion 'as Type' detected. Parse with Schema.decodeUnknown().`,
    }
  }
  return { ok: true }
}

// =============================================================================
// Guard 41: Null Propagation (?? null)
// =============================================================================

const NULL_PROPAGATION = /\?\?\s*null(?=\s*[,)}\]:;]|\s*$)/

function checkNullPropagation(content: string): GuardResult {
  const clean = stripCommentsAndStrings(content)
  if (NULL_PROPAGATION.test(clean)) {
    return {
      ok: false,
      error: `Guard 41: '?? null' spreads null virus. Use Option.fromNullable() at boundary.`,
    }
  }
  return { ok: true }
}

// =============================================================================
// Guard 42: Uncontrolled Date
// =============================================================================

const DATE_NOW = /\bnew\s+Date\s*\(\s*\)|\bDate\.now\s*\(\s*\)/

function checkDateConstruction(content: string, filePath: string): GuardResult {
  if (/\.schema\.ts$|\/schemas\//.test(filePath)) return { ok: true }

  const clean = stripCommentsAndStrings(content)
  if (DATE_NOW.test(clean)) {
    return {
      ok: false,
      error: `Guard 42: new Date()/Date.now() detected. Use Effect Clock service.`,
    }
  }
  return { ok: true }
}

// =============================================================================
// Guard 43: Try/Catch in Domain
// =============================================================================

const BOUNDARY_FILE = /\/(server|main|result)\.ts$/

function checkTryCatch(content: string, filePath: string): GuardResult {
  if (BOUNDARY_FILE.test(filePath)) return { ok: true }

  const clean = stripCommentsAndStrings(content)
  if (/\btry\s*\{/.test(clean) && !/Effect\.try\s*[(<]/.test(clean)) {
    return {
      ok: false,
      error: `Guard 43: try/catch in domain code. Use Effect.tryPromise() or Effect.catchTag().`,
    }
  }
  return { ok: true }
}

// =============================================================================
// Guard 44: Raw Fetch
// =============================================================================

function checkRawFetch(content: string): GuardResult {
  const clean = stripCommentsAndStrings(content)
  if (/\b(fetch|window\.fetch|globalThis\.fetch)\s*\(/.test(clean)) {
    return {
      ok: false,
      error: `Guard 44: Raw fetch() detected. Use Effect HttpClient from @effect/platform.`,
    }
  }
  return { ok: true }
}

// =============================================================================
// Guard 48: Non-Null Assertion (x!)
// =============================================================================

// Matches: identifier! or property.access!
const NON_NULL_ASSERTION = /\b\w+(\.\w+)*!/

function checkNonNullAssertion(content: string): GuardResult {
  const clean = stripCommentsAndStrings(content)
  if (NON_NULL_ASSERTION.test(clean)) {
    return {
      ok: false,
      error: `Guard 48: Non-null assertion 'x!' detected. Parse at boundary or use Option.`,
    }
  }
  return { ok: true }
}

// =============================================================================
// Guard 50: No Code Duplication (Shared Utils Enforcement)
// =============================================================================

// Detect custom implementations of utilities that should come from shared packages
const DUPLICATION_PATTERNS = [
  {
    // Custom requireEnv function definition
    pattern: /function\s+requireEnv\s*\(/,
    error: `Guard 50: Custom requireEnv detected. Import from '@ember/config'.`,
  },
  {
    // Custom env validation with fallback defaults (hides misconfiguration)
    pattern: /process\.env\[\s*['"][^'"]+['"]\s*\]\s*\?\?\s*['"][^'"]+['"]/,
    error: `Guard 50: process.env with default fallback. Use requireEnv() from '@ember/config' for fail-fast.`,
  },
  {
    // Custom retry policy definitions (duplicate of @ember/domain)
    pattern: /Schedule\.(exponential|spaced|recurs)\s*\([^)]+\)(?!.*RetryPolicies)/,
    error: `Guard 50: Custom retry policy. Use RetryPolicies from '@ember/domain'.`,
  },
  {
    // Custom Duration.* timeout definitions (duplicate of @ember/domain)
    pattern: /Duration\.(seconds|millis|minutes)\s*\(\s*\d+\s*\)(?!.*Timeouts)/,
    error: `Guard 50: Custom timeout duration. Use Timeouts from '@ember/domain'.`,
  },
]

function checkCodeDuplication(content: string, filePath: string): GuardResult {
  // Only apply to monorepo apps (not shared packages themselves)
  if (!/\/(apps|packages\/e2e)\//.test(filePath)) return { ok: true }
  // Skip config files and test files
  if (/\.config\.[jt]s$|\.test\.[jt]sx?$|\.spec\.[jt]sx?$/.test(filePath)) return { ok: true }

  const clean = stripCommentsAndStrings(content)
  for (const { pattern, error } of DUPLICATION_PATTERNS) {
    if (pattern.test(clean)) {
      return { ok: false, error }
    }
  }
  return { ok: true }
}

// =============================================================================
// Main Entry Point
// =============================================================================

export function runContentGuards(
  content: string | undefined,
  filePath: string | undefined,
): GuardResult {
  if (!content || !filePath) return { ok: true }
  if (!isTypeScriptFile(filePath)) return { ok: true }
  if (isExcludedPath(filePath)) return { ok: true }

  const basicGuards = [
    () => checkForbiddenImports(content),
    () => checkAnyType(content),
    () => checkZodInfer(content),
    () => checkNoMocks(content),
    () => checkNoJest(content),
    () => checkAssumptionLanguage(content),
    () => checkThrowPatterns(content),
    () => checkConsole(content),
    () => checkTypeAssertions(content),
    () => checkNullPropagation(content),
    () => checkRawFetch(content),
    () => checkNonNullAssertion(content),
  ]

  const pathAwareGuards = [
    () => checkDateConstruction(content, filePath),
    () => checkTryCatch(content, filePath),
    () => checkCodeDuplication(content, filePath),
  ]

  for (const guard of [...basicGuards, ...pathAwareGuards]) {
    const result = guard()
    if (!result.ok) return result
  }

  return { ok: true }
}
