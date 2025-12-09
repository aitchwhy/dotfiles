/**
 * Workflow Port Tests
 *
 * Tests for the Workflow port interface and schema definitions.
 */
import { describe, expect, test } from 'vitest'
import { Schema } from 'effect'

describe('Workflow Port', () => {
  describe('WorkflowStatus Schema', () => {
    test('accepts valid status values', async () => {
      const { WorkflowStatus } = await import('@/ports/workflow')
      const validStatuses = ['pending', 'running', 'completed', 'failed', 'cancelled', 'timed_out']
      for (const status of validStatuses) {
        const result = Schema.decodeUnknownSync(WorkflowStatus)(status)
        expect(result).toBe(status)
      }
    })

    test('rejects invalid status', async () => {
      const { WorkflowStatus } = await import('@/ports/workflow')
      expect(() => Schema.decodeUnknownSync(WorkflowStatus)('invalid')).toThrow()
    })
  })

  describe('WorkflowExecution Schema', () => {
    test('validates a valid execution', async () => {
      const { WorkflowExecution } = await import('@/ports/workflow')
      const validExecution = {
        workflowId: 'wf_123',
        runId: 'run_456',
        status: 'running',
        startedAt: '2025-12-01T00:00:00.000Z',
      }
      const result = Schema.decodeUnknownSync(WorkflowExecution)(validExecution)
      expect(result.workflowId).toBe('wf_123')
      expect(result.status).toBe('running')
    })

    test('allows optional completedAt and result', async () => {
      const { WorkflowExecution } = await import('@/ports/workflow')
      const completedExecution = {
        workflowId: 'wf_123',
        runId: 'run_456',
        status: 'completed',
        startedAt: '2025-12-01T00:00:00.000Z',
        completedAt: '2025-12-01T00:00:00.000Z',
        result: { success: true },
      }
      const result = Schema.decodeUnknownSync(WorkflowExecution)(completedExecution)
      expect(result.completedAt).toBeDefined()
      expect(result.result).toEqual({ success: true })
    })
  })

  describe('WorkflowError Schema', () => {
    test('creates tagged error with valid code', async () => {
      const { WorkflowError } = await import('@/ports/workflow')
      const error = new WorkflowError({
        code: 'WORKFLOW_NOT_FOUND',
        message: 'Workflow not found',
        workflowId: 'wf_123',
      })
      expect(error._tag).toBe('WorkflowError')
      expect(error.code).toBe('WORKFLOW_NOT_FOUND')
    })
  })

  describe('Workflow Context Tag', () => {
    test('Workflow tag is defined', async () => {
      const { Workflow } = await import('@/ports/workflow')
      expect(Workflow).toBeDefined()
      expect(Workflow.key).toBe('Workflow')
    })
  })
})
