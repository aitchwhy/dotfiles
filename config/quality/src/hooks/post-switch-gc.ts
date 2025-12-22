#!/usr/bin/env bun
/**
 * Post-Switch GC Hook
 *
 * Runs after darwin-rebuild switch. Effect-based, no try/catch.
 * - Checks if command was darwin-rebuild switch
 * - Counts Nix generations
 * - Runs GC if >10 generations (background)
 */

import { Effect, pipe, Console, Schema } from "effect";
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
const METRICS_DIR = `${HOME}/.claude-metrics`;
const GC_LOG = `${METRICS_DIR}/gc.log`;
const MAX_GENERATIONS = 10;
const GC_OLDER_THAN = "7d";

// =============================================================================
// Types
// =============================================================================

type PostToolUseOutput = {
	readonly continue: boolean;
	readonly additionalContext?: string;
};

const PostToolUseInputSchema = Schema.Struct({
	hook_event_name: Schema.Literal("PostToolUse"),
	tool_name: Schema.String,
	tool_input: Schema.Struct({
		command: Schema.optional(Schema.String),
	}),
	tool_result: Schema.optional(Schema.String),
});

// =============================================================================
// Helpers
// =============================================================================

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

const isDarwinRebuildSwitch = (toolName: string, command: string | undefined) => {
	if (toolName !== "Bash") return false;
	if (!command) return false;
	return command.includes("darwin-rebuild") && command.includes("switch");
};

const commandSucceeded = (result: string | undefined) => {
	if (!result) return false;
	const lower = result.toLowerCase();
	return !lower.includes("error");
};

const countGenerations = Effect.gen(function* () {
	const result = yield* Effect.tryPromise(async () => {
		const { stdout } = await execAsync("darwin-rebuild --list-generations 2>/dev/null");
		return stdout.trim().split("\n").filter(Boolean).length;
	});
	return result;
});

const runGcBackground = (genCount: number) =>
	Effect.sync(() => {
		const timestamp = new Date().toISOString();

		// Spawn GC process in background
		const script = `
			mkdir -p "${METRICS_DIR}"
			echo "[${timestamp}] Starting auto-GC (${genCount} generations)" >> "${GC_LOG}"
			sudo nix-collect-garbage --delete-older-than ${GC_OLDER_THAN} >> "${GC_LOG}" 2>&1 || true
			nix store optimise >> "${GC_LOG}" 2>&1 || true
			NEW_COUNT=$(darwin-rebuild --list-generations 2>/dev/null | wc -l | tr -d ' ')
			echo "[$(date -Iseconds)] Auto-GC complete (${genCount} → $NEW_COUNT generations)" >> "${GC_LOG}"
		`;

		const child = spawn("bash", ["-c", script], {
			detached: true,
			stdio: "ignore",
		});
		child.unref();
	});

const outputResult = (result: PostToolUseOutput) =>
	Console.log(JSON.stringify(result));

// =============================================================================
// Main
// =============================================================================

const main = Effect.gen(function* () {
	// 1. Parse input
	const rawInput = yield* readStdin.pipe(Effect.catchAll(() => Effect.succeed("")));
	const parsed = yield* Effect.try({
		try: () => JSON.parse(rawInput),
		catch: () => ({}),
	});

	const input = parsed as {
		tool_name?: string;
		tool_input?: { command?: string };
		tool_result?: string;
	};

	// 2. Check if this is darwin-rebuild switch
	const toolName = input.tool_name ?? "";
	const command = input.tool_input?.command;

	if (!isDarwinRebuildSwitch(toolName, command)) {
		yield* outputResult({ continue: true });
		return;
	}

	// 3. Check if command succeeded
	if (!commandSucceeded(input.tool_result)) {
		yield* outputResult({ continue: true });
		return;
	}

	// 4. Count generations
	const genCount = yield* countGenerations.pipe(
		Effect.catchAll(() => Effect.succeed(0))
	);

	// 5. Run GC if needed (background)
	if (genCount > MAX_GENERATIONS) {
		yield* runGcBackground(genCount);
	}

	// 6. Always continue
	yield* outputResult({ continue: true });
});

pipe(
	main,
	Effect.catchAll((error) =>
		outputResult({ continue: true, additionalContext: `Hook error: ${String(error)}` })
	),
	Effect.runPromise,
);
