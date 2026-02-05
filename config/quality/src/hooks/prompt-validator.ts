#!/usr/bin/env bun
/**
 * Prompt Validator - UserPromptSubmit hook for prompt injection detection
 *
 * Blocks prompts that contain potential injection patterns.
 */

import { BunContext, BunRuntime } from '@effect/platform-bun'
import { Console, Effect, Schema } from 'effect'

// =============================================================================
// Schemas
// =============================================================================

const PromptContextSchema = Schema.Struct({
  hook_event_name: Schema.Literal('UserPromptSubmit'),
  prompt: Schema.String,
  session_id: Schema.String,
})

// =============================================================================
// Injection Detection Patterns
// =============================================================================

const INJECTION_PATTERNS = [
  /ignore\s+(previous|all)\s+instructions/i,
  /you\s+are\s+now\s+/i,
  /system\s*:\s*/i,
  /\[SYSTEM\]/i,
  /forget\s+(everything|all|your)/i,
  /disregard\s+(previous|all|your)/i,
  /new\s+instructions?:/i,
  /act\s+as\s+(if|a|an)/i,
] as const

// =============================================================================
// Hook Output
// =============================================================================

type HookDecision =
  | { readonly decision: 'approve'; readonly reason?: string }
  | { readonly decision: 'block'; readonly reason: string }

const approve = (): HookDecision => ({ decision: 'approve' })
const block = (reason: string): HookDecision => ({ decision: 'block', reason })

// =============================================================================
// Main
// =============================================================================

const program = Effect.gen(function* () {
  const stdin = yield* Effect.tryPromise({
    try: () => Bun.stdin.text(),
    catch: () => new Error('Failed to read stdin'),
  })

  const rawJson = yield* Effect.try({
    try: () => JSON.parse(stdin),
    catch: () => new Error('Invalid JSON input'),
  })

  const context = yield* Schema.decodeUnknown(PromptContextSchema)(rawJson)

  for (const pattern of INJECTION_PATTERNS) {
    if (pattern.test(context.prompt)) {
      yield* Console.log(JSON.stringify(block('Potential prompt injection detected')))
      return
    }
  }

  yield* Console.log(JSON.stringify(approve()))
})

const runnable = program.pipe(
  Effect.catchAll(() => Console.log(JSON.stringify(approve()))),
  Effect.provide(BunContext.layer),
)

BunRuntime.runMain(runnable)
