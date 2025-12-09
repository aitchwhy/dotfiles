/**
 * Queue Port - Message Queue Service Interface
 *
 * Defines the contract for async message queue operations.
 * Implemented by adapters like Redis (BullMQ pattern).
 */
import { Context, Effect, Schema } from 'effect'

// ============================================================================
// SCHEMAS
// ============================================================================

export const JobStatus = Schema.Literal(
  'pending',
  'active',
  'completed',
  'failed',
  'delayed',
  'paused',
)

export type JobStatus = Schema.Schema.Type<typeof JobStatus>

export const Job = Schema.Struct({
  id: Schema.String,
  name: Schema.String,
  data: Schema.Unknown,
  status: JobStatus,
  attempts: Schema.Number,
  maxAttempts: Schema.Number,
  createdAt: Schema.Date,
  processedAt: Schema.optional(Schema.Date),
  completedAt: Schema.optional(Schema.Date),
  failedReason: Schema.optional(Schema.String),
})

export type Job = Schema.Schema.Type<typeof Job>

export const JobOptions = Schema.Struct({
  delay: Schema.optional(Schema.Number),
  attempts: Schema.optional(Schema.Number),
  backoff: Schema.optional(
    Schema.Struct({
      type: Schema.Literal('fixed', 'exponential'),
      delay: Schema.Number,
    }),
  ),
  priority: Schema.optional(Schema.Number),
  removeOnComplete: Schema.optional(Schema.Boolean),
  removeOnFail: Schema.optional(Schema.Boolean),
})

export type JobOptions = Schema.Schema.Type<typeof JobOptions>

// ============================================================================
// ERRORS
// ============================================================================

export class QueueError extends Schema.TaggedError<QueueError>()('QueueError', {
  code: Schema.Literal(
    'JOB_NOT_FOUND',
    'QUEUE_NOT_FOUND',
    'SERIALIZATION_ERROR',
    'CONNECTION_ERROR',
    'TIMEOUT',
    'INTERNAL_ERROR',
  ),
  message: Schema.String,
  jobId: Schema.optional(Schema.String),
}) {}

// ============================================================================
// PORT INTERFACE
// ============================================================================

export interface QueueService {
  readonly add: <T>(
    queueName: string,
    jobName: string,
    data: T,
    options?: JobOptions,
  ) => Effect.Effect<Job, QueueError>

  readonly addBulk: <T>(
    queueName: string,
    jobs: readonly { name: string; data: T; options?: JobOptions }[],
  ) => Effect.Effect<readonly Job[], QueueError>

  readonly getJob: (queueName: string, jobId: string) => Effect.Effect<Job | null, QueueError>

  readonly getJobs: (
    queueName: string,
    status?: JobStatus,
    start?: number,
    end?: number,
  ) => Effect.Effect<readonly Job[], QueueError>

  readonly removeJob: (queueName: string, jobId: string) => Effect.Effect<void, QueueError>

  readonly pauseQueue: (queueName: string) => Effect.Effect<void, QueueError>

  readonly resumeQueue: (queueName: string) => Effect.Effect<void, QueueError>
}

export class Queue extends Context.Tag('Queue')<Queue, QueueService>() {}
