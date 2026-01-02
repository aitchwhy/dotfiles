/**
 * Effect-based Command Runner for CI
 *
 * Uses Node.js child_process.exec with full Effect-TS type safety.
 */

import { Effect, Schema, pipe } from 'effect'
import { exec } from 'node:child_process'
import { promisify } from 'node:util'
import { CommandError } from './errors'

const execAsync = promisify(exec)

// ─────────────────────────────────────────────────────────────
// Schemas - Parse at boundary with transformations
// ─────────────────────────────────────────────────────────────

/**
 * Command result - the canonical output type
 */
export const CommandResultSchema = Schema.Struct({
  stdout: Schema.String,
  stderr: Schema.String,
  exitCode: Schema.Number,
})
export type CommandResult = typeof CommandResultSchema.Type

/**
 * Command options with defaults parsed at boundary
 */
const CommandOptionsSchema = Schema.Struct({
  cwd: Schema.optionalWith(Schema.String, { default: () => process.cwd() }),
})

/**
 * Exit code transformation: string codes (e.g., "ENOENT") → 127
 */
const ExitCodeSchema = Schema.transform(
  Schema.Union(Schema.Number, Schema.String),
  Schema.Number,
  {
    strict: true,
    decode: (input) => (typeof input === 'number' ? input : 127),
    encode: (n) => n,
  },
)

/**
 * Exec error shape at boundary - transforms to proper exit code
 */
const ExecErrorSchema = Schema.Struct({
  stdout: Schema.optionalWith(Schema.String, { default: () => '' }),
  stderr: Schema.optionalWith(Schema.String, { default: () => '' }),
  code: pipe(ExitCodeSchema, Schema.optionalWith({ default: () => 1 })),
})

// ─────────────────────────────────────────────────────────────
// Effects - Pure Effect-TS command execution
// ─────────────────────────────────────────────────────────────

/**
 * Execute a command and return result (succeeds even for non-zero exit)
 *
 * This function uses Effect.promise with internal error handling to always
 * return a CommandResult. Non-zero exits are encoded in the exitCode field.
 */
export const runCommand = (
  command: string,
  args: readonly string[],
  options?: { readonly cwd?: string },
): Effect.Effect<CommandResult, never> =>
  Effect.gen(function* () {
    // Parse options at boundary
    const opts = Schema.decodeUnknownSync(CommandOptionsSchema)(options)

    // Build shell command
    const fullCommand = [command, ...args].join(' ')

    // Execute command - handle both success and non-zero exit as CommandResult
    return yield* Effect.promise(async (): Promise<CommandResult> => {
      const execResult = await execAsync(fullCommand, {
        cwd: opts.cwd,
        env: process.env,
        maxBuffer: 10 * 1024 * 1024,
      }).catch((error: unknown) => {
        // Parse exec error at boundary - transforms code to number
        const parsed = Schema.decodeUnknownSync(ExecErrorSchema)(error)
        return { stdout: parsed.stdout, stderr: parsed.stderr, exitCode: parsed.code }
      })

      // Success case or already parsed error
      if ('exitCode' in execResult) {
        return execResult
      }
      return { stdout: execResult.stdout, stderr: execResult.stderr, exitCode: 0 }
    })
  })

/**
 * Run a command and fail if exit code is non-zero
 */
export const runCommandStrict = (
  command: string,
  args: readonly string[],
  options?: { readonly cwd?: string },
): Effect.Effect<CommandResult, CommandError> =>
  Effect.gen(function* () {
    const result = yield* runCommand(command, args, options)
    if (result.exitCode !== 0) {
      return yield* Effect.fail(
        new CommandError({
          command,
          args,
          exitCode: result.exitCode,
          stderr: result.stderr,
        }),
      )
    }
    return result
  })
