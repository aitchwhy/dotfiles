#!/usr/bin/env bun
/**
 * Session Stop Hook
 *
 * Runs at Stop event. Effect-based, no try/catch.
 * - Logs session end with git stats
 * - Runs lesson-writer (best-effort)
 * - Runs consolidation (best-effort)
 * - Runs verification-gate (blocking)
 * - Runs grading (background)
 */

import { Console, Effect, pipe } from "effect";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import * as os from "node:os";
import { exec, spawn } from "node:child_process";
import { promisify } from "node:util";

const execAsync = promisify(exec);

// =============================================================================
// Config
// =============================================================================

const HOME = os.homedir();
const DOTFILES = `${HOME}/dotfiles`;
const METRICS_DIR = `${HOME}/.claude-metrics`;
const LOG_FILE = `${HOME}/.claude/session.log`;
const VERIFY_GATE = `${DOTFILES}/config/agents/hooks/verification-gate.ts`;
const GRADE_SCRIPT = `${DOTFILES}/config/agents/evolution/grade.sh`;
const LESSON_WRITER = `${DOTFILES}/config/agents/hooks/lesson-writer.ts`;
const CONSOLIDATE = `${DOTFILES}/config/agents/evolution/consolidate.ts`;

// =============================================================================
// Types
// =============================================================================

type StopOutput = {
	readonly continue: boolean;
	readonly additionalContext?: string;
};


// =============================================================================
// Helpers
// =============================================================================

const fileExists = (filePath: string) =>
	Effect.tryPromise(() =>
		fs.access(filePath).then(() => true).catch(() => false)
	);

const readStdin = Effect.gen(function* () {
	const chunks: Buffer[] = [];
	const stdin = Bun.stdin;

	if (stdin.stream === null) return "";

	const reader = stdin.stream().getReader();

	while (true) {
		const { done, value } = yield* Effect.tryPromise(() => reader.read());
		if (done) break;
		if (value) chunks.push(Buffer.from(value));
	}

	return Buffer.concat(chunks).toString();
});

const logSessionEnd = Effect.gen(function* () {
	yield* Effect.tryPromise(async () => {
		await fs.mkdir(path.dirname(LOG_FILE), { recursive: true });
		await fs.mkdir(METRICS_DIR, { recursive: true });
	});

	const filesModified = yield* Effect.tryPromise(async () => {
		const { stdout } = await execAsync("git diff --name-only HEAD~5 2>/dev/null || echo ''");
		return stdout.trim().split("\n").filter(Boolean).length;
	}).pipe(Effect.catchAll(() => Effect.succeed(0)));

	const recentCommits = yield* Effect.tryPromise(async () => {
		const { stdout } = await execAsync("git log --oneline --since='1 hour ago' 2>/dev/null || echo ''");
		return stdout.trim().split("\n").filter(Boolean).length;
	}).pipe(Effect.catchAll(() => Effect.succeed(0)));

	const timestamp = new Date().toISOString();
	const cwd = path.basename(process.cwd());
	const logLine = `[${timestamp}] Session ended | Dir: ${cwd} | Files: ${filesModified} modified | Commits: ${recentCommits}`;

	yield* Effect.tryPromise(() => fs.appendFile(LOG_FILE, `${logLine}\n`));
});

const findTranscript = (inputPath: string | undefined) =>
	Effect.gen(function* () {
		if (inputPath) {
			const exists = yield* fileExists(inputPath);
			if (exists) return inputPath;
		}

		const sessionDirs = [`${HOME}/.claude/projects`, `${HOME}/.claude/sessions`];

		for (const dir of sessionDirs) {
			const exists = yield* fileExists(dir);
			if (!exists) continue;

			const result = yield* Effect.tryPromise(async () => {
				const { stdout } = await execAsync(
					`fd -t f -e jsonl --changed-within 10m . "${dir}" 2>/dev/null | head -1`
				);
				return stdout.trim();
			}).pipe(Effect.catchAll(() => Effect.succeed("")));

			if (result) return result;
		}

		return undefined;
	});

