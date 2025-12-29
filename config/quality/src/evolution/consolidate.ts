#!/usr/bin/env bun
/**
 * consolidate.ts - Memory consolidation for the evolution system
 *
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
import { logError } from '../hooks/lib/hook-logging'

// Configuration (can be overridden via environment)
const CONFIG = {
  halfLifeDays: Number.parseInt(process.env['EVOLUTION_HALF_LIFE'] ?? '14', 10),
  archiveThreshold: Number.parseFloat(process.env['EVOLUTION_ARCHIVE_THRESHOLD'] ?? '0.1'),
  similarityThreshold: Number.parseFloat(process.env['EVOLUTION_SIMILARITY'] ?? '0.7'),
  minTokenLength: 2,
  maxLessonLength: 200,
  maxEvidenceLength: 500,
} as const

// Paths - validated before use
const HOME = homedir()
const METRICS_DIR = join(HOME, '.claude-metrics')
const DB_FILE = join(METRICS_DIR, 'evolution.db')
const DOTFILES = join(HOME, 'dotfiles')
const SQL_DUMP_PATH = join(DOTFILES, 'config/quality/memory/lessons.sql')

// Types
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

/**
 * Validate that a path is within expected directories (security)
 */
function validatePath(path: string, allowedPrefixes: readonly string[]): boolean {
  try {
    const realPath = realpathSync(resolve(path))
    return allowedPrefixes.some((prefix) => realPath.startsWith(prefix))
  } catch {
    return false
  }
}

/**
 * Calculate Jaccard similarity between two strings
 * Returns value between 0 (no overlap) and 1 (identical)
 */
