/**
 * Evolution System Database Schemas
 *
 * Zod schemas are the source of truth for database types.
 * All TypeScript types are derived from these schemas.
 */
import { z } from 'zod';

// ============================================================================
// Branded Types for Type Safety
// ============================================================================

declare const __brand: unique symbol;
type Brand<T, B extends string> = T & { readonly [__brand]: B };

export type SessionId = Brand<string, 'SessionId'>;
export type TaskId = Brand<string, 'TaskId'>;
export type CommitSha = Brand<string, 'CommitSha'>;

// ============================================================================
// Enums
// ============================================================================

export const TaskStatus = z.enum(['pending', 'in_progress', 'completed', 'failed']);
export type TaskStatus = z.infer<typeof TaskStatus>;

export const LessonSource = z.enum(['reflection', 'session', 'manual', 'grader']);
export type LessonSource = z.infer<typeof LessonSource>;

export const Recommendation = z.enum(['stable', 'improve', 'urgent']);
export type Recommendation = z.infer<typeof Recommendation>;

export const CycleTrigger = z.enum(['manual', 'session_end', 'scheduled', 'ci']);
export type CycleTrigger = z.infer<typeof CycleTrigger>;

// ============================================================================
// Session Schema
// ============================================================================

export const SessionSchema = z.object({
  id: z.string(),
  started_at: z.string().datetime(),
  ended_at: z.string().datetime().nullable(),
  working_directory: z.string(),
  hostname: z.string(),
  git_branch: z.string().nullable(),
  initial_score: z.number().min(0).max(1).nullable(),
  final_score: z.number().min(0).max(1).nullable(),
  files_modified: z.number().int().nonnegative().default(0),
  commits_made: z.number().int().nonnegative().default(0),
  metadata: z.string().nullable(), // JSON string
});

export type Session = z.infer<typeof SessionSchema>;

export const SessionInsertSchema = SessionSchema.omit({
  ended_at: true,
  final_score: true,
}).extend({
  ended_at: z.string().datetime().optional(),
  final_score: z.number().min(0).max(1).optional(),
});

export type SessionInsert = z.infer<typeof SessionInsertSchema>;

// ============================================================================
// Task Schema
// ============================================================================

export const TaskSchema = z.object({
  id: z.string(),
  session_id: z.string(),
  started_at: z.string().datetime(),
  ended_at: z.string().datetime().nullable(),
  description: z.string().min(1),
  status: TaskStatus,
  files_touched: z.string().nullable(), // JSON array
  metadata: z.string().nullable(),
});

export type Task = z.infer<typeof TaskSchema>;

export const TaskInsertSchema = TaskSchema.omit({
  ended_at: true,
}).extend({
  ended_at: z.string().datetime().optional(),
});

export type TaskInsert = z.infer<typeof TaskInsertSchema>;

// ============================================================================
// Commit Schema
// ============================================================================

export const CommitSchema = z.object({
  id: z.string(), // Git SHA
  session_id: z.string().nullable(),
  created_at: z.string().datetime(),
  message: z.string().min(1),
  files_changed: z.number().int().nonnegative(),
  insertions: z.number().int().nonnegative(),
  deletions: z.number().int().nonnegative(),
  is_conventional: z.boolean(),
  commit_type: z.string().nullable(),
  scope: z.string().nullable(),
});

export type Commit = z.infer<typeof CommitSchema>;

export const CommitInsertSchema = CommitSchema;
export type CommitInsert = z.infer<typeof CommitInsertSchema>;

// ============================================================================
// Lesson Schema
// ============================================================================

export const LessonSchema = z.object({
  id: z.number().int().positive(),
  created_at: z.string().datetime(),
  lesson: z.string().min(1),
  source: LessonSource,
  category: z.string().nullable(),
  confidence: z.number().min(0).max(1).default(1.0),
  times_applied: z.number().int().nonnegative().default(0),
  last_applied_at: z.string().datetime().nullable(),
});

export type Lesson = z.infer<typeof LessonSchema>;

export const LessonInsertSchema = LessonSchema.omit({
  id: true,
  times_applied: true,
  last_applied_at: true,
}).extend({
  times_applied: z.number().int().nonnegative().optional(),
  last_applied_at: z.string().datetime().optional(),
});

export type LessonInsert = z.infer<typeof LessonInsertSchema>;

// ============================================================================
// Metrics Schema
// ============================================================================

export const MetricSchema = z.object({
  id: z.number().int().positive(),
  recorded_at: z.string().datetime(),
  metric_name: z.string().min(1),
  metric_value: z.number(),
  labels: z.string().nullable(), // JSON object
});

