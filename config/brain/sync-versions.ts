#!/usr/bin/env bun

/**
 * Sync versions from versions.json to package.json
 * Run: bun run sync-versions.ts
 */

import { FileSystem } from '@effect/platform'
import { BunContext, BunRuntime } from '@effect/platform-bun'
import { Console, Effect } from 'effect'

const program = Effect.gen(function* () {
  const fs = yield* FileSystem.FileSystem

  const versionsRaw = yield* fs.readFileString('versions.json')
  const versions = JSON.parse(versionsRaw) as Record<string, Record<string, string>>

  const pkgRaw = yield* fs.readFileString('package.json')
  const pkg = JSON.parse(pkgRaw) as Record<string, unknown>

  const deps = pkg['dependencies'] as Record<string, string> | undefined
  const devDeps = pkg['devDependencies'] as Record<string, string> | undefined

  let updated = 0

  const npmVersions = versions['npm'] ?? {}
  const effectVersions = versions['effect'] ?? {}
  const allVersions = { ...npmVersions, ...effectVersions }

  for (const [name, version] of Object.entries(allVersions)) {
    if (deps?.[name] && deps[name] !== version) {
      deps[name] = version
      updated++
      yield* Console.log(`Updated ${name}: ${deps[name]} → ${version}`)
    }
    if (devDeps?.[name] && devDeps[name] !== version) {
      devDeps[name] = version
      updated++
      yield* Console.log(`Updated ${name}: ${devDeps[name]} → ${version}`)
    }
  }

  if (updated > 0) {
    yield* fs.writeFileString('package.json', JSON.stringify(pkg, null, 2) + '\n')
    yield* Console.log(`\n✓ Updated ${updated} dependencies`)
  } else {
    yield* Console.log('✓ All dependencies up to date')
  }
})

const runnable = program.pipe(Effect.provide(BunContext.layer as any))
BunRuntime.runMain(runnable as any)