function jaccardSimilarity(a: string, b: string): number {
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
 * Calculate decay score using Ebbinghaus curve with frequency boost
 */
function calculateDecayScore(lesson: Lesson): number {
  const now = Date.now()
  const created = new Date(lesson.created_at || lesson.date).getTime()
  const daysSinceCreated = (now - created) / (1000 * 60 * 60 * 24)

  // Base decay: exponential with half-life
  const baseDecay = Math.exp(-daysSinceCreated / CONFIG.halfLifeDays)

  // Frequency boost: log scale to prevent runaway
  const frequencyBoost = 1 + Math.log(lesson.occurrence_count || 1)

  // Recency boost if accessed recently
  let recencyBoost = 1
  if (lesson.last_accessed) {
    const lastAccessed = new Date(lesson.last_accessed).getTime()
    const daysSinceAccess = (now - lastAccessed) / (1000 * 60 * 60 * 24)
    if (daysSinceAccess < 7) {
      recencyBoost = 1.5 // 50% boost if accessed in last week
    }
  }

  return Math.min(1, baseDecay * frequencyBoost * recencyBoost)
}

/**
 * Open database with proper error handling
 */
function openDatabase(): Database | null {
  if (!existsSync(DB_FILE)) {
    return null
  }

  // Validate path is within expected location
  if (!validatePath(DB_FILE, [HOME])) {
    logError('consolidate', 'Invalid database path')
    return null
  }

  try {
    return new Database(DB_FILE)
  } catch (error) {
    logError('consolidate', error)
    return null
  }
}

/**
 * Get all active lessons using parameterized query
 */
function getActiveLessons(db: Database): Lesson[] {
  try {
    const stmt = db.query<Lesson, []>('SELECT * FROM lessons ORDER BY decay_score DESC')
    return stmt.all()
  } catch (error) {
    logError('consolidate', error)
    return []
  }
}

/**
 * Find duplicate lessons using Jaccard similarity
 */
function findDuplicates(lessons: readonly Lesson[]): Map<number, number[]> {
  const duplicates = new Map<number, number[]>()

  for (let i = 0; i < lessons.length; i++) {
    const a = lessons[i]
    if (a === undefined) continue

    for (let j = i + 1; j < lessons.length; j++) {
      const b = lessons[j]
      if (b === undefined) continue

      // Same category and similar content
      if (a.category === b.category) {
        const similarity = jaccardSimilarity(a.lesson, b.lesson)
        if (similarity >= CONFIG.similarityThreshold) {
          // Keep the one with higher occurrence count (or older one if equal)
          const primary = a.occurrence_count >= b.occurrence_count ? a : b
          const duplicate = primary === a ? b : a

          const existing = duplicates.get(primary.id) ?? []
          existing.push(duplicate.id)
          duplicates.set(primary.id, existing)
        }
      }
    }
  }

  return duplicates
}

/**
 * Merge duplicate lessons using parameterized queries
 */
function mergeDuplicates(db: Database, duplicates: Map<number, number[]>): number {
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

  try {
    for (const [primaryId, duplicateIds] of duplicates) {
      if (duplicateIds.length === 0) continue

      // Get primary lesson's current count
      const primary = getPrimary.get(primaryId)
      if (!primary) continue

      // Sum occurrence counts from duplicates
      let totalCount = primary.occurrence_count
      for (const id of duplicateIds) {
        const dup = getDuplicateCount.get(id)
        totalCount += dup?.occurrence_count || 1
      }

      // Update primary with combined count
      updatePrimary.run(totalCount, primaryId)

      // Delete duplicates
      for (const id of duplicateIds) {
        deleteById.run(id)
        merged++
      }
    }
  } catch (error) {
    logError('consolidate', error)
  }

  return merged
}

/**
 * Update decay scores for all lessons
 */
function updateDecayScores(db: Database): number {
  const lessons = getActiveLessons(db)
  let updated = 0

  const updateScore = db.query<null, [number, number]>(
    'UPDATE lessons SET decay_score = ? WHERE id = ?',
  )

  try {
    for (const lesson of lessons) {
      const newScore = calculateDecayScore(lesson)
      if (Math.abs(newScore - lesson.decay_score) > 0.01) {
        updateScore.run(newScore, lesson.id)
        updated++
      }
    }
  } catch (error) {
    logError('consolidate', error)
  }

  return updated
}

/**
 * Archive lessons below threshold using parameterized queries
 */
function archiveLowValueLessons(db: Database): number {
  try {
    // Move to archive
    db.run(
      `
      INSERT INTO lessons_archive (id, date, category, lesson, evidence, occurrence_count)
      SELECT id, date, category, lesson, evidence, occurrence_count
      FROM lessons
      WHERE decay_score < ?
    `,
      [CONFIG.archiveThreshold],
    )

    // Count archived
    const countStmt = db.query<{ count: number }, [number]>(
      'SELECT COUNT(*) as count FROM lessons WHERE decay_score < ?',
    )
    const archived = countStmt.get(CONFIG.archiveThreshold)?.count || 0

    // Delete from active
    db.run('DELETE FROM lessons WHERE decay_score < ?', [CONFIG.archiveThreshold])

    return archived
  } catch (error) {
    logError('consolidate', error)
    return 0
  }
}

/**
 * Export active lessons to SQL dump for git tracking
 */
function exportToSql(db: Database): string | null {
  const lessons = getActiveLessons(db)

  if (lessons.length === 0) {
    return null
  }

  // Validate dump path is within dotfiles
  if (!validatePath(DOTFILES, [HOME])) {
    logError('consolidate', 'Invalid dump path')
    return null
  }

  const lines = [
    '-- Active Lessons Dump',
    `-- Generated: ${new Date().toISOString()}`,
    `-- Count: ${lessons.length}`,
    '',
    'BEGIN TRANSACTION;',
    '',
    'DELETE FROM lessons;',
    '',
  ]

  for (const l of lessons) {
    // Escape single quotes for SQL
    const escapedLesson = l.lesson.replace(/'/g, "''")
    const escapedEvidence = l.evidence.replace(/'/g, "''")
    lines.push(
      `INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (${l.id}, '${l.date}', '${l.category}', '${escapedLesson}', '${escapedEvidence}', '${l.source}', ${l.occurrence_count}, ${l.decay_score.toFixed(4)}, '${l.created_at || l.date}');`,
    )
  }

  lines.push('', 'COMMIT;', '')

  const content = lines.join('\n')

  try {
    writeFileSync(SQL_DUMP_PATH, content)
    return SQL_DUMP_PATH
  } catch (error) {
    logError('consolidate', error)
    return null
  }
}

/**
 * Auto-commit the SQL dump to git using spawn (no shell injection)
 */
function gitCommitDump(dumpPath: string): boolean {
  // Validate paths before git operations
  if (!validatePath(dumpPath, [DOTFILES]) || !validatePath(DOTFILES, [HOME])) {
    logError('consolidate', 'Invalid path for git commit')
    return false
  }

  try {
    // Use spawnSync with array args (no shell injection)
    const addResult = spawnSync('git', ['add', dumpPath], {
      cwd: DOTFILES,
      encoding: 'utf-8',
    })

    if (addResult.status !== 0) {
      return false
    }

    // Check if there are changes to commit
    const diffResult = spawnSync('git', ['diff', '--cached', '--quiet'], {
      cwd: DOTFILES,
      encoding: 'utf-8',
    })

    if (diffResult.status === 0) {
      // No changes to commit
      return true
    }

    // Commit changes
    const commitResult = spawnSync('git', ['commit', '-m', 'chore(evolution): archive lessons'], {
      cwd: DOTFILES,
      encoding: 'utf-8',
    })

    return commitResult.status === 0
  } catch (error) {
    logError('consolidate', error)
    return false
  }
}

/**
 * Run full consolidation pipeline with error boundaries
 */
function consolidate(): ConsolidationResult {
  const errors: string[] = []
  let deduplicated = 0
  let decayed = 0
  let archived = 0
  let active = 0
  let dumpPath: string | null = null

  // Open database
  const db = openDatabase()
  if (!db) {
    return {
      deduplicated: 0,
      decayed: 0,
      archived: 0,
      active: 0,
      dumpPath: null,
      errors: ['Failed to open database'],
    }
  }

  try {
    // Step 1: Find and merge duplicates
    try {
      const lessons = getActiveLessons(db)
      const duplicates = findDuplicates(lessons)
      deduplicated = mergeDuplicates(db, duplicates)
    } catch (error) {
      errors.push(`Deduplication failed: ${error}`)
    }

    // Step 2: Update decay scores
    try {
      decayed = updateDecayScores(db)
    } catch (error) {
      errors.push(`Decay update failed: ${error}`)
    }

    // Step 3: Archive low-value lessons
    try {
      archived = archiveLowValueLessons(db)
    } catch (error) {
      errors.push(`Archival failed: ${error}`)
    }

    // Step 4: Export to SQL dump
    try {
      dumpPath = exportToSql(db)
    } catch (error) {
      errors.push(`SQL export failed: ${error}`)
    }

    // Step 5: Git commit (silent failure OK)
    if (dumpPath) {
      gitCommitDump(dumpPath)
    }

    // Count remaining active lessons
    try {
      const countStmt = db.query<{ count: number }, []>('SELECT COUNT(*) as count FROM lessons')
      active = countStmt.get()?.count || 0
    } catch (error) {
      errors.push(`Count failed: ${error}`)
    }
  } finally {
    // Always close database
    db.close()
  }

  return {
    deduplicated,
    decayed,
    archived,
    active,
    dumpPath,
    errors,
  }
}

/**
 * Main entry point
 */
function main(): void {
  if (!existsSync(DB_FILE)) {
    logError('consolidate', 'No database found')
    process.exit(1)
  }

  const result = consolidate()

  // Log errors if any
  for (const error of result.errors) {
    logError('consolidate', error)
  }

  // Output JSON for programmatic use
  process.stdout.write(JSON.stringify(result, null, 2) + '\n')
}

// Run if called directly
if (import.meta.main) {
  main()
}

export { consolidate, calculateDecayScore, jaccardSimilarity }
