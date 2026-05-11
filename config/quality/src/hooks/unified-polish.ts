#!/usr/bin/env bun

/**
 * Unified Polish - Full Quality Gate for PostToolUse
 *
 * PHASE 1: Format (parallel, non-blocking)
 * PHASE 2: Lint - oxlint (blocking)
 * PHASE 3: AST-Grep - delegates to project sgconfig.yml (blocking)
 * PHASE 4: Type Check - tsc --noEmit (blocking)
 *
 * Exit codes:
 * - 0: Success (emitContinue)
 * - 2: Quality violation (emitHalt with reason)
 */

import * as fs from 'node:fs'
import * as path from 'node:path'
import { spawn } from 'bun'
import { Effect, pipe, Schema } from 'effect'
import { FORBIDDEN_PACKAGES } from '../stack'
import { findSgConfigs } from './lib/find-sgconfig'
import { emitContinue, emitHalt, logError, logWarning } from './lib/hook-logging'

// ============================================================================
// Configuration
// ============================================================================

const filePaths = (process.env['CLAUDE_FILE_PATHS'] ?? '').split(',').filter(Boolean)

// Exit early if no files
if (filePaths.length === 0) {
  emitContinue()
  process.exit(0)
}

// Group files by extension for targeted processing
const filesByExt = new Map<string, string[]>()
for (const filePath of filePaths) {
  const lastDotIndex = filePath.lastIndexOf('.')
  const ext = lastDotIndex > 0 ? filePath.slice(lastDotIndex + 1).toLowerCase() : ''
  const files = filesByExt.get(ext) ?? []
  files.push(filePath)
  filesByExt.set(ext, files)
}

const getFiles = (ext: string) => filesByExt.get(ext) ?? []

// TypeScript/JavaScript files for linting and type checking
const tsJsFiles = [...getFiles('ts'), ...getFiles('tsx'), ...getFiles('js'), ...getFiles('jsx')]

// ============================================================================
// Formatter Runners (Effect-based, non-blocking)
// ============================================================================

const runFormatter = (cmd: readonly string[], files: readonly string[]) =>
  files.length === 0
    ? Effect.void
    : pipe(
        Effect.tryPromise({
          try: async () => {
            const proc = spawn([...cmd, ...files], {
              stderr: 'ignore',
              stdout: 'ignore',
            })
            await proc.exited
          },
          catch: () => new Error('Formatter failed'),
        }),
        Effect.ignore, // Formatters should never block - ignore errors
      )

// ============================================================================
// Linter/Checker Runners (Effect-based, blocking)
// ============================================================================

type QualityResult = {
  readonly tool: string
  readonly success: boolean
  readonly output: string
}

const runQualityCheck = (
  tool: string,
  cmd: readonly string[],
  files: readonly string[],
): Effect.Effect<QualityResult> =>
  files.length === 0
    ? Effect.succeed({ tool, success: true, output: '' })
    : pipe(
        Effect.tryPromise({
          try: async () => {
            const proc = spawn([...cmd, ...files], {
              stderr: 'pipe',
              stdout: 'pipe',
            })
            const [stdout, stderr] = await Promise.all([
              new Response(proc.stdout).text(),
              new Response(proc.stderr).text(),
            ])
            const exitCode = await proc.exited
            return {
              tool,
              success: exitCode === 0,
              output: (stdout + stderr).trim(),
            }
          },
          catch: () => new Error(`Failed to run ${tool}`),
        }),
        Effect.catchAll((error) =>
          Effect.succeed({
            tool,
            success: false,
            output: `Failed to run ${tool}: ${error.message}`,
          }),
        ),
      )

// ============================================================================
// AST-Grep Runner
// ============================================================================

