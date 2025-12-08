import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'bun:test';
import { existsSync, mkdirSync, rmSync } from 'node:fs';
import { dirname } from 'node:path';
import { EvolutionDB } from './client';

/**
 * Tests for Evolution Database Client
 *
 * Focus: Auto-GC functionality for lessons management
 */
describe('EvolutionDB', () => {
  const TEST_DB_PATH = '/tmp/evolution-test.db';

  beforeAll(() => {
    // Ensure test directory exists
    const dbDir = dirname(TEST_DB_PATH);
    if (!existsSync(dbDir)) {
      mkdirSync(dbDir, { recursive: true });
    }
  });

  beforeEach(() => {
    // Clean up before each test
    if (existsSync(TEST_DB_PATH)) {
      rmSync(TEST_DB_PATH);
    }
    // Also remove WAL files
    if (existsSync(`${TEST_DB_PATH}-wal`)) {
      rmSync(`${TEST_DB_PATH}-wal`);
    }
    if (existsSync(`${TEST_DB_PATH}-shm`)) {
      rmSync(`${TEST_DB_PATH}-shm`);
    }
  });

  afterAll(() => {
    // Final cleanup
    if (existsSync(TEST_DB_PATH)) {
      rmSync(TEST_DB_PATH);
    }
    if (existsSync(`${TEST_DB_PATH}-wal`)) {
      rmSync(`${TEST_DB_PATH}-wal`);
    }
    if (existsSync(`${TEST_DB_PATH}-shm`)) {
      rmSync(`${TEST_DB_PATH}-shm`);
    }
  });

  describe('getLessonCount', () => {
    test('returns 0 for empty database', () => {
      const result = EvolutionDB.init(TEST_DB_PATH);
      expect(result.ok).toBe(true);
      if (!result.ok) return;

      const db = result.data;
      const countResult = db.getLessonCount();

      expect(countResult.ok).toBe(true);
      if (countResult.ok) {
        expect(countResult.data).toBe(0);
      }

      db.close();
    });

    test('returns correct count after inserting lessons', () => {
      const result = EvolutionDB.init(TEST_DB_PATH);
      expect(result.ok).toBe(true);
      if (!result.ok) return;

      const db = result.data;

      // Insert 3 lessons
      for (let i = 0; i < 3; i++) {
        db.insertLesson({
          created_at: new Date().toISOString(),
          lesson: `Test lesson ${i}`,
          source: 'manual',
          category: 'test',
          confidence: 1.0,
        });
      }

      const countResult = db.getLessonCount();
      expect(countResult.ok).toBe(true);
      if (countResult.ok) {
        expect(countResult.data).toBe(3);
      }

      db.close();
    });
  });

  describe('deleteGarbageLessons', () => {
    test('deletes lessons with JSON fragment patterns', () => {
      const result = EvolutionDB.init(TEST_DB_PATH);
      expect(result.ok).toBe(true);
      if (!result.ok) return;

      const db = result.data;

      // Insert garbage lessons (JSON fragments from Claude API)
      const garbageLessons = [
        '    "thinking": "The user wants..."',
        '    "text": "I will help you..."',
        '      "prompt": "Explore the codebase..."',
        '      "content": "# HOMELAB.md..."',
        '              "label": "Always-on dev server"',
      ];

      for (const lesson of garbageLessons) {
        db.insertLesson({
          created_at: new Date().toISOString(),
          lesson,
          source: 'session',
          category: null,
          confidence: 1.0,
        });
      }

      // Insert a real lesson
      db.insertLesson({
        created_at: new Date().toISOString(),
        lesson: 'Use Result types for error handling',
        source: 'manual',
        category: 'typescript',
        confidence: 1.0,
      });

      // Verify we have 6 lessons
      let countResult = db.getLessonCount();
      expect(countResult.ok).toBe(true);
      if (countResult.ok) {
        expect(countResult.data).toBe(6);
      }

      // Delete garbage
      const deleteResult = db.deleteGarbageLessons();
      expect(deleteResult.ok).toBe(true);
      if (deleteResult.ok) {
        expect(deleteResult.data).toBe(5); // 5 garbage lessons deleted
      }

      // Verify only 1 remains
      countResult = db.getLessonCount();
      expect(countResult.ok).toBe(true);
      if (countResult.ok) {
        expect(countResult.data).toBe(1);
      }

      db.close();
    });

    test('deletes lessons starting with JSON syntax', () => {
      const result = EvolutionDB.init(TEST_DB_PATH);
      expect(result.ok).toBe(true);
      if (!result.ok) return;

      const db = result.data;

      // Insert JSON-like garbage
      db.insertLesson({
        created_at: new Date().toISOString(),
        lesson: '{"key": "value"}',
        source: 'session',
        category: null,
        confidence: 1.0,
      });

      db.insertLesson({
        created_at: new Date().toISOString(),
        lesson: '["item1", "item2"]',
        source: 'session',
        category: null,
        confidence: 1.0,
      });

      // Insert real lesson
      db.insertLesson({
        created_at: new Date().toISOString(),
        lesson: 'TDD: Red-Green-Refactor cycle',
        source: 'manual',
        category: 'testing',
        confidence: 1.0,
      });

      const deleteResult = db.deleteGarbageLessons();
      expect(deleteResult.ok).toBe(true);
      if (deleteResult.ok) {
        expect(deleteResult.data).toBe(2);
      }

      const countResult = db.getLessonCount();
      expect(countResult.ok).toBe(true);
      if (countResult.ok) {
        expect(countResult.data).toBe(1);
      }

      db.close();
    });
  });

  describe('compactLessons', () => {
    test('does nothing when below threshold', () => {
      const result = EvolutionDB.init(TEST_DB_PATH);
      expect(result.ok).toBe(true);
      if (!result.ok) return;

      const db = result.data;

      // Insert 5 lessons (below default threshold of 20)
      for (let i = 0; i < 5; i++) {
        db.insertLesson({
          created_at: new Date().toISOString(),
          lesson: `Test lesson ${i}`,
          source: 'manual',
          category: 'test',
          confidence: 1.0,
        });
      }

      const compactResult = db.compactLessons(20);
      expect(compactResult.ok).toBe(true);
      if (compactResult.ok) {
        expect(compactResult.data).toBe(0); // Nothing deleted
      }

      const countResult = db.getLessonCount();
      expect(countResult.ok).toBe(true);
      if (countResult.ok) {
        expect(countResult.data).toBe(5);
      }

      db.close();
    });

    test('removes oldest lessons when above threshold', () => {
      const result = EvolutionDB.init(TEST_DB_PATH);
      expect(result.ok).toBe(true);
      if (!result.ok) return;

      const db = result.data;

      // Insert 10 lessons with staggered timestamps
      for (let i = 0; i < 10; i++) {
        const date = new Date();
        date.setMinutes(date.getMinutes() - (10 - i)); // Older first
        db.insertLesson({
          created_at: date.toISOString(),
          lesson: `Lesson ${i} (${i < 5 ? 'old' : 'new'})`,
          source: 'manual',
          category: 'test',
          confidence: 1.0,
        });
      }

      // Compact to keep only 5
      const compactResult = db.compactLessons(5);
      expect(compactResult.ok).toBe(true);
      if (compactResult.ok) {
        expect(compactResult.data).toBe(5); // 5 deleted
      }

      // Verify 5 remain
      const countResult = db.getLessonCount();
      expect(countResult.ok).toBe(true);
      if (countResult.ok) {
        expect(countResult.data).toBe(5);
      }

      // Verify the remaining are the newest ones
      const lessonsResult = db.getAllLessons();
      expect(lessonsResult.ok).toBe(true);
      if (lessonsResult.ok) {
        for (const lesson of lessonsResult.data) {
          expect(lesson.lesson).toContain('new');
        }
      }

      db.close();
    });
  });

  describe('deleteStaleLessons', () => {
    test('deletes old lessons with low application count', () => {
      const result = EvolutionDB.init(TEST_DB_PATH);
      expect(result.ok).toBe(true);
      if (!result.ok) return;

      const db = result.data;

      // Insert old, unused lesson (31 days ago)
      const oldDate = new Date();
      oldDate.setDate(oldDate.getDate() - 31);
      db.insertLesson({
        created_at: oldDate.toISOString(),
        lesson: 'Old unused lesson',
        source: 'session',
        category: 'test',
        confidence: 1.0,
        times_applied: 0,
      });

      // Insert recent lesson
      db.insertLesson({
        created_at: new Date().toISOString(),
        lesson: 'Recent lesson',
        source: 'manual',
        category: 'test',
        confidence: 1.0,
      });

      const deleteResult = db.deleteStaleLessons(30, 2);
      expect(deleteResult.ok).toBe(true);
      if (deleteResult.ok) {
        expect(deleteResult.data).toBe(1); // Old lesson deleted
      }

      const countResult = db.getLessonCount();
      expect(countResult.ok).toBe(true);
      if (countResult.ok) {
        expect(countResult.data).toBe(1);
      }

      db.close();
    });

    test('keeps old lessons with high application count', () => {
      const result = EvolutionDB.init(TEST_DB_PATH);
      expect(result.ok).toBe(true);
      if (!result.ok) return;

      const db = result.data;

      // Insert old but frequently used lesson
      const oldDate = new Date();
      oldDate.setDate(oldDate.getDate() - 60);
      db.insertLesson({
        created_at: oldDate.toISOString(),
        lesson: 'Old but useful lesson',
        source: 'manual',
        category: 'test',
        confidence: 1.0,
        times_applied: 10, // Used many times
      });

      const deleteResult = db.deleteStaleLessons(30, 2);
      expect(deleteResult.ok).toBe(true);
      if (deleteResult.ok) {
        expect(deleteResult.data).toBe(0); // Not deleted due to high usage
      }

      db.close();
    });
  });

  describe('autoGC', () => {
    test('runs full garbage collection cycle', () => {
      const result = EvolutionDB.init(TEST_DB_PATH);
      expect(result.ok).toBe(true);
      if (!result.ok) return;

      const db = result.data;

      // Insert garbage lesson
      db.insertLesson({
        created_at: new Date().toISOString(),
        lesson: '    "thinking": "garbage"',
        source: 'session',
        category: null,
        confidence: 1.0,
      });

      // Insert old stale lesson
      const oldDate = new Date();
      oldDate.setDate(oldDate.getDate() - 45);
      db.insertLesson({
        created_at: oldDate.toISOString(),
        lesson: 'Old unused lesson',
        source: 'session',
        category: 'test',
        confidence: 1.0,
        times_applied: 0,
      });

      // Insert 25 recent lessons (above threshold of 20)
      for (let i = 0; i < 25; i++) {
        const date = new Date();
        date.setMinutes(date.getMinutes() - i);
        db.insertLesson({
          created_at: date.toISOString(),
          lesson: `Recent lesson ${i}`,
          source: 'manual',
          category: 'test',
          confidence: 1.0,
        });
      }

      // Verify we have 27 total
      let countResult = db.getLessonCount();
      expect(countResult.ok).toBe(true);
      if (countResult.ok) {
        expect(countResult.data).toBe(27);
      }

      // Run autoGC
      const gcResult = db.autoGC(20, 30);
      expect(gcResult.ok).toBe(true);
      if (gcResult.ok) {
        expect(gcResult.data.garbage).toBe(1); // 1 garbage deleted
        expect(gcResult.data.stale).toBe(1); // 1 stale deleted
        expect(gcResult.data.compacted).toBe(5); // Compacted from 25 to 20
      }

      // Verify final count is 20
      countResult = db.getLessonCount();
      expect(countResult.ok).toBe(true);
      if (countResult.ok) {
        expect(countResult.data).toBe(20);
      }

      db.close();
    });
  });
});
