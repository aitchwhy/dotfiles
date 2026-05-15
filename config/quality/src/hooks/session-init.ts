#!/usr/bin/env bun

/**
 * Session Init Hook
 *
 * Runs at SessionStart. Effect-based, no try/catch.
 * - Logs session start
 * - Cleans old plan files (>7 days)
 * - Environment warnings
 */

import { exec } from 'node:child_process'
import * as fs from 'node:fs/promises'
import * as os from 'node:os'
import * as path from 'node:path'
import { promisify } from 'node:util'
import { Cause, Console, Effect, pipe } from 'effect'
import { isCodexOutputContext } from './lib/hook-output-codex'

const execAsync = promisify(exec)

// =============================================================================
// Config (using os.homedir() for testability)
// =============================================================================

const HOME = os.homedir()
// When invoked from Codex (cx recipe sets CODEX_HOME), plans + logs land
// under $CODEX_HOME so they don't intermix with Claude state. Cleanup
// honors the same dir, so old Codex plans get GC'd alongside Claude's.
const CODEX_HOME = process.env['CODEX_HOME']
const BASE_DIR = CODEX_HOME ?? `${HOME}/.claude`
const PLANS_DIR = `${BASE_DIR}/plans`
const MAX_AGE_DAYS = 7
const LOG_FILE = `${BASE_DIR}/session.log`

// =============================================================================
// Types
// =============================================================================

type SessionStartOutput = {
  readonly continue: boolean
  readonly additionalContext?: string
  readonly hookSpecificOutput?: {
    readonly hookEventName: 'SessionStart'
    readonly additionalContext: string
  }
}

// =============================================================================
// Helpers
// =============================================================================

/**
 * Check if a file/directory exists - Effect pattern (no .then().catch())
 */
const fileExists = (filePath: string) =>
  Effect.tryPromise(() => fs.access(filePath)).pipe(
    Effect.map(() => true),
    Effect.catchAll(() => Effect.succeed(false)),
  )

const appendToLog = (message: string) =>
  Effect.gen(function* () {
    yield* Effect.tryPromise(async () => {
      await fs.mkdir(path.dirname(LOG_FILE), { recursive: true })
      await fs.appendFile(LOG_FILE, `${message}\n`)
    })
  })

const cleanOldPlans = Effect.gen(function* () {
  const exists = yield* fileExists(PLANS_DIR)
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
  const nixShellInfo = yield* fileExists('/tmp/.nix-shell-info')
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

  const hasFlake = yield* fileExists(path.join(cwd, 'flake.nix'))
  const inNixShell = yield* isInNixShell
  if (hasFlake && !inNixShell) {
    warnings.push('⚠️ Nix project - consider nix develop.')
  }

  const hasPackageLock = yield* fileExists(path.join(cwd, 'package-lock.json'))
  if (hasPackageLock) {
    warnings.push('⚠️ package-lock.json found - use pnpm.')
  }

  const hasEnv = yield* fileExists(path.join(cwd, '.env'))
  const hasEnvExample = yield* fileExists(path.join(cwd, '.env.example'))
  if (hasEnv && !hasEnvExample) {
    warnings.push('⚠️ .env without .env.example.')
  }

  return warnings
})

const sessionStartOutput = (additionalContext?: string): SessionStartOutput => {
  if (additionalContext === undefined) return { continue: true }
  if (!isCodexOutputContext()) return { continue: true, additionalContext }
  return {
    continue: true,
    hookSpecificOutput: {
      hookEventName: 'SessionStart',
      additionalContext,
    },
  }
}

const outputResult = (result: SessionStartOutput) => Console.log(JSON.stringify(result))

// =============================================================================
// Main
// =============================================================================

const main = Effect.gen(function* () {
  const messages: string[] = []

  // 1. Log session start (must be first - sequential)
  const timestamp = new Date().toISOString()
  yield* appendToLog(`[${timestamp}] Session started: ${process.cwd()}`)

  // 2-3. Run independent checks in parallel
  const [deletedCount, warnings] = yield* Effect.all(
    [
      cleanOldPlans.pipe(Effect.catchAll(() => Effect.succeed(0))),
      checkEnvironment.pipe(Effect.catchAll(() => Effect.succeed([] as string[]))),
    ],
    { concurrency: 'unbounded' },
  )

  // Aggregate messages
  if (deletedCount > 0) {
    messages.push(`Cleaned ${deletedCount} stale plan(s).`)
  }
  messages.push(...warnings)

  // Output result
  yield* outputResult(sessionStartOutput(messages.length > 0 ? messages.join(' ') : undefined))
})

void pipe(
  main,
  Effect.catchAllCause((cause) =>
    outputResult(sessionStartOutput(`Hook error: ${Cause.pretty(cause)}`)),
  ),
  Effect.runPromise,
)