export type Metric = z.infer<typeof MetricSchema>;

export const MetricInsertSchema = MetricSchema.omit({ id: true });
export type MetricInsert = z.infer<typeof MetricInsertSchema>;

// ============================================================================
// Evolution Cycle Schema
// ============================================================================

export const EvolutionCycleSchema = z.object({
  id: z.number().int().positive(),
  started_at: z.string().datetime(),
  ended_at: z.string().datetime(),
  overall_score: z.number().min(0).max(1),
  recommendation: Recommendation,
  trigger: CycleTrigger,
  session_id: z.string().nullable(),
  proposals: z.string().nullable(), // JSON array
  applied_proposals: z.string().nullable(), // JSON array
});

export type EvolutionCycle = z.infer<typeof EvolutionCycleSchema>;

export const EvolutionCycleInsertSchema = EvolutionCycleSchema.omit({ id: true });
export type EvolutionCycleInsert = z.infer<typeof EvolutionCycleInsertSchema>;

// ============================================================================
// Grader Run Schema
// ============================================================================

export const GraderIssueSchema = z.object({
  file: z.string().optional(),
  line: z.number().int().positive().optional(),
  message: z.string(),
  severity: z.enum(['error', 'warning', 'info']).default('warning'),
});

export type GraderIssue = z.infer<typeof GraderIssueSchema>;

export const GraderRunSchema = z.object({
  id: z.number().int().positive(),
  evolution_cycle_id: z.number().int().positive(),
  grader_name: z.string().min(1),
  started_at: z.string().datetime(),
  ended_at: z.string().datetime(),
  score: z.number().min(0).max(1),
  passed: z.boolean(),
  issues: z.string(), // JSON array of GraderIssue
  raw_output: z.string().nullable(),
  execution_time_ms: z.number().int().nonnegative().nullable(),
});

export type GraderRun = z.infer<typeof GraderRunSchema>;

export const GraderRunInsertSchema = GraderRunSchema.omit({ id: true });
export type GraderRunInsert = z.infer<typeof GraderRunInsertSchema>;

// ============================================================================
// Research Schema
// ============================================================================

export const ResearchSchema = z.object({
  id: z.number().int().positive(),
  created_at: z.string().datetime(),
  query: z.string().min(1),
  source_url: z.string().url().nullable(),
  content_summary: z.string().min(1),
  relevance_score: z.number().min(0).max(1).nullable(),
  related_lesson_id: z.number().int().positive().nullable(),
  metadata: z.string().nullable(),
});

export type Research = z.infer<typeof ResearchSchema>;

export const ResearchInsertSchema = ResearchSchema.omit({ id: true });
export type ResearchInsert = z.infer<typeof ResearchInsertSchema>;

// ============================================================================
// View Types (read-only)
// ============================================================================

export const DoraMetricSchema = z.object({
  date: z.string(),
  deploy_count: z.number().int(),
  avg_improvement: z.number().nullable(),
});

export type DoraMetric = z.infer<typeof DoraMetricSchema>;

export const ScoreTrendSchema = z.object({
  date: z.string(),
  avg_score: z.number(),
  min_score: z.number(),
  max_score: z.number(),
  cycle_count: z.number().int(),
});

export type ScoreTrend = z.infer<typeof ScoreTrendSchema>;

export const LessonEffectivenessSchema = z.object({
  category: z.string().nullable(),
  lesson_count: z.number().int(),
  avg_applications: z.number(),
  avg_confidence: z.number(),
});

export type LessonEffectiveness = z.infer<typeof LessonEffectivenessSchema>;

export const GraderTrendSchema = z.object({
  grader_name: z.string(),
  date: z.string(),
  avg_score: z.number(),
  pass_count: z.number().int(),
  total_runs: z.number().int(),
  avg_execution_time_ms: z.number().nullable(),
});

export type GraderTrend = z.infer<typeof GraderTrendSchema>;

// ============================================================================
// Verification System Schemas (Added in migration 002)
// ============================================================================

// Verification enums
export const VerificationStatus = z.enum(['pending', 'verified', 'failed', 'skipped']);
export type VerificationStatus = z.infer<typeof VerificationStatus>;

export const ClaimType = z.enum(['behavior', 'fix', 'feature', 'refactor']);
export type ClaimType = z.infer<typeof ClaimType>;

export const TddPhase = z.enum(['red', 'green', 'refactor']);
export type TddPhase = z.infer<typeof TddPhase>;

export const AssumptionSeverity = z.enum(['high', 'medium', 'low']);
export type AssumptionSeverity = z.infer<typeof AssumptionSeverity>;

