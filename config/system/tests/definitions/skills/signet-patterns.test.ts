/**
 * Signet Patterns Skill Tests
 */
import { describe, expect, test } from 'bun:test'
import { SystemSkill } from '@/schema'

describe('signet-patterns skill', () => {
  test('validates against schema', async () => {
    const { signetPatternsSkill } = await import('@/definitions/skills/signet-patterns')
    const result = SystemSkill.safeParse(signetPatternsSkill)
    expect(result.success).toBe(true)
  })

  test('has correct name', async () => {
    const { signetPatternsSkill } = await import('@/definitions/skills/signet-patterns')
    expect(signetPatternsSkill.name).toBe('signet-patterns')
  })
})
