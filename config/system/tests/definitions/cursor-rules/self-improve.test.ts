/**
 * Self Improve Rule Test
 */
import { describe, expect, test } from 'bun:test'
import { selfImproveRule } from '@/definitions/cursor-rules/self-improve'
import { CursorRule } from '@/schema'

describe('self-improve rule', () => {
  test('is a valid CursorRule', () => {
    const result = CursorRule.safeParse(selfImproveRule)
    expect(result.success).toBe(true)
  })

  test('has correct name', () => {
    expect(selfImproveRule.name).toBe('self-improve')
  })

  test('applies to all files', () => {
    expect(selfImproveRule.globs).toContain('**/*')
  })

  test('is always applied', () => {
    expect(selfImproveRule.alwaysApply).toBe(true)
  })

  test('has content about rule improvement', () => {
    expect(selfImproveRule.content).toContain('Rule Improvement')
  })
})
