/**
 * Quality Rules Tests
 *
 * Validates rule definitions and AST-grep pattern correctness.
 * Uses SSOT pattern - validates internal consistency, not magic numbers.
 */

import { describe, expect, it } from 'vitest'
import {
  ALL_RULES,
  ARCHITECTURE_RULES,
  EFFECT_RULES,
  OBSERVABILITY_RULES,
  RULE_COUNT,
  TYPE_SAFETY_RULES,
} from '../src/rules'

describe('Quality Rules', () => {
  describe('rule counts - SSOT validation', () => {
    it('ALL_RULES array matches exported RULE_COUNT', () => {
      expect(ALL_RULES).toHaveLength(RULE_COUNT)
      expect(ALL_RULES.length).toBeGreaterThan(0)
    })

    it('category arrays sum to total', () => {
      const categorySum =
        TYPE_SAFETY_RULES.length +
        EFFECT_RULES.length +
        ARCHITECTURE_RULES.length +
        OBSERVABILITY_RULES.length
      expect(categorySum).toBe(ALL_RULES.length)
    })

    it('each category has at least one rule', () => {
      expect(TYPE_SAFETY_RULES.length).toBeGreaterThan(0)
      expect(EFFECT_RULES.length).toBeGreaterThan(0)
      expect(ARCHITECTURE_RULES.length).toBeGreaterThan(0)
      expect(OBSERVABILITY_RULES.length).toBeGreaterThan(0)
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

  describe('critical rules exist', () => {
    const criticalRuleIds = ['no-any', 'no-zod', 'no-try-catch', 'no-mock', 'no-console']

    it.each(criticalRuleIds)('has critical rule: %s', (ruleId) => {
      const rule = ALL_RULES.find((r) => r.id === ruleId)
      expect(rule).toBeDefined()
      expect(rule?.severity).toBe('error')
    })
  })
})
