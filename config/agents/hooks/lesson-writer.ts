#!/usr/bin/env bun
/**
 * lesson-writer.ts - Automated lesson capture from Claude sessions
 *
 * Hook: session-stop (Stop hook on session completion)
 *
 * Analyzes session transcripts for insights and stores them in SQLite.
 * Then triggers consolidation for dedup/decay/archive.
 *
 * Security: Uses bun:sqlite for parameterized queries (no SQL injection)
 */

import { Database } from 'bun:sqlite';
import { spawn } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, realpathSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { homedir } from 'node:os';

// Configuration
const HOME = homedir();
const METRICS_DIR = join(HOME, '.claude-metrics');
const DB_FILE = join(METRICS_DIR, 'evolution.db');
const CONSOLIDATE_SCRIPT = join(HOME, 'dotfiles/config/agents/evolution/consolidate.ts');

// Lesson categories
const LESSON_CATEGORIES = ['bug', 'pattern', 'optimization', 'gotcha', 'workflow'] as const;
type LessonCategory = typeof LESSON_CATEGORIES[number];

type Lesson = {
  readonly date: string;
  readonly category: LessonCategory;
  readonly lesson: string;
  readonly evidence: string;
  readonly source: 'claude' | 'manual';
};

// Patterns that indicate a lesson-worthy insight
const LESSON_PATTERNS: Record<LessonCategory, readonly RegExp[]> = {
  bug: [
    /fixed\s+(?:the\s+)?(?:a\s+)?bug\s+(?:where|in|with)/i,
    /the\s+issue\s+was/i,
    /root\s+cause\s+was/i,
    /problem\s+was\s+(?:that|caused)/i,
    /the\s+error\s+(?:was|occurred)/i,
  ],
  pattern: [
    /this\s+pattern\s+(?:works|is\s+better)/i,
    /the\s+(?:correct|proper|right)\s+way\s+to/i,
    /should\s+(?:always|never)\s+use/i,
    /prefer\s+\w+\s+over\s+\w+/i,
    /best\s+practice\s+is/i,
  ],
  optimization: [
    /improved\s+(?:performance|speed)/i,
    /reduced\s+(?:latency|time|memory)/i,
    /cache\s+(?:hit|miss)/i,
    /\d+x\s+faster/i,
    /optimiz(?:e|ed|ation)/i,
  ],
  gotcha: [
    /gotcha|caveat|watch\s+out/i,
    /common\s+mistake/i,
    /easy\s+to\s+forget/i,
    /subtle\s+(?:bug|issue)/i,
    /important\s+to\s+(?:note|remember)/i,
  ],
  workflow: [
    /workflow\s+(?:improvement|tip)/i,
    /better\s+approach\s+is/i,
    /instead\s+of\s+\w+,\s+use/i,
    /streamlined?\s+(?:the\s+)?process/i,
  ],
};

/**
 * Validate that a path is within expected directories (security)
 */
function validatePath(path: string, allowedPrefixes: readonly string[]): boolean {
  try {
    const realPath = realpathSync(resolve(path));
    return allowedPrefixes.some(prefix => realPath.startsWith(prefix));
  } catch {
    return false;
  }
}

/**
 * Initialize database with proper schema if needed
 */
function initDb(): Database | null {
  if (!existsSync(METRICS_DIR)) {
    mkdirSync(METRICS_DIR, { recursive: true });
  }

  try {
    const db = new Database(DB_FILE);

    // Create tables if they don't exist
    db.run(`
      CREATE TABLE IF NOT EXISTS lessons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        category TEXT NOT NULL CHECK(category IN ('bug', 'pattern', 'optimization', 'gotcha', 'workflow')),
        lesson TEXT NOT NULL CHECK(length(lesson) > 0),
        evidence TEXT NOT NULL,
        source TEXT DEFAULT 'claude',
        occurrence_count INTEGER DEFAULT 1,
        last_accessed TEXT,
        decay_score REAL DEFAULT 1.0,
        created_at TEXT DEFAULT (datetime('now'))
      )
    `);

    db.run('CREATE INDEX IF NOT EXISTS idx_lessons_active ON lessons(decay_score DESC)');
    db.run('CREATE INDEX IF NOT EXISTS idx_lessons_category ON lessons(category)');
    db.run('CREATE INDEX IF NOT EXISTS idx_lessons_date ON lessons(date)');

    db.run(`
      CREATE TABLE IF NOT EXISTS lessons_archive (
        id INTEGER PRIMARY KEY,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        lesson TEXT NOT NULL,
        evidence TEXT,
        occurrence_count INTEGER,
        archived_at TEXT DEFAULT (datetime('now'))
      ) WITHOUT ROWID
    `);

    return db;
  } catch (error) {
    console.error(`[lesson-writer] Failed to initialize database: ${error}`);
    return null;
  }
}

/**
 * Store lesson in SQLite using parameterized query
 */
function storeLesson(db: Database, lesson: Lesson): boolean {
  try {
    const stmt = db.query(`
      INSERT INTO lessons (date, category, lesson, evidence, source, occurrence_count, decay_score, created_at)
      VALUES (?, ?, ?, ?, ?, 1, 1.0, datetime('now'))
    `);

    stmt.run(lesson.date, lesson.category, lesson.lesson, lesson.evidence, lesson.source);
    return true;
  } catch (error) {
    console.error(`[lesson-writer] Failed to store lesson: ${error}`);
    return false;
  }
}

