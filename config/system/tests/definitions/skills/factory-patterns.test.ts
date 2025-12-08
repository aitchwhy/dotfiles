/**
 * Factory Patterns Skill Tests
 */
import { describe, expect, test } from 'bun:test'
import { SystemSkill } from '@/schema'

describe('factory-patterns skill', () => {
  test('validates against schema', async () => {
    const { factoryPatternsSkill } = await import('@/definitions/skills/factory-patterns')
    const result = SystemSkill.safeParse(factoryPatternsSkill)
    expect(result.success).toBe(true)
  })

  test('has correct name', async () => {
    const { factoryPatternsSkill } = await import('@/definitions/skills/factory-patterns')
    expect(factoryPatternsSkill.name).toBe('factory-patterns')
  })
})
