/**
 * Integration Tests
 *
 * End-to-end tests for the quality system.
 * Uses SSOT constants for counts - validates internal consistency, not magic numbers.
 */

import { describe, expect, it } from 'vitest'
import { BEHAVIOR_COUNTS, CRITIC_BEHAVIORS } from '../src/critic-mode'
import { MEMORIES, MEMORY_COUNTS } from '../src/memories'
import { ALL_PERSONAS } from '../src/personas'
import { ALL_RULES, RULE_COUNT } from '../src/rules'
import { ALL_SKILLS } from '../src/skills'

describe('Quality System Integration', () => {
  describe('counts - SSOT validation', () => {
    it('rules array matches exported RULE_COUNT', () => {
      expect(ALL_RULES).toHaveLength(RULE_COUNT)
      expect(ALL_RULES.length).toBeGreaterThan(0)
    })

    it('skills array has items', () => {
      expect(ALL_SKILLS.length).toBeGreaterThan(0)
    })

    it('personas array has items', () => {
      expect(ALL_PERSONAS.length).toBeGreaterThan(0)
    })
  })

  describe('rules coverage', () => {
    it('covers all categories', () => {
      const categories = new Set(ALL_RULES.map((r) => r.category))
      expect(categories).toContain('type-safety')
      expect(categories).toContain('effect')
      expect(categories).toContain('architecture')
      expect(categories).toContain('observability')
    })

    it('has error-severity rules for critical violations', () => {
      const errors = ALL_RULES.filter((r) => r.severity === 'error')
      expect(errors.length).toBeGreaterThan(0)

      const criticalIds = ['no-any', 'no-try-catch', 'no-mock', 'no-console']
      for (const id of criticalIds) {
        expect(errors.some((r) => r.id === id)).toBe(true)
      }
    })
  })

  describe('skills coverage', () => {
    it('has core Effect skill', () => {
      expect(ALL_SKILLS.some((s) => s.frontmatter.name === 'effect-ts')).toBe(true)
    })

    it('has testing skill', () => {
      expect(ALL_SKILLS.some((s) => s.frontmatter.name === 'testing')).toBe(true)
    })

    it('all skills have sections', () => {
      for (const skill of ALL_SKILLS) {
        expect(skill.sections.length).toBeGreaterThan(0)
      }
    })
  })

  describe('personas coverage', () => {
    it('has opus-level personas for complex tasks', () => {
      const opusPersonas = ALL_PERSONAS.filter((p) => p.model === 'opus')
      expect(opusPersonas.length).toBeGreaterThan(0)
    })

    it('all personas have system prompts', () => {
      for (const persona of ALL_PERSONAS) {
        expect(persona.systemPrompt.length).toBeGreaterThan(50)
      }
    })
  })

  describe('memories coverage - SSOT validation', () => {
    it('memories array matches MEMORY_COUNTS.total', () => {
      expect(MEMORIES).toHaveLength(MEMORY_COUNTS.total)
    })

    it('category counts sum to total', () => {
      const sum =
        MEMORY_COUNTS.principle +
        MEMORY_COUNTS.constraint +
        MEMORY_COUNTS.pattern +
        MEMORY_COUNTS.gotcha +
        MEMORY_COUNTS.standard
      expect(sum).toBe(MEMORY_COUNTS.total)
    })

    it('has all required categories', () => {
      const categories = new Set(MEMORIES.map((m) => m.category))
      expect(categories).toContain('principle')
      expect(categories).toContain('constraint')
      expect(categories).toContain('pattern')
      expect(categories).toContain('standard')
    })
  })

  describe('critic-mode coverage - SSOT validation', () => {
    it('behaviors array matches BEHAVIOR_COUNTS.total', () => {
      expect(CRITIC_BEHAVIORS).toHaveLength(BEHAVIOR_COUNTS.total)
    })

    it('phase counts sum to total', () => {
      expect(BEHAVIOR_COUNTS.planning + BEHAVIOR_COUNTS.execution).toBe(BEHAVIOR_COUNTS.total)
    })

    it('covers both phases', () => {
      const phases = new Set(CRITIC_BEHAVIORS.map((b) => b.phase))
      expect(phases).toContain('planning')
      expect(phases).toContain('execution')
    })
  })
})
