/**
 * Pulumi Automation Adapter
 *
 * Implements the Pulumi port using @pulumi/pulumi/automation API.
 * Provides programmatic infrastructure management.
 *
 * @module adapters/pulumi-automation
 */
import { Effect, Layer } from 'effect'
import * as automation from '@pulumi/pulumi/automation'
import {
  Pulumi,
  PulumiError,
  type PulumiService,
  type StackInfo,
  type UpdateSummary,
} from '@/ports/pulumi'
import type { PreviewSummary, UpSummary } from '@/daemon/types'

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Convert Pulumi preview result to PreviewSummary.
 */
function toPreviewSummary(result: automation.PreviewResult): PreviewSummary {
  const summary = result.changeSummary
  const creates = summary?.create ?? 0
  const updates = summary?.update ?? 0
  const deletes = summary?.delete ?? 0
  const sames = summary?.same ?? 0

  return {
    creates,
    updates,
    deletes,
    sames,
    hasChanges: creates > 0 || updates > 0 || deletes > 0,
  }
}

/**
 * Convert Pulumi up result to UpSummary.
 */
function toUpSummary(
  result: automation.UpResult,
  durationMs: number
): UpSummary {
  const summary = result.summary
  const creates = summary.resourceChanges?.create ?? 0
  const updates = summary.resourceChanges?.update ?? 0
  const deletes = summary.resourceChanges?.delete ?? 0

  return {
    success: summary.result === 'succeeded',
    outputs: result.outputs,
    durationMs,
    changedCount: creates + updates + deletes,
  }
}

/**
 * Convert Pulumi update summary to our UpdateSummary type.
 */
function toUpdateSummary(update: automation.UpdateSummary): UpdateSummary {
  return {
    version: update.version ?? 0,
    startTime: new Date(update.startTime ?? Date.now()),
    endTime: update.endTime ? new Date(update.endTime) : undefined,
    result: (update.result ?? 'in-progress') as 'succeeded' | 'failed' | 'in-progress',
    resourceChanges: update.resourceChanges,
  }
}

/**
 * Map Pulumi errors to typed PulumiError.
 */
function mapError(e: unknown, operation: string): PulumiError {
  const message = e instanceof Error ? e.message : String(e)

  // Detect specific error types
  if (message.includes('stack not found') || message.includes('not found')) {
    return new PulumiError({
      code: 'STACK_NOT_FOUND',
      message: `Stack not found: ${message}`,
      cause: e,
    })
  }

  if (message.includes('concurrent update')) {
    return new PulumiError({
      code: 'CONCURRENT_UPDATE',
      message: `Concurrent update detected: ${message}`,
      cause: e,
    })
  }

  if (message.includes('policy') || message.includes('violation')) {
    return new PulumiError({
      code: 'POLICY_VIOLATION',
      message: `Policy violation: ${message}`,
      cause: e,
    })
  }

  // Map by operation
  const codeMap: Record<string, PulumiError['code']> = {
    preview: 'PREVIEW_FAILED',
    up: 'UP_FAILED',
    refresh: 'REFRESH_FAILED',
    destroy: 'DESTROY_FAILED',
    config: 'CONFIG_ERROR',
    workspace: 'WORKSPACE_ERROR',
  }

  return new PulumiError({
    code: codeMap[operation] ?? 'INTERNAL_ERROR',
    message: `${operation} failed: ${message}`,
    cause: e,
  })
}

// ============================================================================
// SERVICE IMPLEMENTATION
// ============================================================================

/**
 * Pulumi Automation service implementation.
 */
