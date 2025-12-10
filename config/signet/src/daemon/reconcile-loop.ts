/**
 * Reconcile Loop - Core Infrastructure Reconciliation Logic
 *
 * Implements the Observe → Compile → Preview → Log cycle.
 * Pure functions for testability, composed with Effect.
 *
 * @module daemon/reconcile-loop
 */
import { Effect, Console } from 'effect'
import { Pulumi, type PulumiError } from '@/ports/pulumi'
import { Telemetry, type TelemetryError } from '@/ports/telemetry'
import {
  type DaemonConfig,
  type DaemonError,
  type ReconcileResult,
  type ObservedState,
  type PreviewSummary,
  EMPTY_PREVIEW,
} from './types'

// ============================================================================
// STEP 1: OBSERVE STATE
// ============================================================================

/**
 * Observe current infrastructure state from the stack.
 * Refreshes to detect drift and retrieves current outputs.
 */
export const observeState = (
  config: DaemonConfig
): Effect.Effect<ObservedState, PulumiError, Pulumi> =>
  Effect.gen(function* () {
    const pulumi = yield* Pulumi

    // Get stack info
    const stackInfo = yield* pulumi.getStackInfo(
      config.stackName,
      config.projectPath
    )

    // Get current outputs
    const outputs = yield* pulumi.getOutputs(
      config.stackName,
      config.projectPath
    )

    // Refresh to detect drift (optional - can be expensive)
    if (!config.dryRun) {
      yield* pulumi.refresh(config.stackName, config.projectPath)
    }

    return {
      outputs,
      resourceCount: stackInfo.resourceCount,
      driftDetected: false, // Would need to compare with previous state
      observedAt: new Date(),
    } satisfies ObservedState
  })

// ============================================================================
// STEP 2: PREVIEW CHANGES
// ============================================================================

/**
 * Preview infrastructure changes without applying them.
 * Returns a summary of what would change.
 */
export const previewChanges = (
  config: DaemonConfig
): Effect.Effect<PreviewSummary, PulumiError, Pulumi> =>
  Effect.gen(function* () {
    const pulumi = yield* Pulumi

    const preview = yield* pulumi.preview(config.stackName, config.projectPath)

    return preview
  })

// ============================================================================
// STEP 3: APPLY CHANGES (IF AUTO-APPLY ENABLED)
// ============================================================================

/**
 * Apply infrastructure changes if autoApply is enabled.
 * Returns the outputs after applying.
 */
export const applyChanges = (
  config: DaemonConfig,
  preview: PreviewSummary
): Effect.Effect<Readonly<Record<string, unknown>>, PulumiError, Pulumi> =>
  Effect.gen(function* () {
    const pulumi = yield* Pulumi

    // Only apply if there are changes and autoApply is enabled
    if (!preview.hasChanges || config.dryRun) {
      return yield* pulumi.getOutputs(config.stackName, config.projectPath)
    }

    if (!config.autoApply) {
      yield* Console.log(
        '⚠️  Changes detected but autoApply is disabled. Run manually to apply.'
      )
      return yield* pulumi.getOutputs(config.stackName, config.projectPath)
    }

    // Apply changes
    const result = yield* pulumi.up(config.stackName, config.projectPath)

    if (!result.success) {
      yield* Console.log('❌ Apply failed')
    }

    return result.outputs
  })

// ============================================================================
// STEP 4: LOG STATUS
// ============================================================================

/**
 * Log reconciliation status to console and telemetry.
 */
