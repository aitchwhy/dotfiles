/**
 * AST Engine Effect Layer
 *
 * Provides TypeScript AST manipulation via ts-morph as an Effect Layer.
 * Used for drift detection and code reconciliation.
 *
 * This is the Port/Adapter pattern:
 * - Port: AstEngineService interface
 * - Adapter: AstEngineLive implementation using ts-morph
 */
import { Context, Effect, Layer } from 'effect'
import { Project, type SourceFile } from 'ts-morph'

// =============================================================================
// Types
// =============================================================================

/**
 * Types of drift that can be detected
 */
export type DriftType =
  | 'missing-import'
  | 'missing-zod-schema'
  | 'missing-result-type'
  | 'missing-export'
  | 'invalid-import-path'

/**
 * Severity of a drift issue
 */
export type DriftSeverity = 'error' | 'warning'

/**
 * A single drift issue detected in code
 */
export interface DriftIssue {
  readonly type: DriftType
  readonly severity: DriftSeverity
  readonly message: string
  readonly line?: number
  readonly column?: number
  readonly fix?: {
    readonly description: string
    readonly replacement: string
  }
}

/**
 * Report of all drift issues in a file
 */
export interface DriftReport {
  readonly filePath: string
  readonly issues: readonly DriftIssue[]
  readonly hasErrors: boolean
  readonly hasWarnings: boolean
}

/**
 * Configuration for drift detection patterns
 */
export interface PatternConfig {
  readonly requireZodImport: boolean
  readonly requireResultType: boolean
  readonly requireExplicitExports: boolean
}

/**
 * AST Engine service interface (Port)
 */
export interface AstEngineService {
  readonly createSourceFile: (path: string, content: string) => Effect.Effect<SourceFile, Error>
  readonly parseSourceFile: (path: string) => Effect.Effect<SourceFile, Error>
  readonly detectDrift: (
    sf: SourceFile,
    patterns: PatternConfig
  ) => Effect.Effect<DriftReport, Error>
  readonly reconcile: (
    sf: SourceFile,
    issues: readonly DriftIssue[]
  ) => Effect.Effect<string, Error>
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
] as const

/**
 * Check if a file uses zod (z.) but doesn't import it
 * Uses specific Zod API patterns to avoid false positives from regex patterns
 */
function checkZodImport(sf: SourceFile): DriftIssue | undefined {
  const text = sf.getFullText()

  // Check if any Zod API pattern is used in the file
  const usesZod = ZOD_API_PATTERNS.some((pattern) => text.includes(pattern))
  if (!usesZod) return undefined

  // Check if zod is imported
  const imports = sf.getImportDeclarations()
  const hasZodImport = imports.some(
    (imp) => imp.getModuleSpecifierValue() === 'zod' || imp.getModuleSpecifierValue() === 'zod/v4'
  )

  if (!hasZodImport) {
    return {
      type: 'missing-import',
      severity: 'error',
      message: "File uses 'z.' but doesn't import from 'zod'",
      fix: {
        description: "Add import { z } from 'zod'",
        replacement: "import { z } from 'zod';\n",
      },
    }
  }

  return undefined
}

/**
 * Check if async functions that could fail return Result type
 */
function checkResultType(sf: SourceFile): DriftIssue[] {
  const issues: DriftIssue[] = []

  // Get all exported functions
  const functions = sf.getFunctions().filter((fn) => fn.isExported())

  for (const fn of functions) {
    const returnType = fn.getReturnType().getText()
    const isAsync = fn.isAsync()
    const name = fn.getName() ?? 'anonymous'

    // Check if function returns Promise but not Result
    if (isAsync && returnType.includes('Promise<') && !returnType.includes('Result<')) {
      // Heuristic: handler functions that deal with external data should return Result
      const isHandler =
        name.toLowerCase().includes('handle') ||
        name.toLowerCase().includes('process') ||
        name.toLowerCase().includes('fetch')

      if (isHandler) {
        issues.push({
          type: 'missing-result-type',
          severity: 'warning',
          message: `Async function '${name}' could fail but doesn't return Result type`,
          line: fn.getStartLineNumber(),
          fix: {
            description: 'Change return type to Promise<Result<...>>',
            replacement: 'Promise<Result<Response, Error>>',
          },
        })
      }
    }

    // Check non-async functions that could fail
    if (!isAsync && !returnType.includes('Result<')) {
      const hasParseInName = name.toLowerCase().includes('parse')
      const hasValidateInName = name.toLowerCase().includes('validate')

      if (hasParseInName || hasValidateInName) {
        issues.push({
          type: 'missing-result-type',
          severity: 'warning',
          message: `Function '${name}' appears to parse/validate but doesn't return Result type`,
          line: fn.getStartLineNumber(),
        })
      }
    }
  }

  return issues
}

