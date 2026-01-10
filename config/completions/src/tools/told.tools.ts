/**
 * Told Codebase Tools
 * Tools specific to the Told project that may not have shell completions
 */
import type { CliTool } from "../schemas";
import { noCompTool } from "../schemas";

export const toldTools: readonly CliTool[] = [
  noCompTool(
    "vitest",
    "vitest",
    "told",
    "npm",
    "Vitest does not provide shell completions",
    "Unit test runner"
  ),
  noCompTool(
    "tsx",
    "tsx",
    "told",
    "npm",
    "tsx is a wrapper around node",
    "TypeScript runner"
  ),
  noCompTool(
    "expo",
    "expo",
    "told",
    "npm",
    "Expo CLI does not provide shell completions",
    "React Native toolchain"
  ),
  noCompTool(
    "drizzle-kit",
    "drizzle-kit",
    "told",
    "npm",
    "drizzle-kit does not provide completions",
    "Database migration tool"
  ),
  noCompTool(
    "knip",
    "knip",
    "told",
    "npm",
    "knip does not provide completions",
    "Unused dependencies checker"
  ),
  noCompTool(
    "oxlint",
    "oxlint",
    "told",
    "npm",
    "oxlint does not provide completions",
    "High-performance linter"
  ),
] as const;
