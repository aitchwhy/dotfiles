/**
 * Pulumi Automation Port - Infrastructure Service Interface
 *
 * Defines the contract for programmatic Pulumi operations.
 * Implemented by adapters using @pulumi/pulumi/automation.
 *
 * @module ports/pulumi
 */
import { Context, type Effect, Schema } from 'effect';
import type { PreviewSummary, UpSummary } from '@/daemon/types';

// ============================================================================
// SCHEMAS
// ============================================================================

export const StackInfo = Schema.Struct({
  name: Schema.String,
  project: Schema.String,
  lastUpdate: Schema.optional(Schema.Date),
  resourceCount: Schema.Number,
});

export type StackInfo = Schema.Schema.Type<typeof StackInfo>;

export const StackOutput = Schema.Struct({
  value: Schema.Unknown,
  secret: Schema.Boolean,
});

export type StackOutput = Schema.Schema.Type<typeof StackOutput>;

export const UpdateSummary = Schema.Struct({
  version: Schema.Number,
  startTime: Schema.Date,
  endTime: Schema.optional(Schema.Date),
  result: Schema.Literal('succeeded', 'failed', 'in-progress'),
  resourceChanges: Schema.optional(Schema.Record({ key: Schema.String, value: Schema.Number })),
});

export type UpdateSummary = Schema.Schema.Type<typeof UpdateSummary>;

// ============================================================================
// ERRORS
// ============================================================================

export class PulumiError extends Schema.TaggedError<PulumiError>()('PulumiError', {
  code: Schema.Literal(
    'STACK_NOT_FOUND',
    'WORKSPACE_ERROR',
    'PREVIEW_FAILED',
    'UP_FAILED',
    'REFRESH_FAILED',
    'DESTROY_FAILED',
    'CONCURRENT_UPDATE',
    'CONFIG_ERROR',
    'POLICY_VIOLATION',
    'INTERNAL_ERROR'
  ),
  message: Schema.String,
  stack: Schema.optional(Schema.String),
  cause: Schema.optional(Schema.Unknown),
}) {}

// ============================================================================
// PORT INTERFACE
// ============================================================================

/**
 * Pulumi Automation API service interface.
 *
 * Provides programmatic control over Pulumi stacks for infrastructure management.
 * All operations return Effects with typed errors for composability.
 */
export interface PulumiService {
  /**
   * Create a new stack or select an existing one.
   * @param name - Stack name (e.g., 'dev', 'staging', 'prod')
   * @param project - Project name
   * @param projectPath - Path to the Pulumi project directory
   * @param program - Optional inline program function
   */
  readonly createOrSelectStack: (
    name: string,
    project: string,
    projectPath: string,
    program?: () => Promise<Record<string, unknown>>
  ) => Effect.Effect<StackInfo, PulumiError>;

  /**
   * Preview changes without applying them.
   * @param stackName - Stack to preview
   * @param projectPath - Path to the Pulumi project directory
   */
  readonly preview: (
    stackName: string,
    projectPath: string
  ) => Effect.Effect<PreviewSummary, PulumiError>;

  /**
   * Apply changes to infrastructure.
   * @param stackName - Stack to update
   * @param projectPath - Path to the Pulumi project directory
   */
  readonly up: (stackName: string, projectPath: string) => Effect.Effect<UpSummary, PulumiError>;

  /**
   * Refresh state from actual infrastructure.
   * @param stackName - Stack to refresh
   * @param projectPath - Path to the Pulumi project directory
   */
  readonly refresh: (stackName: string, projectPath: string) => Effect.Effect<void, PulumiError>;

  /**
   * Destroy all resources in a stack.
   * @param stackName - Stack to destroy
   * @param projectPath - Path to the Pulumi project directory
   */
  readonly destroy: (stackName: string, projectPath: string) => Effect.Effect<void, PulumiError>;

  /**
   * Get stack outputs.
   * @param stackName - Stack to query
   * @param projectPath - Path to the Pulumi project directory
   */
  readonly getOutputs: (
    stackName: string,
    projectPath: string
  ) => Effect.Effect<Readonly<Record<string, unknown>>, PulumiError>;

  /**
   * Get stack update history.
   * @param stackName - Stack to query
   * @param projectPath - Path to the Pulumi project directory
   * @param limit - Maximum number of updates to return
   */
  readonly getHistory: (
    stackName: string,
    projectPath: string,
    limit?: number
  ) => Effect.Effect<readonly UpdateSummary[], PulumiError>;

  /**
   * Set stack configuration value.
   * @param stackName - Stack to configure
   * @param projectPath - Path to the Pulumi project directory
   * @param key - Configuration key
   * @param value - Configuration value
   * @param secret - Whether to encrypt the value
   */
  readonly setConfig: (
    stackName: string,
    projectPath: string,
    key: string,
    value: string,
    secret?: boolean
  ) => Effect.Effect<void, PulumiError>;

  /**
   * Get stack information.
   * @param stackName - Stack to query
   * @param projectPath - Path to the Pulumi project directory
   */
  readonly getStackInfo: (
    stackName: string,
    projectPath: string
  ) => Effect.Effect<StackInfo, PulumiError>;
}

// ============================================================================
// CONTEXT TAG
// ============================================================================

/**
 * Pulumi service context tag for dependency injection.
 *
 * @example
 * ```typescript
 * import { Pulumi } from '@/ports/pulumi'
 *
 * const program = Effect.gen(function* () {
 *   const pulumi = yield* Pulumi
 *   const preview = yield* pulumi.preview('dev', './infra')
 *   return preview
 * })
 * ```
 */
export class Pulumi extends Context.Tag('Pulumi')<Pulumi, PulumiService>() {}
