/**
 * Dev Workflow Rule Test
 */
import { describe, expect, test } from 'bun:test'
import { devWorkflowRule } from '@/definitions/cursor-rules/dev-workflow'
import { CursorRule } from '@/schema'

describe('dev-workflow rule', () => {
  test('is a valid CursorRule', () => {
    const result = CursorRule.safeParse(devWorkflowRule)
    expect(result.success).toBe(true)
  })

  test('has correct name', () => {
    expect(devWorkflowRule.name).toBe('dev-workflow')
  })

  test('applies to all files', () => {
    expect(devWorkflowRule.globs).toContain('**/*')
  })

  test('is always applied', () => {
    expect(devWorkflowRule.alwaysApply).toBe(true)
  })

  test('has content with workflow sections', () => {
    expect(devWorkflowRule.content).toBeDefined()
  })
})
