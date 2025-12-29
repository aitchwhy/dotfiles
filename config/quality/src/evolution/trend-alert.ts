#!/usr/bin/env bun
/**
 * Trend Alert System
 *
 * Analyzes grade trends and alerts on regressions.
 * Run: bun config/quality/evolution/trend-alert.ts
 */

import { Effect, pipe } from 'effect'
import { MetricsDbLive, MetricsDbService } from './lib/metrics-db'

// =============================================================================
// Configuration
// =============================================================================

const THRESHOLDS = {
  warning: 0.7,
  critical: 0.5,
  trendDrop: 0.1, // 10% drop triggers alert
} as const

// =============================================================================
// Types
// =============================================================================

interface AlertResult {
  readonly latest_score: number | null
  readonly alerts: readonly string[]
  readonly trend: readonly { date: string; score: number }[]
  readonly status: 'healthy' | 'warning' | 'critical'
}

// =============================================================================
// ANSI Colors
// =============================================================================

const COLORS = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
} as const

const color = (c: keyof typeof COLORS, text: string): string => `${COLORS[c]}${text}${COLORS.reset}`

// CLI output helper
const print = (text: string): Effect.Effect<void> =>
  Effect.sync(() => {
    process.stdout.write(text + '\n')
  })

// =============================================================================
// Analysis
// =============================================================================

const analyzeAlerts = Effect.gen(function* () {
  const db = yield* MetricsDbService
  const trends = yield* db.getWeeklyTrends(14) // 2 weeks

  if (trends.length < 2) {
    return {
      latest_score: trends[0]?.avg_score ?? null,
      alerts: ['Insufficient data for trend analysis'],
      trend: trends.map((t) => ({ date: t.date, score: t.avg_score })),
      status: 'healthy' as const,
    }
  }

  const latest = trends[0]
  const previous = trends[1]
  const weekAgo = trends[6] ?? trends[trends.length - 1]

  // Type guard - we know these exist due to length check above
  if (latest === undefined || previous === undefined || weekAgo === undefined) {
    return {
      latest_score: null,
      alerts: ['Unexpected data structure'],
      trend: [],
      status: 'healthy' as const,
    }
  }

  const alerts: string[] = []
  let status: 'healthy' | 'warning' | 'critical' = 'healthy'

  // Check absolute thresholds
  if (latest.avg_score < THRESHOLDS.critical) {
    alerts.push(
      `CRITICAL: Score ${Math.round(latest.avg_score * 100)}% below ${THRESHOLDS.critical * 100}%`,
    )
    status = 'critical'
  } else if (latest.avg_score < THRESHOLDS.warning) {
    alerts.push(
      `WARNING: Score ${Math.round(latest.avg_score * 100)}% below ${THRESHOLDS.warning * 100}%`,
    )
    status = 'warning'
  }

  // Check for sudden drop from previous day
  const dropFromPrevious = previous.avg_score - latest.avg_score
  if (dropFromPrevious > THRESHOLDS.trendDrop) {
    alerts.push(`REGRESSION: ${Math.round(dropFromPrevious * 100)}% drop from yesterday`)
    if (status === 'healthy') status = 'warning'
  }

  // Check for weekly decline
  const dropFromWeekAgo = weekAgo.avg_score - latest.avg_score
  if (dropFromWeekAgo > THRESHOLDS.trendDrop * 2) {
    alerts.push(`TREND: ${Math.round(dropFromWeekAgo * 100)}% decline over past week`)
    if (status === 'healthy') status = 'warning'
  }

  // Check for consecutive drops (3+ days)
  let consecutiveDrops = 0
  for (let i = 0; i < trends.length - 1 && i < 5; i++) {
    const current = trends[i]
    const next = trends[i + 1]
    if (current !== undefined && next !== undefined && current.avg_score < next.avg_score) {
      consecutiveDrops++
    } else {
      break
    }
  }
  if (consecutiveDrops >= 3) {
    alerts.push(`DEGRADATION: ${consecutiveDrops} consecutive days of decline`)
    if (status === 'healthy') status = 'warning'
  }

  return {
    latest_score: latest.avg_score,
    alerts,
    trend: trends.slice(0, 7).map((t) => ({ date: t.date, score: t.avg_score })),
    status,
  } satisfies AlertResult
})

// =============================================================================
// Output
// =============================================================================

const renderHuman = (result: AlertResult): Effect.Effect<void> =>
  Effect.gen(function* () {
    if (result.alerts.length === 0) {
      yield* print(color('green', '✓ No alerts - system healthy'))
    } else {
      for (const alert of result.alerts) {
        const alertColor = alert.startsWith('CRITICAL') ? 'red' : 'yellow'
        yield* print(color(alertColor, `⚠ ${alert}`))
      }
    }

    if (result.latest_score !== null) {
      yield* print('')
      yield* print(`Latest score: ${Math.round(result.latest_score * 100)}%`)
    }
  })

const renderJson = (result: AlertResult): Effect.Effect<void> =>
  Effect.sync(() => {
    process.stdout.write(JSON.stringify(result) + '\n')
  })

// =============================================================================
// Main
// =============================================================================

const program = Effect.gen(function* () {
  const result = yield* analyzeAlerts

  // Check for --json flag
  const isJson = process.argv.includes('--json')

  if (isJson) {
    yield* renderJson(result)
  } else {
    yield* renderHuman(result)
  }
})

// =============================================================================
// Run
// =============================================================================

pipe(
  program,
  Effect.provide(MetricsDbLive),
  Effect.catchAll((error) =>
    Effect.sync(() => {
      process.stderr.write(`Error: ${String(error)}\n`)
      process.exit(1)
    }),
  ),
  Effect.runPromise,
)
