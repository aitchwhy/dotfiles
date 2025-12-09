/**
 * Evolution System Database Client
 *
 * Uses Bun's native SQLite for zero-dependency database access.
 * All operations return Result types for type-safe error handling.
 */
import { Database } from 'bun:sqlite';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Ok, type Result, tryCatch } from '../lib/result';
import {
  type ActiveIssue,
  ActiveIssueSchema,
  type DoraMetric,
  DoraMetricSchema,
  type DriftHotspot,
  DriftHotspotSchema,
  type EvolutionCycle,
  type EvolutionCycleInsert,
  EvolutionCycleSchema,
  type GeneratorDrift,
  type GeneratorDriftInsert,
  GeneratorDriftSchema,
  type GraderRun,
  type GraderRunInsert,
  GraderRunSchema,
  type GraderTrend,
  GraderTrendSchema,
  type Lesson,
  type LessonEffectiveness,
  LessonEffectivenessSchema,
  type LessonInsert,
  LessonSchema,
  type Metric,
  type MetricInsert,
  MetricSchema,
  type PatchProposal,
  type PatchProposalInsert,
  PatchProposalSchema,
  type PatchStatus,
  type RuleViolation,
  type RuleViolationInsert,
  RuleViolationSchema,
  type ScoreTrend,
  ScoreTrendSchema,
  type Session,
  type SessionInsert,
  SessionSchema,
  type Task,
  type TaskInsert,
  TaskSchema,
  type ViolationPattern,
  ViolationPatternSchema,
} from './schema';

// ============================================================================
// Database Location
// ============================================================================

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const DEFAULT_DB_PATH = join(
  process.env['HOME'] ?? '',
  'dotfiles',
  '.claude-metrics',
  'evolution.db'
);
const MIGRATIONS_DIR = join(__dirname, 'migrations');

// ============================================================================
// Database Client Class
// ============================================================================

export class EvolutionDB {
  private db: Database;

  private constructor(db: Database, _dbPath: string) {
    this.db = db;
    // dbPath stored for potential future debugging use
  }

  /**
   * Initialize the database connection and run migrations
   */
  static init(dbPath: string = DEFAULT_DB_PATH): Result<EvolutionDB, Error> {
    return tryCatch(() => {
      // Ensure directory exists
      const dbDir = dirname(dbPath);
      const { mkdirSync } = require('node:fs');
      mkdirSync(dbDir, { recursive: true });

      const db = new Database(dbPath);

      // Enable WAL mode for better concurrent access
      db.exec('PRAGMA journal_mode = WAL');
      db.exec('PRAGMA synchronous = NORMAL');
      db.exec('PRAGMA foreign_keys = ON');

      const client = new EvolutionDB(db, dbPath);

      // Run migrations
      const migrationResult = client.runMigrations();
      if (!migrationResult.ok) {
        db.close();
        throw migrationResult.error;
      }

      return client;
    });
  }

  /**
   * Run all pending migrations
   */
  private runMigrations(): Result<void, Error> {
    return tryCatch(() => {
      // Create migrations tracking table
      this.db.exec(`
        CREATE TABLE IF NOT EXISTS _migrations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          applied_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
      `);

      // Get applied migrations
      const applied = new Set(
        this.db
          .query<{ name: string }, []>('SELECT name FROM _migrations')
          .all()
          .map((row) => row.name)
      );

      // Find and apply pending migrations
      const { readdirSync } = require('node:fs');
      const files = readdirSync(MIGRATIONS_DIR).filter(
        (f: string) => f.endsWith('.sql') && !applied.has(f)
      );
      files.sort();

      for (const file of files) {
        const sql = readFileSync(join(MIGRATIONS_DIR, file), 'utf-8');
        this.db.exec(sql);
        this.db.run('INSERT INTO _migrations (name) VALUES (?)', [file]);
        console.log(`Applied migration: ${file}`);
      }
    });
  }

  /**
   * Close the database connection
   */
  close(): void {
    this.db.close();
  }

  // ==========================================================================
  // Session Operations
  // ==========================================================================

