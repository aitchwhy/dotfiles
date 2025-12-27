#!/usr/bin/env bun
/**
 * Post-Tool-Use Hook
 *
 * Auto-formats files after write operations.
 * Non-blocking - always exits 0.
 */

import { Effect, pipe } from 'effect'

// =============================================================================
// Main (placeholder - formatting handled by IDE/pre-commit)
// =============================================================================

const main = Effect.gen(function* () {
  yield* Effect.succeed(undefined)
})

void pipe(main, Effect.runPromise)
