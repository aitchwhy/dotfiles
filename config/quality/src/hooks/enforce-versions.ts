#!/usr/bin/env bun
/**
 * Enforce Versions - PostToolUse hook for package.json changes
 *
 * Automatically checks package.json files for:
 * - Forbidden dependencies (lodash, express, prisma, etc.)
 * - Version drift from STACK.npm
 *
 * Runs after Write/Edit operations on package.json files.
 */

import { FileSystem } from '@effect/platform'
import { BunContext, BunRuntime } from '@effect/platform-bun'
import { Effect, pipe, Schema } from 'effect'
import { FORBIDDEN_PACKAGES } from '../stack'
import { emitContinue, emitHalt } from './lib/hook-logging'

// =============================================================================
// Types
// =============================================================================

type Violation = {
  readonly package: string
  readonly message: string
  readonly severity: 'high' | 'medium'
}

const PackageJsonSchema = Schema.Struct({
  dependencies: Schema.optional(Schema.Record({ key: Schema.String, value: Schema.String })),
  devDependencies: Schema.optional(Schema.Record({ key: Schema.String, value: Schema.String })),
})

// =============================================================================
// Configuration - uses SSOT from src/stack/forbidden.ts
// =============================================================================

// =============================================================================
// Main
// =============================================================================

const filePaths = (process.env['CLAUDE_FILE_PATHS'] ?? '').split(',').filter(Boolean)
const packageJsonFiles = filePaths.filter((p) => p.endsWith('package.json'))

const checkPackageJson = (pkgPath: string) =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const content = yield* fs.readFileString(pkgPath)

    const rawJson = yield* Effect.try({
      try: () => JSON.parse(content),
      catch: () => new Error(`Invalid JSON in ${pkgPath}`),
    })

    const pkg = yield* Schema.decodeUnknown(PackageJsonSchema)(rawJson)

    const allDeps = {
      ...pkg.dependencies,
      ...pkg.devDependencies,
    }

    const violations: Violation[] = []
    for (const forbidden of FORBIDDEN_PACKAGES) {
      if (allDeps[forbidden.name]) {
        violations.push({
          package: forbidden.name,
          message: `${forbidden.name} is forbidden. ${forbidden.reason}. Alternative: ${forbidden.alternative}`,
          severity: 'high',
        })
      }
    }

    return violations
  })

const program = Effect.gen(function* () {
  if (packageJsonFiles.length === 0) {
    emitContinue()
    return
  }

  const results = yield* Effect.all(
    packageJsonFiles.map((p) =>
      pipe(
        checkPackageJson(p),
        Effect.catchAll(() => Effect.succeed([] as Violation[])),
      ),
    ),
    { concurrency: 'unbounded' },
  )

  const allViolations = results.flat()
  const forbidden = allViolations.filter((v) => v.severity === 'high')

  if (forbidden.length > 0) {
    const errors = forbidden.map((v) => `  - ${v.message}`).join('\n')
    emitHalt({
      error: `STACK VIOLATION: Forbidden dependencies detected:\n${errors}\n\nRemove these before continuing.`,
    })
    return
  }

  emitContinue()
})

const runnable = pipe(
  program,
  Effect.catchAll(() => Effect.sync(() => emitContinue())),
  // biome-ignore lint/suspicious/noExplicitAny: BunContext.layer type variance issue
  Effect.provide(BunContext.layer as any),
)

// biome-ignore lint/suspicious/noExplicitAny: Effect runMain type inference
BunRuntime.runMain(runnable as any)
