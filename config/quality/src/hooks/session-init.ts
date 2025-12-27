#!/usr/bin/env bun

/**
 * Session Init Hook
 *
 * Runs at SessionStart. Effect-based, no try/catch.
 * - Logs session start
 * - Cleans old plan files (>7 days)
 * - Environment warnings
 * - Evolution metrics display
 */

import { exec } from 'node:child_process'
import * as fs from 'node:fs/promises'
import * as os from 'node:os'
import * as path from 'node:path'
import { promisify } from 'node:util'
import { Console, Effect, pipe } from 'effect'

const execAsync = promisify(exec)

// =============================================================================
// Config (using os.homedir() for testability)
// =============================================================================

const HOME = os.homedir()
const DOTFILES = `${HOME}/dotfiles`
const PLANS_DIR = `${HOME}/.claude/plans`
const MAX_AGE_DAYS = 7
const LOG_FILE = `${HOME}/.claude/session.log`

// =============================================================================
// Types
// =============================================================================

type SessionStartOutput = {
  readonly continue: boolean
  readonly additionalContext?: string
}

// =============================================================================
// Helpers
// =============================================================================

const appendToLog = (message: string) =>
  Effect.gen(function* () {
    yield* Effect.tryPromise(async () => {
      await fs.mkdir(path.dirname(LOG_FILE), { recursive: true })
      await fs.appendFile(LOG_FILE, `${message}\n`)
    })
  })

const cleanOldPlans = Effect.gen(function* () {
  const exists = yield* Effect.tryPromise(() =>
    fs
      .access(PLANS_DIR)
      .then(() => true)
      .catch(() => false),
  )
  if (!exists) return 0

  const result = yield* Effect.tryPromise(async () => {
    const { stdout } = await execAsync(
      `fd -t f -e md --changed-before ${MAX_AGE_DAYS}d . "${PLANS_DIR}" 2>/dev/null || true`,
    )
    return stdout.trim().split('\n').filter(Boolean)
  })

  let count = 0
  for (const file of result) {
    yield* Effect.tryPromise(() => fs.unlink(file)).pipe(
      Effect.tap(() => Effect.sync(() => count++)),
      Effect.catchAll(() => Effect.succeed(undefined)),
    )
  }
  return count
})

const isInNixShell = Effect.gen(function* () {
  // Check for .nix-shell-info file that nix develop creates
  const nixShellInfo = yield* Effect.tryPromise(() =>
    fs
      .access('/tmp/.nix-shell-info')
      .then(() => true)
      .catch(() => false),
  )
  if (nixShellInfo) return true

  // Check for flake-based dev shell marker
  const result = yield* Effect.tryPromise(async () => {
    const { stdout } = await execAsync('printenv IN_NIX_SHELL 2>/dev/null || true')
    return stdout.trim().length > 0
  }).pipe(Effect.catchAll(() => Effect.succeed(false)))

  return result
})

const checkEnvironment = Effect.gen(function* () {
  const warnings: string[] = []
  const cwd = process.cwd()

  const hasFlake = yield* Effect.tryPromise(() =>
    fs
      .access(path.join(cwd, 'flake.nix'))
      .then(() => true)
      .catch(() => false),
  )
  const inNixShell = yield* isInNixShell
  if (hasFlake && !inNixShell) {
    warnings.push('⚠️ Nix project - consider nix develop.')
  }

  const hasPackageLock = yield* Effect.tryPromise(() =>
    fs
      .access(path.join(cwd, 'package-lock.json'))
      .then(() => true)
      .catch(() => false),
  )
  if (hasPackageLock) {
    warnings.push('⚠️ package-lock.json found - use pnpm.')
  }

  const hasEnv = yield* Effect.tryPromise(() =>
    fs
      .access(path.join(cwd, '.env'))
      .then(() => true)
      .catch(() => false),
  )
  const hasEnvExample = yield* Effect.tryPromise(() =>
    fs
      .access(path.join(cwd, '.env.example'))
      .then(() => true)
      .catch(() => false),
  )
  if (hasEnv && !hasEnvExample) {
    warnings.push('⚠️ .env without .env.example.')
  }

  return warnings
})

const checkEvolutionMetrics = Effect.gen(function* () {
  const metricsPath = `${DOTFILES}/.claude-metrics/latest.json`

  const exists = yield* Effect.tryPromise(() =>
    fs
      .access(metricsPath)
      .then(() => true)
      .catch(() => false),
  )
  if (!exists) return undefined

  const stats = yield* Effect.tryPromise(() => fs.stat(metricsPath))
  const ageHours = Math.floor((Date.now() - stats.mtimeMs) / (1000 * 60 * 60))

  if (ageHours <= 24) return undefined

  const content = yield* Effect.tryPromise(() => fs.readFile(metricsPath, 'utf-8'))
  const metrics = yield* Effect.try({
    try: () => JSON.parse(content) as { overall_score?: number; recommendation?: string },
    catch: () => ({ overall_score: undefined, recommendation: 'unknown' }),
  })

  const score = metrics.overall_score ? Math.floor(metrics.overall_score * 100) : '?'
  const rec = metrics.recommendation ?? 'unknown'

  return `🧬 Evolution: ${score}% (${rec}) - stale (${ageHours}h). Run: just evolve.`
})

const outputResult = (result: SessionStartOutput) => Console.log(JSON.stringify(result))

// =============================================================================
// Main
// =============================================================================

const main = Effect.gen(function* () {
  const messages: string[] = []

  // 1. Log session start
  const timestamp = new Date().toISOString()
  yield* appendToLog(`[${timestamp}] Session started: ${process.cwd()}`)

  // 2. Clean old plans
  const deletedCount = yield* cleanOldPlans.pipe(Effect.catchAll(() => Effect.succeed(0)))
  if (deletedCount > 0) {
    messages.push(`Cleaned ${deletedCount} stale plan(s).`)
  }

  // 3. Environment warnings
  const warnings = yield* checkEnvironment.pipe(Effect.catchAll(() => Effect.succeed([])))
  messages.push(...warnings)

  // 4. Evolution metrics
  const evolutionMsg = yield* checkEvolutionMetrics.pipe(
    Effect.catchAll(() => Effect.succeed(undefined)),
  )
  if (evolutionMsg) {
    messages.push(evolutionMsg)
  }

  // Output result
  const output: SessionStartOutput =
    messages.length > 0
      ? { continue: true, additionalContext: messages.join(' ') }
      : { continue: true }

  yield* outputResult(output)
})

pipe(
  main,
  Effect.catchAll((error) =>
    outputResult({ continue: true, additionalContext: `Hook error: ${String(error)}` }),
  ),
  Effect.runPromise,
)
