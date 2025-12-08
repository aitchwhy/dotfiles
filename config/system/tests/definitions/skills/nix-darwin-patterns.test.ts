/**
 * Nix Darwin Patterns Skill Tests
 */
import { describe, expect, test } from 'bun:test'
import { SystemSkill } from '@/schema'

describe('nix-darwin-patterns skill', () => {
  test('validates against schema', async () => {
    const { nixDarwinPatternsSkill } = await import('@/definitions/skills/nix-darwin-patterns')
    const result = SystemSkill.safeParse(nixDarwinPatternsSkill)
    expect(result.success).toBe(true)
  })

  test('has correct name', async () => {
    const { nixDarwinPatternsSkill } = await import('@/definitions/skills/nix-darwin-patterns')
    expect(nixDarwinPatternsSkill.name).toBe('nix-darwin-patterns')
  })
})
