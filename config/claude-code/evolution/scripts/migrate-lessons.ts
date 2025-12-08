#!/usr/bin/env bun
/**
 * Lessons Migration Script
 *
 * - Removes garbage lessons (JSON fragments from Claude API responses)
 * - Consolidates real lessons into generic, high-impact ones
 * - Adds new foundational lessons
 */
import { Database } from 'bun:sqlite';
import { existsSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

const DB_PATH = `${process.env['HOME']}/dotfiles/.claude-metrics/evolution.db`;

// High-impact consolidated lessons to replace the garbage
const CONSOLIDATED_LESSONS = [
  // Nix/Direnv
  {
    lesson:
      'Nix direnv: IN_NIX_SHELL=impure is normal for `nix develop`. Cache in .direnv/flake-profile-*. Clear with `rm -rf .direnv/ && direnv allow`. Side-effects in shellHook, not .envrc.',
    source: 'session',
    category: 'nix',
    confidence: 1.0,
  },
  // Ember Platform
  {
    lesson:
      'Ember platform: API on Fly.io (Hono+Bun), Web on Cloudflare Pages (React+TanStack Router+Query), DB on Neon Postgres, Storage on Cloudflare R2, Voice on LiveKit.',
    source: 'session',
    category: 'ember',
    confidence: 1.0,
  },
  // TypeScript Patterns
  {
    lesson:
      'TypeScript: Use Result<T,E> for fallible operations (never throw for expected failures). Branded types for IDs. Zod schema → TS type (never reverse). No `any`.',
    source: 'manual',
    category: 'typescript',
    confidence: 1.0,
  },
  // Testing
  {
    lesson:
      'TDD: Red (failing test) → Green (minimal pass) → Refactor (improve). Test file before source file. Hierarchy: E2E (few) → Integration (moderate) → Unit (many).',
    source: 'manual',
    category: 'testing',
    confidence: 1.0,
  },
  // Git
  {
    lesson:
      'Git: Conventional commits (feat/fix/refactor/test/docs/chore). Atomic commits. Never commit broken code. Rebase over merge. Never amend pushed commits.',
    source: 'manual',
    category: 'git',
    confidence: 1.0,
  },
  // Verification-First
  {
    lesson:
      'Verification-first: "should work" is BANNED. Use "VERIFIED via [test]: [assertion]" or "UNVERIFIED: requires [test]". Every claim needs test evidence.',
    source: 'manual',
    category: 'verification',
    confidence: 1.0,
  },
  // Hooks
  {
    lesson:
      'Claude Code hooks: Exit 0 = allow (parse JSON), Exit 2 = block (stderr as error), Exit 1 = non-blocking error. PreToolUse for prevention, Stop for session gates.',
    source: 'session',
    category: 'hooks',
    confidence: 1.0,
  },
  // Schema-First
  {
    lesson:
      'Schema-first: Zod (TS) and Pydantic (Python) are source of truth. Types, API contracts, and DB interfaces derive from schemas. Parse at boundaries, trust internally.',
    source: 'manual',
    category: 'patterns',
    confidence: 1.0,
  },
];

async function main() {
  console.log('🔄 Lessons Migration Script\n');

  // Ensure directory exists
  const dbDir = dirname(DB_PATH);
  if (!existsSync(dbDir)) {
    mkdirSync(dbDir, { recursive: true });
  }

  if (!existsSync(DB_PATH)) {
    console.error(`❌ Database not found: ${DB_PATH}`);
    process.exit(1);
  }

  const db = new Database(DB_PATH);

  try {
    // Step 1: Count current lessons
    const countBefore = db
      .query<{ count: number }, []>('SELECT COUNT(*) as count FROM lessons')
      .get();
    console.log(`📊 Current lessons: ${countBefore?.count ?? 0}`);

    // Step 2: Identify garbage lessons (JSON fragments start with common patterns)
    const garbagePatterns = [
      '    "thinking":%',
      '    "text":%',
      '      "prompt":%',
      '      "content":%',
      '              "label":%',
    ];

    // Delete garbage lessons
    console.log('\n🗑️  Removing garbage lessons...');
    let deletedCount = 0;

    for (const pattern of garbagePatterns) {
      const result = db.run(`DELETE FROM lessons WHERE lesson LIKE ?`, [pattern]);
      deletedCount += result.changes;
    }

    // Also delete any lesson that starts with JSON-like patterns
    const jsonResult = db.run(
      `DELETE FROM lessons WHERE lesson LIKE '{%' OR lesson LIKE '[%' OR lesson LIKE '"%'`
    );
    deletedCount += jsonResult.changes;

    console.log(`   Deleted ${deletedCount} garbage lessons`);

    // Step 3: Check remaining lessons
    const remaining = db
      .query<{ id: number; lesson: string }, []>('SELECT id, lesson FROM lessons ORDER BY id')
      .all();
    console.log(`\n📚 Remaining real lessons: ${remaining.length}`);

    for (const lesson of remaining) {
      const preview =
        lesson.lesson.length > 60 ? `${lesson.lesson.slice(0, 60)}...` : lesson.lesson;
      console.log(`   [${lesson.id}] ${preview}`);
    }

    // Step 4: Clear all and insert consolidated lessons
    console.log('\n🔄 Replacing with consolidated high-impact lessons...');
    db.run('DELETE FROM lessons');

    const insertStmt = db.prepare(`
      INSERT INTO lessons (created_at, lesson, source, category, confidence, times_applied, last_applied_at)
      VALUES (?, ?, ?, ?, ?, 0, NULL)
    `);

    const now = new Date().toISOString();
    for (const lesson of CONSOLIDATED_LESSONS) {
      insertStmt.run(now, lesson.lesson, lesson.source, lesson.category, lesson.confidence);
    }

    // Step 5: Verify final state
    const countAfter = db
      .query<{ count: number }, []>('SELECT COUNT(*) as count FROM lessons')
      .get();
    console.log(`\n✅ Migration complete: ${countAfter?.count ?? 0} consolidated lessons`);

    // List new lessons
    const newLessons = db
      .query<{ id: number; category: string; lesson: string }, []>(
        'SELECT id, category, lesson FROM lessons ORDER BY category, id'
      )
      .all();

    console.log('\n📚 New Lessons:');
    for (const lesson of newLessons) {
      const preview =
        lesson.lesson.length > 70 ? `${lesson.lesson.slice(0, 70)}...` : lesson.lesson;
      console.log(`   [${lesson.category}] ${preview}`);
    }
  } finally {
    db.close();
  }
}

main().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