const makePulumiService = (): PulumiService => ({
  createOrSelectStack: (name, project, projectPath, program) =>
    Effect.tryPromise({
      try: async () => {
        const stack = await automation.LocalWorkspace.createOrSelectStack(
          {
            stackName: name,
            projectName: project,
            program: program ?? (async () => ({})),
          },
          { workDir: projectPath }
        )

        // Get history to determine last update
        const history = await stack.history(1)
        const firstUpdate = history[0]
        const lastUpdate = firstUpdate?.startTime
          ? new Date(firstUpdate.startTime)
          : undefined

        return {
          name,
          project,
          lastUpdate,
          resourceCount: 0, // Resource count not available without refresh
        } satisfies StackInfo
      },
      catch: (e) => mapError(e, 'workspace'),
    }),

  preview: (stackName, projectPath) =>
    Effect.tryPromise({
      try: async () => {
        const stack = await automation.LocalWorkspace.selectStack({
          stackName,
          workDir: projectPath,
        })

        const result = await stack.preview({
          onOutput: (msg) => {
            // Log to console for visibility during daemon operation
            if (process.env['SIGNET_VERBOSE'] === 'true') {
              console.log(`[pulumi:preview] ${msg}`)
            }
          },
        })

        return toPreviewSummary(result)
      },
      catch: (e) => mapError(e, 'preview'),
    }),

  up: (stackName, projectPath) =>
    Effect.tryPromise({
      try: async () => {
        const stack = await automation.LocalWorkspace.selectStack({
          stackName,
          workDir: projectPath,
        })

        const startTime = Date.now()
        const result = await stack.up({
          onOutput: (msg) => {
            if (process.env['SIGNET_VERBOSE'] === 'true') {
              console.log(`[pulumi:up] ${msg}`)
            }
          },
        })

        return toUpSummary(result, Date.now() - startTime)
      },
      catch: (e) => mapError(e, 'up'),
    }),

  refresh: (stackName, projectPath) =>
    Effect.tryPromise({
      try: async () => {
        const stack = await automation.LocalWorkspace.selectStack({
          stackName,
          workDir: projectPath,
        })

        await stack.refresh({
          onOutput: (msg) => {
            if (process.env['SIGNET_VERBOSE'] === 'true') {
              console.log(`[pulumi:refresh] ${msg}`)
            }
          },
        })
      },
      catch: (e) => mapError(e, 'refresh'),
    }),

  destroy: (stackName, projectPath) =>
    Effect.tryPromise({
      try: async () => {
        const stack = await automation.LocalWorkspace.selectStack({
          stackName,
          workDir: projectPath,
        })

        await stack.destroy({
          onOutput: (msg) => {
            if (process.env['SIGNET_VERBOSE'] === 'true') {
              console.log(`[pulumi:destroy] ${msg}`)
            }
          },
        })
      },
      catch: (e) => mapError(e, 'destroy'),
    }),

  getOutputs: (stackName, projectPath) =>
    Effect.tryPromise({
      try: async () => {
        const stack = await automation.LocalWorkspace.selectStack({
          stackName,
          workDir: projectPath,
        })

        const outputs = await stack.outputs()

        // Convert OutputMap to plain Record
        const result: Record<string, unknown> = {}
        for (const [key, output] of Object.entries(outputs)) {
          result[key] = output.value
        }
        return result
      },
      catch: (e) => mapError(e, 'workspace'),
    }),

  getHistory: (stackName, projectPath, limit = 10) =>
    Effect.tryPromise({
      try: async () => {
        const stack = await automation.LocalWorkspace.selectStack({
          stackName,
          workDir: projectPath,
        })

        const history = await stack.history(limit)
        return history.map(toUpdateSummary)
      },
      catch: (e) => mapError(e, 'workspace'),
    }),

  setConfig: (stackName, projectPath, key, value, secret = false) =>
    Effect.tryPromise({
      try: async () => {
        const stack = await automation.LocalWorkspace.selectStack({
          stackName,
          workDir: projectPath,
        })

        await stack.setConfig(key, { value, secret })
      },
      catch: (e) => mapError(e, 'config'),
    }),

  getStackInfo: (stackName, projectPath) =>
    Effect.tryPromise({
      try: async () => {
        const stack = await automation.LocalWorkspace.selectStack({
          stackName,
          workDir: projectPath,
        })

        const ws = stack.workspace
        const projectSettings = await ws.projectSettings()

        // Get history to determine last update
        const history = await stack.history(1)
        const firstUpdate = history[0]
        const lastUpdate = firstUpdate?.startTime
          ? new Date(firstUpdate.startTime)
          : undefined

        return {
          name: stackName,
          project: projectSettings.name,
          lastUpdate,
          resourceCount: 0, // Resource count not available without refresh
        } satisfies StackInfo
      },
      catch: (e) => mapError(e, 'workspace'),
    }),
})

// ============================================================================
// LAYER
// ============================================================================

/**
 * Live Pulumi service layer.
 *
 * @example
 * ```typescript
 * import { PulumiLive } from '@/adapters/pulumi-automation'
 *
 * const program = Effect.gen(function* () {
 *   const pulumi = yield* Pulumi
 *   const preview = yield* pulumi.preview('dev', './infra')
 *   return preview
 * }).pipe(Effect.provide(PulumiLive))
 * ```
 */
export const PulumiLive = Layer.succeed(Pulumi, makePulumiService())

/**
 * Test/mock Pulumi service layer.
 * Returns empty/success responses for testing.
 */
export const PulumiTest = Layer.succeed(
  Pulumi,
  {
    createOrSelectStack: () =>
      Effect.succeed({
        name: 'test',
        project: 'test',
        lastUpdate: new Date(),
        resourceCount: 0,
      }),
    preview: () =>
      Effect.succeed({
        creates: 0,
        updates: 0,
        deletes: 0,
        sames: 0,
        hasChanges: false,
      }),
    up: () =>
      Effect.succeed({
        success: true,
        outputs: {},
        durationMs: 0,
        changedCount: 0,
      }),
    refresh: () => Effect.void,
    destroy: () => Effect.void,
    getOutputs: () => Effect.succeed({}),
    getHistory: () => Effect.succeed([]),
    setConfig: () => Effect.void,
    getStackInfo: () =>
      Effect.succeed({
        name: 'test',
        project: 'test',
        lastUpdate: new Date(),
        resourceCount: 0,
      }),
  } satisfies PulumiService
)
