#!/usr/bin/env bun
/**
 * consolidate.ts - Memory consolidation for the evolution system
 *
 * Effect-TS implementation with typed errors and injectable dependencies.
 * Implements aggressive lesson consolidation:
 * 1. Deduplication - merge similar lessons (70%+ Jaccard similarity)
 * 2. Decay scoring - Ebbinghaus-style decay with frequency boost
 * 3. Archival - move low-value lessons to archive table
 * 4. Git dump - export active lessons to SQL for version control
 *
 * Security: Uses bun:sqlite for parameterized queries (no SQL injection)
 */

import { Database } from 'bun:sqlite'
import { spawnSync } from 'node:child_process'
import { existsSync, realpathSync, writeFileSync } from 'node:fs'
import { homedir } from 'node:os'
import { join, resolve } from 'node:path'
import { Cause, Console, Data, Effect, Option, Schema } from 'effect'
import { logError } from '../hooks/lib/hook-logging'
import { currentTimeIso, daysSince, parseIsoToMs } from '../lib/date.schema'

// =============================================================================
// Configuration Schema (Parse at Boundary)
// =============================================================================

const EnvConfigSchema = Schema.Struct({
  halfLifeDays: Schema.optionalWith(Schema.NumberFromString, { default: () => 14 }),
  archiveThreshold: Schema.optionalWith(Schema.NumberFromString, { default: () => 0.1 }),
  similarityThreshold: Schema.optionalWith(Schema.NumberFromString, { default: () => 0.7 }),
})

const parseEnvConfig = () => {
  const raw = {
    halfLifeDays: process.env['EVOLUTION_HALF_LIFE'],
    archiveThreshold: process.env['EVOLUTION_ARCHIVE_THRESHOLD'],
    similarityThreshold: process.env['EVOLUTION_SIMILARITY'],
  }
  return Schema.decodeUnknownSync(EnvConfigSchema)(raw)
}

const envConfig = parseEnvConfig()

const CONFIG = {
  halfLifeDays: envConfig.halfLifeDays,
  archiveThreshold: envConfig.archiveThreshold,
  similarityThreshold: envConfig.similarityThreshold,
  minTokenLength: 2,
  maxLessonLength: 200,
  maxEvidenceLength: 500,
} as const

// Paths
const HOME = homedir()
const METRICS_DIR = join(HOME, '.claude-metrics')
const DB_FILE = join(METRICS_DIR, 'evolution.db')
const DOTFILES = join(HOME, 'dotfiles')
const SQL_DUMP_PATH = join(DOTFILES, 'config/quality/memory/lessons.sql')

// =============================================================================
// Types
// =============================================================================

type Lesson = {
  readonly id: number
  readonly date: string
  readonly category: string
  readonly lesson: string
  readonly evidence: string
  readonly source: string
  readonly occurrence_count: number
  readonly last_accessed: string | null
  readonly decay_score: number
  readonly created_at: string
}

type ConsolidationResult = {
  readonly deduplicated: number
  readonly decayed: number
  readonly archived: number
  readonly active: number
  readonly dumpPath: string | null
  readonly errors: readonly string[]
}

// =============================================================================
// Typed Errors
// =============================================================================

class DatabaseError extends Data.TaggedError('DatabaseError')<{
  readonly operation: string
  readonly cause: unknown
}> {}

class PathValidationError extends Data.TaggedError('PathValidationError')<{
  readonly path: string
  readonly reason: string
}> {}

class FileSystemError extends Data.TaggedError('FileSystemError')<{
  readonly operation: string
  readonly path: string
  readonly cause: unknown
}> {}

class GitError extends Data.TaggedError('GitError')<{
  readonly operation: string
  readonly cause: unknown
}> {}

// =============================================================================
// Pure Functions (No Effect needed)
// =============================================================================

/**
 * Calculate Jaccard similarity between two strings
 * Returns value between 0 (no overlap) and 1 (identical)
 */
