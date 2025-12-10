/**
 * 5-Tier Verification System
 *
 * Orchestrates all verification tiers in sequence.
 * Hard gate: any tier failure blocks code generation (exit code 2).
 *
 * Tiers:
 * 1. patterns  - AST drift detection, code smells
 * 2. formal    - Contracts, property tests, branded types
 * 3. execution - Typecheck, lint, test execution
 * 4. review    - Multi-agent review (stubbed)
 * 5. context   - Architecture boundaries, dependency graph
 */
import { Context, Effect, Layer } from 'effect'

// =============================================================================
// Types
// =============================================================================

/**
 * Available verification tier names
 */
export type TierName = 'patterns' | 'formal' | 'execution' | 'review' | 'context'

export const ALL_TIERS: readonly TierName[] = ['patterns', 'formal', 'execution', 'review', 'context']

/**
 * Result of running a single tier
 */
export type TierResult = {
  readonly tier: TierName
  readonly passed: boolean
  readonly errors: number
  readonly warnings: number
  readonly details: readonly string[]
  readonly duration: number
}

/**
 * Aggregated result of all verification tiers
 */
export type VerificationResult = {
  readonly passed: boolean
  readonly totalErrors: number
  readonly totalWarnings: number
  readonly tierResults: readonly TierResult[]
  readonly duration: number
}

/**
 * Options for verification
 */
export type VerificationOptions = {
  readonly path: string
  readonly tiers?: readonly TierName[]
  readonly fix: boolean
  readonly verbose: boolean
}

/**
 * Issue detected by a tier
 */
export type VerificationIssue = {
  readonly severity: 'error' | 'warning' | 'hint'
  readonly message: string
  readonly file?: string
  readonly line?: number
  readonly column?: number
  readonly rule?: string
}

// =============================================================================
// Port Definition
// =============================================================================

/**
 * Verification service interface (Port)
 */
export interface VerificationService {
  /** Run all specified tiers and aggregate results */
  readonly runAllTiers: (opts: VerificationOptions) => Effect.Effect<VerificationResult, Error>

  /** Run a single tier */
  readonly runTier: (tier: TierName, opts: VerificationOptions) => Effect.Effect<TierResult, Error>
}

/**
 * Verification Context Tag - the Port that consumers depend on
 */
export class Verification extends Context.Tag('Verification')<Verification, VerificationService>() {}

// =============================================================================
// Tier Runners (will be imported from tiers/)
// =============================================================================

import { runPatternsTier } from './tiers/patterns.js'
import { runFormalTier } from './tiers/formal.js'
import { runExecutionTier } from './tiers/execution.js'
import { runReviewTier } from './tiers/review.js'
import { runContextTier } from './tiers/context.js'

const tierRunners: Record<TierName, (opts: VerificationOptions) => Effect.Effect<TierResult, Error>> = {
  patterns: runPatternsTier,
  formal: runFormalTier,
  execution: runExecutionTier,
  review: runReviewTier,
  context: runContextTier,
}

// =============================================================================
// Live Implementation
// =============================================================================

/**
 * Create the live Verification service implementation
 */
const makeVerificationService = (): VerificationService => ({
  runTier: (tier: TierName, opts: VerificationOptions) => tierRunners[tier](opts),

  runAllTiers: (opts: VerificationOptions) =>
    Effect.gen(function* () {
      const startTime = Date.now()
      const tiersToRun = opts.tiers ?? ALL_TIERS
      const tierResults: TierResult[] = []

      // Run tiers sequentially
      for (const tier of tiersToRun) {
        const result = yield* tierRunners[tier](opts)
        tierResults.push(result)

        // On verbose, log each tier as it completes
        if (opts.verbose) {
          const icon = result.passed ? '✓' : '✗'
          yield* Effect.logInfo(`${icon} Tier ${tier}: ${result.errors} errors, ${result.warnings} warnings`)
        }
      }

      // Aggregate results
      const totalErrors = tierResults.reduce((sum, t) => sum + t.errors, 0)
      const totalWarnings = tierResults.reduce((sum, t) => sum + t.warnings, 0)
      const allPassed = tierResults.every((t) => t.passed)

      return {
        passed: allPassed,
        totalErrors,
        totalWarnings,
        tierResults,
        duration: Date.now() - startTime,
      }
    }),
})

// =============================================================================
// Live Layer
// =============================================================================

/**
 * VerificationLive - the live Layer providing the Verification service
 */
export const VerificationLive = Layer.succeed(Verification, makeVerificationService())

// =============================================================================
// Convenience Functions
// =============================================================================

/**
 * Run all verification tiers - requires Verification in context
 */
export const runAllTiers = (
  opts: VerificationOptions
): Effect.Effect<VerificationResult, Error, Verification> =>
  Effect.flatMap(Verification, (service) => service.runAllTiers(opts))

/**
 * Run a single tier - requires Verification in context
 */
export const runTier = (
  tier: TierName,
  opts: VerificationOptions
): Effect.Effect<TierResult, Error, Verification> =>
  Effect.flatMap(Verification, (service) => service.runTier(tier, opts))

/**
 * Run verification without Effect context (for direct CLI use)
 */
export const runVerification = (opts: VerificationOptions): Effect.Effect<VerificationResult, Error> =>
  runAllTiers(opts).pipe(Effect.provide(VerificationLive))

// =============================================================================
// Formatters
// =============================================================================

/**
 * Format verification result for human-readable output
 */
export const formatVerificationResult = (result: VerificationResult): string => {
  const lines: string[] = []

  lines.push('')
  lines.push('━'.repeat(60))
  lines.push('  SIGNET 5-TIER VERIFICATION')
  lines.push('━'.repeat(60))

  for (const tier of result.tierResults) {
    const icon = tier.passed ? '✓' : '✗'
    const color = tier.passed ? '32' : '31'
    lines.push('')
    lines.push(`\x1b[${color}m${icon}\x1b[0m Tier: ${tier.tier.toUpperCase()}`)
    lines.push(`  Errors: ${tier.errors}, Warnings: ${tier.warnings}, Duration: ${tier.duration}ms`)

    if (tier.details.length > 0) {
      for (const detail of tier.details.slice(0, 5)) {
        lines.push(`    ${detail}`)
      }
      if (tier.details.length > 5) {
        lines.push(`    ... and ${tier.details.length - 5} more`)
      }
    }
  }

  // Determine exit code (hard gate semantics)
  // 0 = all pass, 1 = warnings only, 2 = errors (blocks generation)
  const exitCode = result.totalErrors > 0 ? 2 : result.totalWarnings > 0 ? 1 : 0

  lines.push('')
  lines.push('━'.repeat(60))
  if (result.passed) {
    lines.push('\x1b[32m✅ All tiers passed\x1b[0m')
  } else {
    lines.push(`\x1b[31m❌ Verification failed (exit code ${exitCode})\x1b[0m`)
    lines.push(`   ${result.totalErrors} error(s), ${result.totalWarnings} warning(s)`)
  }
  lines.push('━'.repeat(60))
  lines.push('')

  return lines.join('\n')
}
