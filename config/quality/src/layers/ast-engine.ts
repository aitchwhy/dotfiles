/**
 * AST Engine Effect Layer
 *
 * Provides TypeScript AST manipulation via OXC as an Effect Layer.
 * Used for drift detection and code reconciliation.
 *
 * This is the Port/Adapter pattern:
 * - Port: AstEngineService interface
 * - Adapter: AstEngineLive implementation using OXC
 *
 * @see https://www.npmjs.com/package/oxc-parser
 * @version oxc-parser@0.101.0
 */
import { Context, Effect, Layer } from 'effect';
import type { Program } from 'oxc-parser';
import { parseSync } from 'oxc-parser';

// =============================================================================
// Types
// =============================================================================

/**
 * Parsed source file representation (OXC-based)
 */
export interface ParsedSource {
  readonly filePath: string;
  readonly content: string;
  readonly program: Program;
  readonly errors: readonly ParseError[];
}

/**
 * Parse error from OXC
 */
export interface ParseError {
  readonly message: string;
  readonly span: { readonly start: number; readonly end: number };
}

/**
 * Types of drift that can be detected
 */
export type DriftType =
  | 'missing-import'
  | 'missing-zod-schema'
  | 'missing-result-type'
  | 'missing-export'
  | 'invalid-import-path';

/**
 * Severity of a drift issue
 */
export type DriftSeverity = 'error' | 'warning';

/**
 * A single drift issue detected in code
 */
export interface DriftIssue {
  readonly type: DriftType;
  readonly severity: DriftSeverity;
  readonly message: string;
  readonly line?: number;
  readonly column?: number;
  readonly fix?: {
    readonly description: string;
    readonly replacement: string;
  };
}

/**
 * Report of all drift issues in a file
 */
export interface DriftReport {
  readonly filePath: string;
  readonly issues: readonly DriftIssue[];
  readonly hasErrors: boolean;
  readonly hasWarnings: boolean;
}

/**
 * Configuration for drift detection patterns
 */
export interface PatternConfig {
  readonly requireZodImport: boolean;
  readonly requireResultType: boolean;
  readonly requireExplicitExports: boolean;
}

/**
 * AST Engine service interface (Port)
 */
export interface AstEngineService {
  readonly createSourceFile: (path: string, content: string) => Effect.Effect<ParsedSource, Error>;
  readonly parseSourceFile: (path: string) => Effect.Effect<ParsedSource, Error>;
  readonly detectDrift: (
    source: ParsedSource,
    patterns: PatternConfig
  ) => Effect.Effect<DriftReport, Error>;
  readonly reconcile: (
    source: ParsedSource,
    issues: readonly DriftIssue[]
  ) => Effect.Effect<string, Error>;
}

// =============================================================================
// Context Tag (Port Definition)
// =============================================================================

/**
 * AstEngine Context Tag - the Port that consumers depend on
 */
export class AstEngine extends Context.Tag('AstEngine')<AstEngine, AstEngineService>() {}

// =============================================================================
// Drift Detection Logic
// =============================================================================

/**
 * Common Zod API methods that indicate actual Zod usage
 */
const ZOD_API_PATTERNS = [
  'z.object(',
  'z.string(',
  'z.number(',
  'z.boolean(',
  'z.array(',
  'z.enum(',
  'z.union(',
  'z.literal(',
  'z.optional(',
  'z.nullable(',
  'z.tuple(',
  'z.record(',
  'z.map(',
  'z.set(',
  'z.any(',
  'z.unknown(',
  'z.never(',
  'z.void(',
  'z.date(',
  'z.bigint(',
  'z.symbol(',
  'z.function(',
  'z.lazy(',
  'z.promise(',
  'z.instanceof(',
  'z.coerce.',
  'z.infer<',
  'z.input<',
  'z.output<',
] as const;

/**
 * Check if a file uses zod (z.) but doesn't import it
 * Uses specific Zod API patterns to avoid false positives from regex patterns
 */
function checkZodImport(source: ParsedSource): DriftIssue | undefined {
  const text = source.content;

  // Check if any Zod API pattern is used in the file
  const usesZod = ZOD_API_PATTERNS.some((pattern) => text.includes(pattern));
  if (!usesZod) return undefined;

  // Check if zod is imported by looking at import statements in the AST
  const hasZodImport = source.program.body.some((stmt) => {
    if (stmt.type === 'ImportDeclaration') {
      const importSource = stmt.source.value;
      return importSource === 'zod' || importSource === 'zod/v4';
    }
    return false;
  });

  if (!hasZodImport) {
    return {
      type: 'missing-import',
      severity: 'error',
      message: "File uses 'z.' but doesn't import from 'zod'",
      fix: {
        description: "Add import { z } from 'zod'",
        replacement: "import { z } from 'zod';\n",
      },
    };
  }

  return undefined;
}

/**
 * Check if async functions that could fail return Result type
 * Uses pattern-based heuristics since OXC doesn't provide full type inference
 */