const jaccardSimilarity = (a: string, b: string): number => {
  const tokensA = new Set(
    a
      .toLowerCase()
      .split(/\s+/)
      .filter((t) => t.length > CONFIG.minTokenLength),
  )
  const tokensB = new Set(
    b
      .toLowerCase()
      .split(/\s+/)
      .filter((t) => t.length > CONFIG.minTokenLength),
  )

  if (tokensA.size === 0 && tokensB.size === 0) return 1
  if (tokensA.size === 0 || tokensB.size === 0) return 0

  const intersection = new Set([...tokensA].filter((x) => tokensB.has(x)))
  const union = new Set([...tokensA, ...tokensB])

  return intersection.size / union.size
}

/**
 * Validate that a path is within expected directories (security)
 */
const validatePath = (
  path: string,
  allowedPrefixes: readonly string[],
): Effect.Effect<string, PathValidationError> =>
  Effect.try({
    try: () => {
      const realPath = realpathSync(resolve(path))
      if (!allowedPrefixes.some((prefix) => realPath.startsWith(prefix))) {
        throw new Error('Path not in allowed prefixes')
      }
      return realPath
    },
    catch: () => new PathValidationError({ path, reason: 'Invalid or inaccessible path' }),
  })

/**
 * Find duplicate lessons using Jaccard similarity (pure function)
 * Uses indexed for loop with continue to handle sparse arrays
 */
const findDuplicates = (lessons: readonly Lesson[]): Map<number, number[]> => {
  const duplicates = new Map<number, number[]>()
  const len = lessons.length

  for (let i = 0; i < len; i++) {
    const a = lessons[i]
    if (!a) continue // Guard against sparse array

    for (let j = i + 1; j < len; j++) {
      const b = lessons[j]
      if (!b) continue // Guard against sparse array

      if (a.category === b.category) {
        const similarity = jaccardSimilarity(a.lesson, b.lesson)
        if (similarity >= CONFIG.similarityThreshold) {
          const primary = a.occurrence_count >= b.occurrence_count ? a : b
          const duplicate = primary === a ? b : a

          const existing = duplicates.get(primary.id)
          if (existing) {
            existing.push(duplicate.id)
          } else {
            duplicates.set(primary.id, [duplicate.id])
          }
        }
      }
    }
  }

  return duplicates
}

// =============================================================================
// Database Operations (Effect-based)
// =============================================================================

/**
 * Open database with Effect error handling
 */
const openDatabase: Effect.Effect<Database, DatabaseError | PathValidationError> = Effect.gen(
  function* () {
    if (!existsSync(DB_FILE)) {
      return yield* Effect.fail(new DatabaseError({ operation: 'open', cause: 'File not found' }))
    }

    yield* validatePath(DB_FILE, [HOME])

    return yield* Effect.try({
      try: () => new Database(DB_FILE),
      catch: (cause) => new DatabaseError({ operation: 'open', cause }),
    })
  },
)

/**
 * Get all active lessons
 */
const getActiveLessons = (db: Database): Effect.Effect<readonly Lesson[], DatabaseError> =>
  Effect.try({
    try: () => {
      const stmt = db.query<Lesson, []>('SELECT * FROM lessons ORDER BY decay_score DESC')
      return stmt.all()
    },
    catch: (cause) => new DatabaseError({ operation: 'getActiveLessons', cause }),
  })

/**
 * Calculate decay score using Ebbinghaus curve with frequency boost
 * Uses Effect for Clock-based current time
 */