  insertSession(session: SessionInsert): Result<Session, Error> {
    return tryCatch(() => {
      const stmt = this.db.prepare(`
        INSERT INTO sessions (id, started_at, ended_at, working_directory, hostname, git_branch, initial_score, final_score, files_modified, commits_made, metadata)
        VALUES ($id, $started_at, $ended_at, $working_directory, $hostname, $git_branch, $initial_score, $final_score, $files_modified, $commits_made, $metadata)
        RETURNING *
      `);
      const row = stmt.get({
        $id: session.id,
        $started_at: session.started_at,
        $ended_at: session.ended_at ?? null,
        $working_directory: session.working_directory,
        $hostname: session.hostname,
        $git_branch: session.git_branch,
        $initial_score: session.initial_score,
        $final_score: session.final_score ?? null,
        $files_modified: session.files_modified,
        $commits_made: session.commits_made,
        $metadata: session.metadata,
      });
      return SessionSchema.parse(row);
    });
  }

  updateSession(id: string, updates: Partial<Session>): Result<Session | null, Error> {
    return tryCatch(() => {
      const fields = Object.keys(updates)
        .map((k) => `${k} = $${k}`)
        .join(', ');
      if (!fields) return null;

      const stmt = this.db.prepare(`UPDATE sessions SET ${fields} WHERE id = $id RETURNING *`);
      const row = stmt.get({ $id: id, ...prefixKeys(updates) });
      return row ? SessionSchema.parse(row) : null;
    });
  }

  getSession(id: string): Result<Session | null, Error> {
    return tryCatch(() => {
      const row = this.db.query<Session, [string]>('SELECT * FROM sessions WHERE id = ?').get(id);
      return row ? SessionSchema.parse(row) : null;
    });
  }

  // ==========================================================================
  // Task Operations
  // ==========================================================================

  insertTask(task: TaskInsert): Result<Task, Error> {
    return tryCatch(() => {
      const stmt = this.db.prepare(`
        INSERT INTO tasks (id, session_id, started_at, ended_at, description, status, files_touched, metadata)
        VALUES ($id, $session_id, $started_at, $ended_at, $description, $status, $files_touched, $metadata)
        RETURNING *
      `);
      const row = stmt.get({
        $id: task.id,
        $session_id: task.session_id,
        $started_at: task.started_at,
        $ended_at: task.ended_at ?? null,
        $description: task.description,
        $status: task.status,
        $files_touched: task.files_touched,
        $metadata: task.metadata,
      });
      return TaskSchema.parse(row);
    });
  }

  // ==========================================================================
  // Lesson Operations
  // ==========================================================================

  insertLesson(lesson: LessonInsert): Result<Lesson, Error> {
    return tryCatch(() => {
      const stmt = this.db.prepare(`
        INSERT INTO lessons (created_at, lesson, source, category, confidence, times_applied, last_applied_at)
        VALUES ($created_at, $lesson, $source, $category, $confidence, $times_applied, $last_applied_at)
        RETURNING *
      `);
      const row = stmt.get({
        $created_at: lesson.created_at,
        $lesson: lesson.lesson,
        $source: lesson.source,
        $category: lesson.category,
        $confidence: lesson.confidence,
        $times_applied: lesson.times_applied ?? 0,
        $last_applied_at: lesson.last_applied_at ?? null,
      });
      return LessonSchema.parse(row);
    });
  }

  getAllLessons(): Result<readonly Lesson[], Error> {
    return tryCatch(() => {
      const rows = this.db
        .query<Lesson, []>('SELECT * FROM lessons ORDER BY created_at DESC')
        .all();
      return rows.map((row) => LessonSchema.parse(row));
    });
  }

  // ==========================================================================
  // Evolution Cycle Operations
  // ==========================================================================

  insertEvolutionCycle(cycle: EvolutionCycleInsert): Result<EvolutionCycle, Error> {
    return tryCatch(() => {
      const stmt = this.db.prepare(`
        INSERT INTO evolution_cycles (started_at, ended_at, overall_score, recommendation, trigger, session_id, proposals, applied_proposals)
        VALUES ($started_at, $ended_at, $overall_score, $recommendation, $trigger, $session_id, $proposals, $applied_proposals)
        RETURNING *
      `);
      const row = stmt.get({
        $started_at: cycle.started_at,
        $ended_at: cycle.ended_at,
        $overall_score: cycle.overall_score,
        $recommendation: cycle.recommendation,
        $trigger: cycle.trigger,
        $session_id: cycle.session_id,
        $proposals: cycle.proposals,
        $applied_proposals: cycle.applied_proposals,
      });
      return EvolutionCycleSchema.parse(row);
    });
  }

  getLatestEvolutionCycle(): Result<EvolutionCycle | null, Error> {
    return tryCatch(() => {
      const row = this.db
        .query<EvolutionCycle, []>(
          'SELECT * FROM evolution_cycles ORDER BY started_at DESC LIMIT 1'
        )
        .get();
      return row ? EvolutionCycleSchema.parse(row) : null;
    });
  }

