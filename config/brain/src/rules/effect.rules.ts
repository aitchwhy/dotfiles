/**
 * Effect Rules
 *
 * Enforce Effect-TS patterns for typed effects, errors, and composition.
 */

import type { QualityRule } from '../schemas'
import { RuleId } from '../schemas'

export const EFFECT_RULES: readonly QualityRule[] = [
  {
    id: RuleId('no-try-catch'),
    name: 'No try/catch blocks',
    category: 'effect',
    severity: 'error',
    message: 'try/catch loses error type information',
    patterns: ['try {', '} catch'],
    fix: 'Use Effect.tryPromise or Effect.try for external code, Effect.gen for internal',
  },
  {
    id: RuleId('require-effect-gen'),
    name: 'Prefer Effect.gen over flatMap chains',
    category: 'effect',
    severity: 'warning',
    message: 'Long flatMap chains are harder to read than generator syntax',
    patterns: ['Effect.flatMap', 'Effect.andThen'],
    fix: 'Use Effect.gen(function* () { const x = yield* effect; }) for clarity',
    note: 'Advisory - short chains are acceptable',
  },
  {
    id: RuleId('require-tagged-error'),
    name: 'Use tagged errors',
    category: 'effect',
    severity: 'error',
    message: 'Plain Error objects lose discriminated union benefits',
    patterns: ['new Error("', 'Effect.fail(new Error'],
    fix: "Use Data.TaggedError: class MyError extends Data.TaggedError('MyError')<{...}>() {}",
  },
  {
    id: RuleId('no-throw'),
    name: 'No throw statements',
    category: 'effect',
    severity: 'error',
    message: 'throw bypasses the type system for error handling',
    patterns: ['throw new', 'throw '],
    fix: 'Return Effect.fail(error) or use Result types',
  },
  {
    id: RuleId('no-process-env'),
    name: 'No direct env access',
    category: 'effect',
    severity: 'error',
    message: 'Direct env access is not testable and hides dependencies',
    patterns: ['process.env.', 'Bun.env.'],
    fix: 'Use a Config service: yield* Config; with ConfigLive/ConfigTest layers',
  },
  {
    id: RuleId('no-raw-promise'),
    name: 'No raw Promise usage',
    category: 'effect',
    severity: 'error',
    message: 'Raw Promises lack strict error typing and interruption handling',
    patterns: ['new Promise', 'Promise.resolve', 'Promise.reject'],
    fix: 'Use Effect.promise, Effect.tryPromise, or Effect.async',
  },
  {
    id: RuleId('no-async-function'),
    name: 'No async functions (use Generators)',
    category: 'effect',
    severity: 'warning',
    message: 'Async functions return Promises, not Effects. Use generators with Effect.gen',
    patterns: ['async function', 'async () =>', 'async ()'],
    fix: 'Use Effect.gen(function*() { ... })',
  },
  {
    id: RuleId('no-await'),
    name: 'No await (use yield*)',
    category: 'effect',
    severity: 'error',
    message: 'await works on Promises, not Effects. Use yield* adapter',
    patterns: ['await '],
    fix: 'yield* effect',
    note: 'Only valid inside Effect.gen or Effect.runPromise',
  },
] as const
