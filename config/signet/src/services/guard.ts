/**
 * Guard Service - Pre-write AST Validation
 *
 * Validates code content using AST-grep rules before writing.
 * Uses the PatternEngineLive layer for AST analysis.
 */

import { join } from 'node:path';
import { Effect } from 'effect';
import {
  applyRules,
  detectLanguage,
  loadRulesFromDirectory,
  PatternEngineLive,
  type PatternMatch,
  type PatternRule,
} from '@/layers/patterns';

// =============================================================================
// Types (TypeScript first)
// =============================================================================

export type GuardViolation = {
  readonly rule: string;
  readonly severity: 'error' | 'warning';
  readonly message: string;
  readonly line?: number;
  readonly column?: number;
  readonly fix?: string;
};

export type GuardCheckResult = {
  readonly violations: readonly GuardViolation[];
  readonly passed: boolean;
  readonly blockers: number;
  readonly warnings: number;
};

// =============================================================================
// Configuration
// =============================================================================

/** Path to AST-grep rules directory */
const HOME = process.env['HOME'];
if (!HOME) {
  throw new Error('HOME environment variable not set - required for AST-grep rules');
}
const AST_GREP_RULES_DIR = join(HOME, 'dotfiles/config/agents/rules/ast-grep');

/** Default rules to apply (file basenames without extension) */
const DEFAULT_RULES = [
  'no-any-type',
  'no-zod-infer',
  'no-mock-patterns',
  'no-throw-expected',
  'no-should-work',
];

// =============================================================================
// Helper Functions
// =============================================================================

/**
 * Convert PatternMatch to GuardViolation
 */
function toGuardViolation(match: PatternMatch): GuardViolation {
  const base = {
    rule: match.rule,
    severity: match.severity === 'error' ? ('error' as const) : ('warning' as const),
    message: match.message,
    line: match.node.range.start.line + 1, // 1-indexed
    column: match.node.range.start.column + 1, // 1-indexed
  };

  // Use object spread instead of mutation for type safety
  return match.fix?.replacement ? { ...base, fix: match.fix.replacement } : base;
}

/**
 * Check if file path is a TypeScript file
 */
function isTypeScriptFile(filePath: string): boolean {
  return /\.(ts|tsx|js|jsx|mjs|cjs)$/.test(filePath);
}

// =============================================================================
// Cached Rules (loaded once)
// =============================================================================

let cachedRules: PatternRule[] | null = null;

/**
 * Load rules from directory (with caching)
 */
const loadRules = Effect.gen(function* () {
  if (cachedRules !== null) {
    return cachedRules;
  }

  const rules = yield* loadRulesFromDirectory(AST_GREP_RULES_DIR);
  cachedRules = [...rules];
  return cachedRules;
});

// =============================================================================
// Service Functions (Effect-based)
// =============================================================================

/**
 * Check content against AST-grep rules
 */
export const checkContent = (
  content: string,
  filePath: string,
  ruleFilter?: readonly string[]
): Effect.Effect<GuardCheckResult, Error> =>
  Effect.gen(function* () {
    // Only check TypeScript files
    if (!isTypeScriptFile(filePath)) {
      return {
        violations: [],
        passed: true,
        blockers: 0,
        warnings: 0,
      };
    }

    // Load rules
    const allRules = yield* loadRules;

    // Filter rules if specified
    const rulesToApply = ruleFilter
      ? allRules.filter((r) => ruleFilter.includes(r.id))
      : allRules.filter((r) => DEFAULT_RULES.includes(r.id));

    if (rulesToApply.length === 0) {
      return {
        violations: [],
        passed: true,
        blockers: 0,
        warnings: 0,
      };
    }

    // Detect language
    const language = detectLanguage(filePath);

    // Apply rules
    const result = yield* applyRules(content, language, rulesToApply, filePath);

    // Convert matches to violations
    const violations = result.matches.map(toGuardViolation);
    const blockers = violations.filter((v) => v.severity === 'error').length;
    const warnings = violations.filter((v) => v.severity === 'warning').length;

    return {
      violations,
      passed: blockers === 0,
      blockers,
      warnings,
    };
  }).pipe(Effect.provide(PatternEngineLive));

/**
 * Check content with all available rules (not just defaults)
 */
export const checkContentAllRules = (
  content: string,
  filePath: string
): Effect.Effect<GuardCheckResult, Error> =>
  Effect.gen(function* () {
    // Only check TypeScript files
    if (!isTypeScriptFile(filePath)) {
      return {
        violations: [],
        passed: true,
        blockers: 0,
        warnings: 0,
      };
    }

    // Load rules
    const allRules = yield* loadRules;

    if (allRules.length === 0) {
      return {
        violations: [],
        passed: true,
        blockers: 0,
        warnings: 0,
      };
    }

    // Detect language
    const language = detectLanguage(filePath);

    // Apply all rules
    const result = yield* applyRules(content, language, allRules, filePath);

    // Convert matches to violations
    const violations = result.matches.map(toGuardViolation);
    const blockers = violations.filter((v) => v.severity === 'error').length;
    const warnings = violations.filter((v) => v.severity === 'warning').length;

    return {
      violations,
      passed: blockers === 0,
      blockers,
      warnings,
    };
  }).pipe(Effect.provide(PatternEngineLive));

// =============================================================================
// Formatting
// =============================================================================

/**
 * Format guard check result for MCP output
 */
export function formatGuardResult(result: GuardCheckResult, filePath: string): string {
  const lines: string[] = [];
  lines.push('━'.repeat(50));
  lines.push('  SIGNET CODE GUARD');
  lines.push('━'.repeat(50));
  lines.push('');
  lines.push(`File: ${filePath}`);
  lines.push(`Status: ${result.passed ? '✅ PASS' : '❌ BLOCKED'}`);
  lines.push('');

  if (result.violations.length > 0) {
    if (result.blockers > 0) {
      lines.push(`❌ BLOCKERS (${result.blockers}):`);
      const blockerViolations = result.violations.filter((v) => v.severity === 'error');
      for (const v of blockerViolations.slice(0, 5)) {
        lines.push(`  • [${v.rule}] ${v.message}`);
        if (v.line) {
          lines.push(`    at line ${v.line}, column ${v.column ?? 1}`);
        }
        if (v.fix) {
          lines.push(`    Fix: ${v.fix.slice(0, 50)}${v.fix.length > 50 ? '...' : ''}`);
        }
      }
      if (blockerViolations.length > 5) {
        lines.push(`  ... and ${blockerViolations.length - 5} more`);
      }
      lines.push('');
    }

    if (result.warnings > 0) {
      lines.push(`⚠️  WARNINGS (${result.warnings}):`);
      const warningViolations = result.violations.filter((v) => v.severity === 'warning');
      for (const v of warningViolations.slice(0, 5)) {
        lines.push(`  • [${v.rule}] ${v.message}`);
        if (v.line) {
          lines.push(`    at line ${v.line}, column ${v.column ?? 1}`);
        }
      }
      if (warningViolations.length > 5) {
        lines.push(`  ... and ${warningViolations.length - 5} more`);
      }
      lines.push('');
    }
  } else {
    lines.push('No violations found.');
    lines.push('');
  }

  lines.push(`Rules: ${DEFAULT_RULES.join(', ')}`);

  return lines.join('\n');
}
