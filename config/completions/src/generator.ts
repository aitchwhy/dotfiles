#!/usr/bin/env bun
/**
 * CLI Completions Generator
 * Generates shell completions for tools that need them and creates coverage report
 */
import { exec } from "node:child_process";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import { promisify } from "node:util";
import { Clock, Effect, Exit, Option } from "effect";
import type { CliTool, ToolCategory } from "./schemas";
import { ALL_TOOLS } from "./tools";

const execAsync = promisify(exec);

const GENERATED_DIR = path.join(import.meta.dir, "..", "generated");
const ZSH_DIR = path.join(GENERATED_DIR, "zsh");
const BASH_DIR = path.join(GENERATED_DIR, "bash");

// ─────────────────────────────────────────────────────────────────────────────
// Helper Functions
// ─────────────────────────────────────────────────────────────────────────────

const ensureDir = (dir: string) =>
  Effect.tryPromise({
    try: () => fs.mkdir(dir, { recursive: true }),
    catch: (e) => new Error(`Failed to create directory ${dir}: ${e}`),
  });

const writeFile = (filePath: string, content: string) =>
  Effect.tryPromise({
    try: () => fs.writeFile(filePath, content),
    catch: (e) => new Error(`Failed to write file ${filePath}: ${e}`),
  });

const commandExists = (command: string) =>
  Effect.tryPromise({
    try: async () => {
      await execAsync(`which ${command}`);
      return true;
    },
    catch: () => false,
  });

const executeCommand = (command: string) =>
  Effect.tryPromise({
    try: () => execAsync(command, { timeout: 10000 }),
    catch: (e) => new Error(`Command failed: ${command} - ${e}`),
  });

/** Get completion command for a tool, returns Option */
const getCompletionCommand = (tool: CliTool, shell: "zsh" | "bash"): Option.Option<string> => {
  if (tool.completion.type !== "generate-command") {
    return Option.none();
  }
  const cmd = shell === "zsh" ? tool.completion.zsh : tool.completion.bash;
  return Option.fromNullable(cmd);
};

/** Get reason from none completion, with default */
const getMissingReason = (tool: CliTool): string => {
  if (tool.completion.type === "none" && tool.completion.reason) {
    return tool.completion.reason;
  }
  return "unknown reason";
};

// ─────────────────────────────────────────────────────────────────────────────
// Completion Generation
// ─────────────────────────────────────────────────────────────────────────────

const generateToolCompletion = (tool: CliTool, shell: "zsh" | "bash") =>
  Effect.gen(function* () {
    const commandOption = getCompletionCommand(tool, shell);

    if (Option.isNone(commandOption)) {
      yield* Effect.log(`  [skip] ${tool.name}: no ${shell} command defined`);
      return null;
    }

    const command = commandOption.value;

    // Check if tool exists
    const exists = yield* commandExists(tool.command);
    if (!exists) {
      yield* Effect.log(`  [skip] ${tool.name}: command not found (${tool.command})`);
      return null;
    }

    // Generate completion
    yield* Effect.log(`  [gen]  ${tool.name}: ${command}`);
    const result = yield* executeCommand(command);
    const content = result.stdout;

    if (!content || content.trim().length === 0) {
      yield* Effect.logWarning(`  [warn] ${tool.name}: empty output`);
      return null;
    }

    // Write to file
    const outDir = shell === "zsh" ? ZSH_DIR : BASH_DIR;
    const fileName = shell === "zsh" ? `_${tool.command}` : `${tool.command}.bash`;
    const outPath = path.join(outDir, fileName);

    yield* writeFile(outPath, content);
    yield* Effect.log(`  [done] ${tool.name}: ${fileName}`);

    return outPath;
  });

const generateAllCompletions = (tools: readonly CliTool[]) =>
  Effect.gen(function* () {
    // Ensure directories exist
    yield* ensureDir(ZSH_DIR);
    yield* ensureDir(BASH_DIR);

    // Filter to tools needing generation
    const needsGeneration = tools.filter((t) => t.completion.type === "generate-command");

    yield* Effect.log(`\nGenerating completions for ${needsGeneration.length} tools...`);

    const results: string[] = [];

    for (const tool of needsGeneration) {
      // Generate zsh
      const zshResult = yield* Effect.either(generateToolCompletion(tool, "zsh"));
      if (zshResult._tag === "Right" && zshResult.right) {
        results.push(zshResult.right);
      }

      // Generate bash
      const bashResult = yield* Effect.either(generateToolCompletion(tool, "bash"));
      if (bashResult._tag === "Right" && bashResult.right) {
        results.push(bashResult.right);
      }
    }

    yield* Effect.log(`\nGenerated ${results.length} completion files`);
    return results;
  });