  // ==========================================================================
  // Grader Run Operations
  // ==========================================================================

  insertGraderRun(run: GraderRunInsert): Result<GraderRun, Error> {
    return tryCatch(() => {
      const stmt = this.db.prepare(`
        INSERT INTO grader_runs (evolution_cycle_id, grader_name, started_at, ended_at, score, passed, issues, raw_output, execution_time_ms)
        VALUES ($evolution_cycle_id, $grader_name, $started_at, $ended_at, $score, $passed, $issues, $raw_output, $execution_time_ms)
        RETURNING *
      `);
      const row = stmt.get({
        $evolution_cycle_id: run.evolution_cycle_id,
        $grader_name: run.grader_name,
        $started_at: run.started_at,
        $ended_at: run.ended_at,
        $score: run.score,
        $passed: run.passed ? 1 : 0,
        $issues: run.issues,
        $raw_output: run.raw_output,
        $execution_time_ms: run.execution_time_ms,
      });
      if (!row) throw new Error('Insert failed');
      return GraderRunSchema.parse({
        ...row,
        passed: Boolean((row as Record<string, unknown>)['passed']),
      });
    });
  }

  getGraderRunsByCycle(cycleId: number): Result<readonly GraderRun[], Error> {
    return tryCatch(() => {
      const rows = this.db
        .query<GraderRun, [number]>(
          'SELECT * FROM grader_runs WHERE evolution_cycle_id = ? ORDER BY grader_name'
        )
        .all(cycleId);
      return rows.map((row) => GraderRunSchema.parse({ ...row, passed: Boolean(row.passed) }));
    });
  }

  // ==========================================================================
  // Metric Operations
  // ==========================================================================

  insertMetric(metric: MetricInsert): Result<Metric, Error> {
    return tryCatch(() => {
      const stmt = this.db.prepare(`
        INSERT OR REPLACE INTO metrics (recorded_at, metric_name, metric_value, labels)
        VALUES ($recorded_at, $metric_name, $metric_value, $labels)
        RETURNING *
      `);
      const row = stmt.get({
        $recorded_at: metric.recorded_at,
        $metric_name: metric.metric_name,
        $metric_value: metric.metric_value,
        $labels: metric.labels,
      });
      return MetricSchema.parse(row);
    });
  }

  // ==========================================================================
  // View Queries
  // ==========================================================================

  getDoraMetrics(days: number = 30): Result<readonly DoraMetric[], Error> {
    return tryCatch(() => {
      const rows = this.db
        .query<DoraMetric, [number]>(
          `SELECT * FROM v_dora_metrics WHERE date >= date('now', '-' || ? || ' days')`
        )
        .all(days);
      return rows.map((row) => DoraMetricSchema.parse(row));
    });
  }

  getScoreTrend(days: number = 30): Result<readonly ScoreTrend[], Error> {
    return tryCatch(() => {
      const rows = this.db
        .query<ScoreTrend, [number]>(
          `SELECT * FROM v_score_trend WHERE date >= date('now', '-' || ? || ' days')`
        )
        .all(days);
      return rows.map((row) => ScoreTrendSchema.parse(row));
    });
  }

  getLessonEffectiveness(): Result<readonly LessonEffectiveness[], Error> {
    return tryCatch(() => {
      const rows = this.db
        .query<LessonEffectiveness, []>('SELECT * FROM v_lesson_effectiveness')
        .all();
      return rows.map((row) => LessonEffectivenessSchema.parse(row));
    });
  }

  getGraderTrends(days: number = 30): Result<readonly GraderTrend[], Error> {
    return tryCatch(() => {
      const rows = this.db
        .query<GraderTrend, [number]>(
          `SELECT * FROM v_grader_trends WHERE date >= date('now', '-' || ? || ' days')`
        )
        .all(days);
      return rows.map((row) => GraderTrendSchema.parse(row));
    });
  }

  // ==========================================================================
  // Generator Drift Operations (Migration 003)
  // ==========================================================================

