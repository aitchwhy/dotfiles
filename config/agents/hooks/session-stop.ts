#!/usr/bin/env bun
/**
 * Session Stop Hook - Consolidated Stop handler
 *
 * Orchestrates existing TypeScript tools:
 * - lesson-writer.ts (best-effort)
 * - consolidate.ts (best-effort)
 * - verification-gate.ts (BLOCKING)
 * - grade.ts (background)
 *
 * Exit 2 if verification-gate blocks (unverified claims).
 */

import { Effect, pipe, Schema } from "effect";
import { appendFileSync, mkdirSync, existsSync, readdirSync, statSync } from "node:fs";
import { join, dirname } from "node:path";
import { homedir } from "node:os";
import { SpawnError } from "../evolution/lib/errors";

// =============================================================================
// Configuration
// =============================================================================

const HOME = homedir();
const DOTFILES = process.env.DOTFILES ?? join(HOME, "dotfiles");
const LOG_FILE = join(HOME, ".claude", "session.log");
const METRICS_DIR = join(HOME, ".claude-metrics");

const LESSON_WRITER = join(DOTFILES, "config/agents/hooks/lesson-writer.ts");
const CONSOLIDATE = join(DOTFILES, "config/agents/evolution/consolidate.ts");
const VERIFY_GATE = join(DOTFILES, "config/agents/hooks/verification-gate.ts");
const GRADE_SCRIPT = join(DOTFILES, "config/agents/evolution/grade.ts");

// =============================================================================
// Schema
// =============================================================================

const StopInputSchema = Schema.Struct({
	hook_event_name: Schema.optional(Schema.String),
	session_id: Schema.optional(Schema.String),
	transcript_path: Schema.optional(Schema.String),
});

// =============================================================================
// Script Runner with SpawnError
// =============================================================================

interface SpawnResult {
	readonly exitCode: number;
	readonly stdout: string;
	readonly stderr: string;
}

const runScript = (
	script: string,
	args: readonly string[],
	stdin?: string,
): Effect.Effect<SpawnResult, SpawnError> =>
	Effect.tryPromise({
		try: async () => {
			const proc = Bun.spawn(["bun", "run", script, ...args], {
				stdin: stdin ? new Blob([stdin]) : undefined,
				stdout: "pipe",
				stderr: "pipe",
				cwd: DOTFILES,
			});

			const [exitCode, stdout, stderr] = await Promise.all([
				proc.exited,
				new Response(proc.stdout).text(),
				new Response(proc.stderr).text(),
			]);

			// Allow 0 (success) and 2 (blocking) as valid exit codes
			if (exitCode !== 0 && exitCode !== 2) {
				throw { script, exitCode, stderr };
			}

			return { exitCode, stdout, stderr };
		},
		catch: (e) =>
			new SpawnError({
				script,
				exitCode: typeof e === "object" && e !== null && "exitCode" in e
					? (e as { exitCode: number }).exitCode
					: -1,
				stderr: typeof e === "object" && e !== null && "stderr" in e
					? (e as { stderr: string }).stderr
					: String(e),
			}),
	});

// =============================================================================
// Effects
// =============================================================================

const logSessionEnd = Effect.sync(() => {
	const logDir = dirname(LOG_FILE);
	if (!existsSync(logDir)) {
		mkdirSync(logDir, { recursive: true });
	}

	// Get git stats (best effort)
	let filesModified = 0;
	let commits = 0;

	try {
		const gitDiff = Bun.spawnSync(["git", "diff", "--name-only", "HEAD~5"], {
			cwd: process.cwd(),
		});
		if (gitDiff.exitCode === 0) {
			filesModified = gitDiff.stdout.toString().split("\n").filter(Boolean).length;
		}

		const gitLog = Bun.spawnSync(["git", "log", "--oneline", "--since=1 hour ago"], {
			cwd: process.cwd(),
		});
		if (gitLog.exitCode === 0) {
			commits = gitLog.stdout.toString().split("\n").filter(Boolean).length;
		}
	} catch {
		// Ignore git errors
	}

	const timestamp = new Date().toISOString();
	const dir = process.cwd().split("/").pop() ?? "unknown";
	appendFileSync(
		LOG_FILE,
		`[${timestamp}] Session ended | Dir: ${dir} | Files: ${filesModified} modified | Commits: ${commits}\n`,
	);

	return { logged: true };
});

