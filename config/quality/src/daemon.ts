/**
 * Signet Infrastructure Daemon
 *
 * Continuous reconciliation loop for infrastructure-as-code.
 * Uses Effect.repeat with Schedule for periodic reconciliation.
 *
 * Loop: Observe State → Compile Infra → Preview Changes → Log Status
 *
 * @module daemon
 */
import { Console, Context, Duration, Effect, Layer, Ref, Schedule } from 'effect';
import { PulumiLive, PulumiTest } from '@/adapters/pulumi-automation';
import { Pulumi, type PulumiError } from '@/ports/pulumi';
import { reconcileOnceSimple } from './daemon/reconcile-loop';
import {
  type DaemonConfig,
  DaemonError,
  type DaemonState,
  DEFAULT_CONFIG,
  INITIAL_STATE,
  type ReconcileResult,
} from './daemon/types';

// ============================================================================
// DAEMON SERVICE INTERFACE
// ============================================================================

/**
 * Daemon service interface for infrastructure reconciliation.
 */
export interface DaemonService {
  /**
   * Run a single reconciliation cycle.
   */
  readonly reconcile: () => Effect.Effect<ReconcileResult, PulumiError>;

  /**
   * Start the continuous reconciliation loop.
   * Returns when interrupted or stopped.
   */
  readonly start: () => Effect.Effect<void, PulumiError>;

  /**
   * Stop the daemon gracefully.
   */
  readonly stop: () => Effect.Effect<void>;

  /**
   * Get current daemon state.
   */
  readonly status: () => Effect.Effect<DaemonState>;

  /**
   * Get current configuration.
   */
  readonly config: () => DaemonConfig;
}

/**
 * Daemon service context tag.
 */
export class Daemon extends Context.Tag('Daemon')<Daemon, DaemonService>() {}

// ============================================================================
// DAEMON IMPLEMENTATION
// ============================================================================

/**
 * Create a daemon service with the given configuration.
 */
export const makeDaemon = (config: DaemonConfig) =>
  Effect.gen(function* () {
    const pulumi = yield* Pulumi;

    // Mutable state for tracking daemon status
    const stateRef = yield* Ref.make<DaemonState>(INITIAL_STATE);
    const runningRef = yield* Ref.make<boolean>(false);

    const service: DaemonService = {
      reconcile: () =>
        Effect.gen(function* () {
          yield* Ref.update(stateRef, (s) => ({ ...s, status: 'running' as const }));

          const result = yield* reconcileOnceSimple(config).pipe(
            Effect.provide(Layer.succeed(Pulumi, pulumi)),
            Effect.tap(() =>
              Ref.update(stateRef, (s) => ({
                ...s,
                status: 'idle' as const,
                lastReconcile: new Date(),
                reconcileCount: s.reconcileCount + 1,
                consecutiveErrors: 0,
                lastError: null,
              }))
            ),
            Effect.tapError((e) =>
              Ref.update(stateRef, (s) => ({
                ...s,
                status: 'error' as const,
                consecutiveErrors: s.consecutiveErrors + 1,
                lastError: new DaemonError({
                  code: 'INTERNAL_ERROR',
                  message: e.message,
                }),
              }))
            )
          );

          return result;
        }),

      start: () =>
        Effect.gen(function* () {
          const isRunning = yield* Ref.get(runningRef);
          if (isRunning) {
            yield* Console.log('Daemon is already running');
            return;
          }

          yield* Ref.set(runningRef, true);
          yield* Ref.update(stateRef, (s) => ({ ...s, status: 'running' as const }));

          yield* Console.log(`\n🚀 Signet Daemon starting...`);
          yield* Console.log(`   Stack: ${config.stackName}`);
          yield* Console.log(`   Project: ${config.projectName}`);
          yield* Console.log(`   Path: ${config.projectPath}`);
          yield* Console.log(`   Interval: ${Duration.toMillis(config.interval)}ms`);
          yield* Console.log(`   Auto-apply: ${config.autoApply}`);
          yield* Console.log(`   Dry-run: ${config.dryRun}`);
          yield* Console.log('');

          // Initial reconciliation
          yield* service.reconcile().pipe(
            Effect.catchAll((e) =>
              Effect.gen(function* () {
                yield* Console.log(`⚠️  Initial reconciliation failed: ${e.message}`);
              })
            )
          );

          // Continuous loop with schedule
          yield* Effect.repeat(
            Effect.gen(function* () {
              const running = yield* Ref.get(runningRef);
              if (!running) {
                return yield* Effect.interrupt;
              }

              yield* service.reconcile().pipe(
                Effect.catchAll((e) =>
                  Effect.gen(function* () {
                    yield* Console.log(`⚠️  Reconciliation failed: ${e.message}`);
                  })
                )
              );
            }),
            Schedule.spaced(config.interval)
          ).pipe(
            Effect.catchAll(() =>
              Effect.gen(function* () {
                yield* Console.log('\n🛑 Daemon stopped');
              })
            )
          );
        }),

      stop: () =>
        Effect.gen(function* () {
          yield* Ref.set(runningRef, false);
          yield* Ref.update(stateRef, (s) => ({ ...s, status: 'stopped' as const }));
          yield* Console.log('🛑 Daemon stop requested');
        }),

      status: () => Ref.get(stateRef),

      config: () => config,
    };

    return service;
  });

