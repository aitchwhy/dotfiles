/**
 * Schema Tests for Migration 003: Generator Drift & Reflector System
 *
 * Tests for the new Zod schemas added in migration 003.
 */
import { describe, expect, test } from 'bun:test';
import { z } from 'zod';

// Import the schemas we're about to create
import {
  DriftType,
  DriftSeverity,
  GeneratorDriftSchema,
  GeneratorDriftInsertSchema,
  RuleSource,
  ViolationSeverity,
  RuleViolationSchema,
  RuleViolationInsertSchema,
  PatchType,
  PatchStatus,
  PatchProposalSchema,
  PatchProposalInsertSchema,
  DriftHotspotSchema,
  ViolationPatternSchema,
  ActiveIssueSchema,
} from '../../src/db/schema';

describe('Generator Drift Schemas', () => {
  describe('DriftType enum', () => {
    test('accepts valid drift types', () => {
      expect(DriftType.safeParse('missing-import').success).toBe(true);
      expect(DriftType.safeParse('missing-zod-schema').success).toBe(true);
      expect(DriftType.safeParse('missing-result-type').success).toBe(true);
      expect(DriftType.safeParse('missing-export').success).toBe(true);
      expect(DriftType.safeParse('invalid-import-path').success).toBe(true);
    });

    test('rejects invalid drift types', () => {
      expect(DriftType.safeParse('invalid-type').success).toBe(false);
      expect(DriftType.safeParse('').success).toBe(false);
    });
  });

  describe('GeneratorDriftSchema', () => {
    const validDrift = {
      id: 1,
      detected_at: '2025-12-08T00:00:00.000Z',
      file_path: '/project/src/handler.ts',
      drift_type: 'missing-import',
      severity: 'error',
      message: "File uses 'z.' but doesn't import from 'zod'",
      line_number: 10,
      generator_name: 'api',
      project_path: '/project',
      fix_applied: 0,
      fix_applied_at: null,
      session_id: 'session-123',
    };

    test('parses valid drift record', () => {
      const result = GeneratorDriftSchema.safeParse(validDrift);
      expect(result.success).toBe(true);
    });

    test('requires file_path', () => {
      const { file_path, ...invalid } = validDrift;
      const result = GeneratorDriftSchema.safeParse(invalid);
      expect(result.success).toBe(false);
    });

    test('allows null line_number', () => {
      const drift = { ...validDrift, line_number: null };
      const result = GeneratorDriftSchema.safeParse(drift);
      expect(result.success).toBe(true);
    });

    test('fix_applied must be 0 or 1', () => {
      expect(GeneratorDriftSchema.safeParse({ ...validDrift, fix_applied: 0 }).success).toBe(true);
      expect(GeneratorDriftSchema.safeParse({ ...validDrift, fix_applied: 1 }).success).toBe(true);
      expect(GeneratorDriftSchema.safeParse({ ...validDrift, fix_applied: 2 }).success).toBe(false);
    });
  });

  describe('GeneratorDriftInsertSchema', () => {
    test('does not require id (auto-generated)', () => {
      const insert = {
        file_path: '/project/src/handler.ts',
        drift_type: 'missing-import',
        severity: 'error',
        message: 'Test message',
        line_number: null,
        generator_name: 'api',
        project_path: '/project',
        session_id: null,
      };
      const result = GeneratorDriftInsertSchema.safeParse(insert);
      expect(result.success).toBe(true);
    });
  });
});

describe('Rule Violation Schemas', () => {
  describe('RuleSource enum', () => {
    test('accepts valid rule sources', () => {
      expect(RuleSource.safeParse('hook').success).toBe(true);
      expect(RuleSource.safeParse('grader').success).toBe(true);
      expect(RuleSource.safeParse('enforcer').success).toBe(true);
      expect(RuleSource.safeParse('linter').success).toBe(true);
    });

    test('rejects invalid rule sources', () => {
      expect(RuleSource.safeParse('plugin').success).toBe(false);
    });
  });

  describe('RuleViolationSchema', () => {
    const validViolation = {
      id: 1,
      detected_at: '2025-12-08T00:00:00.000Z',
      rule_source: 'hook',
      rule_name: 'assumption-detector',
      file_path: '/project/src/index.ts',
      line_number: 42,
      violation_message: 'Found assumption language: "should work"',
      severity: 'error',
      auto_fixed: 0,
      session_id: 'session-123',
    };

    test('parses valid violation record', () => {
      const result = RuleViolationSchema.safeParse(validViolation);
      expect(result.success).toBe(true);
    });

    test('severity can be error, warning, or info', () => {
      expect(RuleViolationSchema.safeParse({ ...validViolation, severity: 'error' }).success).toBe(true);
      expect(RuleViolationSchema.safeParse({ ...validViolation, severity: 'warning' }).success).toBe(true);
      expect(RuleViolationSchema.safeParse({ ...validViolation, severity: 'info' }).success).toBe(true);
    });
  });
});

