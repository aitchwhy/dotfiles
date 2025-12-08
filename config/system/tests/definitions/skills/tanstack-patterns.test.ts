/**
 * TanStack Patterns Skill Tests
 */
import { describe, expect, test } from 'bun:test'
import { SystemSkill } from '@/schema'

describe('tanstack-patterns skill', () => {
  test('validates against schema', async () => {
    const { tanstackPatternsSkill } = await import('@/definitions/skills/tanstack-patterns')
    const result = SystemSkill.safeParse(tanstackPatternsSkill)
    expect(result.success).toBe(true)
  })

  test('has correct name', async () => {
    const { tanstackPatternsSkill } = await import('@/definitions/skills/tanstack-patterns')
    expect(tanstackPatternsSkill.name).toBe('tanstack-patterns')
  })
})
