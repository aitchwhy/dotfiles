/**
 * Claude Desktop Generator Adapter
 *
 * Generates personal preferences snapshot for Claude Desktop.
 * Since the "personal preferences" field is server-synced to Anthropic account,
 * we generate a version-controlled snapshot for manual sync.
 */

import * as fs from 'node:fs/promises'
import * as path from 'node:path'
import { Effect } from 'effect'
import { DESKTOP_PREFERENCES } from '../../desktop/preferences'

export const generateDesktopPreferences = (outDir: string) =>
  Effect.gen(function* () {
    yield* Effect.tryPromise(() => fs.mkdir(outDir, { recursive: true }))

    const content = `<!--
  Claude Desktop Personal Preferences
  Generated from: config/quality/src/desktop/preferences.ts

  To use: Copy the content below and paste into:
  Claude Desktop > Settings > General > "What personal preferences should Claude consider in responses"
-->

${DESKTOP_PREFERENCES}
`

    const filePath = path.join(outDir, 'preferences-snapshot.md')
    yield* Effect.tryPromise(() => fs.writeFile(filePath, content))
    yield* Effect.log(`Generated Claude Desktop preferences: ${filePath}`)
  })
