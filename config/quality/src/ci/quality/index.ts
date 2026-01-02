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

// Helper to run bun commands via shell for proper PATH resolution
const runBunScript = (script: string, cwd: string) =>
  runCommand('/bin/sh', ['-c', `bun run ${script}`], { cwd })

const runTypecheck = Effect.gen(function* () {
  yield* Console.log('  Running typecheck...')
  const result = yield* runBunScript('typecheck', env.QUALITY_DIR)
  return result.exitCode === 0
})

const runTests = Effect.gen(function* () {
  yield* Console.log('  Running tests...')
  const result = yield* runBunScript('test', env.QUALITY_DIR)
  return result.exitCode === 0
})

const runValidate = Effect.gen(function* () {
  yield* Console.log('  Validating artifacts...')
  const result = yield* runBunScript('validate', env.QUALITY_DIR)
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
