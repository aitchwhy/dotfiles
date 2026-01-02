/**
 * Effect-based Command Runner for CI
 *
 * Uses Bun.spawn with proper environment inheritance.
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
    const proc = Bun.spawn({
      cmd: [command, ...args],
      cwd: options?.cwd,
      stdout: 'pipe',
      stderr: 'pipe',
      // Explicitly inherit environment including PATH
      env: process.env,
    })

    const [stdout, stderr, exitCode] = yield* Effect.all(
      [
        Effect.promise(() => new Response(proc.stdout).text()),
        Effect.promise(() => new Response(proc.stderr).text()),
        Effect.promise(() => proc.exited),
      ],
      { concurrency: 'unbounded' },
    ).pipe(
      Effect.catchAll((cause) =>
        Effect.fail(
          new CommandError({
            command,
            args,
            exitCode: -1,
            stderr: String(cause),
          }),
        ),
      ),
    )

    return { stdout, stderr, exitCode }
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
