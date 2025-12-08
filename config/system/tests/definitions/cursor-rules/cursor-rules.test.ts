/**
 * Cursor Rules Rule Test
 */
import { describe, expect, test } from 'bun:test'
import { cursorRulesRule } from '@/definitions/cursor-rules/cursor-rules'
import { CursorRule } from '@/schema'

describe('cursor-rules rule', () => {
  test('is a valid CursorRule', () => {
    const result = CursorRule.safeParse(cursorRulesRule)
    expect(result.success).toBe(true)
  })

  test('has correct name', () => {
    expect(cursorRulesRule.name).toBe('cursor-rules')
  })

  test('applies to .mdc files', () => {
    expect(cursorRulesRule.globs).toContain('.cursor/rules/*.mdc')
  })

  test('is always applied', () => {
    expect(cursorRulesRule.alwaysApply).toBe(true)
  })

  test('has content with rule structure', () => {
    expect(cursorRulesRule.content).toContain('Required Rule Structure')
    expect(cursorRulesRule.content).toContain('File References')
    expect(cursorRulesRule.content).toContain('Code Examples')
  })
})
