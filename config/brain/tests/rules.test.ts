/**
 * Quality Rules Tests
 *
 * Validates rule definitions and AST-grep pattern correctness.
 */

import { describe, expect, it } from 'vitest'
import {
  ALL_RULES,
  ARCHITECTURE_RULES,
  EFFECT_RULES,
  OBSERVABILITY_RULES,
  TYPE_SAFETY_RULES,
} from '../src/rules'

describe('Quality Rules', () => {
  describe('rule counts', () => {
    it('has exactly 12 total rules', () => {
      expect(ALL_RULES).toHaveLength(12)
    })

    it('has 3 type-safety rules', () => {
      expect(TYPE_SAFETY_RULES).toHaveLength(3)
    })

    it('has 5 effect rules', () => {
      expect(EFFECT_RULES).toHaveLength(5)
    })

    it('has 3 architecture rules', () => {
      expect(ARCHITECTURE_RULES).toHaveLength(3)
    })

    it('has 1 observability rule', () => {
      expect(OBSERVABILITY_RULES).toHaveLength(1)
    })
  })

  describe('rule structure', () => {
    it('all rules have required fields', () => {
      for (const rule of ALL_RULES) {
        expect(rule.id).toBeDefined()
        expect(rule.name).toBeDefined()
        expect(rule.category).toBeDefined()
        expect(rule.severity).toBeDefined()
        expect(rule.message).toBeDefined()
        expect(rule.patterns).toBeDefined()
        expect(rule.patterns.length).toBeGreaterThan(0)
        expect(rule.fix).toBeDefined()
      }
    })

    it('all rule IDs are unique', () => {
      const ids = ALL_RULES.map((r) => r.id)
      const uniqueIds = new Set(ids)
      expect(uniqueIds.size).toBe(ids.length)
    })

    it('all rules have valid severity', () => {
      for (const rule of ALL_RULES) {
        expect(['error', 'warning']).toContain(rule.severity)
      }
    })

    it('all rules have valid category', () => {
      const validCategories = ['type-safety', 'effect', 'architecture', 'observability']
      for (const rule of ALL_RULES) {
        expect(validCategories).toContain(rule.category)
      }
    })
  })

  describe('specific rules exist', () => {
    it('has no-any rule', () => {
      const rule = ALL_RULES.find((r) => r.id === 'no-any')
      expect(rule).toBeDefined()
      expect(rule?.severity).toBe('error')
    })

    it('has no-zod rule', () => {
      const rule = ALL_RULES.find((r) => r.id === 'no-zod')
      expect(rule).toBeDefined()
      expect(rule?.severity).toBe('error')
    })

    it('has no-try-catch rule', () => {
      const rule = ALL_RULES.find((r) => r.id === 'no-try-catch')
      expect(rule).toBeDefined()
      expect(rule?.severity).toBe('error')
    })

    it('has no-mock rule', () => {
      const rule = ALL_RULES.find((r) => r.id === 'no-mock')
      expect(rule).toBeDefined()
      expect(rule?.severity).toBe('error')
    })

    it('has no-console rule', () => {
      const rule = ALL_RULES.find((r) => r.id === 'no-console')
      expect(rule).toBeDefined()
      expect(rule?.severity).toBe('error')
    })
  })
})
