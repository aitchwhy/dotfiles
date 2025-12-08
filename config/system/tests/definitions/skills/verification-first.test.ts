/**
 * Verification First Skill Tests
 */
import { describe, expect, test } from 'bun:test'
import { SystemSkill } from '@/schema'

describe('verification-first skill', () => {
  test('validates against schema', async () => {
    const { verificationFirstSkill } = await import('@/definitions/skills/verification-first')
    const result = SystemSkill.safeParse(verificationFirstSkill)
    expect(result.success).toBe(true)
  })

  test('has correct name', async () => {
    const { verificationFirstSkill } = await import('@/definitions/skills/verification-first')
    expect(verificationFirstSkill.name).toBe('verification-first')
  })
})
