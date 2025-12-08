/**
 * Twelve Factor Skill Tests
 */
import { describe, test, expect } from 'bun:test'
import { SystemSkill } from '@/schema'

describe('twelve-factor skill', () => {
  test('validates against schema', async () => {
    const { twelveFactorSkill } = await import('@/definitions/skills/twelve-factor')
    const result = SystemSkill.safeParse(twelveFactorSkill)
    expect(result.success).toBe(true)
  })

  test('has correct name', async () => {
    const { twelveFactorSkill } = await import('@/definitions/skills/twelve-factor')
    expect(twelveFactorSkill.name).toBe('twelve-factor')
  })
})
