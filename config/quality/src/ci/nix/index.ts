/**
 * Nix Flake Check
 *
 * Runs nix flake check --no-build for evaluation validation.
 */

import { Effect, Console, Schema } from 'effect'
import { runCommand } from '../lib/command'

// Parse environment at boundary
const EnvSchema = Schema.Struct({
  DOTFILES: Schema.optionalWith(Schema.String, {
    default: () => `${process.env['HOME']}/dotfiles`,
  }),
})

const env = Schema.decodeUnknownSync(EnvSchema)({
  DOTFILES: process.env['DOTFILES'],
})

/**
 * Run nix flake check (eval only, no build)
 */
export const runNixCheck = Effect.gen(function* () {
  yield* Console.log('\n❄️  Nix Flake Check')
  yield* Console.log('─'.repeat(50))

  yield* Console.log('  Running nix flake check --no-build...')

  const result = yield* runCommand('nix', ['flake', 'check', '--no-build', env.DOTFILES])

  const success = result.exitCode === 0

  if (success) {
    yield* Console.log('✅ Nix flake check passed')
  } else {
    yield* Console.error('❌ Nix flake check failed')
    if (result.stderr) {
      yield* Console.error(result.stderr.slice(0, 500))
    }
  }

  return { success, evalOnly: true }
})