// Verification Claim Schema
export const VerificationClaimSchema = z.object({
  id: z.number().int().positive(),
  session_id: z.string(),
  claim_text: z.string().min(1),
  claim_type: ClaimType,
  verification_status: VerificationStatus.default('pending'),
  test_file: z.string().nullable(),
  test_name: z.string().nullable(),
  test_output: z.string().nullable(),
  verified_at: z.string().datetime().nullable(),
  created_at: z.string().datetime(),
});

export type VerificationClaim = z.infer<typeof VerificationClaimSchema>;

export const VerificationClaimInsertSchema = VerificationClaimSchema.omit({
  id: true,
  verified_at: true,
  created_at: true,
}).extend({
  verified_at: z.string().datetime().optional(),
  created_at: z.string().datetime().optional(),
});

export type VerificationClaimInsert = z.infer<typeof VerificationClaimInsertSchema>;

// TDD Cycle Schema
export const TddCycleSchema = z.object({
  id: z.number().int().positive(),
  session_id: z.string(),
  cycle_number: z.number().int().positive(),
  phase: TddPhase,
  test_file: z.string().nullable(),
  source_file: z.string().nullable(),
  started_at: z.string().datetime(),
  completed_at: z.string().datetime().nullable(),
});

export type TddCycle = z.infer<typeof TddCycleSchema>;

export const TddCycleInsertSchema = TddCycleSchema.omit({
  id: true,
  started_at: true,
  completed_at: true,
}).extend({
  started_at: z.string().datetime().optional(),
  completed_at: z.string().datetime().optional(),
});

export type TddCycleInsert = z.infer<typeof TddCycleInsertSchema>;

// Assumption Log Schema
export const AssumptionLogSchema = z.object({
  id: z.number().int().positive(),
  session_id: z.string(),
  assumption_text: z.string().min(1),
  context: z.string().nullable(),
  severity: AssumptionSeverity,
  logged_at: z.string().datetime(),
});

export type AssumptionLog = z.infer<typeof AssumptionLogSchema>;

export const AssumptionLogInsertSchema = AssumptionLogSchema.omit({
  id: true,
  logged_at: true,
}).extend({
  logged_at: z.string().datetime().optional(),
});

export type AssumptionLogInsert = z.infer<typeof AssumptionLogInsertSchema>;

// ============================================================================
// Verification Analytics Views (read-only)
// ============================================================================

export const SessionEffectivenessSchema = z.object({
  session_id: z.string(),
  total_claims: z.number().int(),
  verified_claims: z.number().int(),
  failed_claims: z.number().int(),
  pending_claims: z.number().int(),
  verification_rate: z.number(),
});

export type SessionEffectiveness = z.infer<typeof SessionEffectivenessSchema>;

export const TddComplianceSchema = z.object({
  session_id: z.string(),
  total_cycles: z.number().int(),
  red_phases: z.number().int(),
  green_phases: z.number().int(),
  refactor_phases: z.number().int(),
});

export type TddCompliance = z.infer<typeof TddComplianceSchema>;

export const AssumptionTrendSchema = z.object({
  date: z.string(),
  severity: AssumptionSeverity,
  count: z.number().int(),
  sample_texts: z.string().nullable(),
});

export type AssumptionTrend = z.infer<typeof AssumptionTrendSchema>;

// ============================================================================
// Generator Drift Schemas (Added in migration 003)
// ============================================================================

export const DriftType = z.enum([
  'missing-import',
  'missing-zod-schema',
  'missing-result-type',
  'missing-export',
  'invalid-import-path',
]);
export type DriftType = z.infer<typeof DriftType>;

export const DriftSeverity = z.enum(['error', 'warning']);
export type DriftSeverity = z.infer<typeof DriftSeverity>;

export const GeneratorDriftSchema = z.object({
  id: z.number().int().positive(),
  detected_at: z.string().datetime(),
  file_path: z.string(),
  drift_type: DriftType,
  severity: DriftSeverity,
  message: z.string(),
  line_number: z.number().int().positive().nullable(),
  generator_name: z.string().nullable(),
  project_path: z.string(),
  fix_applied: z.union([z.literal(0), z.literal(1)]),
  fix_applied_at: z.string().datetime().nullable(),
  session_id: z.string().nullable(),
});

export type GeneratorDrift = z.infer<typeof GeneratorDriftSchema>;

export const GeneratorDriftInsertSchema = GeneratorDriftSchema.omit({
  id: true,
  detected_at: true,
  fix_applied: true,
  fix_applied_at: true,
}).extend({
  detected_at: z.string().datetime().optional(),
  fix_applied: z.union([z.literal(0), z.literal(1)]).optional(),
  fix_applied_at: z.string().datetime().optional(),
});

