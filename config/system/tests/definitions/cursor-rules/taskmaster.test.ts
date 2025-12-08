/**
 * Taskmaster Rule Test
 */
import { describe, expect, test } from 'bun:test'
import { taskmasterRule } from '@/definitions/cursor-rules/taskmaster'
import { CursorRule } from '@/schema'

describe('taskmaster rule', () => {
  test('is a valid CursorRule', () => {
    const result = CursorRule.safeParse(taskmasterRule)
    expect(result.success).toBe(true)
  })

  test('has correct name', () => {
    expect(taskmasterRule.name).toBe('taskmaster')
  })

  test('applies to all files', () => {
    expect(taskmasterRule.globs).toContain('**/*')
  })

  test('is always applied', () => {
    expect(taskmasterRule.alwaysApply).toBe(true)
  })

  test('has content about Taskmaster tools', () => {
    expect(taskmasterRule.content).toBeDefined()
  })
})
