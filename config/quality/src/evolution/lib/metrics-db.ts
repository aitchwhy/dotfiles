/**
 * MetricsDb Service - Effect Layer for SQLite metrics database
 *
 * Uses Context.Tag and Layer for proper dependency injection.
 * Parameterized queries prevent SQL injection (bun:sqlite).
 */

import { Context, Effect, Layer } from "effect";
import { Database } from "bun:sqlite";
import { existsSync, mkdirSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { DatabaseError } from "./errors";

// =============================================================================
// Types
// =============================================================================

export interface GradeRecord {
	readonly timestamp: string;
	readonly overall_score: number;
	readonly recommendation: "ok" | "warning" | "urgent";
	readonly details_json: string;
}

export interface TrendRecord {
	readonly date: string;
	readonly avg_score: number;
	readonly min_score: number;
	readonly max_score: number;
	readonly check_count: number;
}

// =============================================================================
// Service Definition
// =============================================================================

export interface MetricsDb {
	readonly storeGrade: (grade: GradeRecord) => Effect.Effect<void, DatabaseError>;
	readonly updateTrend: (
		date: string,
		score: number,
	) => Effect.Effect<void, DatabaseError>;
	readonly getRecentGrades: (
		limit: number,
	) => Effect.Effect<readonly GradeRecord[], DatabaseError>;
	readonly getWeeklyTrends: (
		limit: number,
	) => Effect.Effect<readonly TrendRecord[], DatabaseError>;
}

export class MetricsDbService extends Context.Tag("MetricsDb")<
	MetricsDbService,
	MetricsDb
>() {}

// =============================================================================
// Implementation
// =============================================================================

const METRICS_DIR = join(homedir(), ".claude-metrics");
const DB_FILE = join(METRICS_DIR, "evolution.db");

const initSchema = (db: Database): void => {
	db.exec(`
		CREATE TABLE IF NOT EXISTS grades (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			timestamp TEXT NOT NULL,
			overall_score REAL NOT NULL,
			recommendation TEXT NOT NULL,
			details_json TEXT NOT NULL
		);

		CREATE TABLE IF NOT EXISTS trends (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			date TEXT NOT NULL UNIQUE,
			avg_score REAL NOT NULL,
			min_score REAL NOT NULL,
			max_score REAL NOT NULL,
			check_count INTEGER NOT NULL
		);

		CREATE INDEX IF NOT EXISTS idx_grades_timestamp ON grades(timestamp);
		CREATE INDEX IF NOT EXISTS idx_trends_date ON trends(date);
	`);
};

const makeMetricsDb = (db: Database): MetricsDb => ({
	storeGrade: (grade) =>
		Effect.try({
			try: () => {
				const stmt = db.prepare(`
					INSERT INTO grades (timestamp, overall_score, recommendation, details_json)
					VALUES ($timestamp, $score, $recommendation, $details)
				`);
				stmt.run({
					$timestamp: grade.timestamp,
					$score: grade.overall_score,
					$recommendation: grade.recommendation,
					$details: grade.details_json,
				});
			},
			catch: (cause) =>
				new DatabaseError({ operation: "storeGrade", cause }),
		}),

	updateTrend: (date, score) =>
		Effect.try({
			try: () => {
				const stmt = db.prepare(`
					INSERT INTO trends (date, avg_score, min_score, max_score, check_count)
					VALUES ($date, $score, $score, $score, 1)
					ON CONFLICT(date) DO UPDATE SET
						avg_score = (avg_score * check_count + $score) / (check_count + 1),
						min_score = MIN(min_score, $score),
						max_score = MAX(max_score, $score),
						check_count = check_count + 1
				`);
				stmt.run({ $date: date, $score: score });
			},
			catch: (cause) =>
				new DatabaseError({ operation: "updateTrend", cause }),
		}),

	getRecentGrades: (limit) =>
		Effect.try({
			try: () => {
				const stmt = db.prepare<GradeRecord, { $limit: number }>(`
					SELECT timestamp, overall_score, recommendation, details_json
					FROM grades
					ORDER BY id DESC
					LIMIT $limit
				`);
				return stmt.all({ $limit: limit });
			},
			catch: (cause) =>
				new DatabaseError({ operation: "getRecentGrades", cause }),
		}),

	getWeeklyTrends: (limit) =>
		Effect.try({
			try: () => {
				const stmt = db.prepare<TrendRecord, { $limit: number }>(`
					SELECT date, avg_score, min_score, max_score, check_count
					FROM trends
					ORDER BY date DESC
					LIMIT $limit
				`);
				return stmt.all({ $limit: limit });
			},
			catch: (cause) =>
				new DatabaseError({ operation: "getWeeklyTrends", cause }),
		}),
});

// =============================================================================
// Layer
// =============================================================================

export const MetricsDbLive = Layer.sync(MetricsDbService, () => {
	// Ensure directory exists
	if (!existsSync(METRICS_DIR)) {
		mkdirSync(METRICS_DIR, { recursive: true });
	}

	const db = new Database(DB_FILE);
	initSchema(db);

	return makeMetricsDb(db);
});
