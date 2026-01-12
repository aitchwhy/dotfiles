#!/usr/bin/env bun

/**
 * Quality System Generator
 *
 * Generates Claude Code artifacts from TypeScript definitions.
 * Run with: bun run src/generate.ts
 */

import { BunContext } from '@effect/platform-bun'
import * as fs from 'node:fs'
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
} from './generators/claude'
import { generateDesktopPreferences } from './generators/claude-desktop'
import { generateCursorRules } from './generators/cursor'
import { generateGeminiConfig } from './generators/gemini'

import { MEMORY_COUNTS } from './memories'
import { ALL_PERSONAS } from './personas'
import { ALL_RULES } from './rules'
import { ALL_SKILLS } from './skills'

const QUALITY_DIR = path.dirname(new URL(import.meta.url).pathname)
const GENERATED_ROOT = path.join(QUALITY_DIR, '..', 'generated')

// Provider Output Directories
const CLAUDE_OUT = path.join(GENERATED_ROOT, 'claude')
const CLAUDE_DESKTOP_OUT = path.join(GENERATED_ROOT, 'claude-desktop')
const CURSOR_OUT = path.join(GENERATED_ROOT, 'cursor')
const GEMINI_OUT = path.join(GENERATED_ROOT, 'gemini')

const HOOK_PATH = path.join(QUALITY_DIR, 'hooks', 'pre-tool-use.ts')

const main = Effect.gen(function* () {
  yield* Effect.log('Brain System Generator')
  yield* Effect.log(`Root Output: ${GENERATED_ROOT}`)
  yield* Effect.log('')

  // CLEAN SLATE: Delete generated directory to prevent orphaned artifacts
  // This ensures source count == generated count after each run
  yield* Effect.log('--- Cleaning Generated Directory (Clean Slate) ---')
  if (fs.existsSync(GENERATED_ROOT)) {
    fs.rmSync(GENERATED_ROOT, { recursive: true, force: true })
    yield* Effect.log('✓ Removed stale generated artifacts')
  }
  yield* Effect.log('')

  // 1. CLAUDE GENERATION
  yield* Effect.log('--- Generatng Claude Adapters ---')
  yield* Effect.log(`Output: ${CLAUDE_OUT}`)

  yield* generateAllSkills(ALL_SKILLS, CLAUDE_OUT)
  yield* generateAllPersonas(ALL_PERSONAS, CLAUDE_OUT)
  yield* generateRules(ALL_RULES, CLAUDE_OUT)
  yield* generateMemoriesFile(CLAUDE_OUT)
  yield* generateCriticModeFile(CLAUDE_OUT)
  yield* generateSettingsFile(ALL_SKILLS, ALL_PERSONAS, HOOK_PATH, CLAUDE_OUT)

  // 2. CURSOR GENERATION
  yield* Effect.log('')
  yield* Effect.log('--- Generating Cursor Adapters ---')
  yield* Effect.log(`Output: ${CURSOR_OUT}`)
  yield* generateCursorRules(ALL_SKILLS, CURSOR_OUT)

  // 3. GEMINI GENERATION
  yield* Effect.log('')
  yield* Effect.log('--- Generating Gemini Adapters ---')
  yield* Effect.log(`Output: ${GEMINI_OUT}`)
  yield* generateGeminiConfig(ALL_SKILLS, ALL_PERSONAS, GEMINI_OUT)

  // 4. CLAUDE DESKTOP GENERATION
  yield* Effect.log('')
  yield* Effect.log('--- Generating Claude Desktop Adapters ---')
  yield* Effect.log(`Output: ${CLAUDE_DESKTOP_OUT}`)
  yield* generateDesktopPreferences(CLAUDE_DESKTOP_OUT)

  yield* Effect.log('')
  yield* Effect.log('All Generation complete!')
  yield* Effect.log(`  Skills:    ${ALL_SKILLS.length}`)
  yield* Effect.log(`  Personas:  ${ALL_PERSONAS.length}`)
  yield* Effect.log(`  Rules:     ${ALL_RULES.length}`)
  yield* Effect.log(`  Memories:  ${MEMORY_COUNTS.total}`)
  yield* Effect.log(`  Behaviors: ${BEHAVIOR_COUNTS.total}`)

  // VERIFICATION: Ensure generated skill count matches source count
  // This catches any generation errors that would cause orphans or missing skills
  yield* Effect.log('')
  yield* Effect.log('--- Verifying Generated Artifacts ---')

  const skillsDir = path.join(CLAUDE_OUT, 'skills')
  const generatedSkills = fs.existsSync(skillsDir)
    ? fs.readdirSync(skillsDir).filter((f) => !f.startsWith('.'))
    : []

  const sourceSkillCount = ALL_SKILLS.length
  const generatedSkillCount = generatedSkills.length

  yield* Effect.log(`Source skills:    ${sourceSkillCount}`)
  yield* Effect.log(`Generated skills: ${generatedSkillCount}`)

  if (sourceSkillCount !== generatedSkillCount) {
    yield* Effect.logError(
      `FATAL: Skill count mismatch! Source=${sourceSkillCount}, Generated=${generatedSkillCount}`,
    )
    process.exit(1)
  }

  yield* Effect.log('✓ Verification passed: source count == generated count')
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
