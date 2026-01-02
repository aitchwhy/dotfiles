/**
 * Effect-based Command Runner for CI
 *
 * Uses Node.js child_process.exec for cross-platform compatibility.
 */

import { Effect, Schema } from 'effect'
import { exec } from 'node:child_process'
import { promisify } from 'node:util'
import { CommandError } from './errors'

const execAsync = promisify(exec)

export interface CommandResult {
  readonly stdout: string
  readonly stderr: string
  readonly exitCode: number
}

interface CommandOptions {
  readonly cwd: string
}

const defaultOptions: CommandOptions = { cwd: process.cwd() }

// Schema for parsing exec error shape at boundary
const ExecErrorSchema = Schema.Struct({
  stdout: Schema.optionalWith(Schema.String, { default: () => '' }),
  stderr: Schema.optionalWith(Schema.String, { default: () => '' }),
  code: Schema.optionalWith(Schema.Number, { default: () => 1 }),
})

export const runCommand = (
  command: string,
  args: readonly string[],
  options?: { readonly cwd?: string },
): Effect.Effect<CommandResult, CommandError> =>
  Effect.gen(function* () {
    // Merge with defaults using Object.assign (no nullish coalescing needed)
    const opts: CommandOptions = Object.assign({}, defaultOptions, options)

    // Build shell command string
    const fullCommand = [command, ...args].join(' ')

    // exec throws on non-zero exit, so we catch and parse the error for exit code
    const result = yield* Effect.async<CommandResult, CommandError>((resume) => {
      execAsync(fullCommand, {
        cwd: opts.cwd,
        env: process.env,
        maxBuffer: 10 * 1024 * 1024,
      })
        .then(({ stdout, stderr }) => {
          resume(Effect.succeed({ stdout, stderr, exitCode: 0 }))
        })
        .catch((error: unknown) => {
          // Parse error at boundary using Schema for non-zero exit
          const parsed = Schema.decodeUnknownSync(ExecErrorSchema)(error)
          resume(Effect.succeed({ stdout: parsed.stdout, stderr: parsed.stderr, exitCode: parsed.code }))
        })
    })

    return result
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
