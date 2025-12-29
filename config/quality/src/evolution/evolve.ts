#!/usr/bin/env bun
/**
 * Evolution System - Interactive Health Dashboard
 *
 * Full Effect pipeline. Replaces evolve.sh.
 * Run: bun config/quality/evolution/evolve.ts
 */

import { Effect, pipe } from 'effect'
import {
  type GradeRecord,
  MetricsDbLive,
  MetricsDbService,
  type TrendRecord,
} from './lib/metrics-db'

// =============================================================================
// ANSI Colors (no chalk dependency)
// =============================================================================

const COLORS = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  gray: '\x1b[90m',
} as const

const color = (c: keyof typeof COLORS, text: string): string => `${COLORS[c]}${text}${COLORS.reset}`

// =============================================================================
// Formatters
// =============================================================================

const getScoreColor = (score: number): keyof typeof COLORS =>
  score >= 0.8 ? 'green' : score >= 0.5 ? 'yellow' : 'red'

const formatPercent = (score: number): string => `${Math.round(score * 100)}%`

const makeBar = (score: number, width: number = 20): string => {
  const filled = Math.round(score * width)
  return '█'.repeat(filled) + '░'.repeat(width - filled)
}

// CLI output helper (stdout is the intended output for CLI tools)
const print = (text: string): Effect.Effect<void> =>
  Effect.sync(() => {
    process.stdout.write(text + '\n')
  })

// =============================================================================
// Dashboard
// =============================================================================

type DetailsRecord = Record<string, { score?: number; message?: string }>

const parseDetails = (detailsJson: string): Effect.Effect<DetailsRecord, never> =>
  pipe(
    Effect.try({
      try: () => JSON.parse(detailsJson) as DetailsRecord,
      catch: () => new Error('JSON parse failed'),
    }),
    Effect.orElseSucceed((): DetailsRecord => ({})),
  )

const renderDashboard = (
  grades: readonly GradeRecord[],
  trends: readonly TrendRecord[],
): Effect.Effect<void> =>
  Effect.gen(function* () {
    yield* print('')
    yield* print(color('bold', '═══════════════════════════════════════════════════════'))
    yield* print(color('bold', '              EVOLUTION SYSTEM DASHBOARD'))
    yield* print(color('bold', '═══════════════════════════════════════════════════════'))
    yield* print('')

    // Latest Grade Section
    const latest = grades[0]
    if (latest !== undefined) {
      const scoreColor = getScoreColor(latest.overall_score)

      yield* print(color('cyan', '┌─ Latest Grade ─────────────────────────────────────┐'))
      yield* print(
        `│  Score: ${color(scoreColor, formatPercent(latest.overall_score))} ${color(scoreColor, makeBar(latest.overall_score))} │`,
      )
      yield* print(
        `│  Status: ${color(scoreColor, latest.recommendation.toUpperCase().padEnd(10))}                              │`,
      )
      yield* print(
        `│  Time: ${color('gray', latest.timestamp.slice(0, 19).padEnd(25))}             │`,
      )
      yield* print(color('cyan', '└────────────────────────────────────────────────────┘'))
      yield* print('')

      // Parse details for component breakdown
      const details = yield* parseDetails(latest.details_json)
      if (Object.keys(details).length > 0) {
        yield* print(color('cyan', 'Components:'))
        for (const [name, result] of Object.entries(details)) {
          if (typeof result === 'object' && result !== null && 'score' in result) {
            const score = (result.score ?? 0) / 100
            const sc = getScoreColor(score)
            const label = name.replace(/_/g, ' ').padEnd(15)
            yield* print(
              `  ${label} ${color(sc, formatPercent(score).padStart(4))} ${color(sc, makeBar(score, 10))}`,
            )
          }
        }
        yield* print('')
      }
    } else {
      yield* print(color('yellow', 'No grades recorded yet. Run: just grade'))
      yield* print('')
    }

    // Weekly Trend Section
    if (trends.length > 0) {
      yield* print(color('cyan', '┌─ 7-Day Trend ──────────────────────────────────────┐'))
      for (const t of trends.slice(0, 7)) {
        const sc = getScoreColor(t.avg_score)
        const date = t.date.slice(5) // MM-DD
        yield* print(
          `│  ${date}  ${color(sc, makeBar(t.avg_score, 25))} ${color(sc, formatPercent(t.avg_score).padStart(4))} │`,
        )
      }
      yield* print(color('cyan', '└────────────────────────────────────────────────────┘'))
      yield* print('')

      // Trend analysis
      const latestTrend = trends[0]
      const previousTrend = trends[1]
      if (latestTrend !== undefined && previousTrend !== undefined) {
        const delta = latestTrend.avg_score - previousTrend.avg_score

        if (Math.abs(delta) > 0.05) {
          const trend = delta > 0 ? '↑ Improving' : '↓ Declining'
          const trendColor = delta > 0 ? 'green' : 'red'
          yield* print(
            `  Trend: ${color(trendColor, trend)} (${delta > 0 ? '+' : ''}${Math.round(delta * 100)}%)`,
          )
          yield* print('')
        }
      }
    }

    // Recommendations
    const firstGrade = grades[0]
    if (firstGrade !== undefined && firstGrade.overall_score < 0.8) {
      yield* print(color('yellow', 'Recommendations:'))
      const details = yield* parseDetails(firstGrade.details_json)
      for (const [name, result] of Object.entries(details)) {
        if (typeof result === 'object' && result !== null && 'score' in result) {
          const score = result.score ?? 100
          if (score < 80) {
            yield* print(`  • Fix: ${name.replace(/_/g, ' ')} (${score}%)`)
          }
        }
      }
      yield* print('')
    }

    yield* print(color('gray', "Run 'just grade' for detailed health check"))
    yield* print(color('gray', "Run 'just reflect' to synthesize lessons"))
    yield* print('')
  })

// =============================================================================
// JSON Mode
// =============================================================================

const renderJson = (
  grades: readonly GradeRecord[],
  trends: readonly TrendRecord[],
): Effect.Effect<void> =>
  Effect.sync(() => {
    const latest = grades[0]
    const trend0 = trends[0]
    const trend1 = trends[1]
    const trendDirection =
      trend0 !== undefined && trend1 !== undefined
        ? trend0.avg_score > trend1.avg_score
          ? 'improving'
          : trend0.avg_score < trend1.avg_score
            ? 'declining'
            : 'stable'
        : null
    const output = {
      score_percent: latest !== undefined ? Math.round(latest.overall_score * 100) : null,
      recommendation: latest?.recommendation ?? null,
      trend: trendDirection,
      weekly_avg:
        trends.length > 0
          ? Math.round((trends.reduce((sum, t) => sum + t.avg_score, 0) / trends.length) * 100)
          : null,
      last_grade: latest?.timestamp ?? null,
    }
    process.stdout.write(JSON.stringify(output) + '\n')
  })

// =============================================================================
// Main
// =============================================================================

const program = Effect.gen(function* () {
  const db = yield* MetricsDbService

  // Get recent data
  const grades = yield* db.getRecentGrades(10)
  const trends = yield* db.getWeeklyTrends(7)

  // Check for --json flag
  const isJson = process.argv.includes('--json')

  if (isJson) {
    yield* renderJson(grades, trends)
  } else {
    yield* renderDashboard(grades, trends)
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
      process.stderr.write(color('red', `Error: ${String(error)}`) + '\n')
      process.exit(1)
    }),
  ),
  Effect.runPromise,
)
