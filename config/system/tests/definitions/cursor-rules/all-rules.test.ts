/**
 * All Cursor Rules Test
 *
 * Validates all cursor rule definitions against the CursorRule schema.
 */
import { readdir } from 'node:fs/promises'
import { join } from 'node:path'
import { describe, expect, test } from 'bun:test'
import { CursorRule } from '@/schema'

const DEFINITIONS_DIR = join(import.meta.dir, '../../../src/definitions/cursor-rules')

describe('All Cursor Rules', () => {
  test('all definitions are valid CursorRule schemas', async () => {
    const entries = await readdir(DEFINITIONS_DIR, { withFileTypes: true })
    const ruleFiles = entries.filter((e) => e.isFile() && e.name.endsWith('.ts'))

    expect(ruleFiles.length).toBeGreaterThan(0)

    for (const file of ruleFiles) {
      const modulePath = join(DEFINITIONS_DIR, file.name)
      const module = await import(modulePath)

      // Find exported rule (convention: {name}Rule export)
      const exports = Object.entries(module).filter(([key]) => key.endsWith('Rule'))
      expect(exports.length).toBeGreaterThan(0)

      for (const [exportName, exportValue] of exports) {
        const result = CursorRule.safeParse(exportValue)

        if (!result.success) {
          console.error(`Validation failed for ${exportName} in ${file.name}:`, result.error.issues)
        }

        expect(result.success).toBe(true)
      }
    }
  })

  test('all rules have unique names', async () => {
    const entries = await readdir(DEFINITIONS_DIR, { withFileTypes: true })
    const ruleFiles = entries.filter((e) => e.isFile() && e.name.endsWith('.ts'))

    const names: string[] = []

    for (const file of ruleFiles) {
      const modulePath = join(DEFINITIONS_DIR, file.name)
      const module = await import(modulePath)

      for (const [exportName, exportValue] of Object.entries(module)) {
        if (exportName.endsWith('Rule')) {
          const rule = exportValue as { name: string }
          if (names.includes(rule.name)) {
            console.error(`Duplicate rule name: ${rule.name}`)
          }
          expect(names.includes(rule.name)).toBe(false)
          names.push(rule.name)
        }
      }
    }
  })

  test('all rules have at least one glob pattern', async () => {
    const entries = await readdir(DEFINITIONS_DIR, { withFileTypes: true })
    const ruleFiles = entries.filter((e) => e.isFile() && e.name.endsWith('.ts'))

    for (const file of ruleFiles) {
      const modulePath = join(DEFINITIONS_DIR, file.name)
      const module = await import(modulePath)

      for (const [exportName, exportValue] of Object.entries(module)) {
        if (exportName.endsWith('Rule')) {
          const rule = exportValue as { name: string; globs: string[] }
          expect(rule.globs.length).toBeGreaterThan(0)
        }
      }
    }
  })
})