// ============================================================================
// LAYERS
// ============================================================================

/**
 * Create a daemon layer with configuration.
 */
export const DaemonLive = (config: DaemonConfig) =>
  Layer.effect(Daemon, makeDaemon(config).pipe(Effect.provide(PulumiLive)));

/**
 * Create a test daemon layer.
 */
export const DaemonTest = (config: DaemonConfig) =>
  Layer.effect(Daemon, makeDaemon(config).pipe(Effect.provide(PulumiTest)));

// ============================================================================
// CONVENIENCE FUNCTIONS
// ============================================================================

/**
 * Run a single reconciliation with the given configuration.
 */
export const runReconcile = (config: DaemonConfig) =>
  Effect.gen(function* () {
    const daemon = yield* Daemon;
    return yield* daemon.reconcile();
  }).pipe(Effect.provide(DaemonLive(config)));

/**
 * Start the daemon with the given configuration.
 * Blocks until interrupted.
 */
export const startDaemon = (config: DaemonConfig) =>
  Effect.gen(function* () {
    const daemon = yield* Daemon;
    yield* daemon.start();
  }).pipe(Effect.provide(DaemonLive(config)));

/**
 * Parse interval string to Duration.
 * Supports: "30s", "1m", "5m", "1h"
 */
export const parseInterval = (interval: string | undefined): Duration.Duration => {
  if (!interval) {
    return Duration.seconds(30); // Default
  }

  const match = interval.match(/^(\d+)(s|m|h)$/);
  if (!match) {
    return Duration.seconds(30); // Default
  }

  const [, value, unit] = match;
  if (!value) {
    return Duration.seconds(30);
  }

  const num = parseInt(value, 10);

  switch (unit) {
    case 's':
      return Duration.seconds(num);
    case 'm':
      return Duration.minutes(num);
    case 'h':
      return Duration.hours(num);
    default:
      return Duration.seconds(30);
  }
};

/**
 * Create daemon configuration from CLI options.
 */
export const createConfig = (options: {
  interval?: string;
  stack?: string;
  project?: string;
  path: string;
  autoApply?: boolean;
  dryRun?: boolean;
}): DaemonConfig => ({
  ...DEFAULT_CONFIG,
  interval: options.interval ? parseInterval(options.interval) : DEFAULT_CONFIG.interval,
  stackName: options.stack ?? DEFAULT_CONFIG.stackName,
  projectName: options.project ?? DEFAULT_CONFIG.projectName,
  projectPath: options.path,
  autoApply: options.autoApply ?? DEFAULT_CONFIG.autoApply,
  dryRun: options.dryRun ?? DEFAULT_CONFIG.dryRun,
});

// Re-export types
export type { DaemonConfig, DaemonState, ReconcileResult } from './daemon/types';
export { DEFAULT_CONFIG, EMPTY_PREVIEW, INITIAL_STATE } from './daemon/types';