/**
 * Run all drift detection checks on a source file
 */
function runDriftDetection(sf: SourceFile, patterns: PatternConfig): DriftReport {
  const issues: DriftIssue[] = []
  const filePath = sf.getFilePath()

  // Check Zod import
  if (patterns.requireZodImport) {
    const zodIssue = checkZodImport(sf)
    if (zodIssue) issues.push(zodIssue)
  }

  // Check Result type usage
  if (patterns.requireResultType) {
    const resultIssues = checkResultType(sf)
    issues.push(...resultIssues)
  }

  return {
    filePath,
    issues,
    hasErrors: issues.some((i) => i.severity === 'error'),
    hasWarnings: issues.some((i) => i.severity === 'warning'),
  }
}

// =============================================================================
// Live Implementation (Adapter)
// =============================================================================

/**
 * Create a ts-morph Project instance (singleton per service)
 */
const createProject = (): Project => {
  return new Project({
    useInMemoryFileSystem: true,
    compilerOptions: {
      strict: true,
      target: 99, // ESNext
      module: 99, // ESNext
    },
  })
}

/**
 * Create the live AstEngine service implementation
 */
const makeAstEngineService = (): AstEngineService => {
  const project = createProject()

  return {
    createSourceFile: (path: string, content: string) =>
      Effect.try({
        try: () => project.createSourceFile(path, content, { overwrite: true }),
        catch: (e) => new Error(`Failed to create source file ${path}: ${e}`),
      }),

    parseSourceFile: (path: string) =>
      Effect.try({
        try: () => {
          const sf = project.addSourceFileAtPath(path)
          return sf
        },
        catch: (e) => new Error(`Failed to parse source file ${path}: ${e}`),
      }),

    detectDrift: (sf: SourceFile, patterns: PatternConfig) =>
      Effect.try({
        try: () => runDriftDetection(sf, patterns),
        catch: (e) => new Error(`Failed to detect drift: ${e}`),
      }),

    reconcile: (sf: SourceFile, issues: readonly DriftIssue[]) =>
      Effect.try({
        try: () => {
          // Apply fixes for issues that have them
          for (const issue of issues) {
            if (issue.fix && issue.type === 'missing-import') {
              // Prepend import to file
              sf.insertText(0, issue.fix.replacement)
            }
          }
          return sf.getFullText()
        },
        catch: (e) => new Error(`Failed to reconcile: ${e}`),
      }),
  }
}

/**
 * AstEngineLive - the live Layer providing the AstEngine service
 */
export const AstEngineLive = Layer.succeed(AstEngine, makeAstEngineService())

// =============================================================================
// Convenience Functions
// =============================================================================

/**
 * Create a source file from content - requires AstEngine in context
 */
export const createSourceFile = (
  path: string,
  content: string
): Effect.Effect<SourceFile, Error, AstEngine> =>
  Effect.flatMap(AstEngine, (engine) => engine.createSourceFile(path, content))

/**
 * Parse a source file from disk - requires AstEngine in context
 */
export const parseSourceFile = (path: string): Effect.Effect<SourceFile, Error, AstEngine> =>
  Effect.flatMap(AstEngine, (engine) => engine.parseSourceFile(path))

/**
 * Detect drift in a source file - requires AstEngine in context
 */
export const detectDrift = (
  sf: SourceFile,
  patterns: PatternConfig
): Effect.Effect<DriftReport, Error, AstEngine> =>
  Effect.flatMap(AstEngine, (engine) => engine.detectDrift(sf, patterns))

/**
 * Reconcile drift issues in a source file - requires AstEngine in context
 */
export const reconcile = (
  sf: SourceFile,
  issues: readonly DriftIssue[]
): Effect.Effect<string, Error, AstEngine> =>
  Effect.flatMap(AstEngine, (engine) => engine.reconcile(sf, issues))
