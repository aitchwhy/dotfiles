/**
 * PARAGON Guards - Parallel Execution with Effect.all
 *
 * All guards run simultaneously using unbounded concurrency.
 * Each guard uses ripgrep for fast pattern matching.
 */

import { Effect, Console, Schema } from 'effect'
import { runCommand } from '../lib/command'

// Parse environment at boundary using Effect Schema
const EnvSchema = Schema.Struct({
  DOTFILES: Schema.optionalWith(Schema.String, {
    default: () => `${process.env['HOME']}/dotfiles`,
  }),
})

const env = Schema.decodeUnknownSync(EnvSchema)({
  DOTFILES: process.env['DOTFILES'],
})

interface GuardResult {
  readonly success: boolean
  readonly guard: string
  readonly matches?: readonly string[]
}

/**
 * Create a guard that searches for a pattern using ripgrep
 */
const createGuard = (
  name: string,
  pattern: string,
  rgArgs: readonly string[],
): Effect.Effect<GuardResult, never> =>
  Effect.gen(function* () {
    const result = yield* runCommand('rg', [pattern, ...rgArgs, env.DOTFILES]).pipe(
      Effect.catchAll(() => Effect.succeed({ stdout: '', stderr: '', exitCode: 1 })),
    )

    // Exit code 0 means matches found (violation)
    // Exit code 1 means no matches (pass)
    if (result.exitCode === 0 && result.stdout.trim()) {
      const matches = result.stdout.split('\n').filter(Boolean)
      yield* Console.error(`❌ ${name}: ${matches.length} violation(s) found`)
      return { success: false, guard: name, matches }
    }

    yield* Console.log(`✅ ${name}`)
    return { success: true, guard: name }
  })

// Guard 3: No Forbidden Files
const guard3_noForbiddenFiles = createGuard(
  'Guard 3: No Forbidden Files',
  'bun\\.lock$|package-lock\\.json$|yarn\\.lock$|\\.eslintrc|\\.prettierrc|jest\\.config',
  ['--files', '--glob', '!node_modules/**', '--glob', '!.git/**'],
)

// Guard 5: No Any Types (exclude .d.ts files)
const guard5_noAnyTypes = createGuard(
  'Guard 5: No Any Types',
  ':\\s*any\\b|as\\s+any\\b|<any\\s*>',
  ['-t', 'ts', '--glob', '!*.d.ts', '--glob', '!node_modules/**'],
)

// Guard 6: No z.infer
const guard6_noZInfer = createGuard(
  'Guard 6: No z.infer',
  'z\\.infer\\s*<|z\\.input\\s*<|z\\.output\\s*<',
  ['-t', 'ts', '--glob', '!node_modules/**'],
)

// Guard 7: No Mock Patterns
const guard7_noMockPatterns = createGuard(
  'Guard 7: No Mock Patterns',
  'jest\\.mock\\s*\\(|vi\\.mock\\s*\\(|Mock[A-Z][a-zA-Z]*Live',
  ['-t', 'ts', '-t', 'js', '--glob', '!node_modules/**'],
)

// Guard 13: No Assumption Language (exclude test files)
const guard13_noAssumptionLanguage = createGuard(
  'Guard 13: No Assumption Language',
  'should (now )?work|should fix|this fixes|probably (works|fixed)|I think (this|it)|might (work|fix)|likely (fixed|works)',
  [
    '-i', // case insensitive
    '-t',
    'ts',
    '--glob',
    '!*.test.ts',
    '--glob',
    '!*.spec.ts',
    '--glob',
    '!node_modules/**',
  ],
)

// Guard 26: No Console Methods (exclude test files)
const guard26_noConsoleMethods = createGuard(
  'Guard 26: No Console Methods',
  'console\\.(log|error|warn|debug|info)\\s*\\(',
  [
    '-t',
    'ts',
    '--glob',
    '!*.test.ts',
    '--glob',
    '!*.spec.ts',
    '--glob',
    '!node_modules/**',
    '--glob',
    '!src/ci/**', // CI scripts can use console
  ],
)

/**
 * Run all PARAGON guards in parallel
 */
export const runAllGuards: Effect.Effect<
  { readonly success: boolean; readonly failures: readonly GuardResult[] },
  never
> = Effect.gen(function* () {
  yield* Console.log('\n🛡️  PARAGON Guards')
  yield* Console.log('─'.repeat(50))

  const results = yield* Effect.all(
    [
      guard3_noForbiddenFiles,
      guard5_noAnyTypes,
      guard6_noZInfer,
      guard7_noMockPatterns,
      guard13_noAssumptionLanguage,
      guard26_noConsoleMethods,
    ],
    { concurrency: 'unbounded' },
  )

  const failures = results.filter((r) => !r.success)

  if (failures.length > 0) {
    yield* Console.error(`\n❌ ${failures.length} guard(s) failed`)
    return { success: false, failures }
  }

  yield* Console.log('\n✅ All guards passed')
  return { success: true, failures: [] }
})
