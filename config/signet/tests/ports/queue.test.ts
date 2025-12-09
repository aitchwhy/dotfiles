/**
 * Queue Port Tests
 *
 * Tests for the Queue port interface and schema definitions.
 */
import { describe, expect, test } from 'vitest'
import { Schema } from 'effect'

describe('Queue Port', () => {
  describe('JobStatus Schema', () => {
    test('accepts valid status values', async () => {
      const { JobStatus } = await import('@/ports/queue')
      const validStatuses = ['pending', 'active', 'completed', 'failed', 'delayed', 'paused']
      for (const status of validStatuses) {
        const result = Schema.decodeUnknownSync(JobStatus)(status)
        expect(result).toBe(status)
      }
    })

    test('rejects invalid status', async () => {
      const { JobStatus } = await import('@/ports/queue')
      expect(() => Schema.decodeUnknownSync(JobStatus)('invalid')).toThrow()
    })
  })

  describe('Job Schema', () => {
    test('validates a valid job', async () => {
      const { Job } = await import('@/ports/queue')
      const validJob = {
        id: 'job_123',
        name: 'send-email',
        data: { to: 'user@example.com', subject: 'Hello' },
        status: 'pending',
        attempts: 0,
        maxAttempts: 3,
        createdAt: '2025-12-01T00:00:00.000Z',
      }
      const result = Schema.decodeUnknownSync(Job)(validJob)
      expect(result.id).toBe('job_123')
      expect(result.name).toBe('send-email')
      expect(result.status).toBe('pending')
    })

    test('allows optional processedAt and completedAt', async () => {
      const { Job } = await import('@/ports/queue')
      const completedJob = {
        id: 'job_123',
        name: 'send-email',
        data: {},
        status: 'completed',
        attempts: 1,
        maxAttempts: 3,
        createdAt: '2025-12-01T00:00:00.000Z',
        processedAt: '2025-12-01T00:00:00.000Z',
        completedAt: '2025-12-01T00:00:00.000Z',
      }
      const result = Schema.decodeUnknownSync(Job)(completedJob)
      expect(result.completedAt).toBeDefined()
    })
  })

  describe('JobOptions Schema', () => {
    test('validates options with backoff', async () => {
      const { JobOptions } = await import('@/ports/queue')
      const validOptions = {
        delay: 5000,
        attempts: 3,
        backoff: { type: 'exponential', delay: 1000 },
        priority: 1,
      }
      const result = Schema.decodeUnknownSync(JobOptions)(validOptions)
      expect(result.backoff?.type).toBe('exponential')
    })

    test('allows empty options', async () => {
      const { JobOptions } = await import('@/ports/queue')
      const emptyOptions = {}
      const result = Schema.decodeUnknownSync(JobOptions)(emptyOptions)
      expect(result.delay).toBeUndefined()
    })
  })

  describe('QueueError Schema', () => {
    test('creates tagged error with valid code', async () => {
      const { QueueError } = await import('@/ports/queue')
      const error = new QueueError({
        code: 'JOB_NOT_FOUND',
        message: 'Job not found',
        jobId: 'job_123',
      })
      expect(error._tag).toBe('QueueError')
      expect(error.code).toBe('JOB_NOT_FOUND')
    })
  })

  describe('Queue Context Tag', () => {
    test('Queue tag is defined', async () => {
      const { Queue } = await import('@/ports/queue')
      expect(Queue).toBeDefined()
      expect(Queue.key).toBe('Queue')
    })
  })
})