const calculateDecayScore = (lesson: Lesson): Effect.Effect<number> =>
  Effect.gen(function* () {
    const createdMs = parseIsoToMs(lesson.created_at || lesson.date)
    const daysSinceCreated = yield* daysSince(createdMs)

    // Base decay: exponential with half-life
    const baseDecay = Math.exp(-daysSinceCreated / CONFIG.halfLifeDays)

    // Frequency boost: log scale to prevent runaway
    const frequencyBoost = 1 + Math.log(lesson.occurrence_count || 1)

    // Recency boost if accessed recently
    let recencyBoost = 1
    if (lesson.last_accessed) {
      const lastAccessedMs = parseIsoToMs(lesson.last_accessed)
      const daysSinceAccess = yield* daysSince(lastAccessedMs)
      if (daysSinceAccess < 7) {
        recencyBoost = 1.5
      }
    }

    return Math.min(1, baseDecay * frequencyBoost * recencyBoost)
  })

/**
 * Merge duplicate lessons using parameterized queries
 */
const mergeDuplicates = (
  db: Database,
  duplicates: Map<number, number[]>,
): Effect.Effect<number, DatabaseError> =>
  Effect.gen(function* () {
    let merged = 0

    const getPrimary = db.query<Pick<Lesson, 'occurrence_count'>, [number]>(
      'SELECT occurrence_count FROM lessons WHERE id = ?',
    )
    const getDuplicateCount = db.query<Pick<Lesson, 'occurrence_count'>, [number]>(
      'SELECT occurrence_count FROM lessons WHERE id = ?',
    )
    const updatePrimary = db.query<null, [number, number]>(
      "UPDATE lessons SET occurrence_count = ?, last_accessed = datetime('now') WHERE id = ?",
    )
    const deleteById = db.query<null, [number]>('DELETE FROM lessons WHERE id = ?')

    for (const [primaryId, duplicateIds] of duplicates) {
      if (duplicateIds.length === 0) continue

      const primaryOption = yield* Effect.try({
        try: () => Option.fromNullable(getPrimary.get(primaryId)),
        catch: (cause) => new DatabaseError({ operation: 'getPrimary', cause }),
      })

      if (Option.isNone(primaryOption)) continue
      const primary = primaryOption.value

      let totalCount = primary.occurrence_count
      for (const id of duplicateIds) {
        const dupOption = yield* Effect.try({
          try: () => Option.fromNullable(getDuplicateCount.get(id)),
          catch: (cause) => new DatabaseError({ operation: 'getDuplicateCount', cause }),
        })
        if (Option.isSome(dupOption)) {
          totalCount += dupOption.value.occurrence_count
        }
      }

      yield* Effect.try({
        try: () => updatePrimary.run(totalCount, primaryId),
        catch: (cause) => new DatabaseError({ operation: 'updatePrimary', cause }),
      })

      for (const id of duplicateIds) {
        yield* Effect.try({
          try: () => deleteById.run(id),
          catch: (cause) => new DatabaseError({ operation: 'deleteById', cause }),
        })
        merged++
      }
    }

    return merged
  })

/**
 * Update decay scores for all lessons
 */
const updateDecayScores = (db: Database): Effect.Effect<number, DatabaseError> =>
  Effect.gen(function* () {
    const lessons = yield* getActiveLessons(db)
    let updated = 0

    const updateScore = db.query<null, [number, number]>(
      'UPDATE lessons SET decay_score = ? WHERE id = ?',
    )

    for (const lesson of lessons) {
      const newScore = yield* calculateDecayScore(lesson)
      if (Math.abs(newScore - lesson.decay_score) > 0.01) {
        yield* Effect.try({
          try: () => updateScore.run(newScore, lesson.id),
          catch: (cause) => new DatabaseError({ operation: 'updateScore', cause }),
        })
        updated++
      }
    }

    return updated
  })

/**
 * Archive lessons below threshold
 */
