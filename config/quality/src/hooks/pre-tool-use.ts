#!/usr/bin/env bun
/**
 * Pre-Tool-Use Hook
 *
 * Blocks writes that violate quality rules.
 * Effect-based, no try/catch.
 *
 * Integrates PARAGON guards (39 guards across 3 modules):
 * - Procedural: bash safety, commits, TDD, DevOps, secrets
 * - Content: type safety, imports, mocks, throw patterns
 * - Structural: clean code metrics
 */

import { Effect, pipe, Schema } from 'effect'
import { ALL_RULES } from '../rules'
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
  readStdin,
} from './lib/effect-hook'
import { runContentGuards } from './lib/guards/content'
import { runProceduralGuards } from './lib/guards/procedural'
import { runStructuralGuards } from './lib/guards/structural'

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
    const matches = yield* checkContent(content, ALL_RULES)
    const errors = filterBySeverity(matches, ALL_RULES, 'error')

    if (errors.length > 0) {
      return block(`Quality rule violations:\n\n${formatMatches(errors, ALL_RULES)}`)
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
    return { ...(pkg.dependencies ?? {}), ...(pkg.devDependencies ?? {}) }
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
  Effect.gen(function* () {
    if (input.tool_name !== 'Bash') return approve()

    const command = input.tool_input.command
    if (!command) return approve()

    const dangerous = ['rm -rf /', 'rm -rf ~', 'chmod -R 777', '> /dev/sda', 'mkfs.', ':(){:|:&};:']
    const found = dangerous.find((p) => command.includes(p))

    return found ? block(`Dangerous command detected: ${found}`) : approve()
  })

// =============================================================================
// PARAGON Guards Integration
// =============================================================================

const runParagonGuards = (input: PreToolUseInput) =>
  Effect.gen(function* () {
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

    // Content guards (type safety, imports, throw patterns)
    const contentResult = runContentGuards(effectiveContent, filePath)
    if (!contentResult.ok) {
      return block(contentResult.error)
    }

    // Structural guards (clean code metrics)
    const structuralResult = runStructuralGuards(effectiveContent, filePath)
    if (!structuralResult.ok) {
      return block(structuralResult.error)
    }

    // Collect warnings from all guards
    const warnings = [
      ...(proceduralResult.warnings ?? []),
      ...(contentResult.warnings ?? []),
      ...(structuralResult.warnings ?? []),
    ]

    if (warnings.length > 0) {
      return approve(`Warnings:\n${warnings.map((w) => `  - ${w}`).join('\n')}`)
    }

    return approve()
  })

// =============================================================================
// Main
// =============================================================================

const main = Effect.gen(function* () {
  const raw = yield* readStdin
  const input = yield* parseInput(raw)

  // Run all checks in order
  const checks = [
    runParagonGuards, // PARAGON guards (39 guards)
    checkTypeScriptContent, // AST-grep quality rules
    checkForbiddenPackages, // Stack compliance
    checkDangerousCommands, // Bash safety
  ]

  for (const check of checks) {
    const result = yield* check(input)
    if (result.decision === 'block') {
      yield* outputDecision(result)
      return
    }
  }

  yield* outputDecision(approve())
})

pipe(
  main,
  Effect.catchAll((error) => outputDecision(block(`Hook error: ${String(error)}`))),
  Effect.runPromise,
)
