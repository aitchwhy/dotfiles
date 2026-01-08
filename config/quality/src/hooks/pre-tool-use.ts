#!/usr/bin/env bun

/**
 * Pre-Tool-Use Hook (Fiber Parallelism Architecture - Jan 2026)
 */

import * as path from 'node:path'
import { Cause, Effect, pipe, Schema } from 'effect'
import { isForbidden } from '../stack'
import { checkContent, filterBySeverity, formatMatches } from './lib/ast-grep'
import {
  approve,
  block,
  formatAggregatedErrors,
  type GuardCheckResult,
  isExcludedPath,
  isTypeScriptFile,
  outputDecision,
  type PreToolUseInput,
  parseInput,
  readStdin,
  runGuardsFibers,
} from './lib/effect-hook'
import { runProceduralGuards } from './lib/guards/procedural'

const RULES_DIR = path.resolve(import.meta.dir, '../../rules/paragon')

const DependenciesSchema = Schema.Record({ key: Schema.String, value: Schema.String })
const PackageJsonSchema = Schema.Struct({
  dependencies: Schema.optional(DependenciesSchema),
  devDependencies: Schema.optional(DependenciesSchema),
})

const extractContent = (input: PreToolUseInput) => ({
  filePath: input.tool_input.file_path,
  content: input.tool_input.content ?? input.tool_input.new_string,
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

const pass = (warnings?: readonly string[]): GuardCheckResult =>
  warnings !== undefined
    ? { source: 'ast-grep', blocked: false, warnings }
    : { source: 'ast-grep', blocked: false }
const fail = (source: GuardCheckResult['source'], message: string): GuardCheckResult => ({
  source,
  blocked: true,
  message,
})

const checkTypeScriptContent = (
  input: PreToolUseInput,
): Effect.Effect<GuardCheckResult, never, never> =>
  Effect.gen(function* () {
    const { filePath, content } = extractContent(input)
    if (!filePath || !content) return pass()
    if (!isTypeScriptFile(filePath)) return pass()
    if (isExcludedPath(filePath)) return pass()
    const matches = yield* checkContent(content, RULES_DIR).pipe(
      Effect.catchAll(() => Effect.succeed([] as const)),
    )
    const errors = filterBySeverity(matches, 'error')
    if (errors.length > 0)
      return fail('ast-grep', `AST-grep violations:\n\n${formatMatches(errors)}`)
    return pass()
  })

const checkForbiddenPackages = (
  input: PreToolUseInput,
): Effect.Effect<GuardCheckResult, never, never> =>
  Effect.gen(function* () {
    const { filePath, content } = extractContent(input)
    if (!filePath?.endsWith('package.json') || !content) return pass()
    const deps = yield* parseDependencies(content).pipe(
      Effect.catchAll(() => Effect.succeed({} as Record<string, string>)),
    )
    const violations: string[] = []
    for (const name of Object.keys(deps)) {
      const forbidden = isForbidden(name)
      if (forbidden)
        violations.push(
          `Forbidden package: ${name}\nReason: ${forbidden.reason}\nAlternative: ${forbidden.alternative}`,
        )
    }
    if (violations.length > 0) return fail('package', violations.join('\n\n'))
    return pass()
  })

const checkDangerousCommands = (
  input: PreToolUseInput,
): Effect.Effect<GuardCheckResult, never, never> =>
  Effect.sync(() => {
    if (input.tool_name !== 'Bash') return pass()
    const command = input.tool_input.command
    if (!command) return pass()
    const dangerous = ['rm -rf /', 'rm -rf ~', 'chmod -R 777', '> /dev/sda', 'mkfs.', ':(){:|:&};:']
    const found = dangerous.find((p) => command.includes(p))
    return found ? fail('command', `Dangerous command detected: ${found}`) : pass()
  })

const runProceduralChecks = (
  input: PreToolUseInput,
): Effect.Effect<GuardCheckResult, never, never> =>
  Effect.sync(() => {
    const { file_path: filePath, content, new_string, command, pattern, glob, path } = input.tool_input
    const effectiveContent = content ?? new_string
    const toolInput: { file_path?: string; content?: string; command?: string; pattern?: string; glob?: string; path?: string } = {}
    if (filePath !== undefined) toolInput.file_path = filePath
    if (effectiveContent !== undefined) toolInput.content = effectiveContent
    if (command !== undefined) toolInput.command = command
    // Grep fields (Guard 56)
    if (pattern !== undefined) toolInput.pattern = pattern
    if (glob !== undefined) toolInput.glob = glob
    if (path !== undefined) toolInput.path = path
    const proceduralResult = runProceduralGuards(input.tool_name, toolInput)
    if (!proceduralResult.ok) return fail('procedural', proceduralResult.error)
    return proceduralResult.warnings !== undefined
      ? { source: 'procedural' as const, blocked: false, warnings: proceduralResult.warnings }
      : { source: 'procedural' as const, blocked: false }
  })

const main = Effect.gen(function* () {
  const raw = yield* readStdin
  const input = yield* parseInput(raw)
  const guardChecks = [
    runProceduralChecks(input),
    checkTypeScriptContent(input),
    checkForbiddenPackages(input),
    checkDangerousCommands(input),
  ]
  const result = yield* runGuardsFibers(guardChecks)
  if (result.errors.length > 0) yield* outputDecision(block(formatAggregatedErrors(result)))
  else if (result.warnings.length > 0)
    yield* outputDecision(
      approve(`Warnings:\n${result.warnings.map((w) => `  - ${w}`).join('\n')}`),
    )
  else yield* outputDecision(approve())
})

void pipe(
  main,
  Effect.catchAllCause((cause) => outputDecision(block(`Hook error: ${Cause.pretty(cause)}`))),
  Effect.runPromise,
)