const archiveLowValueLessons = (db: Database): Effect.Effect<number, DatabaseError> =>
  Effect.gen(function* () {
    yield* Effect.try({
      try: () =>
        db.run(
          `
        INSERT INTO lessons_archive (id, date, category, lesson, evidence, occurrence_count)
        SELECT id, date, category, lesson, evidence, occurrence_count
        FROM lessons
        WHERE decay_score < ?
      `,
          [CONFIG.archiveThreshold],
        ),
      catch: (cause) => new DatabaseError({ operation: 'archiveInsert', cause }),
    })

    const countStmt = db.query<{ count: number }, [number]>(
      'SELECT COUNT(*) as count FROM lessons WHERE decay_score < ?',
    )

    const archivedResult = yield* Effect.try({
      try: () => Option.fromNullable(countStmt.get(CONFIG.archiveThreshold)),
      catch: (cause) => new DatabaseError({ operation: 'archiveCount', cause }),
    })

    const archived = Option.isSome(archivedResult) ? archivedResult.value.count : 0

    yield* Effect.try({
      try: () => db.run('DELETE FROM lessons WHERE decay_score < ?', [CONFIG.archiveThreshold]),
      catch: (cause) => new DatabaseError({ operation: 'archiveDelete', cause }),
    })

    return archived
  })

/**
 * Count active lessons
 */
const countActiveLessons = (db: Database): Effect.Effect<number, DatabaseError> =>
  Effect.gen(function* () {
    const countStmt = db.query<{ count: number }, []>('SELECT COUNT(*) as count FROM lessons')

    const result = yield* Effect.try({
      try: () => Option.fromNullable(countStmt.get()),
      catch: (cause) => new DatabaseError({ operation: 'countActive', cause }),
    })

    return Option.isSome(result) ? result.value.count : 0
  })

/**
 * Export active lessons to SQL dump
 */
