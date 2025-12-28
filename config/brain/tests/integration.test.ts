/**
 * Integration Tests
 *
 * End-to-end tests for the quality system.
 */

import { describe, expect, it } from 'vitest'
import { BEHAVIOR_COUNTS, CRITIC_BEHAVIORS } from '../src/critic-mode'
import { MEMORIES, MEMORY_COUNTS } from '../src/memories'
import { ALL_PERSONAS } from '../src/personas'
import { ALL_RULES } from '../src/rules'
import { ALL_SKILLS } from '../src/skills'

describe('Quality System Integration', () => {
  describe('counts', () => {
    it('has exactly 12 rules', () => {
      expect(ALL_RULES).toHaveLength(12)
    })

    it('has exactly 28 skills', () => {
      expect(ALL_SKILLS).toHaveLength(28)
    })

    it('has exactly 14 personas', () => {
      expect(ALL_PERSONAS).toHaveLength(14)
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

  describe('memories coverage', () => {
    it('has exactly 22 memories', () => {
      expect(MEMORIES).toHaveLength(22)
      expect(MEMORY_COUNTS.total).toBe(22)
    })

    it('has all required categories', () => {
      const categories = new Set(MEMORIES.map((m) => m.category))
      expect(categories).toContain('principle')
      expect(categories).toContain('constraint')
      expect(categories).toContain('pattern')
      expect(categories).toContain('gotcha')
    })

    it('has correct category counts', () => {
      expect(MEMORY_COUNTS.principle).toBe(5)
      expect(MEMORY_COUNTS.constraint).toBe(4)
      expect(MEMORY_COUNTS.pattern).toBe(11)
      expect(MEMORY_COUNTS.gotcha).toBe(2)
    })
  })

  describe('critic-mode coverage', () => {
    it('has exactly 5 behaviors', () => {
      expect(CRITIC_BEHAVIORS).toHaveLength(5)
      expect(BEHAVIOR_COUNTS.total).toBe(5)
    })

    it('covers both phases', () => {
      const phases = new Set(CRITIC_BEHAVIORS.map((b) => b.phase))
      expect(phases).toContain('planning')
      expect(phases).toContain('execution')
    })

    it('has correct phase counts', () => {
      expect(BEHAVIOR_COUNTS.planning).toBe(3)
      expect(BEHAVIOR_COUNTS.execution).toBe(2)
    })
  })
})
