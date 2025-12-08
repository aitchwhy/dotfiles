/**
 * Zod Patterns Skill Tests
 */
import { describe, test, expect } from 'bun:test'
import { SystemSkill } from '@/schema'

describe('zod-patterns skill', () => {
  test('validates against schema', async () => {
    const { zodPatternsSkill } = await import('@/definitions/skills/zod-patterns')
    const result = SystemSkill.safeParse(zodPatternsSkill)
    expect(result.success).toBe(true)
  })

  test('has correct name', async () => {
    const { zodPatternsSkill } = await import('@/definitions/skills/zod-patterns')
    expect(zodPatternsSkill.name).toBe('zod-patterns')
  })
})
