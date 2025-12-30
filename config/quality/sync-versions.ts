#!/usr/bin/env bun

/**
 * Sync versions from versions.ts SSOT to package.json
 * Run: bun run sync-versions.ts
 *
 * Uses Bun's native file APIs for simplicity (no @effect/platform dependency issues)
 */

import { Console, Effect, Record, Schema } from 'effect'
import { STACK } from './src/stack/versions'

// Schema for package.json structure - parse at boundary with defaults
const DepsRecord = Schema.Record({ key: Schema.String, value: Schema.String })

const PackageJsonSchema = Schema.Struct({
  dependencies: Schema.optionalWith(DepsRecord, { default: () => ({}) }),
  devDependencies: Schema.optionalWith(DepsRecord, { default: () => ({}) }),
}).pipe(Schema.extend(Schema.Record({ key: Schema.String, value: Schema.Unknown })))

const program = Effect.gen(function* () {
  const pkgRaw = yield* Effect.try({
    try: () => Bun.file('package.json').text(),
    catch: (e) => new Error(`Failed to read package.json: ${e}`),
  }).pipe(Effect.flatMap((p) => Effect.promise(() => p)))

  const parsed = yield* Schema.decodeUnknown(Schema.parseJson(PackageJsonSchema))(pkgRaw)

  // After parsing, deps and devDeps are guaranteed to be objects (never undefined)
  const deps = parsed.dependencies
  const devDeps = parsed.devDependencies

  let updated = 0
  const updatedDeps = { ...deps }
  const updatedDevDeps = { ...devDeps }

  // Use STACK.npm as the single source of truth
  for (const [name, version] of Object.entries(STACK.npm)) {
    const currentDep = Record.get(deps, name)
    const currentDevDep = Record.get(devDeps, name)

    if (currentDep._tag === 'Some' && currentDep.value !== version) {
      updatedDeps[name] = version
      updated++
      yield* Console.log(`Updated ${name}: ${currentDep.value} → ${version}`)
    }
    if (currentDevDep._tag === 'Some' && currentDevDep.value !== version) {
      updatedDevDeps[name] = version
      updated++
      yield* Console.log(`Updated ${name}: ${currentDevDep.value} → ${version}`)
    }
  }

  if (updated > 0) {
    const updatedPkg = {
      ...parsed,
      dependencies: updatedDeps,
      devDependencies: updatedDevDeps,
    }
    yield* Effect.try({
      try: () => Bun.write('package.json', JSON.stringify(updatedPkg, null, 2) + '\n'),
      catch: (e) => new Error(`Failed to write package.json: ${e}`),
    }).pipe(Effect.flatMap((p) => Effect.promise(() => p)))
    yield* Console.log(`\n✓ Updated ${updated} dependencies`)
  } else {
    yield* Console.log('✓ All dependencies up to date')
  }
})

// Run with Effect.runPromise
void Effect.runPromise(program)
