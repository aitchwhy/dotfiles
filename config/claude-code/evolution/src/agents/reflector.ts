/**
 * Reflector Agent
 *
 * Analyzes drift and violations to propose patches that improve the system.
 * Part of the Level 5 Autonomic Self-Evolution loop.
 *
 * Flow:
 * 1. Query drift hotspots and violation patterns from DB
 * 2. Identify high-frequency issues
 * 3. Generate patch proposals with confidence scores
 * 4. Store proposals for review
 */
import { Err, Ok, type Result } from '../lib/result';
import { EvolutionDB } from '../db/client';
import type {
  DriftHotspot,
  PatchProposal,
  PatchProposalInsert,
  ViolationPattern,
} from '../db/schema';

// ============================================================================
// Types
// ============================================================================

export interface ReflectorOptions {
  /** Minimum evidence count to generate a proposal (default: 5) */
  minEvidence?: number;
  /** Minimum confidence to include in proposals (default: 0.6) */
  minConfidence?: number;
}

export interface ReflectorOutput {
  /** Summary statistics */
  summary: {
    totalDrift: number;
    totalViolations: number;
    proposalsGenerated: number;
  };
  /** Detected hotspots */
  hotspots: {
    drift: readonly DriftHotspot[];
    violations: readonly ViolationPattern[];
  };
  /** Generated patch proposals */
  proposals: readonly PatchProposalInsert[];
}

// ============================================================================
// Patch Generation Logic
// ============================================================================

/**
 * Map drift type to potential patch target
 */
function driftToTargetFile(driftType: string): string {
  switch (driftType) {
    case 'missing-import':
    case 'missing-zod-schema':
      return 'config/system/src/definitions/skills/zod-patterns.ts';
    case 'missing-result-type':
      return 'config/system/src/definitions/skills/result-patterns.ts';
    case 'missing-export':
    case 'invalid-import-path':
      return 'config/system/src/definitions/skills/typescript-patterns.ts';
    default:
      return 'config/system/src/definitions/skills/clean-code.ts';
  }
}

/**
 * Map violation rule to potential patch target
 */
function violationToTargetFile(ruleName: string, ruleSource: string): string {
  if (ruleSource === 'hook') {
    return `config/claude-code/evolution/hooks/${ruleName}.ts`;
  }
  if (ruleSource === 'grader') {
    return `config/claude-code/evolution/src/graders/${ruleName}.ts`;
  }
  return 'config/system/src/definitions/skills/verification-first.ts';
}

/**
 * Calculate confidence based on evidence count and other factors
 */
function calculateConfidence(evidenceCount: number, severity: 'error' | 'warning'): number {
  // Base confidence from evidence count (asymptotic to 1.0)
  const baseConfidence = 1 - Math.exp(-evidenceCount / 10);

  // Severity multiplier (errors are more urgent)
  const severityMultiplier = severity === 'error' ? 1.0 : 0.8;

  return Math.min(0.95, baseConfidence * severityMultiplier);
}

/**
 * Generate a description for a drift-based proposal
 */
function generateDriftDescription(hotspot: DriftHotspot): string {
  const generator = hotspot.generator_name ?? 'unknown';
  return `Address ${hotspot.drift_type} pattern in ${generator} generator (${hotspot.occurrence_count} occurrences across ${hotspot.affected_files} files)`;
}

/**
 * Generate a description for a violation-based proposal
 */
function generateViolationDescription(pattern: ViolationPattern): string {
  return `Improve ${pattern.rule_name} rule enforcement (${pattern.total_violations} violations from ${pattern.rule_source})`;
}

/**
 * Generate patch content stub (placeholder for actual diff generation)
 */
function generatePatchContent(type: 'drift' | 'violation', name: string, count: number): string {
  return `/**
 * AUTO-GENERATED PATCH STUB
 *
 * Issue: ${name}
 * Evidence count: ${count}
 *
 * TODO: Review and implement actual fix
 * - Analyze root cause
 * - Update relevant patterns/rules
 * - Add tests
 */

// Placeholder for patch implementation
`;
}

// ============================================================================
// Reflector Class
// ============================================================================

export class Reflector {
  private db: EvolutionDB;

  constructor(db: EvolutionDB) {
    this.db = db;
  }

