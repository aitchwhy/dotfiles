#!/usr/bin/env bun

/**
 * Reflection System - Synthesize Lessons into CLAUDE.md Updates
 *
 * Analyzes high-decay lessons and proposes updates to CLAUDE.md.
 * This CLOSES THE SELF-EVOLUTION LOOP.
 *
 * Run: bun config/quality/evolution/reflect.ts
 */

import { Database } from 'bun:sqlite'
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { homedir } from 'node:os'
import { join } from 'node:path'
import { Data, Effect, pipe } from 'effect'

// =============================================================================
// Configuration
// =============================================================================

const HOME = homedir()
const METRICS_DB = join(HOME, '.claude-metrics', 'evolution.db')
const CLAUDE_MD = join(HOME, '.claude', 'CLAUDE.md')
const REFLECTIONS_DIR = join(HOME, '.claude', 'memory', 'reflections')

// =============================================================================
// Types & Errors
// =============================================================================

interface Lesson {
  readonly id: number
  readonly category: string
  readonly lesson: string
  readonly occurrence_count: number
  readonly decay_score: number
}

class ReflectionError extends Data.TaggedError('ReflectionError')<{
  readonly message: string
}> {}

// =============================================================================
// ANSI Colors
// =============================================================================

const COLORS = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
  gray: '\x1b[90m',
} as const

const color = (c: keyof typeof COLORS, text: string): string => `${COLORS[c]}${text}${COLORS.reset}`

// CLI output helper
const print = (text: string): Effect.Effect<void> =>
  Effect.sync(() => {
    process.stdout.write(`${text}\n`)
  })

// =============================================================================
// Database
// =============================================================================

const ensureDb = Effect.try({
  try: () => {
    if (!existsSync(METRICS_DB)) {
      return null
    }
    const db = new Database(METRICS_DB)

    // Ensure lessons table exists
    db.exec(`
			CREATE TABLE IF NOT EXISTS lessons (
				id INTEGER PRIMARY KEY AUTOINCREMENT,
				date TEXT NOT NULL,
				category TEXT NOT NULL,
				lesson TEXT NOT NULL,
				evidence TEXT NOT NULL,
				source TEXT DEFAULT 'session',
				occurrence_count INTEGER DEFAULT 1,
				last_accessed TEXT,
				decay_score REAL DEFAULT 1.0,
				created_at TEXT DEFAULT (datetime('now'))
			);
			CREATE INDEX IF NOT EXISTS idx_lessons_decay ON lessons(decay_score DESC);
		`)

    return db
  },
  catch: () => null,
})

const getHighConfidenceLessons = (db: Database): Effect.Effect<readonly Lesson[], never> =>
  pipe(
    Effect.try({
      try: () =>
        db
          .query<Lesson, []>(`
					SELECT id, category, lesson, occurrence_count, decay_score
					FROM lessons
					WHERE decay_score > 0.8 AND occurrence_count >= 2
					ORDER BY decay_score DESC, occurrence_count DESC
					LIMIT 10
				`)
          .all() as readonly Lesson[],
      catch: () => new Error('Query failed'),
    }),
    Effect.orElseSucceed((): readonly Lesson[] => []),
  )

const markLessonsProcessed = (db: Database, ids: readonly number[]): Effect.Effect<void, never> =>
  pipe(
    Effect.try({
      try: (): void => {
        for (const id of ids) {
          db.run(`UPDATE lessons SET last_accessed = datetime('now') WHERE id = ?`, [id])
        }
      },
      catch: () => new Error('Update failed'),
    }),
    Effect.orElseSucceed((): void => {}),
  )

// =============================================================================
// Synthesis
// =============================================================================

const groupByCategory = (lessons: readonly Lesson[]): Map<string, Lesson[]> => {
  const groups = new Map<string, Lesson[]>()
  for (const lesson of lessons) {
    const existing = groups.get(lesson.category) ?? []
    existing.push(lesson)
    groups.set(lesson.category, existing)
  }
  return groups
}