const runAstGrep = (files: readonly string[]): Effect.Effect<QualityResult> => {
  if (files.length === 0) {
    return Effect.succeed({ tool: 'ast-grep', success: true, output: '' })
  }

  // Find project root + all sgconfig*.yml files (uses first file as reference).
  const found = findSgConfigs(files[0]!)
  if (!found) {
    return Effect.succeed({ tool: 'ast-grep', success: true, output: '' })
  }
  const { root, configs } = found

  return pipe(
    Effect.tryPromise({
      try: async () => {
        const sections: string[] = []
        let allOk = true

        for (const config of configs) {
          const proc = spawn(['ast-grep', 'scan', '-c', config, ...files], {
            cwd: root,
            stderr: 'pipe',
            stdout: 'pipe',
          })

          const [stdout, stderr] = await Promise.all([
            new Response(proc.stdout).text(),
            new Response(proc.stderr).text(),
          ])
          const exitCode = await proc.exited
          const output = (stdout + stderr).trim()

          if (exitCode !== 0) {
            allOk = false
            sections.push(
              output.length > 0
                ? `── ${config} ──\n${output}`
                : `── ${config} ── (exit ${exitCode})`,
            )
          }
        }

        return {
          tool: 'ast-grep',
          success: allOk,
          output: sections.join('\n\n'),
        }
      },
      catch: () => new Error('Failed to run ast-grep'),
    }),
    Effect.catchAll((error) =>
      Effect.succeed({
        tool: 'ast-grep',
        success: false,
        output: `Failed to run ast-grep: ${error.message}`,
      }),
    ),
  )
}

// ============================================================================
// Package.json Forbidden-Dependency Check (was: enforce-packages.ts)
// ============================================================================

const PackageJsonSchema = Schema.Struct({
  dependencies: Schema.optional(Schema.Record({ key: Schema.String, value: Schema.String })),
  devDependencies: Schema.optional(Schema.Record({ key: Schema.String, value: Schema.String })),
})

const runPackageJsonCheck = (files: readonly string[]): Effect.Effect<QualityResult> => {
  const packageJsonFiles = files.filter((p) => p.endsWith('package.json'))
  if (packageJsonFiles.length === 0) {
    return Effect.succeed({ tool: 'forbidden-packages', success: true, output: '' })
  }

  return pipe(
    Effect.tryPromise({
      try: async () => {
        const violations: string[] = []
        for (const pkgPath of packageJsonFiles) {
          const content = await Bun.file(pkgPath).text()
          const rawJson = JSON.parse(content)
          const decoded = await Effect.runPromise(
            Schema.decodeUnknown(PackageJsonSchema)(rawJson).pipe(
              Effect.catchAll(() =>
                Effect.succeed(
                  {} as {
                    dependencies?: Record<string, string>
                    devDependencies?: Record<string, string>
                  },
                ),
              ),
            ),
          )
          const allDeps: Record<string, string> = {
            ...decoded.dependencies,
            ...decoded.devDependencies,
          }
          for (const forbidden of FORBIDDEN_PACKAGES) {
            if (allDeps[forbidden.name]) {
              violations.push(
                `  - ${forbidden.name} (${pkgPath}): ${forbidden.reason}. Alternative: ${forbidden.alternative}`,
              )
            }
          }
        }
        return {
          tool: 'forbidden-packages',
          success: violations.length === 0,
          output: violations.length > 0 ? `STACK VIOLATION:\n${violations.join('\n')}` : '',
        }
      },
      catch: () => new Error('Failed to scan package.json files'),
    }),
    Effect.catchAll((error) =>
      Effect.succeed({
        tool: 'forbidden-packages',
        success: false,
        output: `Failed: ${error.message}`,
      }),
    ),
  )
}

// ============================================================================
// TypeScript Type Check Runner
// ============================================================================

const findTsConfig = (file: string): string | null => {
  let dir = path.dirname(file)
  while (dir !== '/') {
    const tsconfig = path.join(dir, 'tsconfig.json')
    if (fs.existsSync(tsconfig)) {
      return dir
    }
    dir = path.dirname(dir)
  }
  return null
}

const runTypeCheck = (files: readonly string[]): Effect.Effect<QualityResult> => {
  // Find unique project roots that have tsconfig.json
  const projectRoots = new Set<string>()
  for (const file of files) {
    const root = findTsConfig(file)
    if (root !== null) projectRoots.add(root)
  }

  if (projectRoots.size === 0) {
    return Effect.succeed({ tool: 'tsc', success: true, output: '' })
  }

  return pipe(
    Effect.tryPromise({
      try: async () => {
        const errors: string[] = []

        for (const root of projectRoots) {
          const proc = spawn(['npx', 'tsc', '--noEmit', '--pretty'], {
            cwd: root,
            stderr: 'pipe',
            stdout: 'pipe',
          })

          const [stdout, stderr] = await Promise.all([
            new Response(proc.stdout).text(),
            new Response(proc.stderr).text(),
          ])
          const exitCode = await proc.exited

          if (exitCode !== 0) {
            const output = (stdout + stderr).trim()
            // Filter to only show errors for modified files
            const relevantLines = output
              .split('\n')
              .filter((line) => files.some((f) => line.includes(path.basename(f))))
              .join('\n')

            if (relevantLines.length > 0) {
              errors.push(`=== ${root} ===\n${relevantLines}`)
            }
          }
        }

        return {
          tool: 'tsc',
          success: errors.length === 0,
          output: errors.join('\n\n'),
        }
      },
      catch: () => new Error('Failed to run tsc'),
    }),
    Effect.catchAll((error) =>
      Effect.succeed({
        tool: 'tsc',
        success: false,
        output: `Failed to run tsc: ${error.message}`,
      }),
    ),
  )
}

