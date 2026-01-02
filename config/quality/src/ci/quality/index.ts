/**
 * Quality System Tests
 *
 * Runs typecheck, tests, and artifact validation.
 */

import { Effect, Console, Schema } from 'effect'
import { runCommand } from '../lib/command'

// Parse environment at boundary
const EnvSchema = Schema.Struct({
  QUALITY_DIR: Schema.optionalWith(Schema.String, {
    default: () => `${process.env['HOME']}/dotfiles/config/quality`,
  }),
})

const env = Schema.decodeUnknownSync(EnvSchema)({
  QUALITY_DIR: process.env['QUALITY_DIR'],
})

// Get bun binary path from environment or fallback
const getBunPath = (): string => {
  // First check explicit BUN_PATH from workflow
  const bunPath = process.env['BUN_PATH']
  if (bunPath) {
    return bunPath
  }
  // Then check BUN_INSTALL from setup-bun
  const bunInstall = process.env['BUN_INSTALL']
  if (bunInstall) {
    return `${bunInstall}/bin/bun`
  }
  // Fallback to the running bun binary
  return process.execPath
}

const bunPath = getBunPath()

const runTypecheck = Effect.gen(function* () {
  yield* Console.log('  Running typecheck...')
  const result = yield* runCommand(bunPath, ['run', 'typecheck'], { cwd: env.QUALITY_DIR })
  return result.exitCode === 0
})

const runTests = Effect.gen(function* () {
  yield* Console.log('  Running tests...')
  const result = yield* runCommand(bunPath, ['run', 'test'], { cwd: env.QUALITY_DIR })
  return result.exitCode === 0
})

const runValidate = Effect.gen(function* () {
  yield* Console.log('  Validating artifacts...')
  const result = yield* runCommand(bunPath, ['run', 'validate'], { cwd: env.QUALITY_DIR })
  return result.exitCode === 0
})

/**
 * Run all quality checks in parallel
 */
export const runQualityTests = Effect.gen(function* () {
  yield* Console.log('\n🧪 Quality System Tests')
  yield* Console.log('─'.repeat(50))

  const [typecheck, tests, validate] = yield* Effect.all([runTypecheck, runTests, runValidate], {
    concurrency: 'unbounded',
  })

  const success = typecheck && tests && validate

  if (success) {
    yield* Console.log('✅ Quality checks passed')
  } else {
    yield* Console.error('❌ Quality checks failed')
    if (!typecheck) yield* Console.error('  - Typecheck failed')
    if (!tests) yield* Console.error('  - Tests failed')
    if (!validate) yield* Console.error('  - Validation failed')
  }

  return { success, typecheck, tests, validate }
})