const runLessonWriter = (transcriptPath: string) =>
	Effect.gen(function* () {
		const exists = yield* fileExists(LESSON_WRITER);
		if (!exists) return;

		yield* Effect.tryPromise(async () => {
			await execAsync(`bun run "${LESSON_WRITER}" "${transcriptPath}" 2>/dev/null`);
		}).pipe(Effect.catchAll(() => Effect.succeed(undefined)));
	});

const runConsolidation = Effect.gen(function* () {
	const exists = yield* fileExists(CONSOLIDATE);
	if (!exists) return;

	yield* Effect.tryPromise(async () => {
		await execAsync(`bun run "${CONSOLIDATE}" >/dev/null 2>&1`);
	}).pipe(Effect.catchAll(() => Effect.succeed(undefined)));
});

const runVerificationGate = (rawInput: string) =>
	Effect.gen(function* () {
		const exists = yield* fileExists(VERIFY_GATE);
		if (!exists) return { passed: true, output: "" };

		const result = yield* Effect.tryPromise(async () => {
			const { stdout, stderr } = await execAsync(
				`echo '${rawInput.replace(/'/g, "'\\''")}' | bun run "${VERIFY_GATE}" 2>&1`
			);
			return { stdout, stderr, exitCode: 0 };
		}).pipe(
			Effect.catchAll((error) => {
				const err = error as { stdout?: string; stderr?: string; code?: number };
				return Effect.succeed({
					stdout: err.stdout ?? "",
					stderr: err.stderr ?? "",
					exitCode: err.code ?? 1,
				});
			})
		);

		if (result.exitCode === 2) {
			return { passed: false, output: result.stdout || result.stderr };
		}

		return { passed: true, output: "" };
	});

const runGradingBackground = Effect.gen(function* () {
	const exists = yield* fileExists(GRADE_SCRIPT);
	if (!exists) return;

	// Spawn in background, don't wait
	yield* Effect.sync(() => {
		const logPath = `${METRICS_DIR}/last-grade.log`;
		const child = spawn("bash", [GRADE_SCRIPT], {
			detached: true,
			stdio: ["ignore", "pipe", "pipe"],
		});
		child.unref();

		const logStream = Bun.file(logPath).writer();
		child.stdout?.on("data", (data: Buffer) => logStream.write(data));
		child.stderr?.on("data", (data: Buffer) => logStream.write(data));
	});
});

const outputResult = (result: StopOutput) =>
	Console.log(JSON.stringify(result));

// =============================================================================
// Main
// =============================================================================

const main = Effect.gen(function* () {
	// 1. Log session end
	yield* logSessionEnd.pipe(Effect.catchAll(() => Effect.succeed(undefined)));

	// 2. Parse input
	const rawInput = yield* readStdin.pipe(Effect.catchAll(() => Effect.succeed("")));
	const parsed = yield* Effect.try({
		try: () => (rawInput ? JSON.parse(rawInput) : {}),
		catch: () => ({}),
	});
	const transcriptPath = (parsed as { transcript_path?: string }).transcript_path;

	// 3. Find transcript
	const transcript = yield* findTranscript(transcriptPath).pipe(
		Effect.catchAll(() => Effect.succeed(undefined))
	);

	// 4. Run lesson writer (best-effort)
	if (transcript) {
		yield* runLessonWriter(transcript);
	}

	// 5. Run consolidation (best-effort)
	yield* runConsolidation;

	// 6. Verification gate (BLOCKING)
	const gateResult = yield* runVerificationGate(rawInput);
	if (!gateResult.passed) {
		yield* outputResult({
			continue: false,
			additionalContext: gateResult.output,
		});
		yield* Effect.sync(() => {
			process.exitCode = 2;
		});
		return;
	}

	// 7. Run grading (background)
	yield* runGradingBackground;

	// 8. Success
	yield* outputResult({ continue: true });
});

pipe(
	main,
	Effect.catchAll((error) =>
		outputResult({ continue: true, additionalContext: `Hook error: ${String(error)}` })
	),
	Effect.runPromise,
);
