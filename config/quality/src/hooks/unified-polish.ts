#!/usr/bin/env bun
/**
 * Unified Polish - Consolidated PostToolUse formatter
 *
 * REPLACES:
 * - TypeScript/JS formatter (biome)
 * - Python formatter (ruff)
 * - Nix formatter (alejandra)
 * - JSON formatter (biome)
 * - Shell formatter (shfmt)
 * - YAML/TOML formatter (prettier)
 * - Lua formatter (stylua)
 * - CSS/SCSS formatter (prettier)
 * - SQL formatter (sql-formatter)
 *
 * Key optimization: All formatters run in PARALLEL via Effect.all()
 * This consolidation reduces shell spawns from 9 → 1 per Write/Edit operation.
 */

import { spawn } from 'bun'
import { Effect, pipe } from 'effect'
import { emitContinue } from './lib/hook-logging'

// ============================================================================
// Configuration
// ============================================================================

const filePaths = (process.env['CLAUDE_FILE_PATHS'] ?? '').split(',').filter(Boolean)

// Exit early if no files
if (filePaths.length === 0) {
  process.exit(0)
}

// Group files by extension for targeted formatting
const filesByExt = new Map<string, string[]>()
for (const path of filePaths) {
  const ext = path.split('.').pop()?.toLowerCase() ?? ''
  const files = filesByExt.get(ext) ?? []
  files.push(path)
  filesByExt.set(ext, files)
}

// ============================================================================
// Formatter Runners (Effect-based)
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
// Format Tasks (Run in Parallel)
// ============================================================================

const getFiles = (ext: string) => filesByExt.get(ext) ?? []

const program = Effect.gen(function* () {
  // TypeScript/JavaScript/JSX/TSX → Biome
  const tsJsFiles = [...getFiles('ts'), ...getFiles('tsx'), ...getFiles('js'), ...getFiles('jsx')]

  // JSON → Biome
  const jsonFiles = getFiles('json')

  // Python → Ruff format + lint (sequential)
  const pyFiles = getFiles('py')

  // Nix → nixfmt (RFC-style by default)
  const nixFiles = getFiles('nix')

  // Shell → shfmt
  const shellFiles = [...getFiles('sh'), ...getFiles('bash'), ...getFiles('zsh')]

  // YAML/TOML → Prettier
  const yamlTomlFiles = [...getFiles('yaml'), ...getFiles('yml'), ...getFiles('toml')]

  // Lua → Stylua
  const luaFiles = getFiles('lua')

  // CSS/SCSS → Prettier
  const cssFiles = [...getFiles('css'), ...getFiles('scss')]

  // SQL → sql-formatter
  const sqlFiles = getFiles('sql')

  // Run all formatters in parallel
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

  emitContinue()
})

// ============================================================================
// Run
// ============================================================================

void pipe(
  program,
  Effect.catchAll(() => Effect.sync(() => emitContinue())),
  Effect.runPromise,
)
