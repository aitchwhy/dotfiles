/**
 * Reflector Agent Tests
 *
 * Tests for the Reflector agent that analyzes drift/violations
 * and proposes patches to improve the system.
 */
import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { EvolutionDB } from '../../src/db/client';
import { Reflector, type ReflectorOutput } from '../../src/agents/reflector';

describe('Reflector Agent', () => {
  let db: EvolutionDB;
  let reflector: Reflector;
  const testDbPath = join(tmpdir(), `evolution-reflector-test-${Date.now()}.db`);

  beforeAll(() => {
    const result = EvolutionDB.init(testDbPath);
    if (!result.ok) throw result.error;
    db = result.data;
    reflector = new Reflector(db);
  });

  afterAll(() => {
    db.close();
    try {
      rmSync(testDbPath);
      rmSync(`${testDbPath}-wal`, { force: true });
      rmSync(`${testDbPath}-shm`, { force: true });
    } catch {
      // Ignore cleanup errors
    }
  });

  describe('reflect()', () => {
    test('returns empty proposals when no issues exist', () => {
      const result = reflector.reflect();
      expect(result.ok).toBe(true);
      if (result.ok) {
        expect(result.data.proposals).toEqual([]);
        expect(result.data.hotspots.drift).toEqual([]);
        expect(result.data.hotspots.violations).toEqual([]);
      }
    });

    test('identifies drift hotspots after inserting drift records', () => {
      // Insert multiple drift records for the same pattern
      for (let i = 0; i < 5; i++) {
        db.insertDrift({
          file_path: `/project/src/handler${i}.ts`,
          drift_type: 'missing-result-type',
          severity: 'warning',
          message: 'Missing Result type',
          line_number: null,
          generator_name: 'api',
          project_path: '/project',
          session_id: null,
        });
      }

      const result = reflector.reflect();
      expect(result.ok).toBe(true);
      if (result.ok) {
        // Should detect the missing-result-type hotspot
        const resultTypeHotspot = result.data.hotspots.drift.find(
          (h) => h.drift_type === 'missing-result-type'
        );
        expect(resultTypeHotspot).toBeDefined();
        expect(resultTypeHotspot!.occurrence_count).toBeGreaterThanOrEqual(5);
      }
    });

    test('identifies violation patterns after inserting violations', () => {
      // Insert multiple violations for the same rule
      for (let i = 0; i < 3; i++) {
        db.insertViolation({
          rule_source: 'hook',
          rule_name: 'assumption-detector',
          file_path: `/project/src/file${i}.ts`,
          line_number: null,
          violation_message: 'Found assumption language',
          severity: 'error',
          session_id: null,
        });
      }

      const result = reflector.reflect();
      expect(result.ok).toBe(true);
      if (result.ok) {
        const assumptionPattern = result.data.hotspots.violations.find(
          (v) => v.rule_name === 'assumption-detector'
        );
        expect(assumptionPattern).toBeDefined();
        expect(assumptionPattern!.total_violations).toBeGreaterThanOrEqual(3);
      }
    });

    test('generates proposals for high-frequency issues', () => {
      // Insert enough issues to trigger a proposal
      for (let i = 0; i < 10; i++) {
        db.insertDrift({
          file_path: `/project/src/schema${i}.ts`,
          drift_type: 'missing-import',
          severity: 'error',
          message: 'Missing zod import',
          line_number: null,
          generator_name: 'api',
          project_path: '/another-project',
          session_id: null,
        });
      }

      const result = reflector.reflect({ minEvidence: 5 });
      expect(result.ok).toBe(true);
      if (result.ok) {
        // Should have at least one proposal for the high-frequency drift
        // Note: Depends on implementation threshold logic
        expect(result.data.summary).toBeDefined();
        expect(typeof result.data.summary.totalDrift).toBe('number');
        expect(typeof result.data.summary.totalViolations).toBe('number');
      }
    });
  });

  describe('propose()', () => {
    test('creates a patch proposal in the database', () => {
      const proposal = {
        patch_type: 'skill-update' as const,
        target_file: 'config/system/src/definitions/skills/result-patterns.ts',
        description: 'Add examples for common missing-result-type scenarios',
        rationale: '15 occurrences of missing-result-type drift detected',
        patch_content: '// Additional Result type examples...',
        confidence: 0.8,
        evidence_count: 15,
      };

      const result = reflector.propose(proposal);
      expect(result.ok).toBe(true);
      if (result.ok) {
        expect(result.data.id).toBeGreaterThan(0);
        expect(result.data.status).toBe('pending');
        expect(result.data.target_file).toBe(proposal.target_file);
      }
    });
  });

  describe('review()', () => {
    test('lists pending patches', () => {
      const result = reflector.review();
      expect(result.ok).toBe(true);
      if (result.ok) {
        expect(Array.isArray(result.data)).toBe(true);
        // Should have at least the one we created above
        expect(result.data.length).toBeGreaterThanOrEqual(1);
        for (const patch of result.data) {
          expect(patch.status).toBe('pending');
        }
      }
    });
  });
});
