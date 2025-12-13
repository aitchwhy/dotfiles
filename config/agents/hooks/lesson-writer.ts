#!/usr/bin/env bun
/**
 * lesson-writer.ts - Automated lesson capture from Claude sessions
 *
 * Hook: session-stop (PostToolUse on session completion)
 *
 * Analyzes session transcripts for insights and stores them in SQLite.
 * Lessons are structured with category, content, evidence, and source.
 */

import { execSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, writeFileSync, appendFileSync } from 'node:fs';
import { join } from 'node:path';
import { homedir } from 'node:os';

// Configuration
const METRICS_DIR = join(homedir(), '.claude-metrics');
const DB_FILE = join(METRICS_DIR, 'evolution.db');
const LESSONS_MD = join(homedir(), 'dotfiles/config/agents/memory/lessons.md');

// Lesson categories
type LessonCategory = 'bug' | 'pattern' | 'optimization' | 'gotcha' | 'workflow';

interface Lesson {
  readonly date: string;
  readonly category: LessonCategory;
  readonly lesson: string;
  readonly evidence: string;
  readonly source: 'claude' | 'manual';
}

// Patterns that indicate a lesson-worthy insight
const LESSON_PATTERNS = {
  bug: [
    /fixed\s+(?:the\s+)?(?:a\s+)?bug\s+(?:where|in|with)/i,
    /the\s+issue\s+was/i,
    /root\s+cause\s+was/i,
    /problem\s+was\s+(?:that|caused)/i,
  ],
  pattern: [
    /this\s+pattern\s+(?:works|is\s+better)/i,
    /the\s+(?:correct|proper|right)\s+way\s+to/i,
    /should\s+(?:always|never)\s+use/i,
    /prefer\s+\w+\s+over\s+\w+/i,
  ],
  optimization: [
    /improved\s+(?:performance|speed)/i,
    /reduced\s+(?:latency|time|memory)/i,
    /cache\s+(?:hit|miss)/i,
    /\d+x\s+faster/i,
  ],
  gotcha: [
    /gotcha|caveat|watch\s+out/i,
    /common\s+mistake/i,
    /easy\s+to\s+forget/i,
    /subtle\s+(?:bug|issue)/i,
  ],
  workflow: [
    /workflow\s+(?:improvement|tip)/i,
    /better\s+approach\s+is/i,
    /instead\s+of\s+\w+,\s+use/i,
  ],
};

// Initialize database if needed
function initDb(): void {
  if (!existsSync(METRICS_DIR)) {
    mkdirSync(METRICS_DIR, { recursive: true });
  }

  if (!existsSync(DB_FILE)) {
    execSync(`sqlite3 "${DB_FILE}" "
      CREATE TABLE IF NOT EXISTS lessons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        lesson TEXT NOT NULL,
        evidence TEXT NOT NULL,
        source TEXT DEFAULT 'claude'
      );
      CREATE INDEX IF NOT EXISTS idx_lessons_category ON lessons(category);
      CREATE INDEX IF NOT EXISTS idx_lessons_date ON lessons(date);
    "`);
  }
}

// Store lesson in SQLite
function storeLesson(lesson: Lesson): void {
  const escapedLesson = lesson.lesson.replace(/'/g, "''");
  const escapedEvidence = lesson.evidence.replace(/'/g, "''");

  execSync(`sqlite3 "${DB_FILE}" "
    INSERT INTO lessons (date, category, lesson, evidence, source)
    VALUES ('${lesson.date}', '${lesson.category}', '${escapedLesson}', '${escapedEvidence}', '${lesson.source}');
  "`);
}

// Append lesson to lessons.md
function appendToMarkdown(lesson: Lesson): void {
  if (!existsSync(LESSONS_MD)) {
    return;
  }

  const entry = `
## ${lesson.date} - ${lesson.category.toUpperCase()}

**Lesson**: ${lesson.lesson}

**Evidence**: ${lesson.evidence}

**Source**: ${lesson.source}

---
`;

  appendFileSync(LESSONS_MD, entry);
}

// Detect lesson category from text
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

// Extract lesson from session content
function extractLessons(sessionContent: string): Lesson[] {
  const lessons: Lesson[] = [];
  const date = new Date().toISOString().split('T')[0];

  // Split into paragraphs/sections
  const sections = sessionContent.split(/\n\n+/);

  for (const section of sections) {
    const category = detectCategory(section);
    if (!category) continue;

    // Skip if too short
    if (section.length < 50) continue;

    // Skip if it looks like code
    if (section.startsWith('```') || section.match(/^\s{4,}/)) continue;

    // Extract a concise lesson statement
    const lines = section.split('\n').filter((l) => l.trim().length > 0);
    const lessonText = lines[0].slice(0, 200); // First line, capped

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

  return lessons;
}

// Main execution
async function main(): Promise<void> {
  // Read session content from stdin (piped from session-stop hook)
  let sessionContent = '';

  // Check if we have stdin data
  if (!process.stdin.isTTY) {
    const chunks: Buffer[] = [];
    for await (const chunk of process.stdin) {
      chunks.push(chunk);
    }
    sessionContent = Buffer.concat(chunks).toString('utf-8');
  }

  // If no stdin, check for command line argument (file path)
  if (!sessionContent && process.argv[2]) {
    const filePath = process.argv[2];
    if (existsSync(filePath)) {
      sessionContent = readFileSync(filePath, 'utf-8');
    }
  }

  if (!sessionContent) {
    // No content to analyze
    process.exit(0);
  }

  // Initialize database
  initDb();

  // Extract lessons
  const lessons = extractLessons(sessionContent);

  if (lessons.length === 0) {
    // No lessons detected
    process.exit(0);
  }

  // Store lessons
  for (const lesson of lessons) {
    try {
      storeLesson(lesson);
      appendToMarkdown(lesson);
      console.error(`[lesson-writer] Captured: ${lesson.category} - ${lesson.lesson.slice(0, 50)}...`);
    } catch (error) {
      console.error(`[lesson-writer] Failed to store lesson: ${error}`);
    }
  }

  console.error(`[lesson-writer] Captured ${lessons.length} lesson(s)`);
}

main().catch((error) => {
  console.error(`[lesson-writer] Error: ${error}`);
  process.exit(1);
});
