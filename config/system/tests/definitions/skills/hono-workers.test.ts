/**
 * Hono Workers Skill Tests
 */
import { describe, test, expect } from 'bun:test'
import { SystemSkill } from '@/schema'

describe('hono-workers skill', () => {
  test('validates against schema', async () => {
    const { honoWorkersSkill } = await import('@/definitions/skills/hono-workers')
    const result = SystemSkill.safeParse(honoWorkersSkill)
    expect(result.success).toBe(true)
  })

  test('has correct name', async () => {
    const { honoWorkersSkill } = await import('@/definitions/skills/hono-workers')
    expect(honoWorkersSkill.name).toBe('hono-workers')
  })
})
