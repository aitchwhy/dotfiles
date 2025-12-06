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
