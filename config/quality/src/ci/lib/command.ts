/**
 * Effect-based Command Runner for CI
 *
 * Uses Bun's shell API (Bun.$) for reliable subprocess execution.
 */

import { Effect } from 'effect'
import { CommandError } from './errors'

export interface CommandResult {
  readonly stdout: string
  readonly stderr: string
  readonly exitCode: number
}

export const runCommand = (
  command: string,
  args: readonly string[],
  options?: { readonly cwd?: string },
): Effect.Effect<CommandResult, CommandError> =>
  Effect.gen(function* () {
    // Build command string with proper escaping
    const cmdString = [command, ...args].join(' ')

    // Use Bun.$ shell API for reliable PATH resolution
    const result = yield* Effect.tryPromise({
      try: async () => {
        const shell = options?.cwd ? Bun.$.cwd(options.cwd) : Bun.$
        // Use .nothrow() to not throw on non-zero exit, .quiet() to capture output
        return shell`${cmdString}`.nothrow().quiet()
      },
      catch: (cause) =>
        new CommandError({
          command,
          args,
          exitCode: -1,
          stderr: String(cause),
        }),
    })

    return {
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
      exitCode: result.exitCode,
    }
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
