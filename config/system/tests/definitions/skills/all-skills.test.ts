/**
 * All Skills Definition Tests
 *
 * Generic tests that validate all skill definitions against the schema.
 * Each skill file exports a {name}Skill constant that must pass validation.
 */
import { describe, expect, test } from 'bun:test'
import { readdirSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { SystemSkill } from '@/schema'

const __dirname = dirname(fileURLToPath(import.meta.url))
const skillsDir = join(__dirname, '../../../src/definitions/skills')

/**
 * Load a skill from a module file, throwing if not found
 */
async function loadSkill(file: string): Promise<{ name: string; export: string; skill: unknown }> {
  const modulePath = join(skillsDir, file)
  const module = await import(modulePath)
  const skillExport = Object.keys(module).find((k) => k.endsWith('Skill'))

  if (!skillExport) {
    throw new Error(`No skill export found in ${file}`)
  }

  return {
    name: file.replace('.ts', ''),
    export: skillExport,
    skill: module[skillExport],
  }
}

// Dynamically discover and test all skill definitions
describe('skill definitions', () => {
  const skillFiles = readdirSync(skillsDir).filter(
    (f) => f.endsWith('.ts') && !f.endsWith('.test.ts') && !f.endsWith('.spec.ts')
  )

  test('at least one skill definition exists', () => {
    expect(skillFiles.length).toBeGreaterThanOrEqual(1)
  })

  // Test each discovered skill
  for (const file of skillFiles) {
    const skillName = file.replace('.ts', '')

    describe(`${skillName}`, () => {
      test('exports a valid skill', async () => {
        const { skill, export: skillExport } = await loadSkill(file)
        expect(skillExport).toBeDefined()
        expect(skill).toBeDefined()
      })

      test('validates against SystemSkill schema', async () => {
        const { skill } = await loadSkill(file)
        const result = SystemSkill.safeParse(skill)

        if (!result.success) {
          console.error(`Validation errors for ${skillName}:`, result.error.issues)
        }
        expect(result.success).toBe(true)
      })

      test('has valid name matching filename', async () => {
        const { skill, name } = await loadSkill(file)
        expect((skill as { name: string }).name).toBe(name)
      })

      test('has description between 20-300 chars', async () => {
        const { skill } = await loadSkill(file)
        const s = skill as { description: string }
        expect(s.description.length).toBeGreaterThanOrEqual(20)
        expect(s.description.length).toBeLessThanOrEqual(300)
      })

      test('has at least one allowed tool', async () => {
        const { skill } = await loadSkill(file)
        const s = skill as { allowedTools: string[] }
        expect(s.allowedTools.length).toBeGreaterThanOrEqual(1)
      })

      test('has at least one section', async () => {
        const { skill } = await loadSkill(file)
        const s = skill as { sections: unknown[] }
        expect(s.sections.length).toBeGreaterThanOrEqual(1)
      })
    })
  }
})
