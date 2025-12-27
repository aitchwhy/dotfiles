/**
 * Hook Logging Utilities
 *
 * Provides standardized logging for Claude Code hooks.
 * Uses process.stdout/stderr to comply with hook protocol.
 *
 * Zero dependencies - hooks should be lightweight.
 */

// =============================================================================
// Types
// =============================================================================

/**
 * PreToolUse hook decision output for Claude Code protocol
 */
export type HookDecision = {
  readonly decision: 'approve' | 'block' | 'skip'
  readonly reason?: string
  readonly [key: string]: unknown
}

/**
 * PostToolUse/Stop hook output for Claude Code protocol
 */
export type HookContinue = {
  readonly continue: boolean
  readonly [key: string]: unknown
}

// =============================================================================
// Hook Protocol Output
// =============================================================================

/**
 * Emit a hook decision to stdout in the Claude Code protocol format.
 * This is the primary interface for hooks to communicate decisions.
 *
 * @example
 * ```typescript
 * emitDecision({ decision: 'approve' });
 * emitDecision({ decision: 'block', reason: 'Guard 5 violation' });
 * ```
 */
export const emitDecision = (output: HookDecision): void => {
  process.stdout.write(`${JSON.stringify(output)}\n`)
}

/**
 * Emit an approval decision
 */
export const approve = (reason?: string): void => {
  if (reason) {
    emitDecision({ decision: 'approve', reason })
  } else {
    emitDecision({ decision: 'approve' })
  }
}

/**
 * Emit a block decision
 */
export const block = (reason: string): void => {
  emitDecision({ decision: 'block', reason })
}

/**
 * Emit a skip decision (hook doesn't apply)
 */
export const skip = (reason?: string): void => {
  if (reason) {
    emitDecision({ decision: 'skip', reason })
  } else {
    emitDecision({ decision: 'skip' })
  }
}

// =============================================================================
// PostToolUse/Stop Hook Protocol Output
// =============================================================================

/**
 * Emit a continue signal for PostToolUse/Stop hooks.
 * This tells Claude Code to continue processing.
 *
 * @example
 * ```typescript
 * emitContinue(); // { continue: true }
 * emitContinue({ modifiedFiles: ['a.ts'] }); // { continue: true, modifiedFiles: ['a.ts'] }
 * ```
 */
export const emitContinue = (extra?: Record<string, unknown>): void => {
  const output: HookContinue = { continue: true, ...extra }
  process.stdout.write(`${JSON.stringify(output)}\n`)
}

/**
 * Emit a halt signal for PostToolUse/Stop hooks.
 * This tells Claude Code to stop processing.
 */
export const emitHalt = (extra?: Record<string, unknown>): void => {
  const output: HookContinue = { continue: false, ...extra }
  process.stdout.write(`${JSON.stringify(output)}\n`)
}

// =============================================================================
// Error Logging (stderr - does not affect protocol output)
// =============================================================================

/**
 * Log an error to stderr. Does not affect protocol output.
 * Use for internal errors that shouldn't be part of the decision.
 */
export const logError = (context: string, error?: unknown): void => {
  const errorMessage = error instanceof Error ? error.message : String(error ?? '')
  const stack = error instanceof Error ? error.stack : undefined

  process.stderr.write(
    `${JSON.stringify({
      level: 'error',
      context,
      message: errorMessage,
      stack,
      timestamp: new Date().toISOString(),
    })}\n`,
  )
}

/**
 * Log a warning to stderr. Does not affect protocol output.
 */
export const logWarning = (context: string, message: string): void => {
  process.stderr.write(
    `${JSON.stringify({
      level: 'warning',
      context,
      message,
      timestamp: new Date().toISOString(),
    })}\n`,
  )
}

/**
 * Log debug info to stderr. Does not affect protocol output.
 */
export const logDebug = (context: string, message: string, data?: unknown): void => {
  process.stderr.write(
    `${JSON.stringify({
      level: 'debug',
      context,
      message,
      data,
      timestamp: new Date().toISOString(),
    })}\n`,
  )
}
