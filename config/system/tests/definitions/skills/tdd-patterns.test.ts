/**
 * TDD Patterns Skill Tests
 */
import { describe, test, expect } from 'bun:test'
import { SystemSkill } from '@/schema'

describe('tdd-patterns skill', () => {
  test('validates against schema', async () => {
    const { tddPatternsSkill } = await import('@/definitions/skills/tdd-patterns')
    const result = SystemSkill.safeParse(tddPatternsSkill)
    expect(result.success).toBe(true)
  })

  test('has correct name', async () => {
    const { tddPatternsSkill } = await import('@/definitions/skills/tdd-patterns')
    expect(tddPatternsSkill.name).toBe('tdd-patterns')
  })
})
