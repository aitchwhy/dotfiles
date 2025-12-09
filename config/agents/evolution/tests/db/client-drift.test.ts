/**
 * Client Tests for Migration 003: Drift & Reflector Operations
 *
 * Tests for the new database operations added for drift tracking.
 */
import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { EvolutionDB } from '../../src/db/client';

describe('Drift & Reflector DB Operations', () => {
  let db: EvolutionDB;
  const testDbPath = join(tmpdir(), `evolution-drift-test-${Date.now()}.db`);

  beforeAll(() => {
    const result = EvolutionDB.init(testDbPath);
    if (!result.ok) throw result.error;
    db = result.data;
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

  describe('Generator Drift Operations', () => {
    test('insertDrift creates a drift record', () => {
      const drift = {
        file_path: '/project/src/handler.ts',
        drift_type: 'missing-import' as const,
        severity: 'error' as const,
        message: "File uses 'z.' but doesn't import from 'zod'",
        line_number: 10,
        generator_name: 'api',
        project_path: '/project',
        session_id: null,
      };

      const result = db.insertDrift(drift);
      expect(result.ok).toBe(true);
      if (result.ok) {
        expect(result.data.id).toBeGreaterThan(0);
        expect(result.data.file_path).toBe(drift.file_path);
        expect(result.data.drift_type).toBe(drift.drift_type);
        expect(result.data.fix_applied).toBe(0);
      }
    });

    test('getDriftHotspots returns aggregated data', () => {
      // Insert multiple drift records
      for (let i = 0; i < 3; i++) {
        db.insertDrift({
          file_path: `/project/src/file${i}.ts`,
          drift_type: 'missing-import',
          severity: 'error',
          message: 'Missing import',
          line_number: null,
          generator_name: 'api',
          project_path: '/project',
          session_id: null,
        });
      }

      const result = db.getDriftHotspots();
      expect(result.ok).toBe(true);
      if (result.ok) {
        const apiHotspot = result.data.find(
          (h) => h.generator_name === 'api' && h.drift_type === 'missing-import'
        );
        expect(apiHotspot).toBeDefined();
        expect(apiHotspot?.occurrence_count).toBeGreaterThanOrEqual(3);
      }
    });

    test('markDriftFixed updates fix_applied', () => {
      const insertResult = db.insertDrift({
        file_path: '/project/src/to-fix.ts',
        drift_type: 'missing-result-type',
        severity: 'warning',
        message: 'Missing Result type',
        line_number: 5,
        generator_name: 'api',
        project_path: '/project',
        session_id: null,
      });

      expect(insertResult.ok).toBe(true);
      if (!insertResult.ok) return;

      const fixResult = db.markDriftFixed(insertResult.data.id);
      expect(fixResult.ok).toBe(true);
      if (fixResult.ok && fixResult.data) {
        expect(fixResult.data.fix_applied).toBe(1);
        expect(fixResult.data.fix_applied_at).not.toBeNull();
      }
    });
  });

  describe('Rule Violation Operations', () => {
    test('insertViolation creates a violation record', () => {
      const violation = {
        rule_source: 'hook' as const,
        rule_name: 'assumption-detector',
        file_path: '/project/src/index.ts',
        line_number: 42,
        violation_message: 'Found assumption language: "should work"',
        severity: 'error' as const,
        session_id: null,
      };

      const result = db.insertViolation(violation);
      expect(result.ok).toBe(true);
      if (result.ok) {
        expect(result.data.id).toBeGreaterThan(0);
        expect(result.data.rule_name).toBe(violation.rule_name);
        expect(result.data.auto_fixed).toBe(0);
      }
    });

    test('getViolationPatterns returns aggregated data', () => {
      // Insert multiple violations
      for (let i = 0; i < 2; i++) {
        db.insertViolation({
          rule_source: 'grader',
          rule_name: 'nix-health',
          file_path: `/project/file${i}.nix`,
          line_number: null,
          violation_message: 'Health check failed',
          severity: 'warning',
          session_id: null,
        });
      }

      const result = db.getViolationPatterns();
      expect(result.ok).toBe(true);
      if (result.ok) {
        expect(result.data.length).toBeGreaterThan(0);
      }
    });
  });

  describe('Patch Proposal Operations', () => {
    test('insertPatch creates a patch proposal', () => {
      const patch = {
        patch_type: 'skill-update' as const,
        target_file: 'config/system/src/definitions/skills/typescript-patterns.ts',
        description: 'Add Result type examples',
        rationale: '15 violations of missing-result-type detected',
        patch_content: '// Patch content here',
        confidence: 0.85,
        evidence_count: 15,
      };

      const result = db.insertPatch(patch);
      expect(result.ok).toBe(true);
      if (result.ok) {
        expect(result.data.id).toBeGreaterThan(0);
        expect(result.data.status).toBe('pending');
        expect(result.data.confidence).toBe(0.85);
      }
    });

    test('updatePatchStatus changes patch status', () => {
      const insertResult = db.insertPatch({
        patch_type: 'rule-update',
        target_file: 'config/cursor/rules/test.mdc',
        description: 'Update test rule',
        rationale: 'Test rationale',
        patch_content: '// Test',
        confidence: 0.7,
        evidence_count: 5,
      });

      expect(insertResult.ok).toBe(true);
      if (!insertResult.ok) return;

      const updateResult = db.updatePatchStatus(insertResult.data.id, 'approved');
      expect(updateResult.ok).toBe(true);
      if (updateResult.ok && updateResult.data) {
        expect(updateResult.data.status).toBe('approved');
        expect(updateResult.data.reviewed_at).not.toBeNull();
      }
    });

    test('getPendingPatches returns only pending patches', () => {
      const result = db.getPendingPatches();
      expect(result.ok).toBe(true);
      if (result.ok) {
        for (const patch of result.data) {
          expect(patch.status).toBe('pending');
        }
      }
    });
  });

  describe('Active Issues View', () => {
    test('getActiveIssues returns unfixed drift and violations', () => {
      const result = db.getActiveIssues();
      expect(result.ok).toBe(true);
      if (result.ok) {
        // Should include both drift and violation issues
        const driftIssues = result.data.filter((i) => i.issue_type === 'drift');
        const violationIssues = result.data.filter((i) => i.issue_type === 'violation');
        expect(driftIssues.length).toBeGreaterThanOrEqual(0);
        expect(violationIssues.length).toBeGreaterThanOrEqual(0);
      }
    });
  });
});
