/**
 * LiveKit Agents Skill Tests
 */
import { describe, expect, test } from 'bun:test'
import { SystemSkill } from '@/schema'

describe('livekit-agents skill', () => {
  test('validates against schema', async () => {
    const { livekitAgentsSkill } = await import('@/definitions/skills/livekit-agents')
    const result = SystemSkill.safeParse(livekitAgentsSkill)
    expect(result.success).toBe(true)
  })

  test('has correct name', async () => {
    const { livekitAgentsSkill } = await import('@/definitions/skills/livekit-agents')
    expect(livekitAgentsSkill.name).toBe('livekit-agents')
  })
})
