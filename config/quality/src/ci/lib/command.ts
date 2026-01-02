/**
 * Effect-based Command Runner for CI
 *
 * Uses Bun's $ shell template for reliable execution in containers.
 */

import { Effect } from 'effect'
import { $ } from 'bun'
import { CommandError } from './errors'

export interface CommandResult {
  readonly stdout: string
  readonly stderr: string
  readonly exitCode: number
}

interface CommandOptions {
  readonly cwd: string
}

const defaultOptions: CommandOptions = { cwd: process.cwd() }

export const runCommand = (
  command: string,
  args: readonly string[],
  options?: { readonly cwd?: string },
): Effect.Effect<CommandResult, CommandError> =>
  Effect.gen(function* () {
    // Merge with defaults using Object.assign (no nullish coalescing needed)
    const opts: CommandOptions = Object.assign({}, defaultOptions, options)

    // Use Bun's $ shell for reliable execution in containers
    const fullCommand = [command, ...args].join(' ')

    const result = yield* Effect.tryPromise({
      try: async () => {
        const output = await $`cd ${opts.cwd} && ${fullCommand}`.quiet().nothrow()
        return {
          stdout: output.stdout.toString(),
          stderr: output.stderr.toString(),
          exitCode: output.exitCode,
        }
      },
      catch: (error) =>
        new CommandError({
          command,
          args,
          exitCode: -1,
          stderr: String(error),
        }),
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
