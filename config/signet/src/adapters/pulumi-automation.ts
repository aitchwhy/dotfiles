/**
 * Pulumi Automation Adapter (Stub)
 *
 * Placeholder implementation of the Pulumi port.
 * Actual @pulumi/pulumi/automation integration should be in generated projects.
 *
 * @module adapters/pulumi-automation
 */
import { Effect, Layer } from 'effect';
import type { PreviewSummary, UpSummary } from '@/daemon/types';
import { Pulumi, type PulumiService, type StackInfo } from '@/ports/pulumi';

// ============================================================================
// PLACEHOLDER SERVICE IMPLEMENTATION
// ============================================================================

/**
 * Placeholder Pulumi service.
 * Returns mock responses for testing/development.
 * Real implementation should use @pulumi/pulumi/automation in generated projects.
 */
const makePulumiService = (): PulumiService => ({
  createOrSelectStack: (name, project, _projectPath, _program) =>
    Effect.succeed({
      name,
      project,
      lastUpdate: new Date(),
      resourceCount: 0,
    } satisfies StackInfo),

  preview: (_stackName, _projectPath) =>
    Effect.succeed({
      creates: 0,
      updates: 0,
      deletes: 0,
      sames: 0,
      hasChanges: false,
    } satisfies PreviewSummary),

  up: (_stackName, _projectPath) =>
    Effect.succeed({
      success: true,
      outputs: {},
      durationMs: 0,
      changedCount: 0,
    } satisfies UpSummary),

  refresh: (_stackName, _projectPath) => Effect.void,

  destroy: (_stackName, _projectPath) => Effect.void,

  getOutputs: (_stackName, _projectPath) => Effect.succeed({}),

  getHistory: (_stackName, _projectPath, _limit) => Effect.succeed([]),

  setConfig: (_stackName, _projectPath, _key, _value, _secret) => Effect.void,

  getStackInfo: (stackName, _projectPath) =>
    Effect.succeed({
      name: stackName,
      project: 'placeholder',
      lastUpdate: new Date(),
      resourceCount: 0,
    } satisfies StackInfo),
});

// ============================================================================
// LAYER
// ============================================================================

/**
 * Placeholder Pulumi service layer.
 *
 * This is a stub implementation. For real Pulumi operations,
 * use @pulumi/pulumi/automation directly in your generated project.
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
export const PulumiLive = Layer.succeed(Pulumi, makePulumiService());

/**
 * Test/mock Pulumi service layer.
 * Returns empty/success responses for testing.
 */
export const PulumiTest = PulumiLive;