const exportToSql = (
  db: Database,
): Effect.Effect<string | null, DatabaseError | PathValidationError | FileSystemError> =>
  Effect.gen(function* () {
    const lessons = yield* getActiveLessons(db)

    if (lessons.length === 0) {
      return null
    }

    yield* validatePath(DOTFILES, [HOME])

    const timestamp = yield* currentTimeIso

    const lines = [
      '-- Active Lessons Dump',
      `-- Generated: ${timestamp}`,
      `-- Count: ${lessons.length}`,
      '',
      'BEGIN TRANSACTION;',
      '',
      'DELETE FROM lessons;',
      '',
    ]

    for (const l of lessons) {
      const escapedLesson = l.lesson.replace(/'/g, "''")
      const escapedEvidence = l.evidence.replace(/'/g, "''")
      lines.push(
        `INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (${l.id}, '${l.date}', '${l.category}', '${escapedLesson}', '${escapedEvidence}', '${l.source}', ${l.occurrence_count}, ${l.decay_score.toFixed(4)}, '${l.created_at || l.date}');`,
      )
    }

    lines.push('', 'COMMIT;', '')

    const content = lines.join('\n')

    yield* Effect.try({
      try: () => writeFileSync(SQL_DUMP_PATH, content),
      catch: (cause) => new FileSystemError({ operation: 'writeFile', path: SQL_DUMP_PATH, cause }),
    })

    return SQL_DUMP_PATH
  })

/**
 * Git commit the SQL dump (best-effort, failures are logged but not fatal)
 */
const gitCommitDump = (dumpPath: string): Effect.Effect<boolean, GitError | PathValidationError> =>
  Effect.gen(function* () {
    yield* validatePath(dumpPath, [DOTFILES])
    yield* validatePath(DOTFILES, [HOME])

    const addResult = yield* Effect.try({
      try: () =>
        spawnSync('git', ['add', dumpPath], {
          cwd: DOTFILES,
          encoding: 'utf-8',
        }),
      catch: (cause) => new GitError({ operation: 'add', cause }),
    })

    if (addResult.status !== 0) {
      return false
    }

    const diffResult = yield* Effect.try({
      try: () =>
        spawnSync('git', ['diff', '--cached', '--quiet'], {
          cwd: DOTFILES,
          encoding: 'utf-8',
        }),
      catch: (cause) => new GitError({ operation: 'diff', cause }),
    })

    if (diffResult.status === 0) {
      return true // No changes to commit
    }

    const commitResult = yield* Effect.try({
      try: () =>
        spawnSync('git', ['commit', '-m', 'chore(evolution): archive lessons'], {
          cwd: DOTFILES,
          encoding: 'utf-8',
        }),
      catch: (cause) => new GitError({ operation: 'commit', cause }),
    })

    return commitResult.status === 0
  })

// =============================================================================
// Main Pipeline
// =============================================================================

const pipeline = (db: Database): Effect.Effect<ConsolidationResult> =>
  Effect.gen(function* () {
    const errors: string[] = []

    // Step 1: Find and merge duplicates
    const deduplicatedResult = yield* Effect.option(
      Effect.gen(function* () {
        const lessons = yield* getActiveLessons(db)
        const duplicates = findDuplicates(lessons)
        return yield* mergeDuplicates(db, duplicates)
      }),
    )
    const deduplicated = Option.getOrElse(deduplicatedResult, () => {
      errors.push('Deduplication failed')
      return 0
    })

    // Step 2: Update decay scores
    const decayedResult = yield* Effect.option(updateDecayScores(db))
    const decayed = Option.getOrElse(decayedResult, () => {
      errors.push('Decay update failed')
      return 0
    })

    // Step 3: Archive low-value lessons
    const archivedResult = yield* Effect.option(archiveLowValueLessons(db))
    const archived = Option.getOrElse(archivedResult, () => {
      errors.push('Archival failed')
      return 0
    })

    // Step 4: Export to SQL dump
    const dumpPathResult = yield* Effect.option(exportToSql(db))
    const dumpPath = Option.getOrElse(dumpPathResult, () => {
      errors.push('SQL export failed')
      return null
    })

    // Step 5: Git commit (silent failure OK)
    if (dumpPath) {
      yield* gitCommitDump(dumpPath).pipe(Effect.catchAll(() => Effect.succeed(false)))
    }

    // Step 6: Count remaining active lessons
    const activeResult = yield* Effect.option(countActiveLessons(db))
    const active = Option.getOrElse(activeResult, () => {
      errors.push('Count failed')
      return 0
    })

    return {
      deduplicated,
      decayed,
      archived,
      active,
      dumpPath,
      errors,
    }
  })

/**
 * Run consolidation with database resource management
 */
const consolidate: Effect.Effect<ConsolidationResult, DatabaseError | PathValidationError> =
  Effect.gen(function* () {
    const db = yield* openDatabase

    return yield* Effect.ensuring(
      pipeline(db),
      Effect.sync(() => db.close()),
    )
  })

// =============================================================================
// Main Entry Point
// =============================================================================

const main = Effect.gen(function* () {
  if (!existsSync(DB_FILE)) {
    logError('consolidate', 'No database found')
    return yield* Effect.fail(1)
  }

  const result = yield* consolidate.pipe(
    Effect.catchAll((error) =>
      Effect.succeed<ConsolidationResult>({
        deduplicated: 0,
        decayed: 0,
        archived: 0,
        active: 0,
        dumpPath: null,
        errors: [error._tag === 'DatabaseError' ? error.operation : error.reason],
      }),
    ),
  )

  // Log errors if any
  for (const error of result.errors) {
    logError('consolidate', error)
  }

  // Output JSON for programmatic use
  yield* Console.log(JSON.stringify(result, null, 2))
})

// Run with Effect.runPromise (simpler entry point)
void Effect.runPromise(
  main.pipe(
    Effect.catchAllCause((cause) =>
      Console.error(`Consolidate failed: ${Cause.pretty(cause)}`).pipe(
        Effect.andThen(Effect.sync(() => (process.exitCode = 1))),
      ),
    ),
  ),
)

export { consolidate, calculateDecayScore, jaccardSimilarity }
