#!/usr/bin/env bun

/**
 * Unified Polish - Full Quality Gate for PostToolUse
 *
 * PARAGON Enforcement System v3.7
 *
 * PHASE 1: Format (parallel, non-blocking)
 * - biome format (TS/JS/JSON)
 * - ruff format + lint (Python)
 * - nixfmt (Nix)
 * - shfmt (Shell)
 * - prettier (YAML/TOML/CSS)
 * - stylua (Lua)
 *
 * PHASE 2: Lint (blocking, exit 2)
 * - oxlint (645+ rules, type-aware)
 *
 * PHASE 3: AST-Grep (blocking, exit 2)
 * - paragon rules
 * - effect rules
 * - xstate rules
 *
 * PHASE 4: Type Check (blocking, exit 2)
 * - tsc --noEmit
 *
 * Exit codes:
 * - 0: Success (emitContinue)
 * - 2: Quality violation (emitHalt with reason)
 */

import * as fs from 'node:fs'
import * as path from 'node:path'
import { spawn } from 'bun'
import { Effect, pipe } from 'effect'
import { emitContinue, emitHalt, logError, logWarning } from './lib/hook-logging'

// ============================================================================
// Configuration
// ============================================================================

const filePaths = (process.env['CLAUDE_FILE_PATHS'] ?? '').split(',').filter(Boolean)
const RULES_DIR = `${process.env['HOME']}/dotfiles/config/quality/rules`

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

const runAstGrep = (files: readonly string[]): Effect.Effect<QualityResult> =>
  files.length === 0
    ? Effect.succeed({ tool: 'ast-grep', success: true, output: '' })
    : pipe(
        Effect.tryPromise({
          try: async () => {
            // Check if rules directory exists
            if (!fs.existsSync(RULES_DIR)) {
              return { tool: 'ast-grep', success: true, output: '' }
            }

            const categories = ['paragon', 'effect', 'effect-xstate', 'xstate', 'zod', 'versions']
            const errors: string[] = []

            for (const category of categories) {
              const categoryDir = path.join(RULES_DIR, category)
              if (!fs.existsSync(categoryDir)) continue

              const ruleFiles = fs.readdirSync(categoryDir).filter((f) => f.endsWith('.yml'))
              for (const ruleFile of ruleFiles) {
                const rulePath = path.join(categoryDir, ruleFile)
                const proc = spawn(['ast-grep', 'scan', '--rule', rulePath, ...files], {
                  stderr: 'pipe',
                  stdout: 'pipe',
                })

                const [stdout, stderr] = await Promise.all([
                  new Response(proc.stdout).text(),
                  new Response(proc.stderr).text(),
                ])
                const exitCode = await proc.exited

                // ast-grep exits non-zero when it finds matches
                if (exitCode !== 0) {
                  const output = (stdout + stderr)
                    .split('\n')
                    .filter(
                      (line) =>
                        !line.includes('paragon-guard') &&
                        !line.includes('sig-') &&
                        !line.includes('ast-engine'),
                    )
                    .join('\n')
                    .trim()

                  if (
                    output.length > 0 &&
                    (output.includes('error') ||
                      output.includes('warning') ||
                      output.includes('note:'))
                  ) {
                    errors.push(`=== ${category}/${ruleFile} ===\n${output}`)
                  }
                }
              }
            }

            return {
              tool: 'ast-grep',
              success: errors.length === 0,
              output: errors.join('\n\n'),
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

  if (tsJsFiles.length === 0) {
    emitContinue()
    return
  }

  // Run quality checks in parallel
  const [oxlintResult, astGrepResult, tscResult] = yield* Effect.all(
    [
      runQualityCheck('oxlint', ['oxlint', '--deny', 'correctness'], tsJsFiles),
      runAstGrep(tsJsFiles),
      runTypeCheck(tsJsFiles),
    ],
    { concurrency: 'unbounded' },
  )

  // Collect failures
  const failures: QualityResult[] = [oxlintResult, astGrepResult, tscResult].filter(
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