const findTranscriptPath = (inputPath: string | undefined): Effect.Effect<string | null> =>
	Effect.sync(() => {
		// Use provided path if valid
		if (inputPath && existsSync(inputPath)) {
			return inputPath;
		}

		// Fallback: find recent session files
		const searchDirs = [
			join(HOME, ".claude", "projects"),
			join(HOME, ".claude", "sessions"),
		];

		for (const dir of searchDirs) {
			if (!existsSync(dir)) continue;

			try {
				// Find .jsonl files modified in last 10 minutes
				const now = Date.now();
				const tenMinutes = 10 * 60 * 1000;

				const findRecent = (searchDir: string): string | null => {
					const entries = readdirSync(searchDir, { withFileTypes: true });
					for (const entry of entries) {
						const fullPath = join(searchDir, entry.name);
						if (entry.isDirectory()) {
							const found = findRecent(fullPath);
							if (found) return found;
						} else if (entry.name.endsWith(".jsonl")) {
							const stat = statSync(fullPath);
							if (now - stat.mtimeMs < tenMinutes) {
								return fullPath;
							}
						}
					}
					return null;
				};

				const found = findRecent(dir);
				if (found) return found;
			} catch {
				// Skip inaccessible directories
			}
		}

		return null;
	});

const runLessonWriter = (transcriptPath: string | null) =>
	transcriptPath && existsSync(LESSON_WRITER)
		? runScript(LESSON_WRITER, [transcriptPath]).pipe(
				Effect.catchAll(() => Effect.succeed({ exitCode: 0, stdout: "", stderr: "" })),
			)
		: Effect.succeed({ exitCode: 0, stdout: "", stderr: "" });

const runConsolidate = () =>
	existsSync(CONSOLIDATE)
		? runScript(CONSOLIDATE, []).pipe(
				Effect.catchAll(() => Effect.succeed({ exitCode: 0, stdout: "", stderr: "" })),
			)
		: Effect.succeed({ exitCode: 0, stdout: "", stderr: "" });

const runVerificationGate = (stdin: string) =>
	existsSync(VERIFY_GATE)
		? runScript(VERIFY_GATE, [], stdin)
		: Effect.succeed({ exitCode: 0, stdout: "", stderr: "" });

const spawnGradeInBackground = Effect.sync(() => {
	if (existsSync(GRADE_SCRIPT)) {
		if (!existsSync(METRICS_DIR)) {
			mkdirSync(METRICS_DIR, { recursive: true });
		}

		// Fire and forget - don't await
		Bun.spawn(["bun", "run", GRADE_SCRIPT], {
			stdout: Bun.file(join(METRICS_DIR, "last-grade.log")),
			stderr: "inherit",
			cwd: DOTFILES,
		});
	}
	return { spawned: true };
});

// =============================================================================
// Main Pipeline
// =============================================================================

const readStdin = Effect.tryPromise({
	try: () => new Response(Bun.stdin.stream()).text(),
	catch: () => "",
}).pipe(Effect.catchAll(() => Effect.succeed("")));

const program = Effect.gen(function* () {
	// Read stdin
	const stdinText = yield* readStdin;

	// Parse input (lenient)
	let parsed: Record<string, unknown> = {};
	try {
		parsed = JSON.parse(stdinText || "{}");
	} catch {
		// Invalid JSON, use empty object
	}

	const input = Schema.decodeUnknownSync(StopInputSchema)(parsed);

	// 1. Log session end
	yield* logSessionEnd;

	// 2. Find transcript path
	const transcriptPath = yield* findTranscriptPath(input.transcript_path);

	// 3. Run lesson writer (best-effort)
	yield* runLessonWriter(transcriptPath);

	// 4. Run consolidation (best-effort)
	yield* runConsolidate();

	// 5. Run verification gate (BLOCKING)
	const gateResult = yield* runVerificationGate(stdinText).pipe(
		Effect.catchAll((error) => {
			// If spawn failed entirely, log but don't block
			process.stderr.write(JSON.stringify({
				level: "warning",
				context: "verification-gate",
				message: `Spawn failed: ${error.stderr}`,
				timestamp: new Date().toISOString(),
			}) + "\n");
			return Effect.succeed({ exitCode: 0, stdout: "", stderr: "" });
		}),
	);

	// If verification gate returned exit code 2, propagate block
	if (gateResult.exitCode === 2) {
		process.stdout.write(gateResult.stdout || JSON.stringify({ continue: false }) + "\n");
		process.exit(2);
	}

	// 6. Spawn grade in background (non-blocking)
	yield* spawnGradeInBackground;

	// 7. Success
	process.stdout.write(JSON.stringify({ continue: true }) + "\n");
});

// =============================================================================
// Run
// =============================================================================

pipe(
	program,
	Effect.catchAll((error) => {
		// Log error to stderr but don't block session
		process.stderr.write(JSON.stringify({
			level: "error",
			context: "session-stop",
			message: String(error),
			timestamp: new Date().toISOString(),
		}) + "\n");
		// Still allow session to end
		process.stdout.write(JSON.stringify({ continue: true }) + "\n");
		return Effect.void;
	}),
	Effect.runPromise,
);