// ─────────────────────────────────────────────────────────────────────────────
// Coverage Report Types
// ─────────────────────────────────────────────────────────────────────────────

interface MissingTool {
  readonly name: string;
  readonly category: ToolCategory;
  readonly reason: string;
}

interface CoverageData {
  readonly generatedAtMs: number;
  readonly total: number;
  readonly coverage: Record<string, number>;
  readonly byCategory: Record<string, number>;
  readonly missing: readonly MissingTool[];
}

// ─────────────────────────────────────────────────────────────────────────────
// Coverage Report
// ─────────────────────────────────────────────────────────────────────────────

const generateCoverageReport = (tools: readonly CliTool[]) =>
  Effect.gen(function* () {
    const bySource: Record<string, number> = {};
    const byCategory: Record<string, number> = {};
    const missing: MissingTool[] = [];

    for (const tool of tools) {
      // Count by source type
      const sourceType = tool.completion.type;
      const currentSourceCount = bySource[sourceType];
      bySource[sourceType] = (currentSourceCount ? currentSourceCount : 0) + 1;

      // Count by category
      const currentCategoryCount = byCategory[tool.category];
      byCategory[tool.category] = (currentCategoryCount ? currentCategoryCount : 0) + 1;

      // Track missing
      if (sourceType === "none") {
        missing.push({
          name: tool.name,
          category: tool.category,
          reason: getMissingReason(tool),
        });
      }
    }

    // Get current time via Clock service (store as milliseconds)
    const generatedAtMs = yield* Clock.currentTimeMillis;

    const report: CoverageData = {
      generatedAtMs,
      total: tools.length,
      coverage: bySource,
      byCategory,
      missing,
    };

    const reportPath = path.join(GENERATED_DIR, "coverage.json");
    yield* ensureDir(GENERATED_DIR);
    yield* writeFile(reportPath, JSON.stringify(report, null, 2));

    // Print summary using Effect.log
    yield* Effect.log("\n═══════════════════════════════════════════════════════════════");
    yield* Effect.log("                    CLI TOOLS COVERAGE REPORT                   ");
    yield* Effect.log("═══════════════════════════════════════════════════════════════");
    yield* Effect.log(`Total tools: ${report.total}`);
    yield* Effect.log("\nBy completion source:");
    for (const [source, count] of Object.entries(bySource)) {
      const percent = ((count / report.total) * 100).toFixed(1);
      yield* Effect.log(`  ${source.padEnd(20)} ${count.toString().padStart(3)} (${percent}%)`);
    }
    yield* Effect.log("\nBy category:");
    for (const [category, count] of Object.entries(byCategory)) {
      yield* Effect.log(`  ${category.padEnd(15)} ${count.toString().padStart(3)}`);
    }
    if (missing.length > 0) {
      yield* Effect.log(`\nTools without completions (${missing.length}):`);
      for (const m of missing) {
        yield* Effect.log(`  - ${m.name}: ${m.reason}`);
      }
    }
    yield* Effect.log("═══════════════════════════════════════════════════════════════\n");

    return report;
  });

// ─────────────────────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────────────────────

const main = Effect.gen(function* () {
  yield* Effect.log("╔═══════════════════════════════════════════════════════════════╗");
  yield* Effect.log("║         CLI COMPLETIONS SSOT GENERATOR                        ║");
  yield* Effect.log("╚═══════════════════════════════════════════════════════════════╝");

  // Generate completions
  yield* generateAllCompletions(ALL_TOOLS);

  // Generate coverage report
  yield* generateCoverageReport(ALL_TOOLS);

  yield* Effect.log("Done!");
});

// Run with proper exit handling
const runMain = async () => {
  const exit = await Effect.runPromiseExit(main);
  if (Exit.isFailure(exit)) {
    process.stderr.write(`Error: ${exit.cause}\n`);
    process.exit(1);
  }
};

runMain();
