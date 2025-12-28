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
// Configuration (must match config/brain/src/stack/versions.ts)
// =============================================================================

const FORBIDDEN_DEPS: Record<string, string> = {
  lodash: 'Use native Array/Object methods or Effect utilities',
  'lodash-es': 'Use native Array/Object methods or Effect utilities',
  underscore: 'Use native Array/Object methods or Effect utilities',
  express: 'Use Effect Platform HTTP instead (@effect/platform)',
  fastify: 'Use Effect Platform HTTP instead (@effect/platform)',
  koa: 'Use Effect Platform HTTP instead (@effect/platform)',
  hono: 'Use Effect Platform HTTP instead (@effect/platform)',
  prisma: 'Use Drizzle ORM instead (type-safe, SQL-first)',
  '@prisma/client': 'Use Drizzle ORM instead (type-safe, SQL-first)',
  mongoose: 'Use Drizzle + PostgreSQL instead of MongoDB',
  moment: 'Use native Date API or Temporal (Stage 3)',
  'moment-timezone': 'Use native Date API or Temporal (Stage 3)',
  axios: 'Use native fetch() or Effect HttpClient',
  jest: 'Use Vitest instead (Vite-native, faster)',
  '@jest/globals': 'Use Vitest instead (Vite-native, faster)',
  eslint: 'Use Biome or OXLint instead (faster, unified)',
  prettier: 'Use Biome instead (unified format + lint)',
  redux: 'Use XState (state machines) or Zustand (simple state)',
  '@reduxjs/toolkit': 'Use XState (state machines) or Zustand (simple state)',
  webpack: 'Use Vite instead (ESM-native, faster)',
  'webpack-cli': 'Use Vite instead (ESM-native, faster)',
}

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
    for (const [dep, reason] of Object.entries(FORBIDDEN_DEPS)) {
      if (allDeps[dep]) {
        violations.push({
          package: dep,
          message: `${dep} is forbidden. ${reason}`,
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
  Effect.provide(BunContext.layer as any),
)

BunRuntime.runMain(runnable as any)
