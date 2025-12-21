#!/usr/bin/env bun
/**
 * Pre-Tool-Use Hook
 *
 * Blocks writes that violate quality rules.
 * Effect-based, no try/catch.
 */

import { Effect, pipe, Schema } from "effect";
import { ALL_RULES } from "../rules";
import { isForbidden } from "../stack";
import {
	type PreToolUseInput,
	approve,
	block,
	isExcludedPath,
	isTypeScriptFile,
	outputDecision,
	parseInput,
	readStdin,
} from "./lib/effect-hook";
import { checkContent, filterBySeverity, formatMatches } from "./lib/ast-grep";

// =============================================================================
// Schemas
// =============================================================================

const DependenciesSchema = Schema.Record({
	key: Schema.String,
	value: Schema.String,
});

const PackageJsonSchema = Schema.Struct({
	dependencies: Schema.optional(DependenciesSchema),
	devDependencies: Schema.optional(DependenciesSchema),
});

// =============================================================================
// Helpers
// =============================================================================

const extractContent = (input: PreToolUseInput) => ({
	filePath: input.tool_input.file_path,
	content: input.tool_input.content ?? input.tool_input.new_string,
});

const checkRuleViolations = (content: string) =>
	Effect.gen(function* () {
		const matches = yield* checkContent(content, ALL_RULES);
		const errors = filterBySeverity(matches, ALL_RULES, "error");

		if (errors.length > 0) {
			return block(`Quality rule violations:\n\n${formatMatches(errors, ALL_RULES)}`);
		}

		return approve();
	});

const parseDependencies = (content: string) =>
	Effect.gen(function* () {
		const rawJson = yield* Effect.try({
			try: () => JSON.parse(content),
			catch: () => new Error("Invalid package.json"),
		});
		const pkg = yield* Schema.decodeUnknown(PackageJsonSchema)(rawJson);
		return { ...(pkg.dependencies ?? {}), ...(pkg.devDependencies ?? {}) };
	});

// =============================================================================
// Guard Checks
// =============================================================================

const checkTypeScriptContent = (input: PreToolUseInput) =>
	Effect.gen(function* () {
		const { filePath, content } = extractContent(input);

		if (!filePath || !content) return approve();
		if (!isTypeScriptFile(filePath)) return approve();
		if (isExcludedPath(filePath)) return approve("Excluded path");

		return yield* checkRuleViolations(content);
	});

const checkForbiddenPackages = (input: PreToolUseInput) =>
	Effect.gen(function* () {
		const { filePath, content } = extractContent(input);

		if (!filePath?.endsWith("package.json") || !content) return approve();

		const deps = yield* parseDependencies(content);

		for (const name of Object.keys(deps)) {
			const forbidden = isForbidden(name);
			if (forbidden) {
				return block(
					`Forbidden package: ${name}\nReason: ${forbidden.reason}\nAlternative: ${forbidden.alternative}`,
				);
			}
		}

		return approve();
	});

const checkDangerousCommands = (input: PreToolUseInput) =>
	Effect.gen(function* () {
		if (input.tool_name !== "Bash") return approve();

		const command = input.tool_input.command;
		if (!command) return approve();

		const dangerous = ["rm -rf /", "rm -rf ~", "chmod -R 777", "> /dev/sda", "mkfs.", ":(){:|:&};:"];
		const found = dangerous.find((p) => command.includes(p));

		return found ? block(`Dangerous command detected: ${found}`) : approve();
	});

// =============================================================================
// Main
// =============================================================================

const main = Effect.gen(function* () {
	const raw = yield* readStdin;
	const input = yield* parseInput(raw);

	for (const check of [checkTypeScriptContent, checkForbiddenPackages, checkDangerousCommands]) {
		const result = yield* check(input);
		if (result.decision === "block") {
			yield* outputDecision(result);
			return;
		}
	}

	yield* outputDecision(approve());
});

pipe(
	main,
	Effect.catchAll((error) => outputDecision(block(`Hook error: ${String(error)}`))),
	Effect.runPromise,
);
