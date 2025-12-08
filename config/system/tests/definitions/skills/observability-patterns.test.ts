/**
 * Observability Patterns Skill Tests
 */
import { describe, test, expect } from 'bun:test'
import { SystemSkill } from '@/schema'

describe('observability-patterns skill', () => {
  test('validates against schema', async () => {
    const { observabilityPatternsSkill } = await import('@/definitions/skills/observability-patterns')
    const result = SystemSkill.safeParse(observabilityPatternsSkill)
    expect(result.success).toBe(true)
  })

  test('has correct name', async () => {
    const { observabilityPatternsSkill } = await import('@/definitions/skills/observability-patterns')
    expect(observabilityPatternsSkill.name).toBe('observability-patterns')
  })
})
