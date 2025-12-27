#!/usr/bin/env bun

/**
 * Quality System Generator
 *
 * Generates Claude Code artifacts from TypeScript definitions.
 * Run with: bun run src/generate.ts
 */

import * as path from 'node:path'
import { Effect, pipe } from 'effect'
import { BEHAVIOR_COUNTS } from './critic-mode'
import {
  generateAllPersonas,
  generateAllSkills,
  generateCriticModeFile,
  generateMemoriesFile,
  generateRules,
  generateSettingsFile,
} from './generators'
import { MEMORY_COUNTS } from './memories'
import { ALL_PERSONAS } from './personas'
import { ALL_RULES } from './rules'
import { ALL_SKILLS } from './skills'

const QUALITY_DIR = path.dirname(new URL(import.meta.url).pathname)
const OUT_DIR = path.join(QUALITY_DIR, '..', 'generated')
const HOOK_PATH = path.join(QUALITY_DIR, 'hooks', 'pre-tool-use.ts')

const main = Effect.gen(function* () {
  yield* Effect.log('Quality System Generator')
  yield* Effect.log(`Output: ${OUT_DIR}`)
  yield* Effect.log('')

  yield* Effect.log(`Generating ${ALL_SKILLS.length} skills...`)
  yield* generateAllSkills(ALL_SKILLS, OUT_DIR)

  yield* Effect.log(`Generating ${ALL_PERSONAS.length} personas...`)
  yield* generateAllPersonas(ALL_PERSONAS, OUT_DIR)

  yield* Effect.log(`Generating ${ALL_RULES.length} rules documentation...`)
  yield* generateRules(ALL_RULES, OUT_DIR)

  yield* Effect.log(`Generating ${MEMORY_COUNTS.total} memories...`)
  yield* generateMemoriesFile(OUT_DIR)

  yield* Effect.log(`Generating ${BEHAVIOR_COUNTS.total} critic behaviors...`)
  yield* generateCriticModeFile(OUT_DIR)

  yield* Effect.log('Generating settings.json...')
  yield* generateSettingsFile(ALL_SKILLS, ALL_PERSONAS, HOOK_PATH, OUT_DIR)

  yield* Effect.log('')
  yield* Effect.log('Generation complete!')
  yield* Effect.log(`  Skills:    ${ALL_SKILLS.length}`)
  yield* Effect.log(`  Personas:  ${ALL_PERSONAS.length}`)
  yield* Effect.log(`  Rules:     ${ALL_RULES.length}`)
  yield* Effect.log(`  Memories:  ${MEMORY_COUNTS.total}`)
  yield* Effect.log(`  Behaviors: ${BEHAVIOR_COUNTS.total}`)
})

void pipe(
  main,
  Effect.catchAll((error) =>
    Effect.gen(function* () {
      yield* Effect.logError('Generation failed', error)
      process.exit(1)
    }),
  ),
  Effect.runPromise,
)
