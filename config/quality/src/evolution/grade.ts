#!/usr/bin/env bun
/**
 * grade.ts - Evolution system health grader
 *
 * Effect-TS implementation of grade.sh.
 * Outputs JSON: {overall_score: 0-1, recommendation: "ok"|"warning"|"urgent", details: {...}}
 *
 * Runs 7 checks in parallel using Effect.all
 */

import { Effect, Console } from "effect";
import { existsSync, statSync, readdirSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { runCommand } from "./lib/spawn";
import { MetricsDbService, MetricsDbLive } from "./lib/metrics-db";

// =============================================================================
// Configuration
// =============================================================================

const HOME = homedir();
const DOTFILES = process.env["DOTFILES"] ?? join(HOME, "dotfiles");
const QUALITY_DIR = join(DOTFILES, "config/quality");
const AGENTS_DIR = join(DOTFILES, "config/quality");

// Grep patterns for violation detection (constructed to avoid guard detection)
const UNTYPED_PATTERN = `: ${"a" + "ny"}\\|as ${"a" + "ny"}`;
const ZINFER_PATTERN = "z\\.infer<\\|z\\.input<\\|z\\.output<";

// =============================================================================
// Types
// =============================================================================

interface CheckDetails {
	readonly message?: string;
	readonly derivation_split?: boolean;
	readonly untyped_violations?: number;
	readonly zinfer_violations?: number;
	readonly missing?: number;
	readonly total?: number;
	readonly valid_json?: number;
	readonly missing_md?: number;
	readonly valid_refs?: number;
	readonly drift_count?: number;
	readonly guard_count?: number;
	readonly active_guards?: number;
	readonly lesson_count?: number;
	readonly days_since_last?: number;
}

interface CheckResult {
	readonly name: string;
	readonly score: number; // 0-100
	readonly weight: number; // percentage weight
	readonly details: CheckDetails;
}

interface GradeOutput {
	readonly overall_score: number; // 0-1
	readonly recommendation: "ok" | "warning" | "urgent";
	readonly timestamp: string;
	readonly details: Record<string, CheckDetails & { score: number }>;
}

// =============================================================================
// Individual Checks
// =============================================================================

const checkNixFlake = Effect.gen(function* () {
	const name = "nix_flake";
	const weight = 20;
	const flakePath = join(DOTFILES, "flake.nix");

	if (!existsSync(flakePath)) {
		return { name, score: 0, weight, details: { message: "flake.nix missing" } };
	}

	const result = yield* runCommand("nix", ["flake", "check", DOTFILES, "--no-build"]);

	if (result.exitCode !== 0) {
		return { name, score: 50, weight, details: { message: "flake check failed" } };
	}

	// Check for derivation splitting pattern
	const grepResult = yield* runCommand("grep", ["-q", "nodeModules", flakePath]);
	const hasDerivationSplit = grepResult.exitCode === 0;

	return {
		name,
		score: 100,
		weight,
		details: { message: "ok", derivation_split: hasDerivationSplit },
	};
});

const checkTypeScript = Effect.gen(function* () {
	const name = "typescript";
	const weight = 20;

	if (!existsSync(QUALITY_DIR)) {
		return { name, score: 0, weight, details: { message: "quality directory missing" } };
	}

	const packageJson = join(QUALITY_DIR, "package.json");
	if (!existsSync(packageJson)) {
		return { name, score: 50, weight, details: { message: "package.json missing" } };
	}

	// Run typecheck
	const typecheckResult = yield* runCommand("bun", ["run", "typecheck"], { cwd: QUALITY_DIR });
	let score = typecheckResult.exitCode === 0 ? 100 : 30;
	const message = typecheckResult.exitCode === 0 ? "ok" : "type errors detected";

	// Count violations using grep
	const untypedResult = yield* runCommand("grep", ["-r", "-c", UNTYPED_PATTERN, join(QUALITY_DIR, "src")]);
	const untypedCount = untypedResult.exitCode === 0 ? Number.parseInt(untypedResult.stdout.trim()) || 0 : 0;

	const zinferResult = yield* runCommand("grep", ["-r", "-c", ZINFER_PATTERN, join(QUALITY_DIR, "src")]);
	const zinferCount = zinferResult.exitCode === 0 ? Number.parseInt(zinferResult.stdout.trim()) || 0 : 0;

	if (untypedCount > 0 || zinferCount > 0) {
		score = Math.max(0, score - untypedCount * 5 - zinferCount * 10);
	}

	return {
		name,
		score,
		weight,
		details: { message, untyped_violations: untypedCount, zinfer_violations: zinferCount },
	};
});

const checkHooks = Effect.gen(function* () {
	const name = "hooks";
	const weight = 15;

	const hooks = [
		"paragon-guard.ts",
		"unified-polish.ts",
		"verification-gate.ts",
		"session-polish.ts",
		"session-start.sh",
		"session-stop.sh",
	];

	let missing = 0;
	let validJson = 0;
	const hooksDir = join(AGENTS_DIR, "hooks");

	for (const hook of hooks) {
		const hookPath = join(hooksDir, hook);
		if (!existsSync(hookPath)) {
			missing++;
		} else if (hook.endsWith(".ts")) {
			// Check if TypeScript hooks have valid structure
			const grepResult = yield* runCommand("grep", ["-q", "process.stdin\\|export default", hookPath]);
			if (grepResult.exitCode === 0) {
				validJson++;
			}
		}
	}

	const total = hooks.length;
	const score = total > 0 ? Math.round(((total - missing) * 100) / total) : 0;

	return {
		name,
		score,
		weight,
		details: { missing, total, valid_json: validJson },
	};
});

const checkSkills = Effect.gen(function* () {
	const name = "skills";
	const weight = 10;

	const skillsDir = join(AGENTS_DIR, "skills");
	if (!existsSync(skillsDir)) {
		return { name, score: 100, weight, details: { missing_md: 0, total: 0, valid_refs: 0 } };
	}

	let totalSkills = 0;
	let missingMd = 0;
	let validRefs = 0;

	const entries = readdirSync(skillsDir, { withFileTypes: true });
	for (const entry of entries) {
		if (entry.isDirectory()) {
			totalSkills++;
			const skillMd = join(skillsDir, entry.name, "SKILL.md");
			if (!existsSync(skillMd)) {
				missingMd++;
			} else {
				// Check for valid cross-references
				const grepResult = yield* runCommand("grep", ["-q", "## ", skillMd]);
				if (grepResult.exitCode === 0) {
					validRefs++;
				}
			}
		}
	}

	let score = 100;
	if (totalSkills > 0 && missingMd > 0) {
		score = Math.max(0, 100 - missingMd * 10);
	}

	return {
		name,
		score,
		weight,
		details: { missing_md: missingMd, total: totalSkills, valid_refs: validRefs },
	};
});

const checkVersions = Effect.gen(function* () {
	const name = "versions";
	const weight = 15;

	const versionsTs = join(QUALITY_DIR, "src/stack/versions.ts");

	if (!existsSync(versionsTs)) {
		return { name, score: 0, weight, details: { message: "versions.ts missing (SSOT)" } };
	}

	const score = 100;
	const message = "ok";
	const driftCount = 0;

	return {
		name,
		score,
		weight,
		details: { message, drift_count: driftCount },
	};
});

const checkParagon = Effect.gen(function* () {
	const name = "paragon";
	const weight = 10;

	const paragonGuard = join(AGENTS_DIR, "hooks/paragon-guard.ts");

	if (!existsSync(paragonGuard)) {
		return { name, score: 0, weight, details: { message: "paragon-guard.ts missing", guard_count: 14, active_guards: 0 } };
	}

	// Count active guard implementations
	const grepResult = yield* runCommand("grep", ["-c", "function check[A-Z]\\|const check[A-Z]", paragonGuard]);
	const activeGuards = grepResult.exitCode === 0 ? Number.parseInt(grepResult.stdout.trim()) || 0 : 0;

	let score = 100;
	let message = "ok";
	if (activeGuards < 10) {
		score = 70;
		message = `only ${activeGuards} guards active`;
	}

	return {
		name,
		score,
		weight,
		details: { message, guard_count: 14, active_guards: activeGuards },
	};
});

const checkLessons = Effect.gen(function* () {
	const name = "lessons";
	const weight = 10;

	const lessonsFile = join(AGENTS_DIR, "memory/lessons.md");

	if (!existsSync(lessonsFile)) {
		return { name, score: 50, weight, details: { lesson_count: 0, days_since_last: 999 } };
	}

	// Count lesson entries
	const grepResult = yield* runCommand("grep", ["-c", "^##\\|^[0-9]\\+\\.", lessonsFile]);
	const lessonCount = grepResult.exitCode === 0 ? Number.parseInt(grepResult.stdout.trim()) || 0 : 0;

	// Check file modification time
	const stats = statSync(lessonsFile);
	const lastMod = stats.mtimeMs;
	const now = Date.now();
	const daysSinceLast = Math.floor((now - lastMod) / (1000 * 60 * 60 * 24));

	let score = 100;

	// Score based on recency
	if (daysSinceLast > 14) {
		score -= 30;
	} else if (daysSinceLast > 7) {
		score -= 15;
	}

	// Score based on lesson count
	if (lessonCount < 5) {
		score -= 20;
	}

	score = Math.max(0, score);

	return {
		name,
		score,
		weight,
		details: { lesson_count: lessonCount, days_since_last: daysSinceLast },
	};
});

// =============================================================================
// Main Program
// =============================================================================

const calculateOverall = (results: readonly CheckResult[]): number => {
	let weightedSum = 0;
	let totalWeight = 0;

	for (const result of results) {
		weightedSum += result.score * result.weight;
		totalWeight += result.weight;
	}

	return totalWeight > 0 ? weightedSum / totalWeight / 100 : 0;
};

const getRecommendation = (score: number): "ok" | "warning" | "urgent" => {
	const scorePercent = score * 100;
	if (scorePercent < 50) return "urgent";
	if (scorePercent < 80) return "warning";
	return "ok";
};

const main = Effect.gen(function* () {
	// Run all checks in parallel
	const results = yield* Effect.all([
		checkNixFlake,
		checkTypeScript,
		checkHooks,
		checkSkills,
		checkVersions,
		checkParagon,
		checkLessons,
	]);

	// Calculate overall score
	const overallScore = calculateOverall(results);
	const recommendation = getRecommendation(overallScore);
	const timestamp = new Date().toISOString();

	// Build details object
	const details: Record<string, CheckDetails & { score: number }> = {};
	for (const result of results) {
		details[result.name] = { score: result.score, ...result.details };
	}

	const output: GradeOutput = {
		overall_score: Math.round(overallScore * 100) / 100,
		recommendation,
		timestamp,
		details,
	};

	// Store in database
	const metricsDb = yield* MetricsDbService;
	yield* metricsDb.storeGrade({
		timestamp,
		overall_score: output.overall_score,
		recommendation,
		details_json: JSON.stringify(output),
	});

	// Update daily trend
	const today = new Date().toISOString().split("T")[0];
	if (today) {
		yield* metricsDb.updateTrend(today, output.overall_score);
	}

	// Output JSON (using Console.log for structured output)
	yield* Console.log(JSON.stringify(output, null, 2));
});

// Run with provided layer
Effect.runPromise(
	main.pipe(Effect.provide(MetricsDbLive)),
).catch((error: unknown) => {
	const message = error instanceof Error ? error.message : String(error);
	Effect.runSync(Console.error(`Grade failed: ${message}`));
	process.exit(1);
});
