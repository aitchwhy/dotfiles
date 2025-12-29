/**
 * Effect-based Command Runner
 *
 * Provides type-safe subprocess execution using Bun's spawn API.
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
  Effect.tryPromise({
    try: async () => {
      const spawnOptions: { stdout: 'pipe'; stderr: 'pipe'; cwd?: string } = {
        stdout: 'pipe',
        stderr: 'pipe',
      }
      if (options?.cwd !== undefined) {
        spawnOptions.cwd = options.cwd
      }
      const proc = Bun.spawn([command, ...args], spawnOptions)
      const [stdout, stderr, exitCode] = await Promise.all([
        new Response(proc.stdout).text(),
        new Response(proc.stderr).text(),
        proc.exited,
      ])
      return { stdout, stderr, exitCode }
    },
    catch: (cause) =>
      new CommandError({
        command,
        args,
        exitCode: -1,
        stderr: String(cause),
      }),
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