export const logStatus = (
  result: ReconcileResult,
  config: DaemonConfig
): Effect.Effect<void, TelemetryError, Telemetry> =>
  Effect.gen(function* () {
    const telemetry = yield* Telemetry

    // Log to console
    const { preview, applied, durationMs } = result
    const timestamp = result.timestamp.toISOString()

    if (preview.hasChanges) {
      yield* Console.log(
        `[${timestamp}] 🔄 Changes: +${preview.creates} ~${preview.updates} -${preview.deletes} (${durationMs}ms)${applied ? ' ✅ Applied' : ''}`
      )
    } else {
      yield* Console.log(`[${timestamp}] ✓ No changes detected (${durationMs}ms)`)
    }

    // Log to telemetry
    yield* telemetry.capture({
      name: 'signet.daemon.reconcile',
      properties: {
        stack: config.stackName,
        project: config.projectName,
        creates: preview.creates,
        updates: preview.updates,
        deletes: preview.deletes,
        hasChanges: preview.hasChanges,
        applied,
        durationMs,
      },
    })
  })

// ============================================================================
// COMPLETE RECONCILIATION CYCLE
// ============================================================================

/**
 * Run a single reconciliation cycle.
 *
 * Cycle: Observe → Preview → (Apply) → Log
 */
export const reconcileOnce = (
  config: DaemonConfig
): Effect.Effect<ReconcileResult, PulumiError | TelemetryError | DaemonError, Pulumi | Telemetry> =>
  Effect.gen(function* () {
    const startTime = Date.now()
    const timestamp = new Date()

    yield* Console.log(`\n🔍 Starting reconciliation for ${config.stackName}...`)

    // Step 1: Observe current state (used for drift detection, currently logged)
    yield* observeState(config).pipe(
      Effect.catchAll((e) =>
        Effect.gen(function* () {
          // Log error but continue with preview
          yield* Console.log(`⚠️  Failed to observe state: ${e.message}`)
          return {
            outputs: {},
            resourceCount: 0,
            driftDetected: false,
            observedAt: new Date(),
          } satisfies ObservedState
        })
      )
    )

    // Step 2: Preview changes
    const preview = yield* previewChanges(config).pipe(
      Effect.catchAll((e) =>
        Effect.gen(function* () {
          yield* Console.log(`⚠️  Preview failed: ${e.message}`)
          return EMPTY_PREVIEW
        })
      )
    )

    // Step 3: Apply changes (if applicable)
    const outputs = yield* applyChanges(config, preview).pipe(
      Effect.catchAll((e) =>
        Effect.gen(function* () {
          yield* Console.log(`❌ Apply failed: ${e.message}`)
          return {} as Readonly<Record<string, unknown>>
        })
      )
    )

    const durationMs = Date.now() - startTime
    const applied = config.autoApply && preview.hasChanges && !config.dryRun

    const result: ReconcileResult = {
      timestamp,
      durationMs,
      preview,
      applied,
      outputs,
    }

    // Step 4: Log status
    yield* logStatus(result, config).pipe(
      Effect.catchAll((e) =>
        Effect.gen(function* () {
          yield* Console.log(`⚠️  Telemetry failed: ${e.message}`)
        })
      )
    )

    return result
  })

// ============================================================================
// RECONCILIATION WITHOUT TELEMETRY
// ============================================================================

/**
 * Run reconciliation without telemetry dependency.
 * Useful for testing or when telemetry is not available.
 */
export const reconcileOnceSimple = (
  config: DaemonConfig
): Effect.Effect<ReconcileResult, PulumiError, Pulumi> =>
  Effect.gen(function* () {
    const startTime = Date.now()
    const timestamp = new Date()

    yield* Console.log(`\n🔍 Starting reconciliation for ${config.stackName}...`)

    // Preview changes
    const preview = yield* previewChanges(config)

    // Apply changes (if applicable)
    const outputs = yield* applyChanges(config, preview)

    const durationMs = Date.now() - startTime
    const applied = config.autoApply && preview.hasChanges && !config.dryRun

    const result: ReconcileResult = {
      timestamp,
      durationMs,
      preview,
      applied,
      outputs,
    }

    // Log to console
    if (preview.hasChanges) {
      yield* Console.log(
        `🔄 Changes: +${preview.creates} ~${preview.updates} -${preview.deletes} (${durationMs}ms)${applied ? ' ✅ Applied' : ''}`
      )
    } else {
      yield* Console.log(`✓ No changes detected (${durationMs}ms)`)
    }

    return result
  })
