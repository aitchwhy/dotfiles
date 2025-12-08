/**
 * TypeScript Patterns Skill Tests
 */
import { describe, test, expect } from 'bun:test'
import { SystemSkill } from '@/schema'

describe('typescript-patterns skill', () => {
  test('validates against schema', async () => {
    const { typescriptPatternsSkill } = await import('@/definitions/skills/typescript-patterns')
    const result = SystemSkill.safeParse(typescriptPatternsSkill)
    expect(result.success).toBe(true)
  })

  test('has correct name', async () => {
    const { typescriptPatternsSkill } = await import('@/definitions/skills/typescript-patterns')
    expect(typescriptPatternsSkill.name).toBe('typescript-patterns')
  })
})
