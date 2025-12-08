/**
 * CursorRule Schema Tests
 *
 * Tests for Cursor IDE rule schema validation.
 */
import { describe, expect, test } from 'bun:test'

// These imports will fail until we implement the module (RED phase)
import {
  CodeExample,
  CrossReference,
  CursorRule,
  type CursorRule as CursorRuleType,
  RuleName,
} from '@/schema/cursor-rule'

describe('CursorRule Schema', () => {
  describe('RuleName', () => {
    test('accepts valid kebab-case names', () => {
      expect(RuleName.safeParse('cursor-rules').success).toBe(true)
      expect(RuleName.safeParse('dev-workflow').success).toBe(true)
      expect(RuleName.safeParse('self-improve').success).toBe(true)
      expect(RuleName.safeParse('abc123').success).toBe(true)
    })

    test('rejects invalid names', () => {
      expect(RuleName.safeParse('CursorRules').success).toBe(false) // PascalCase
      expect(RuleName.safeParse('cursor_rules').success).toBe(false) // snake_case
      expect(RuleName.safeParse('123-start').success).toBe(false) // starts with number
      expect(RuleName.safeParse('').success).toBe(false) // empty
    })
  })

  describe('CodeExample', () => {
    test('parses valid code example with defaults', () => {
      const result = CodeExample.safeParse({
        code: 'const x = 1',
      })
      expect(result.success).toBe(true)
      if (result.success) {
        expect(result.data.language).toBe('typescript')
        expect(result.data.annotation).toBe('neutral')
      }
    })

    test('parses code example with explicit values', () => {
      const result = CodeExample.safeParse({
        language: 'nix',
        code: 'pkgs.hello',
        annotation: 'good',
        description: 'Example of Nix code',
      })
      expect(result.success).toBe(true)
      if (result.success) {
        expect(result.data.language).toBe('nix')
        expect(result.data.annotation).toBe('good')
        expect(result.data.description).toBe('Example of Nix code')
      }
    })
  })

  describe('CrossReference', () => {
    test('parses valid cross-reference', () => {
      const result = CrossReference.safeParse({
        label: 'taskmaster.mdc',
        path: '.cursor/rules/taskmaster.mdc',
      })
      expect(result.success).toBe(true)
      if (result.success) {
        expect(result.data.label).toBe('taskmaster.mdc')
        expect(result.data.path).toBe('.cursor/rules/taskmaster.mdc')
      }
    })
  })

  describe('CursorRule', () => {
    const validRule: CursorRuleType = {
      name: 'test-rule' as CursorRuleType['name'],
      description: 'A test rule for validation purposes',
      globs: ['**/*.ts'],
      alwaysApply: false,
    }

    test('parses minimal valid rule', () => {
      const result = CursorRule.safeParse(validRule)
      expect(result.success).toBe(true)
    })

    test('applies default for alwaysApply', () => {
      const result = CursorRule.safeParse({
        name: 'test-rule',
        description: 'A test rule for validation',
        globs: ['**/*.ts'],
      })
      expect(result.success).toBe(true)
      if (result.success) {
        expect(result.data.alwaysApply).toBe(false)
      }
    })

    test('parses full rule with all fields', () => {
      const fullRule = {
        ...validRule,
        requirements: ['Must use strict mode', 'No any types'],
        examples: [{ code: 'const x: number = 1', annotation: 'good' as const }],
        antiPatterns: [{ code: 'const x: any = 1', annotation: 'bad' as const }],
        references: [{ label: 'other.mdc', path: '.cursor/rules/other.mdc' }],
        content: '## Additional Content\n\nMore details here.',
      }
      const result = CursorRule.safeParse(fullRule)
      expect(result.success).toBe(true)
    })

    test('rejects rule with short description', () => {
      const result = CursorRule.safeParse({
        ...validRule,
        description: 'Too short',
      })
      expect(result.success).toBe(false)
    })

    test('rejects rule with empty globs', () => {
      const result = CursorRule.safeParse({
        ...validRule,
        globs: [],
      })
      expect(result.success).toBe(false)
    })

    test('rejects rule with invalid name', () => {
      const result = CursorRule.safeParse({
        ...validRule,
        name: 'InvalidName',
      })
      expect(result.success).toBe(false)
    })
  })
})