const generateProposals = (grouped: Map<string, Lesson[]>, currentContent: string): string[] => {
  const proposals: string[] = []

  for (const [category, items] of grouped) {
    const categoryHeader = `## ${category.toUpperCase()} Lessons (Auto-Synthesized)`

    // Check if already in CLAUDE.md
    if (currentContent.includes(categoryHeader)) {
      continue
    }

    proposals.push('')
    proposals.push(categoryHeader)
    for (const item of items.slice(0, 3)) {
      const truncated = item.lesson.slice(0, 150).replace(/\n/g, ' ')
      proposals.push(`- ${truncated}`)
    }
  }

  return proposals
}

const saveReflection = (
  lessons: readonly Lesson[],
  proposals: readonly string[],
): Effect.Effect<string, ReflectionError> =>
  Effect.try({
    try: () => {
      if (!existsSync(REFLECTIONS_DIR)) {
        mkdirSync(REFLECTIONS_DIR, { recursive: true })
      }

      const date = new Date().toISOString().slice(0, 10)
      const reflectionPath = join(REFLECTIONS_DIR, `${date}-reflection.md`)

      const content = `# Reflection ${new Date().toISOString()}

## Proposed CLAUDE.md Updates

${proposals.join('\n')}

## Source Lessons

${lessons.map((l) => `- [${l.category}] ${l.lesson.slice(0, 100)} (score: ${l.decay_score.toFixed(2)}, count: ${l.occurrence_count})`).join('\n')}

## Action Required

Review above and manually add relevant items to ~/.claude/CLAUDE.md
`

      writeFileSync(reflectionPath, content)
      return reflectionPath
    },
    catch: (e) => new ReflectionError({ message: `Failed to save reflection: ${e}` }),
  })

// =============================================================================
// Main
// =============================================================================

const program = Effect.gen(function* () {
  yield* print('')
  yield* print(color('bold', '═══════════════════════════════════════════════════════'))
  yield* print(color('bold', '              REFLECTION SYSTEM'))
  yield* print(color('bold', '═══════════════════════════════════════════════════════'))
  yield* print('')

  // Open database
  const db = yield* ensureDb
  if (!db) {
    yield* print(color('yellow', 'No evolution database found. Run sessions to generate lessons.'))
    return
  }

  // Get high-confidence lessons
  const lessons = yield* getHighConfidenceLessons(db)

  if (lessons.length === 0) {
    yield* print(color('gray', 'No high-confidence lessons to synthesize.'))
    yield* print(color('gray', 'Lessons need decay_score > 0.8 and occurrence_count >= 2'))
    yield* print('')
    return
  }

  yield* print(color('cyan', `Found ${lessons.length} high-confidence lessons:`))
  yield* print('')

  // Group by category
  const grouped = groupByCategory(lessons)
  for (const [category, items] of grouped) {
    yield* print(color('yellow', `  ${category.toUpperCase()} (${items.length} lessons)`))
    for (const item of items.slice(0, 2)) {
      yield* print(color('gray', `    • ${item.lesson.slice(0, 60)}...`))
    }
  }
  yield* print('')

  // Read current CLAUDE.md
  const currentContent = existsSync(CLAUDE_MD) ? readFileSync(CLAUDE_MD, 'utf-8') : ''

  // Generate proposals
  const proposals = generateProposals(grouped, currentContent)

  if (proposals.length === 0) {
    yield* print(color('green', '✓ All lessons already in CLAUDE.md'))
    return
  }

  // Save reflection
  const reflectionPath = yield* saveReflection(lessons, proposals)

  yield* print(color('green', `✓ Reflection saved to ${reflectionPath}`))
  yield* print(
    color('cyan', `  Found ${proposals.length - grouped.size} new lesson entries to consider`),
  )
  yield* print('')

  // Mark lessons as processed
  yield* markLessonsProcessed(
    db,
    lessons.map((l) => l.id),
  )

  yield* print(
    color(
      'gray',
      'Review the reflection file and manually add relevant items to ~/.claude/CLAUDE.md',
    ),
  )
  yield* print('')
})

// =============================================================================
// Run
// =============================================================================

pipe(
  program,
  Effect.catchAll((error) =>
    Effect.sync(() => {
      process.stderr.write(`Error: ${String(error)}\n`)
      process.exit(1)
    }),
  ),
  Effect.runPromise,
)