describe('Patch Proposal Schemas', () => {
  describe('PatchType enum', () => {
    test('accepts valid patch types', () => {
      expect(PatchType.safeParse('skill-update').success).toBe(true);
      expect(PatchType.safeParse('rule-update').success).toBe(true);
      expect(PatchType.safeParse('hook-update').success).toBe(true);
      expect(PatchType.safeParse('generator-fix').success).toBe(true);
      expect(PatchType.safeParse('schema-change').success).toBe(true);
    });
  });

  describe('PatchStatus enum', () => {
    test('accepts valid statuses', () => {
      expect(PatchStatus.safeParse('pending').success).toBe(true);
      expect(PatchStatus.safeParse('approved').success).toBe(true);
      expect(PatchStatus.safeParse('rejected').success).toBe(true);
      expect(PatchStatus.safeParse('applied').success).toBe(true);
    });
  });

  describe('PatchProposalSchema', () => {
    const validPatch = {
      id: 1,
      created_at: '2025-12-08T00:00:00.000Z',
      patch_type: 'skill-update',
      target_file: 'config/system/src/definitions/skills/typescript-patterns.ts',
      description: 'Add Result type pattern examples',
      rationale: '15 violations of missing-result-type detected in last 7 days',
      patch_content: '// Patch diff here...',
      status: 'pending',
      confidence: 0.85,
      evidence_count: 15,
      reviewed_at: null,
      applied_at: null,
      applied_by: null,
    };

    test('parses valid patch proposal', () => {
      const result = PatchProposalSchema.safeParse(validPatch);
      expect(result.success).toBe(true);
    });

    test('confidence must be between 0 and 1', () => {
      expect(PatchProposalSchema.safeParse({ ...validPatch, confidence: 0 }).success).toBe(true);
      expect(PatchProposalSchema.safeParse({ ...validPatch, confidence: 1 }).success).toBe(true);
      expect(PatchProposalSchema.safeParse({ ...validPatch, confidence: 0.5 }).success).toBe(true);
      expect(PatchProposalSchema.safeParse({ ...validPatch, confidence: 1.5 }).success).toBe(false);
      expect(PatchProposalSchema.safeParse({ ...validPatch, confidence: -0.1 }).success).toBe(false);
    });

    test('evidence_count must be non-negative', () => {
      expect(PatchProposalSchema.safeParse({ ...validPatch, evidence_count: 0 }).success).toBe(true);
      expect(PatchProposalSchema.safeParse({ ...validPatch, evidence_count: 100 }).success).toBe(true);
      expect(PatchProposalSchema.safeParse({ ...validPatch, evidence_count: -1 }).success).toBe(false);
    });
  });
});

describe('Analytics View Schemas', () => {
  describe('DriftHotspotSchema', () => {
    test('parses drift hotspot record', () => {
      const hotspot = {
        generator_name: 'api',
        drift_type: 'missing-import',
        occurrence_count: 25,
        affected_files: 10,
        fixed_count: 5,
        last_seen: '2025-12-08T00:00:00.000Z',
      };
      const result = DriftHotspotSchema.safeParse(hotspot);
      expect(result.success).toBe(true);
    });
  });

  describe('ViolationPatternSchema', () => {
    test('parses violation pattern record', () => {
      const pattern = {
        rule_source: 'hook',
        rule_name: 'assumption-detector',
        severity: 'error',
        total_violations: 50,
        affected_files: 20,
        auto_fixed_count: 0,
        first_seen: '2025-12-01T00:00:00.000Z',
        last_seen: '2025-12-08T00:00:00.000Z',
      };
      const result = ViolationPatternSchema.safeParse(pattern);
      expect(result.success).toBe(true);
    });
  });

  describe('ActiveIssueSchema', () => {
    test('parses drift issue', () => {
      const issue = {
        issue_type: 'drift',
        id: 1,
        detected_at: '2025-12-08T00:00:00.000Z',
        file_path: '/project/src/handler.ts',
        issue_name: 'missing-import',
        message: 'Missing zod import',
        severity: 'error',
        context: '/project',
      };
      const result = ActiveIssueSchema.safeParse(issue);
      expect(result.success).toBe(true);
    });

    test('parses violation issue', () => {
      const issue = {
        issue_type: 'violation',
        id: 2,
        detected_at: '2025-12-08T00:00:00.000Z',
        file_path: '/project/src/index.ts',
        issue_name: 'assumption-detector',
        message: 'Found assumption language',
        severity: 'warning',
        context: 'hook',
      };
      const result = ActiveIssueSchema.safeParse(issue);
      expect(result.success).toBe(true);
    });
  });
});