function checkResultType(source: ParsedSource): DriftIssue[] {
  const issues: DriftIssue[] = [];
  const text = source.content;

  // Find exported function declarations using regex patterns
  // This is a simplified heuristic approach since OXC doesn't provide type inference
  const exportedFunctionPattern = /export\s+(async\s+)?function\s+(\w+)\s*\([^)]*\)\s*:\s*([^{]+)/g;
  let match: RegExpExecArray | null;

  while ((match = exportedFunctionPattern.exec(text)) !== null) {
    const isAsync = Boolean(match[1]);
    const name = match[2] ?? '';
    const returnType = (match[3] ?? '').trim();

    // Skip if we couldn't extract name or return type
    if (!name || !returnType) continue;

    // Check if function returns Promise but not Result
    if (isAsync && returnType.includes('Promise<') && !returnType.includes('Result<')) {
      // Heuristic: handler functions that deal with external data should return Result
      const nameLower = name.toLowerCase();
      const isHandler =
        nameLower.includes('handle') ||
        nameLower.includes('process') ||
        nameLower.includes('fetch');

      if (isHandler) {
        // Calculate approximate line number
        const lineNumber = text.substring(0, match.index).split('\n').length;

        issues.push({
          type: 'missing-result-type',
          severity: 'warning',
          message: `Async function '${name}' could fail but doesn't return Result type`,
          line: lineNumber,
          fix: {
            description: 'Change return type to Promise<Result<...>>',
            replacement: 'Promise<Result<Response, Error>>',
          },
        });
      }
    }

    // Check non-async functions that could fail
    if (!isAsync && !returnType.includes('Result<')) {
      const nameLower = name.toLowerCase();
      const hasParseInName = nameLower.includes('parse');
      const hasValidateInName = nameLower.includes('validate');

      if (hasParseInName || hasValidateInName) {
        const lineNumber = text.substring(0, match.index).split('\n').length;

        issues.push({
          type: 'missing-result-type',
          severity: 'warning',
          message: `Function '${name}' appears to parse/validate but doesn't return Result type`,
          line: lineNumber,
        });
      }
    }
  }

  return issues;
}

/**
 * Run all drift detection checks on a source file
 */
function runDriftDetection(source: ParsedSource, patterns: PatternConfig): DriftReport {
  const issues: DriftIssue[] = [];

  // Check Zod import
  if (patterns.requireZodImport) {
    const zodIssue = checkZodImport(source);
    if (zodIssue) issues.push(zodIssue);
  }

  // Check Result type usage
  if (patterns.requireResultType) {
    const resultIssues = checkResultType(source);
    issues.push(...resultIssues);
  }

  return {
    filePath: source.filePath,
    issues,
    hasErrors: issues.some((i) => i.severity === 'error'),
    hasWarnings: issues.some((i) => i.severity === 'warning'),
  };
}

// =============================================================================
// Live Implementation (Adapter)
// =============================================================================

import { readFile } from 'node:fs/promises';

/**
 * Parse source code using OXC
 */
const parseWithOxc = (filePath: string, content: string): ParsedSource => {
  const result = parseSync(filePath, content);

  return {
    filePath,
    content,
    program: result.program,
    errors: result.errors.map((e) => ({
      message: e.message,
      // OXC errors use 'labels' array with spans, fallback to 0 if not available
      span: {
        start:
          (e as unknown as { labels?: Array<{ span: { start: number } }> }).labels?.[0]?.span
            ?.start ?? 0,
        end:
          (e as unknown as { labels?: Array<{ span: { end: number } }> }).labels?.[0]?.span?.end ??
          0,
      },
    })),
  };
};

/**
 * Create the live AstEngine service implementation
 */
const makeAstEngineService = (): AstEngineService => ({
  createSourceFile: (path: string, content: string) =>
    Effect.try({
      try: () => parseWithOxc(path, content),
      catch: (e) => new Error(`Failed to create source file ${path}: ${e}`),
    }),

  parseSourceFile: (path: string) =>
    Effect.tryPromise({
      try: async () => {
        const content = await readFile(path, 'utf-8');
        return parseWithOxc(path, content);
      },
      catch: (e) => new Error(`Failed to parse source file ${path}: ${e}`),
    }),

  detectDrift: (source: ParsedSource, patterns: PatternConfig) =>
    Effect.try({
      try: () => runDriftDetection(source, patterns),
      catch: (e) => new Error(`Failed to detect drift: ${e}`),
    }),

  reconcile: (source: ParsedSource, issues: readonly DriftIssue[]) =>
    Effect.try({
      try: () => {
        let content = source.content;

        // Apply fixes for issues that have them
        // Sort by position (reverse order) to preserve offsets
        const fixableIssues = [...issues]
          .filter((i) => i.fix)
          .sort((a, b) => (b.line ?? 0) - (a.line ?? 0));

        for (const issue of fixableIssues) {
          if (issue.fix && issue.type === 'missing-import') {
            // Prepend import to file
            content = issue.fix.replacement + content;
          }
        }

        return content;
      },
      catch: (e) => new Error(`Failed to reconcile: ${e}`),
    }),
});

/**
 * AstEngineLive - the live Layer providing the AstEngine service
 */
export const AstEngineLive = Layer.succeed(AstEngine, makeAstEngineService());

// =============================================================================
// Convenience Functions
// =============================================================================

/**
 * Create a source file from content - requires AstEngine in context
 */
export const createSourceFile = (
  path: string,
  content: string
): Effect.Effect<ParsedSource, Error, AstEngine> =>
  Effect.flatMap(AstEngine, (engine) => engine.createSourceFile(path, content));

/**
 * Parse a source file from disk - requires AstEngine in context
 */
export const parseSourceFile = (path: string): Effect.Effect<ParsedSource, Error, AstEngine> =>
  Effect.flatMap(AstEngine, (engine) => engine.parseSourceFile(path));

/**
 * Detect drift in a source file - requires AstEngine in context
 */
export const detectDrift = (
  source: ParsedSource,
  patterns: PatternConfig
): Effect.Effect<DriftReport, Error, AstEngine> =>
  Effect.flatMap(AstEngine, (engine) => engine.detectDrift(source, patterns));

/**
 * Reconcile drift issues in a source file - requires AstEngine in context
 */
export const reconcile = (
  source: ParsedSource,
  issues: readonly DriftIssue[]
): Effect.Effect<string, Error, AstEngine> =>
  Effect.flatMap(AstEngine, (engine) => engine.reconcile(source, issues));
