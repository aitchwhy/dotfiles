/**
 * Effect-TS Logging Utilities
 *
 * Standardized logging layers for CLI and service contexts.
 * All logging in the codebase MUST use these Effect-based patterns.
 */

import { Effect, Layer, Logger, LogLevel } from 'effect'

// =============================================================================
// Types
// =============================================================================

/**
 * Hook output format for Claude Code protocol
 */
export type HookOutput = {
  readonly decision: 'allow' | 'block' | 'skip'
  readonly reason?: string
  readonly [key: string]: unknown
}

// =============================================================================
// CLI Logging Layer
// =============================================================================

/**
 * Pretty-printed logging for CLI tools (doctor, generators, etc.)
 * Human-readable format with colors and formatting.
 * In Effect-TS 3.x, Logger.pretty is already a Layer.
 */
export const CliLoggerLive = Logger.pretty

/**
 * Minimal logging (warnings and errors only) for quiet mode
 */
export const QuietLoggerLive = Layer.mergeAll(
  Logger.pretty,
  Logger.minimumLogLevel(LogLevel.Warning),
)

// =============================================================================
// Service Logging Layer
// =============================================================================

/**
 * Structured JSON logging for services (MCP server, daemons)
 * Machine-parseable format for log aggregation.
 * In Effect-TS 3.x, Logger.json is already a Layer.
 */
export const ServiceLoggerLive = Logger.json

/**
 * Debug-level logging for development
 */
export const DebugLoggerLive = Layer.mergeAll(Logger.pretty, Logger.minimumLogLevel(LogLevel.Debug))

// =============================================================================
// Hook Logging Layer (Claude Code Protocol)
// =============================================================================

/**
 * Custom logger for Claude Code hooks.
 * Outputs JSON to stdout for protocol compliance.
 * Format: { level, message, annotations, timestamp }
 */
const HookLogger = Logger.make(({ logLevel, message, annotations }) => {
  // For hook protocol, we need raw JSON on stdout
  const output = JSON.stringify({
    level: logLevel.label,
    message,
    ...Object.fromEntries(annotations),
    timestamp: new Date().toISOString(),
  })
  process.stdout.write(`${output}\n`)
})

/**
 * Logger layer for Claude Code hooks.
 * Use this for paragon-guard.ts, session-polish.ts, verification-gate.ts, etc.
 * In Effect-TS 3.x, we create a Layer by providing our custom HookLogger
 * using Logger.add or by replacing the default with Logger.replaceScoped.
 */
export const HookLoggerLive = Logger.add(HookLogger)

// =============================================================================
// Convenience Functions
// =============================================================================

/**
 * Run an Effect with CLI-style pretty logging
 */
export const runWithCliLogging = <A, E>(effect: Effect.Effect<A, E>): Promise<A> =>
  Effect.runPromise(effect.pipe(Effect.provide(CliLoggerLive)))

/**
 * Run an Effect synchronously with CLI-style pretty logging
 */
export const runSyncWithCliLogging = <A, E>(effect: Effect.Effect<A, E>): A =>
  Effect.runSync(effect.pipe(Effect.provide(CliLoggerLive)))

/**
 * Run an Effect with structured JSON logging
 */
export const runWithServiceLogging = <A, E>(effect: Effect.Effect<A, E>): Promise<A> =>
  Effect.runPromise(effect.pipe(Effect.provide(ServiceLoggerLive)))

/**
 * Run an Effect with hook protocol logging (stdout JSON)
 */
export const runWithHookLogging = <A, E>(effect: Effect.Effect<A, E>): A =>
  Effect.runSync(effect.pipe(Effect.provide(HookLoggerLive)))

// =============================================================================
// Hook Protocol Helpers
// =============================================================================

/**
 * Output a hook decision to stdout in the Claude Code protocol format.
 * This is the primary interface for hooks to communicate decisions.
 *
 * @example
 * ```typescript
 * emitHookDecision({ decision: 'allow' });
 * emitHookDecision({ decision: 'block', reason: 'Guard 5 violation' });
 * ```
 */
export const emitHookDecision = (output: HookOutput): void => {
  process.stdout.write(`${JSON.stringify(output)}\n`)
}

/**
 * Effect version of emitHookDecision for use in Effect pipelines.
 *
 * @example
 * ```typescript
 * yield* logHookDecision({ decision: 'allow' });
 * ```
 */
export const logHookDecision = (output: HookOutput): Effect.Effect<void> =>
  Effect.sync(() => emitHookDecision(output))

/**
 * Log an error to stderr for hooks (does not affect protocol output).
 * Use for internal errors that shouldn't be part of the decision.
 */
const stringifyError = (error: unknown): string =>
  error instanceof Error
    ? error.message
    : typeof error === 'string'
      ? error
      : error === undefined || error === null
        ? ''
        : JSON.stringify(error)

export const logHookError = (message: string, error?: unknown): Effect.Effect<void> =>
  Effect.sync(() => {
    const errorMessage = stringifyError(error)
    process.stderr.write(`[hook-error] ${message}${errorMessage ? `: ${errorMessage}` : ''}\n`)
  })
