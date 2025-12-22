#!/usr/bin/env bun
/**
 * Session Initialization Hook
 *
 * Runs at SessionStart. Effect pipeline, never throws.
 * - Cleans up stale plan files (>7 days)
 * - Warns about environment issues
 * - Checks evolution metrics staleness
 */

import { Effect, pipe } from "effect";
import { existsSync, readdirSync, statSync, unlinkSync, appendFileSync, mkdirSync, readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { homedir } from "node:os";

// =============================================================================
// Configuration
// =============================================================================

const PLANS_DIR = join(homedir(), ".claude", "plans");
const LOG_FILE = join(homedir(), ".claude", "session.log");
const STALE_DAYS = 7;
const STALE_MS = STALE_DAYS * 24 * 60 * 60 * 1000;
const DOTFILES = process.env.DOTFILES ?? join(homedir(), "dotfiles");
const METRICS_FILE = join(DOTFILES, ".claude-metrics", "latest.json");

// =============================================================================
// Effects
// =============================================================================

const logSessionStart = Effect.sync(() => {
	const logDir = dirname(LOG_FILE);
	if (!existsSync(logDir)) {
		mkdirSync(logDir, { recursive: true });
	}
	const timestamp = new Date().toISOString();
	const cwd = process.cwd();
	appendFileSync(LOG_FILE, `[${timestamp}] Session started: ${cwd}\n`);
	return { logged: true };
});

const cleanStalePlans = Effect.sync(() => {
	if (!existsSync(PLANS_DIR)) {
		return { cleaned: 0 };
	}

	const now = Date.now();
	const files = readdirSync(PLANS_DIR);
	let cleaned = 0;

	for (const file of files) {
		if (!file.endsWith(".md")) continue;

		const filePath = join(PLANS_DIR, file);
		try {
			const stat = statSync(filePath);
			if (now - stat.mtimeMs > STALE_MS) {
				unlinkSync(filePath);
				cleaned++;
			}
		} catch {
			// Skip files that can't be stat'd
		}
	}

	return { cleaned };
});

const checkEnvironment = Effect.sync(() => {
	const warnings: string[] = [];
	const cwd = process.cwd();

	// Check for Nix project not in shell
	if (existsSync(join(cwd, "flake.nix")) && !process.env.IN_NIX_SHELL) {
		warnings.push("Nix project - consider nix develop");
	}

	// Check for package-lock.json (should use pnpm)
	if (existsSync(join(cwd, "package-lock.json"))) {
		warnings.push("package-lock.json found - use pnpm");
	}

	// Check for .env without .env.example
	if (existsSync(join(cwd, ".env")) && !existsSync(join(cwd, ".env.example"))) {
		warnings.push(".env without .env.example");
	}

	return { warnings };
});

const checkEvolutionMetrics = Effect.sync(() => {
	if (!existsSync(METRICS_FILE)) {
		return { stale: false, context: null };
	}

	try {
		const stat = statSync(METRICS_FILE);
		const ageHours = Math.floor((Date.now() - stat.mtimeMs) / (60 * 60 * 1000));

		if (ageHours <= 24) {
			return { stale: false, context: null };
		}

		// Read metrics for context
		const content = readFileSync(METRICS_FILE, "utf-8");
		const metrics = JSON.parse(content) as {
			overall_score?: number;
			recommendation?: string;
		};

		const score = metrics.overall_score
			? Math.floor(metrics.overall_score * 100)
			: "?";
		const rec = metrics.recommendation ?? "unknown";

		return {
			stale: true,
			context: `Evolution: ${score}% (${rec}) - stale (${ageHours}h). Run: just evolve`,
		};
	} catch {
		return { stale: false, context: null };
	}
});

// =============================================================================
// Main Pipeline
// =============================================================================

const program = Effect.gen(function* () {
	// Run all checks in parallel
	const [_log, plans, env, metrics] = yield* Effect.all([
		logSessionStart,
		cleanStalePlans,
		checkEnvironment,
		checkEvolutionMetrics,
	], { concurrency: "unbounded" });

	// Build additional context
	const contextParts: string[] = [];

	if (plans.cleaned > 0) {
		contextParts.push(`Cleaned ${plans.cleaned} stale plan(s)`);
	}

	for (const warning of env.warnings) {
		contextParts.push(warning);
	}

	if (metrics.stale && metrics.context) {
		contextParts.push(metrics.context);
	}

	// Output JSON for Claude to consume
	const output = contextParts.length > 0
		? { continue: true, additionalContext: contextParts.join(". ") + "." }
		: { continue: true };

	process.stdout.write(JSON.stringify(output) + "\n");
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
			context: "session-init",
			message: String(error),
			timestamp: new Date().toISOString(),
		}) + "\n");
		// Still allow session to continue
		process.stdout.write(JSON.stringify({ continue: true }) + "\n");
		return Effect.void;
	}),
	Effect.runPromise,
);
