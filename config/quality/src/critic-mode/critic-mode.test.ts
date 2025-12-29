/**
 * Critic Mode Tests
 *
 * Validates metacognitive behaviors and configuration.
 * Uses SSOT pattern - validates internal consistency, not magic numbers.
 */
import { Schema } from 'effect'
import { describe, expect, it } from 'vitest'
import { BEHAVIOR_COUNTS, CRITIC_BEHAVIORS, CRITIC_MODE_CONFIG, getBehaviorsByPhase } from './index'
import { CriticBehaviorSchema, CriticModeConfigSchema } from './schemas'

describe('Critic Mode System', () => {
  describe('counts - SSOT validation', () => {
    it('behaviors array matches BEHAVIOR_COUNTS.total', () => {
      expect(CRITIC_BEHAVIORS).toHaveLength(BEHAVIOR_COUNTS.total)
      expect(CRITIC_BEHAVIORS.length).toBeGreaterThan(0)
    })

    it('phase counts sum to total', () => {
      expect(BEHAVIOR_COUNTS.planning + BEHAVIOR_COUNTS.execution).toBe(BEHAVIOR_COUNTS.total)
    })

    it('each phase count matches actual behaviors', () => {
      expect(getBehaviorsByPhase('planning')).toHaveLength(BEHAVIOR_COUNTS.planning)
      expect(getBehaviorsByPhase('execution')).toHaveLength(BEHAVIOR_COUNTS.execution)
    })
  })

  describe('schema validation', () => {
    it('all behaviors pass schema validation', () => {
      const decode = Schema.decodeUnknownSync(CriticBehaviorSchema)
      for (const behavior of CRITIC_BEHAVIORS) {
        expect(() => decode(behavior)).not.toThrow()
      }
    })

    it('config passes schema validation', () => {
      const decode = Schema.decodeUnknownSync(CriticModeConfigSchema)
      expect(() => decode(CRITIC_MODE_CONFIG)).not.toThrow()
    })

    it('all behavior IDs are unique', () => {
      const ids = CRITIC_BEHAVIORS.map((b) => b.id)
      const uniqueIds = new Set(ids)
      expect(uniqueIds.size).toBe(ids.length)
    })

    it('all behavior IDs match kebab-case pattern', () => {
      const pattern = /^[a-z0-9-]+$/
      for (const behavior of CRITIC_BEHAVIORS) {
        expect(behavior.id).toMatch(pattern)
      }
    })
  })

  describe('content quality', () => {
    it('all behaviors have non-empty triggers', () => {
      for (const behavior of CRITIC_BEHAVIORS) {
        expect(behavior.trigger.length).toBeGreaterThan(10)
      }
    })

    it('all behaviors have non-empty actions', () => {
      for (const behavior of CRITIC_BEHAVIORS) {
        expect(behavior.action.length).toBeGreaterThan(20)
      }
    })

    it('all behaviors have titles under 60 chars', () => {
      for (const behavior of CRITIC_BEHAVIORS) {
        expect(behavior.title.length).toBeLessThanOrEqual(60)
      }
    })
  })

  describe('helper functions', () => {
    it('getBehaviorsByPhase returns behaviors with correct phase', () => {
      const planningBehaviors = getBehaviorsByPhase('planning')
      for (const behavior of planningBehaviors) {
        expect(behavior.phase).toBe('planning')
      }

      const executionBehaviors = getBehaviorsByPhase('execution')
      for (const behavior of executionBehaviors) {
        expect(behavior.phase).toBe('execution')
      }
    })
  })

  describe('config state', () => {
    it('critic mode is enabled by default', () => {
      expect(CRITIC_MODE_CONFIG.enabled).toBe(true)
    })

    it('config behaviors match CRITIC_BEHAVIORS', () => {
      expect(CRITIC_MODE_CONFIG.behaviors).toHaveLength(CRITIC_BEHAVIORS.length)
    })
  })

  describe('specific behaviors exist', () => {
    const requiredIds = [
      'assumption-detection',
      'scope-boundary-check',
      'failure-mode-enumeration',
      'side-effect-audit',
      'incremental-verification',
    ]

    it.each(requiredIds)('has required behavior: %s', (id) => {
      const behavior = CRITIC_BEHAVIORS.find((b) => b.id === id)
      expect(behavior).toBeDefined()
    })
  })
})