  insertDrift(drift: GeneratorDriftInsert): Result<GeneratorDrift, Error> {
    return tryCatch(() => {
      const stmt = this.db.prepare(`
        INSERT INTO generator_drift (file_path, drift_type, severity, message, line_number, generator_name, project_path, session_id)
        VALUES ($file_path, $drift_type, $severity, $message, $line_number, $generator_name, $project_path, $session_id)
        RETURNING *
      `);
      const row = stmt.get({
        $file_path: drift.file_path,
        $drift_type: drift.drift_type,
        $severity: drift.severity,
        $message: drift.message,
        $line_number: drift.line_number,
        $generator_name: drift.generator_name,
        $project_path: drift.project_path,
        $session_id: drift.session_id,
      });
      return GeneratorDriftSchema.parse(row);
    });
  }

  markDriftFixed(id: number): Result<GeneratorDrift | null, Error> {
    return tryCatch(() => {
      const stmt = this.db.prepare(`
        UPDATE generator_drift
        SET fix_applied = 1, fix_applied_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
        WHERE id = $id
        RETURNING *
      `);
      const row = stmt.get({ $id: id });
      return row ? GeneratorDriftSchema.parse(row) : null;
    });
  }

  getDriftHotspots(): Result<readonly DriftHotspot[], Error> {
    return tryCatch(() => {
      const rows = this.db
        .query<DriftHotspot, []>('SELECT * FROM v_drift_hotspots')
        .all();
      return rows.map((row) => DriftHotspotSchema.parse(row));
    });
  }

  // ==========================================================================
  // Rule Violation Operations (Migration 003)
  // ==========================================================================

  insertViolation(violation: RuleViolationInsert): Result<RuleViolation, Error> {
    return tryCatch(() => {
      const stmt = this.db.prepare(`
        INSERT INTO rule_violations (rule_source, rule_name, file_path, line_number, violation_message, severity, session_id)
        VALUES ($rule_source, $rule_name, $file_path, $line_number, $violation_message, $severity, $session_id)
        RETURNING *
      `);
      const row = stmt.get({
        $rule_source: violation.rule_source,
        $rule_name: violation.rule_name,
        $file_path: violation.file_path,
        $line_number: violation.line_number,
        $violation_message: violation.violation_message,
        $severity: violation.severity,
        $session_id: violation.session_id,
      });
      return RuleViolationSchema.parse(row);
    });
  }

  getViolationPatterns(): Result<readonly ViolationPattern[], Error> {
    return tryCatch(() => {
      const rows = this.db
        .query<ViolationPattern, []>('SELECT * FROM v_violation_patterns')
        .all();
      return rows.map((row) => ViolationPatternSchema.parse(row));
    });
  }

  // ==========================================================================
  // Patch Proposal Operations (Migration 003)
  // ==========================================================================

  insertPatch(patch: PatchProposalInsert): Result<PatchProposal, Error> {
    return tryCatch(() => {
      const stmt = this.db.prepare(`
        INSERT INTO patch_proposals (patch_type, target_file, description, rationale, patch_content, confidence, evidence_count)
        VALUES ($patch_type, $target_file, $description, $rationale, $patch_content, $confidence, $evidence_count)
        RETURNING *
      `);
      const row = stmt.get({
        $patch_type: patch.patch_type,
        $target_file: patch.target_file,
        $description: patch.description,
        $rationale: patch.rationale,
        $patch_content: patch.patch_content,
        $confidence: patch.confidence,
        $evidence_count: patch.evidence_count,
      });
      return PatchProposalSchema.parse(row);
    });
  }

  updatePatchStatus(id: number, status: PatchStatus): Result<PatchProposal | null, Error> {
    return tryCatch(() => {
      const stmt = this.db.prepare(`
        UPDATE patch_proposals
        SET status = $status,
            reviewed_at = CASE WHEN $status IN ('approved', 'rejected') THEN strftime('%Y-%m-%dT%H:%M:%fZ', 'now') ELSE reviewed_at END,
            applied_at = CASE WHEN $status = 'applied' THEN strftime('%Y-%m-%dT%H:%M:%fZ', 'now') ELSE applied_at END
        WHERE id = $id
        RETURNING *
      `);
      const row = stmt.get({ $id: id, $status: status });
      return row ? PatchProposalSchema.parse(row) : null;
    });
  }

  getPendingPatches(): Result<readonly PatchProposal[], Error> {
    return tryCatch(() => {
      const rows = this.db
        .query<PatchProposal, []>("SELECT * FROM patch_proposals WHERE status = 'pending' ORDER BY confidence DESC")
        .all();
      return rows.map((row) => PatchProposalSchema.parse(row));
    });
  }

  // ==========================================================================
  // Active Issues View (Migration 003)
  // ==========================================================================

