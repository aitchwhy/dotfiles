#!/usr/bin/env bun

/**
 * Quality System Generator
 *
 * Generates Claude Code settings.json from TypeScript definitions.
 * Run with: bun run src/generate.ts
 */

import { FileSystem } from '@effect/platform'
import { BunContext } from '@effect/platform-bun'
import * as path from 'node:path'
import { Effect, pipe } from 'effect'
import { generateSettingsFile } from './generators/claude'
import { generateCodexConfigFile } from './generators/codex'

const QUALITY_DIR = path.dirname(new URL(import.meta.url).pathname)
const GENERATED_ROOT = path.join(QUALITY_DIR, '..', 'generated')
const CLAUDE_OUT = path.join(GENERATED_ROOT, 'claude')
const CODEX_OUT = path.join(GENERATED_ROOT, 'codex')

const main = Effect.gen(function* () {
  const fileSystem = yield* FileSystem.FileSystem

  yield* Effect.log('Quality System Generator')
  yield* Effect.log(`Output: ${GENERATED_ROOT}`)
  yield* Effect.log('')

  // Clean generated directory
  const generatedExists = yield* fileSystem.exists(GENERATED_ROOT)
  if (generatedExists) {
    yield* fileSystem.remove(GENERATED_ROOT, { recursive: true })
    yield* Effect.log('Removed stale generated artifacts')
  }

  // Ensure output directories exist
  yield* fileSystem.makeDirectory(CLAUDE_OUT, { recursive: true })
  yield* fileSystem.makeDirectory(CODEX_OUT, { recursive: true })

  // Generate Claude settings.json
  yield* generateSettingsFile(CLAUDE_OUT)

  // Generate Codex config.toml
  yield* generateCodexConfigFile(CODEX_OUT)

  yield* Effect.log('')
  yield* Effect.log('Generation complete (Claude settings.json + Codex config.toml)')
})

void pipe(
  main,
  Effect.provide(BunContext.layer),
  Effect.catchAll((error) =>
    Effect.gen(function* () {
      yield* Effect.logError('Generation failed', error)
      process.exit(1)
    }),
  ),
  Effect.runPromise,
)
