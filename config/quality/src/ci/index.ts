#!/usr/bin/env bun
/**
 * Unified CI Pipeline
 *
 * Runs all CI checks in parallel using Effect.all with unbounded concurrency.
 * Entry point: bun run ci
 */

import { Effect, Console, Cause, Clock } from 'effect'
import { runAllGuards } from './guards'
import { runQualityTests } from './quality'
import { runMcpSmokeTests } from './mcp'
import { runNixCheck } from './nix'
import { runConfigValidation } from './config'

interface CIResult {
  readonly guards: { success: boolean }
  readonly quality: { success: boolean }
  readonly mcp: { success: boolean }
  readonly nix: { success: boolean }
  readonly config: { success: boolean }
}

const program = Effect.gen(function* () {
  yield* Console.log('═'.repeat(60))
  yield* Console.log('         UNIFIED CI PIPELINE (Effect + Bun)')
  yield* Console.log('═'.repeat(60))

  const startTime = yield* Clock.currentTimeMillis

  // Run all independent checks in parallel
  const results: CIResult = yield* Effect.all(
    {
      guards: runAllGuards,
      quality: runQualityTests,
      mcp: runMcpSmokeTests,
      nix: runNixCheck,
      config: runConfigValidation,
    },
    { concurrency: 'unbounded' },
  )

  const endTime = yield* Clock.currentTimeMillis
  const elapsed = ((endTime - startTime) / 1000).toFixed(1)

  // Aggregate results
  const checks = Object.entries(results)
  const failures = checks.filter(([_, r]) => !r.success)
  const passed = checks.filter(([_, r]) => r.success)

  yield* Console.log('\n' + '═'.repeat(60))
  yield* Console.log('                    SUMMARY')
  yield* Console.log('═'.repeat(60))
  yield* Console.log(`\n⏱️  Total time: ${elapsed}s`)
  yield* Console.log(`✅ Passed: ${passed.length}/${checks.length}`)

  if (failures.length > 0) {
    yield* Console.error(`❌ Failed: ${failures.map(([k]) => k).join(', ')}`)
    yield* Console.log('\n' + '═'.repeat(60))
    return yield* Effect.fail(1)
  }

  yield* Console.log('\n🎉 All CI checks passed!')
  yield* Console.log('═'.repeat(60))
})

// Run with Effect.runPromise
void Effect.runPromise(
  program.pipe(
    Effect.catchAllCause((cause) =>
      Console.error(`CI failed: ${Cause.pretty(cause)}`).pipe(
        Effect.andThen(Effect.sync(() => (process.exitCode = 1))),
      ),
    ),
  ),
)