  getActiveIssues(limit: number = 100): Result<readonly ActiveIssue[], Error> {
    return tryCatch(() => {
      const rows = this.db
        .query<ActiveIssue, [number]>('SELECT * FROM v_active_issues LIMIT ?')
        .all(limit);
      return rows.map((row) => ActiveIssueSchema.parse(row));
    });
  }

  // ==========================================================================
  // Auto-GC Operations
  // ==========================================================================

  /**
   * Get lesson count for threshold checks
   */
  getLessonCount(): Result<number, Error> {
    return tryCatch(() => {
      const row = this.db
        .query<{ count: number }, []>('SELECT COUNT(*) as count FROM lessons')
        .get();
      return row?.count ?? 0;
    });
  }

  /**
   * Delete lessons that match garbage patterns (JSON fragments)
   * Returns number of deleted lessons
   */
  deleteGarbageLessons(): Result<number, Error> {
    return tryCatch(() => {
      const garbagePatterns = [
        '    "thinking":%',
        '    "text":%',
        '      "prompt":%',
        '      "content":%',
        '              "label":%',
      ];

      let deleted = 0;
      for (const pattern of garbagePatterns) {
        const result = this.db.run('DELETE FROM lessons WHERE lesson LIKE ?', [pattern]);
        deleted += result.changes;
      }

      // Also delete JSON-like patterns
      const jsonResult = this.db.run(
        `DELETE FROM lessons WHERE lesson LIKE '{%' OR lesson LIKE '[%' OR lesson LIKE '"%'`
      );
      deleted += jsonResult.changes;

      return deleted;
    });
  }

  /**
   * Delete oldest lessons above threshold, keeping only the most recent N
   * @param threshold Maximum number of lessons to keep
   * Returns number of deleted lessons
   */
  compactLessons(threshold: number = 20): Result<number, Error> {
    return tryCatch(() => {
      const countResult = this.getLessonCount();
      if (!countResult.ok) throw countResult.error;

      const count = countResult.data;
      if (count <= threshold) return 0;

      // Delete oldest lessons, keeping only threshold count
      const result = this.db.run(
        `DELETE FROM lessons WHERE id NOT IN (
          SELECT id FROM lessons ORDER BY created_at DESC LIMIT ?
        )`,
        [threshold]
      );

      return result.changes;
    });
  }

  /**
   * Delete lessons older than specified days with low application count
   * @param days Lessons older than this many days are candidates
   * @param minApplications Lessons with fewer applications than this are deleted
   */
  deleteStaleLessons(days: number = 30, minApplications: number = 2): Result<number, Error> {
    return tryCatch(() => {
      const result = this.db.run(
        `DELETE FROM lessons
         WHERE created_at < datetime('now', '-' || ? || ' days')
         AND times_applied < ?`,
        [days, minApplications]
      );
      return result.changes;
    });
  }

  /**
   * Run full auto-GC cycle:
   * 1. Delete garbage lessons (JSON fragments)
   * 2. Delete stale unused lessons (>30 days, <2 applications)
   * 3. Compact if above threshold
   *
   * @param threshold Maximum lessons to keep (default: 20)
   * @param staleDays Delete unused lessons older than this (default: 30)
   */
  autoGC(
    threshold: number = 20,
    staleDays: number = 30
  ): Result<{ garbage: number; stale: number; compacted: number }, Error> {
    return tryCatch(() => {
      const garbageResult = this.deleteGarbageLessons();
      const garbage = garbageResult.ok ? garbageResult.data : 0;

      const staleResult = this.deleteStaleLessons(staleDays, 2);
      const stale = staleResult.ok ? staleResult.data : 0;

      const compactResult = this.compactLessons(threshold);
      const compacted = compactResult.ok ? compactResult.data : 0;

      return { garbage, stale, compacted };
    });
  }
}

// ============================================================================
// Helpers
// ============================================================================

function prefixKeys<T extends Record<string, unknown>>(obj: T): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(obj)) {
    result[`$${key}`] = value;
  }
  return result;
}

// ============================================================================
// Singleton Export
// ============================================================================

let dbInstance: EvolutionDB | null = null;

export function getDB(): Result<EvolutionDB, Error> {
  if (dbInstance) return Ok(dbInstance);

  const result = EvolutionDB.init();
  if (result.ok) {
    dbInstance = result.data;
  }
  return result;
}

export function closeDB(): void {
  if (dbInstance) {
    dbInstance.close();
    dbInstance = null;
  }
}
