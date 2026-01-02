#!/usr/bin/env bun

/**
 * Pre-Tool-Use Hook (Unified AST Architecture)
 *
 * Blocks writes that violate quality rules.
 * Uses strict AST-grep enforcement via NAPI + YAML rules.
 *
 * architecture: Unified Purity (Context 7 + AST-Grep)
 */

import * as path from 'node:path'
import { Cause, Effect, pipe, Schema } from 'effect'
import { isForbidden } from '../stack'
import { checkContent, filterBySeverity, formatMatches } from './lib/ast-grep'
import {
  approve,
  block,
  isExcludedPath,
  isTypeScriptFile,
  outputDecision,
  type PreToolUseInput,
  parseInput,
  raceToFirstBlock,
  readStdin,
} from './lib/effect-hook'
import { runProceduralGuards } from './lib/guards/procedural'

// =============================================================================
// Constants
// =============================================================================

// Canonical Rules Directory (SSOT)
const RULES_DIR = path.resolve(
  import.meta.dir,
  '../../rules/paragon', // hooks -> src -> quality -> rules/paragon
)

// =============================================================================
// Schemas
// =============================================================================

const DependenciesSchema = Schema.Record({
  key: Schema.String,
  value: Schema.String,
})

const PackageJsonSchema = Schema.Struct({
  dependencies: Schema.optional(DependenciesSchema),
  devDependencies: Schema.optional(DependenciesSchema),
})

// =============================================================================
// Helpers
// =============================================================================

const extractContent = (input: PreToolUseInput) => ({
  filePath: input.tool_input.file_path,
  content: input.tool_input.content ?? input.tool_input.new_string,
})

const checkRuleViolations = (content: string) =>
  Effect.gen(function* () {
    // Check using unified AST rules
    const matches = yield* checkContent(content, RULES_DIR)
    const errors = filterBySeverity(matches, 'error')

    if (errors.length > 0) {
      return block(`Quality rule violations (AST-Strict):\n\n${formatMatches(errors)}`)
    }

    return approve()
  })

const parseDependencies = (content: string) =>
  Effect.gen(function* () {
    const rawJson = yield* Effect.try({
      try: () => JSON.parse(content),
      catch: () => new Error('Invalid package.json'),
    })
    const pkg = yield* Schema.decodeUnknown(PackageJsonSchema)(rawJson)
    return { ...pkg.dependencies, ...pkg.devDependencies }
  })

// =============================================================================
// Guard Checks
// =============================================================================

const checkTypeScriptContent = (input: PreToolUseInput) =>
  Effect.gen(function* () {
    const { filePath, content } = extractContent(input)

    if (!filePath || !content) return approve()
    if (!isTypeScriptFile(filePath)) return approve()
    if (isExcludedPath(filePath)) return approve('Excluded path')

    return yield* checkRuleViolations(content)
  })

const checkForbiddenPackages = (input: PreToolUseInput) =>
  Effect.gen(function* () {
    const { filePath, content } = extractContent(input)

    if (!filePath?.endsWith('package.json') || !content) return approve()

    const deps = yield* parseDependencies(content)

    for (const name of Object.keys(deps)) {
      const forbidden = isForbidden(name)
      if (forbidden) {
        return block(
          `Forbidden package: ${name}\nReason: ${forbidden.reason}\nAlternative: ${forbidden.alternative}`,
        )
      }
    }

    return approve()
  })

const checkDangerousCommands = (input: PreToolUseInput) =>
  Effect.sync(() => {
    if (input.tool_name !== 'Bash') return approve()

    const command = input.tool_input.command
    if (!command) return approve()

    const dangerous = ['rm -rf /', 'rm -rf ~', 'chmod -R 777', '> /dev/sda', 'mkfs.', ':(){:|:&};:']
    const found = dangerous.find((p) => command.includes(p))

    return found ? block(`Dangerous command detected: ${found}`) : approve()
  })

// =============================================================================
// PARAGON Guards Integration (Procedural Only)
// =============================================================================

const runProceduralChecks = (input: PreToolUseInput) =>
  Effect.sync(() => {
    const { file_path: filePath, content, new_string, command } = input.tool_input
    const effectiveContent = content ?? new_string

    // Procedural guards (bash, commits, TDD, secrets, etc.)
    const toolInput: { file_path?: string; content?: string; command?: string } = {}
    if (filePath !== undefined) toolInput.file_path = filePath
    if (effectiveContent !== undefined) toolInput.content = effectiveContent
    if (command !== undefined) toolInput.command = command

    const proceduralResult = runProceduralGuards(input.tool_name, toolInput)
    if (!proceduralResult.ok) {
      return block(proceduralResult.error)
    }

    // Warnings
    if (proceduralResult.warnings && proceduralResult.warnings.length > 0) {
      return approve(`Warnings:\n${proceduralResult.warnings.map((w) => `  - ${w}`).join('\n')}`)
    }

    return approve()
  })

// =============================================================================
// Main
// =============================================================================

const main = Effect.gen(function* () {
  const raw = yield* readStdin
  const input = yield* parseInput(raw)

  // Run all checks in PARALLEL with race-to-first-block
  // First block wins and interrupts remaining checks
  const checks = [
    runProceduralChecks(input), // Procedural logic (TDD, etc)
    checkTypeScriptContent(input), // Pure AST-grep (Content)
    checkForbiddenPackages(input), // Regex/Schema (Stack)
    checkDangerousCommands(input), // Regex (Safety)
  ]

  const result = yield* raceToFirstBlock(checks)
  yield* outputDecision(result)
})

void pipe(
  main,
  Effect.catchAllCause((cause) => outputDecision(block(`Hook error: ${Cause.pretty(cause)}`))),
  Effect.runPromise,
)