/**
 * Detect lesson category from text
 */
function detectCategory(text: string): LessonCategory | null {
  for (const [category, patterns] of Object.entries(LESSON_PATTERNS)) {
    for (const pattern of patterns) {
      if (pattern.test(text)) {
        return category as LessonCategory;
      }
    }
  }
  return null;
}

/**
 * Parse JSONL transcript file
 */
function parseTranscript(filePath: string): string[] {
  // Validate path is within expected locations
  if (!validatePath(filePath, [HOME])) {
    console.error('[lesson-writer] Invalid transcript path');
    return [];
  }

  try {
    const content = readFileSync(filePath, 'utf-8');
    const lines = content.split('\n').filter((l) => l.trim());
    const assistantMessages: string[] = [];

    for (const line of lines) {
      try {
        const obj = JSON.parse(line) as {
          type?: string;
          message?: { content?: unknown };
        };

        // Extract assistant messages
        if (obj.type === 'assistant' && obj.message?.content) {
          const textBlocks = Array.isArray(obj.message.content)
            ? obj.message.content
                .filter((b: { type: string }) => b.type === 'text')
                .map((b: { text: string }) => b.text)
            : [obj.message.content as string];
          assistantMessages.push(...textBlocks);
        }
      } catch {
        // Skip malformed lines
      }
    }

    return assistantMessages;
  } catch (error) {
    console.error(`[lesson-writer] Failed to parse transcript: ${error}`);
    return [];
  }
}

/**
 * Extract lessons from session content
 */
function extractLessons(messages: readonly string[]): Lesson[] {
  const lessons: Lesson[] = [];
  const date = new Date().toISOString().split('T')[0];
  const seen = new Set<string>();

  for (const message of messages) {
    // Split into paragraphs/sections
    const sections = message.split(/\n\n+/);

    for (const section of sections) {
      const category = detectCategory(section);
      if (!category) continue;

      // Skip if too short
      if (section.length < 50) continue;

      // Skip if it looks like code
      if (section.startsWith('```') || /^\s{4,}/.test(section)) continue;

      // Extract a concise lesson statement
      const lines = section.split('\n').filter((l) => l.trim().length > 0);
      const lessonText = lines[0].slice(0, 200); // First line, capped

      // Deduplicate within session
      const key = `${category}:${lessonText.slice(0, 50)}`;
      if (seen.has(key)) continue;
      seen.add(key);

      // Use full section as evidence
      const evidence = section.slice(0, 500);

      lessons.push({
        date,
        category,
        lesson: lessonText,
        evidence,
        source: 'claude',
      });
    }
  }

  return lessons;
}

/**
 * Trigger consolidation in background with error logging
 */
function triggerConsolidation(): void {
  if (!existsSync(CONSOLIDATE_SCRIPT)) {
    console.error('[lesson-writer] Consolidation script not found');
    return;
  }

  // Validate path
  if (!validatePath(CONSOLIDATE_SCRIPT, [HOME])) {
    console.error('[lesson-writer] Invalid consolidation script path');
    return;
  }

  try {
    // Spawn in background with error logging
    const child = spawn('bun', ['run', CONSOLIDATE_SCRIPT], {
      detached: true,
      stdio: ['ignore', 'ignore', 'pipe'], // Capture stderr
    });

    // Log any errors from the spawned process
    if (child.stderr) {
      child.stderr.on('data', (data: Buffer) => {
        console.error(`[consolidate] ${data.toString().trim()}`);
      });
    }

    child.on('error', (err) => {
      console.error(`[lesson-writer] Failed to spawn consolidation: ${err}`);
    });

    child.unref();
  } catch (error) {
    console.error(`[lesson-writer] Consolidation trigger failed: ${error}`);
  }
}

/**
 * Main execution
 */
async function main(): Promise<void> {
  // Check for transcript path as argument
  const transcriptPath = process.argv[2];

  if (!transcriptPath || !existsSync(transcriptPath)) {
    // No transcript to analyze
    process.exit(0);
  }

  // Initialize database
  const db = initDb();
  if (!db) {
    process.exit(1);
  }

  try {
    // Parse transcript
    const messages = parseTranscript(transcriptPath);

    if (messages.length === 0) {
      process.exit(0);
    }

    // Extract lessons
    const lessons = extractLessons(messages);

    if (lessons.length === 0) {
      process.exit(0);
    }

    // Store lessons
    let stored = 0;
    for (const lesson of lessons) {
      if (storeLesson(db, lesson)) {
        stored++;
        console.error(`[lesson-writer] Captured: ${lesson.category} - ${lesson.lesson.slice(0, 50)}...`);
      }
    }

    if (stored > 0) {
      console.error(`[lesson-writer] Captured ${stored} lesson(s)`);
      // Trigger consolidation
      triggerConsolidation();
    }
  } finally {
    db.close();
  }
}

main().catch((error) => {
  console.error(`[lesson-writer] Error: ${error}`);
  process.exit(1);
});