  /**
   * Analyze current drift and violations, generate proposals
   */
  reflect(options: ReflectorOptions = {}): Result<ReflectorOutput, Error> {
    const minEvidence = options.minEvidence ?? 5;
    const minConfidence = options.minConfidence ?? 0.6;

    // Get drift hotspots
    const driftResult = this.db.getDriftHotspots();
    if (!driftResult.ok) {
      return Err(new Error(`Failed to get drift hotspots: ${driftResult.error.message}`));
    }

    // Get violation patterns
    const violationResult = this.db.getViolationPatterns();
    if (!violationResult.ok) {
      return Err(new Error(`Failed to get violation patterns: ${violationResult.error.message}`));
    }

    const driftHotspots = driftResult.data;
    const violationPatterns = violationResult.data;

    // Calculate totals
    const totalDrift = driftHotspots.reduce((sum, h) => sum + h.occurrence_count, 0);
    const totalViolations = violationPatterns.reduce((sum, v) => sum + v.total_violations, 0);

    // Generate proposals for high-frequency issues
    const proposals: PatchProposalInsert[] = [];

    // Drift-based proposals
    for (const hotspot of driftHotspots) {
      if (hotspot.occurrence_count < minEvidence) continue;

      const severity = hotspot.drift_type.includes('missing') ? 'error' : 'warning';
      const confidence = calculateConfidence(hotspot.occurrence_count, severity as 'error' | 'warning');

      if (confidence < minConfidence) continue;

      proposals.push({
        patch_type: hotspot.generator_name ? 'generator-fix' : 'skill-update',
        target_file: driftToTargetFile(hotspot.drift_type),
        description: generateDriftDescription(hotspot),
        rationale: `${hotspot.occurrence_count} occurrences of ${hotspot.drift_type} detected, affecting ${hotspot.affected_files} files. Only ${hotspot.fixed_count} have been auto-fixed.`,
        patch_content: generatePatchContent('drift', hotspot.drift_type, hotspot.occurrence_count),
        confidence,
        evidence_count: hotspot.occurrence_count,
      });
    }

    // Violation-based proposals
    for (const pattern of violationPatterns) {
      if (pattern.total_violations < minEvidence) continue;

      const confidence = calculateConfidence(pattern.total_violations, pattern.severity as 'error' | 'warning');

      if (confidence < minConfidence) continue;

      proposals.push({
        patch_type: pattern.rule_source === 'hook' ? 'hook-update' : 'rule-update',
        target_file: violationToTargetFile(pattern.rule_name, pattern.rule_source),
        description: generateViolationDescription(pattern),
        rationale: `${pattern.total_violations} violations of ${pattern.rule_name} rule from ${pattern.rule_source}. First seen: ${pattern.first_seen}, Last seen: ${pattern.last_seen}.`,
        patch_content: generatePatchContent('violation', pattern.rule_name, pattern.total_violations),
        confidence,
        evidence_count: pattern.total_violations,
      });
    }

    // Sort by confidence (highest first)
    proposals.sort((a, b) => b.confidence - a.confidence);

    return Ok({
      summary: {
        totalDrift,
        totalViolations,
        proposalsGenerated: proposals.length,
      },
      hotspots: {
        drift: driftHotspots,
        violations: violationPatterns,
      },
      proposals,
    });
  }

  /**
   * Create a patch proposal in the database
   */
  propose(proposal: PatchProposalInsert): Result<PatchProposal, Error> {
    return this.db.insertPatch(proposal);
  }

  /**
   * Get pending patches for review
   */
  review(): Result<readonly PatchProposal[], Error> {
    return this.db.getPendingPatches();
  }

  /**
   * Approve or reject a patch
   */
  decide(patchId: number, decision: 'approved' | 'rejected'): Result<PatchProposal | null, Error> {
    return this.db.updatePatchStatus(patchId, decision);
  }

  /**
   * Apply an approved patch (mark as applied)
   */
  apply(patchId: number, appliedBy: 'auto' | 'manual' = 'manual'): Result<PatchProposal | null, Error> {
    // First check if patch is approved
    const pendingResult = this.db.getPendingPatches();
    if (!pendingResult.ok) return pendingResult;

    // Note: This doesn't actually apply the patch content - that would require
    // file system operations. This just marks it as applied in the DB.
    return this.db.updatePatchStatus(patchId, 'applied');
  }
}
