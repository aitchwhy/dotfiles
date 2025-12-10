/**
 * Daemon Type Definitions
 *
 * TypeScript types are the source of truth.
 * Schemas use `satisfies z.ZodType<T>` pattern.
 *
 * @module daemon/types
 */
import { Duration, Schema } from 'effect';

// ============================================================================
// CONFIGURATION TYPES
// ============================================================================

/**
 * Daemon configuration for infrastructure reconciliation.
 * Controls the reconcile loop behavior.
 */
export type DaemonConfig = {
  /** Interval between reconciliation cycles */
  readonly interval: Duration.Duration;
  /** Pulumi stack name (e.g., 'dev', 'staging', 'prod') */
  readonly stackName: string;
  /** Pulumi project name */
  readonly projectName: string;
  /** Path to the Pulumi project directory */
  readonly projectPath: string;
  /** If true, automatically apply changes (dangerous in production) */
  readonly autoApply: boolean;
  /** If true, preview only without applying */
  readonly dryRun: boolean;
  /** Optional policy packs to enforce */
  readonly policyPacks?: readonly string[];
};

// ============================================================================
// STATE TYPES
// ============================================================================

/**
 * Current daemon state for status reporting.
 */
export type DaemonState = {
  /** Current daemon status */
  readonly status: 'idle' | 'running' | 'stopped' | 'error';
  /** Timestamp of last reconciliation (null if never run) */
  readonly lastReconcile: Date | null;
  /** Total number of reconciliations performed */
  readonly reconcileCount: number;
  /** Number of consecutive errors (resets on success) */
  readonly consecutiveErrors: number;
  /** Last error encountered (null if no errors) */
  readonly lastError: DaemonError | null;
};

// ============================================================================
// RESULT TYPES
// ============================================================================

/**
 * Summary of changes from Pulumi preview/up.
 */
export type PreviewSummary = {
  /** Number of resources to create */
  readonly creates: number;
  /** Number of resources to update */
  readonly updates: number;
  /** Number of resources to delete */
  readonly deletes: number;
  /** Number of unchanged resources */
  readonly sames: number;
  /** True if any changes detected */
  readonly hasChanges: boolean;
};

/**
 * Summary of applied changes from Pulumi up.
 */
export type UpSummary = {
  /** Whether the update succeeded */
  readonly success: boolean;
  /** Stack outputs after update */
  readonly outputs: Readonly<Record<string, unknown>>;
  /** Duration of the update in milliseconds */
  readonly durationMs: number;
  /** Number of resources changed */
  readonly changedCount: number;
};

/**
 * Result of a single reconciliation cycle.
 */
export type ReconcileResult = {
  /** Timestamp when reconciliation started */
  readonly timestamp: Date;
  /** Duration of reconciliation in milliseconds */
  readonly durationMs: number;
  /** Preview summary (changes detected) */
  readonly preview: PreviewSummary;
  /** Whether changes were applied */
  readonly applied: boolean;
  /** Stack outputs (if applied or refreshed) */
  readonly outputs: Readonly<Record<string, unknown>>;
};

// ============================================================================
// ERROR TYPES
// ============================================================================

/**
 * Error codes for daemon operations.
 */
export type DaemonErrorCode =
  | 'STACK_NOT_FOUND'
  | 'PREVIEW_FAILED'
  | 'UP_FAILED'
  | 'REFRESH_FAILED'
  | 'CONFIG_ERROR'
  | 'POLICY_VIOLATION'
  | 'NETWORK_ERROR'
  | 'INTERNAL_ERROR';

/**
 * Tagged error for daemon operations.
 * Uses Effect Schema for type-safe error handling.
 */
export class DaemonError extends Schema.TaggedError<DaemonError>()('DaemonError', {
  code: Schema.Literal(
    'STACK_NOT_FOUND',
    'PREVIEW_FAILED',
    'UP_FAILED',
    'REFRESH_FAILED',
    'CONFIG_ERROR',
    'POLICY_VIOLATION',
    'NETWORK_ERROR',
    'INTERNAL_ERROR'
  ),
  message: Schema.String,
  cause: Schema.optional(Schema.Unknown),
}) {}

// ============================================================================
// OBSERVED STATE TYPES
// ============================================================================

/**
 * State observed from current infrastructure.
 */
export type ObservedState = {
  /** Current stack outputs */
  readonly outputs: Readonly<Record<string, unknown>>;
  /** Number of resources managed by the stack */
  readonly resourceCount: number;
  /** Whether drift was detected from last known state */
  readonly driftDetected: boolean;
  /** Timestamp of observation */
  readonly observedAt: Date;
};

/**
 * Compiled infrastructure program ready for deployment.
 */
export type CompiledInfra = {
  /** The Pulumi program function */
  readonly program: () => Promise<Record<string, unknown>>;
  /** Stack configuration */
  readonly config: Readonly<Record<string, string>>;
};

// ============================================================================
// DEFAULT VALUES
// ============================================================================

/**
 * Default daemon configuration.
 */
export const DEFAULT_CONFIG: Omit<DaemonConfig, 'projectPath'> = {
  interval: Duration.seconds(30),
  stackName: 'dev',
  projectName: 'signet',
  autoApply: false,
  dryRun: true,
  policyPacks: [],
};

/**
 * Initial daemon state.
 */
export const INITIAL_STATE: DaemonState = {
  status: 'idle',
  lastReconcile: null,
  reconcileCount: 0,
  consecutiveErrors: 0,
  lastError: null,
};

/**
 * Empty preview summary (no changes).
 */
export const EMPTY_PREVIEW: PreviewSummary = {
  creates: 0,
  updates: 0,
  deletes: 0,
  sames: 0,
  hasChanges: false,
};