// ============================================================================
// Main Program
// ============================================================================

const program = Effect.gen(function* () {
  // JSON files for biome
  const jsonFiles = getFiles('json')

  // Python files
  const pyFiles = getFiles('py')

  // Nix files
  const nixFiles = getFiles('nix')

  // Shell files
  const shellFiles = [...getFiles('sh'), ...getFiles('bash'), ...getFiles('zsh')]

  // YAML/TOML files
  const yamlTomlFiles = [...getFiles('yaml'), ...getFiles('yml'), ...getFiles('toml')]

  // Lua files
  const luaFiles = getFiles('lua')

  // CSS/SCSS files
  const cssFiles = [...getFiles('css'), ...getFiles('scss')]

  // SQL files
  const sqlFiles = getFiles('sql')

  // ============================================================================
  // PHASE 1: Format (parallel, non-blocking)
  // ============================================================================

  yield* Effect.all(
    [
      runFormatter(['bunx', '@biomejs/biome', 'format', '--write'], tsJsFiles),
      runFormatter(['bunx', '@biomejs/biome', 'format', '--write'], jsonFiles),
      // Python needs sequential format then lint
      pipe(
        runFormatter(['ruff', 'format'], pyFiles),
        Effect.andThen(runFormatter(['ruff', 'check', '--fix'], pyFiles)),
      ),
      runFormatter(['nixfmt'], nixFiles),
      runFormatter(['shfmt', '-w'], shellFiles),
      runFormatter(['npx', 'prettier', '--write'], yamlTomlFiles),
      runFormatter(['stylua'], luaFiles),
      runFormatter(['npx', 'prettier', '--write'], cssFiles),
      runFormatter(['npx', 'sql-formatter', '--fix'], sqlFiles),
    ],
    { concurrency: 'unbounded' },
  )

  // ============================================================================
  // PHASE 2-4: Quality Checks (blocking)
  // Only run on TS/JS/TSX/JSX files
  // ============================================================================

  const packageJsonFiles = filePaths.filter((p) => p.endsWith('package.json'))

  if (tsJsFiles.length === 0 && packageJsonFiles.length === 0) {
    emitContinue()
    return
  }

  // Run quality checks in parallel
  const [oxlintResult, astGrepResult, tscResult, pkgResult] = yield* Effect.all(
    [
      runQualityCheck('oxlint', ['oxlint', '--deny', 'correctness'], tsJsFiles),
      runAstGrep(tsJsFiles),
      runTypeCheck(tsJsFiles),
      runPackageJsonCheck(filePaths),
    ],
    { concurrency: 'unbounded' },
  )

  // Collect failures
  const failures: QualityResult[] = [oxlintResult, astGrepResult, tscResult, pkgResult].filter(
    (r) => !r.success,
  )

  if (failures.length > 0) {
    const reasons = failures
      .map((f) => {
        const preview = f.output.split('\n').slice(0, 10).join('\n')
        return `**${f.tool}**: ${preview}${f.output.split('\n').length > 10 ? '\n...(truncated)' : ''}`
      })
      .join('\n\n')

    logWarning('unified-polish', `Quality gate failed: ${failures.map((f) => f.tool).join(', ')}`)
    emitHalt({ reason: `Quality gate violation:\n${reasons}` })
    process.exit(2)
  }

  emitContinue()
})

// ============================================================================
// Run
// ============================================================================

void pipe(
  program,
  Effect.catchAll((error) => {
    logError('unified-polish', error)
    emitContinue() // Don't block on unexpected errors
    return Effect.void
  }),
  Effect.runPromise,
)
