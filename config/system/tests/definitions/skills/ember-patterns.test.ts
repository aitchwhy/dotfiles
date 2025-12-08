/**
 * Ember Patterns Skill Tests
 */
import { describe, test, expect } from 'bun:test'
import { SystemSkill } from '@/schema'

describe('ember-patterns skill', () => {
  test('validates against schema', async () => {
    const { emberPatternsSkill } = await import('@/definitions/skills/ember-patterns')
    const result = SystemSkill.safeParse(emberPatternsSkill)
    expect(result.success).toBe(true)
  })

  test('has correct name', async () => {
    const { emberPatternsSkill } = await import('@/definitions/skills/ember-patterns')
    expect(emberPatternsSkill.name).toBe('ember-patterns')
  })
})
