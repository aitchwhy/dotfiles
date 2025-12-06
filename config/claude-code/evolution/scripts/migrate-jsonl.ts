#!/usr/bin/env bun
/**
 * JSONL to SQLite Migration Script
 *
 * Migrates existing data from:
 * - ~/.claude-metrics/history.jsonl → evolution_cycles + grader_runs
 * - config/claude-code/evolution/lessons/lessons.jsonl → lessons
 */
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { getDB, closeDB } from '../src/db/client';
import type { EvolutionCycleInsert, GraderRunInsert, LessonInsert } from '../src/db/schema';

const HOME = process.env['HOME'] ?? '';
const DOTFILES = process.env['DOTFILES'] ?? join(HOME, 'dotfiles');
const METRICS_DIR = join(HOME, 'dotfiles', '.claude-metrics');

// ============================================================================
// JSONL Types (from old format)
// ============================================================================

interface OldGraderResult {
  grader: string;
  score: number;
  passed: boolean;
  issues: string[];
}

interface OldHistoryEntry {
  timestamp: string;
  overall_score: number;
  recommendation: string;
  graders: OldGraderResult[];
}

interface OldLesson {
  timestamp?: string;
  created_at?: string;
  lesson: string;
  source?: string;
  category?: string;
}

// ============================================================================
// Migration Functions
// ============================================================================

function parseJsonl<T>(content: string): T[] {
  return content
    .split('\n')
    .filter((line) => line.trim())
    .map((line) => JSON.parse(line) as T);
}

async function migrateHistory(): Promise<{ cycles: number; runs: number }> {
  const historyPath = join(METRICS_DIR, 'history.jsonl');

  if (!existsSync(historyPath)) {
    console.log('No history.jsonl found, skipping...');
    return { cycles: 0, runs: 0 };
  }

  const content = readFileSync(historyPath, 'utf-8');
  const entries = parseJsonl<OldHistoryEntry>(content);

  const dbResult = getDB();
  if (!dbResult.ok) {
    throw new Error(`Database error: ${dbResult.error.message}`);
  }

  const db = dbResult.data;
  let cycleCount = 0;
  let runCount = 0;

  for (const entry of entries) {
    // Map recommendation to new enum
    let recommendation: 'stable' | 'improve' | 'urgent';
    switch (entry.recommendation) {
      case 'stable':
        recommendation = 'stable';
        break;
      case 'urgent':
        recommendation = 'urgent';
        break;
      default:
        recommendation = 'improve';
    }

    const cycleInsert: EvolutionCycleInsert = {
      started_at: entry.timestamp,
      ended_at: entry.timestamp,
      overall_score: entry.overall_score,
      recommendation,
      trigger: 'manual',
      session_id: null,
      proposals: null,
      applied_proposals: null,
    };

    const cycleResult = db.insertEvolutionCycle(cycleInsert);
    if (!cycleResult.ok) {
      console.error(`Failed to insert cycle: ${cycleResult.error.message}`);
      continue;
    }

    cycleCount++;

    // Insert grader runs
    for (const grader of entry.graders) {
      const runInsert: GraderRunInsert = {
        evolution_cycle_id: cycleResult.data.id,
        grader_name: grader.grader,
        started_at: entry.timestamp,
        ended_at: entry.timestamp,
        score: grader.score,
        passed: grader.passed,
        issues: JSON.stringify(grader.issues.map((msg) => ({ message: msg, severity: 'warning' }))),
        raw_output: null,
        execution_time_ms: null,
      };

      const runResult = db.insertGraderRun(runInsert);
      if (runResult.ok) {
        runCount++;
      }
    }
  }

  return { cycles: cycleCount, runs: runCount };
}

async function migrateLessons(): Promise<number> {
  const lessonsPath = join(DOTFILES, 'config', 'claude-code', 'evolution', 'lessons', 'lessons.jsonl');

  if (!existsSync(lessonsPath)) {
    console.log('No lessons.jsonl found, skipping...');
    return 0;
  }

  const content = readFileSync(lessonsPath, 'utf-8');
  if (!content.trim()) {
    console.log('lessons.jsonl is empty, skipping...');
    return 0;
  }

  const entries = parseJsonl<OldLesson>(content);

  const dbResult = getDB();
  if (!dbResult.ok) {
    throw new Error(`Database error: ${dbResult.error.message}`);
  }

  const db = dbResult.data;
  let count = 0;

  for (const entry of entries) {
    const timestamp = entry.timestamp ?? entry.created_at ?? new Date().toISOString();

    const lessonInsert: LessonInsert = {
      created_at: timestamp,
      lesson: entry.lesson,
      source: (entry.source as 'reflection' | 'session' | 'manual' | 'grader') ?? 'manual',
      category: entry.category ?? null,
      confidence: 1.0,
    };

    const result = db.insertLesson(lessonInsert);
    if (result.ok) {
      count++;
    }
  }

  return count;
}

// ============================================================================
// Main
// ============================================================================

async function main() {
  console.log('🔄 JSONL to SQLite Migration\n');
  console.log('='.repeat(50));

  try {
    console.log('\n📊 Migrating history.jsonl...');
    const historyResult = await migrateHistory();
    console.log(`   Migrated ${historyResult.cycles} evolution cycles`);
    console.log(`   Migrated ${historyResult.runs} grader runs`);

    console.log('\n📚 Migrating lessons.jsonl...');
    const lessonCount = await migrateLessons();
    console.log(`   Migrated ${lessonCount} lessons`);

    console.log('\n✅ Migration complete!');
    console.log(`   Database: ${join(METRICS_DIR, 'evolution.db')}`);
  } catch (err) {
    console.error('\n❌ Migration failed:', err);
    process.exit(1);
  } finally {
    closeDB();
  }

  console.log('\n' + '='.repeat(50));
}

main();