export type GeneratorDriftInsert = z.infer<typeof GeneratorDriftInsertSchema>;

// ============================================================================
// Rule Violations Schemas (Added in migration 003)
// ============================================================================

export const RuleSource = z.enum(['hook', 'grader', 'enforcer', 'linter']);
export type RuleSource = z.infer<typeof RuleSource>;

export const ViolationSeverity = z.enum(['error', 'warning', 'info']);
export type ViolationSeverity = z.infer<typeof ViolationSeverity>;

export const RuleViolationSchema = z.object({
  id: z.number().int().positive(),
  detected_at: z.string().datetime(),
  rule_source: RuleSource,
  rule_name: z.string(),
  file_path: z.string().nullable(),
  line_number: z.number().int().positive().nullable(),
  violation_message: z.string(),
  severity: ViolationSeverity,
  auto_fixed: z.union([z.literal(0), z.literal(1)]),
  session_id: z.string().nullable(),
});

export type RuleViolation = z.infer<typeof RuleViolationSchema>;

export const RuleViolationInsertSchema = RuleViolationSchema.omit({
  id: true,
  detected_at: true,
  auto_fixed: true,
}).extend({
  detected_at: z.string().datetime().optional(),
  auto_fixed: z.union([z.literal(0), z.literal(1)]).optional(),
});

export type RuleViolationInsert = z.infer<typeof RuleViolationInsertSchema>;

// ============================================================================
// Patch Proposals Schemas (Added in migration 003)
// ============================================================================

export const PatchType = z.enum([
  'skill-update',
  'rule-update',
  'hook-update',
  'generator-fix',
  'schema-change',
]);
export type PatchType = z.infer<typeof PatchType>;

export const PatchStatus = z.enum(['pending', 'approved', 'rejected', 'applied']);
export type PatchStatus = z.infer<typeof PatchStatus>;

export const PatchProposalSchema = z.object({
  id: z.number().int().positive(),
  created_at: z.string().datetime(),
  patch_type: PatchType,
  target_file: z.string(),
  description: z.string(),
  rationale: z.string(),
  patch_content: z.string(),
  status: PatchStatus,
  confidence: z.number().min(0).max(1),
  evidence_count: z.number().int().nonnegative(),
  reviewed_at: z.string().datetime().nullable(),
  applied_at: z.string().datetime().nullable(),
  applied_by: z.string().nullable(),
});

export type PatchProposal = z.infer<typeof PatchProposalSchema>;

export const PatchProposalInsertSchema = PatchProposalSchema.omit({
  id: true,
  created_at: true,
  status: true,
  reviewed_at: true,
  applied_at: true,
  applied_by: true,
}).extend({
  created_at: z.string().datetime().optional(),
  status: PatchStatus.optional(),
  reviewed_at: z.string().datetime().optional(),
  applied_at: z.string().datetime().optional(),
  applied_by: z.string().optional(),
});

export type PatchProposalInsert = z.infer<typeof PatchProposalInsertSchema>;

// ============================================================================
// Reflector Analytics Views (read-only)
// ============================================================================

export const DriftHotspotSchema = z.object({
  generator_name: z.string().nullable(),
  drift_type: DriftType,
  occurrence_count: z.number().int(),
  affected_files: z.number().int(),
  fixed_count: z.number().int(),
  last_seen: z.string().datetime(),
});

export type DriftHotspot = z.infer<typeof DriftHotspotSchema>;

export const ViolationPatternSchema = z.object({
  rule_source: RuleSource,
  rule_name: z.string(),
  severity: ViolationSeverity,
  total_violations: z.number().int(),
  affected_files: z.number().int(),
  auto_fixed_count: z.number().int(),
  first_seen: z.string().datetime(),
  last_seen: z.string().datetime(),
});

export type ViolationPattern = z.infer<typeof ViolationPatternSchema>;

export const PatchSummarySchema = z.object({
  patch_type: PatchType,
  status: PatchStatus,
  count: z.number().int(),
  avg_confidence: z.number(),
  avg_evidence: z.number(),
});

export type PatchSummary = z.infer<typeof PatchSummarySchema>;

export const ActiveIssueSchema = z.object({
  issue_type: z.enum(['drift', 'violation']),
  id: z.number().int().positive(),
  detected_at: z.string().datetime(),
  file_path: z.string().nullable(),
  issue_name: z.string(),
  message: z.string(),
  severity: z.string(),
  context: z.string().nullable(),
});

export type ActiveIssue = z.infer<typeof ActiveIssueSchema>;
