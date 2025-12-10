/**
 * Workflow Port - Durable Workflow Service Interface
 *
 * Defines the contract for durable workflow execution.
 * Implemented by adapters like Temporal or Restate.
 */
import { Context, type Effect, Schema } from 'effect';

// ============================================================================
// SCHEMAS
// ============================================================================

export const WorkflowStatus = Schema.Literal(
  'pending',
  'running',
  'completed',
  'failed',
  'cancelled',
  'timed_out'
);

export type WorkflowStatus = Schema.Schema.Type<typeof WorkflowStatus>;

export const WorkflowExecution = Schema.Struct({
  workflowId: Schema.String,
  runId: Schema.String,
  status: WorkflowStatus,
  startedAt: Schema.Date,
  completedAt: Schema.optional(Schema.Date),
  result: Schema.optional(Schema.Unknown),
  error: Schema.optional(Schema.String),
});

export type WorkflowExecution = Schema.Schema.Type<typeof WorkflowExecution>;

export const WorkflowOptions = Schema.Struct({
  taskQueue: Schema.String,
  workflowId: Schema.optional(Schema.String),
  retryPolicy: Schema.optional(
    Schema.Struct({
      maximumAttempts: Schema.optional(Schema.Number),
      initialInterval: Schema.optional(Schema.String),
      maximumInterval: Schema.optional(Schema.String),
      backoffCoefficient: Schema.optional(Schema.Number),
    })
  ),
});

export type WorkflowOptions = Schema.Schema.Type<typeof WorkflowOptions>;

// ============================================================================
// ERRORS
// ============================================================================

export class WorkflowError extends Schema.TaggedError<WorkflowError>()('WorkflowError', {
  code: Schema.Literal(
    'WORKFLOW_NOT_FOUND',
    'WORKFLOW_ALREADY_EXISTS',
    'WORKFLOW_FAILED',
    'CONNECTION_ERROR',
    'TIMEOUT',
    'INTERNAL_ERROR'
  ),
  message: Schema.String,
  workflowId: Schema.optional(Schema.String),
}) {}

// ============================================================================
// PORT INTERFACE
// ============================================================================

export interface WorkflowService {
  readonly start: <_T>(
    workflowType: string,
    args: unknown[],
    options: WorkflowOptions
  ) => Effect.Effect<WorkflowExecution, WorkflowError>;

  readonly signal: (
    workflowId: string,
    signalName: string,
    args: unknown[]
  ) => Effect.Effect<void, WorkflowError>;

  readonly query: <T>(
    workflowId: string,
    queryType: string,
    args: unknown[]
  ) => Effect.Effect<T, WorkflowError>;

  readonly cancel: (workflowId: string) => Effect.Effect<void, WorkflowError>;

  readonly getStatus: (workflowId: string) => Effect.Effect<WorkflowExecution, WorkflowError>;
}

export class Workflow extends Context.Tag('Workflow')<Workflow, WorkflowService>() {}
