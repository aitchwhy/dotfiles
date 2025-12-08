/**
 * All Skills Definition Tests
 *
 * Generic tests that validate all skill definitions against the schema.
 * Each skill file exports a {name}Skill constant that must pass validation.
 */
import { describe, test, expect } from 'bun:test'
import { SystemSkill } from '@/schema'
import { readdirSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const skillsDir = join(__dirname, '../../../src/definitions/skills')

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
        const modulePath = join(skillsDir, file)
        const module = await import(modulePath)

        // Find the skill export (convention: {camelCase}Skill)
        const skillExport = Object.keys(module).find((k) => k.endsWith('Skill'))
        expect(skillExport).toBeDefined()

        const skill = module[skillExport!]
        expect(skill).toBeDefined()
      })

      test('validates against SystemSkill schema', async () => {
        const modulePath = join(skillsDir, file)
        const module = await import(modulePath)
        const skillExport = Object.keys(module).find((k) => k.endsWith('Skill'))!
        const skill = module[skillExport]

        const result = SystemSkill.safeParse(skill)
        if (!result.success) {
          console.error(`Validation errors for ${skillName}:`, result.error.issues)
        }
        expect(result.success).toBe(true)
      })

      test('has valid name matching filename', async () => {
        const modulePath = join(skillsDir, file)
        const module = await import(modulePath)
        const skillExport = Object.keys(module).find((k) => k.endsWith('Skill'))!
        const skill = module[skillExport]

        expect(skill.name).toBe(skillName)
      })

      test('has description between 20-300 chars', async () => {
        const modulePath = join(skillsDir, file)
        const module = await import(modulePath)
        const skillExport = Object.keys(module).find((k) => k.endsWith('Skill'))!
        const skill = module[skillExport]

        expect(skill.description.length).toBeGreaterThanOrEqual(20)
        expect(skill.description.length).toBeLessThanOrEqual(300)
      })

      test('has at least one allowed tool', async () => {
        const modulePath = join(skillsDir, file)
        const module = await import(modulePath)
        const skillExport = Object.keys(module).find((k) => k.endsWith('Skill'))!
        const skill = module[skillExport]

        expect(skill.allowedTools.length).toBeGreaterThanOrEqual(1)
      })

      test('has at least one section', async () => {
        const modulePath = join(skillsDir, file)
        const module = await import(modulePath)
        const skillExport = Object.keys(module).find((k) => k.endsWith('Skill'))!
        const skill = module[skillExport]

        expect(skill.sections.length).toBeGreaterThanOrEqual(1)
      })
    })
  }
})
