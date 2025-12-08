/**
 * Clean Code Skill Definition Tests
 *
 * Tests that the clean-code skill definition validates against the schema.
 */
import { describe, expect, test } from 'bun:test'
import { cleanCodeSkill } from '@/definitions/skills/clean-code'
import { SystemSkill } from '@/schema'

describe('clean-code skill definition', () => {
  test('validates against SystemSkill schema', () => {
    const result = SystemSkill.safeParse(cleanCodeSkill)
    expect(result.success).toBe(true)
  })

  test('has correct name', () => {
    expect(cleanCodeSkill.name).toBe('clean-code')
  })

  test('has valid description', () => {
    expect(cleanCodeSkill.description.length).toBeGreaterThanOrEqual(20)
    expect(cleanCodeSkill.description.length).toBeLessThanOrEqual(300)
  })

  test('has at least one allowed tool', () => {
    expect(cleanCodeSkill.allowedTools.length).toBeGreaterThanOrEqual(1)
  })

  test('has at least one section', () => {
    expect(cleanCodeSkill.sections.length).toBeGreaterThanOrEqual(1)
  })

  test('has Nix-specific patterns section', () => {
    const nixSection = cleanCodeSkill.sections.find((s) => s.title.includes('Nix'))
    expect(nixSection).toBeDefined()
  })

  test('has TypeScript patterns section', () => {
    const tsSection = cleanCodeSkill.sections.find((s) => s.title.includes('TypeScript'))
    expect(tsSection).toBeDefined()
  })

  test('has File Organization section', () => {
    const fileSection = cleanCodeSkill.sections.find((s) => s.title.includes('File'))
    expect(fileSection).toBeDefined()
  })
})
