/**
 * CLI Tool Completions - Effect Schema Definitions
 * SSOT for tracking all CLI tools and their completion sources
 */
import { Schema } from "effect";

// ─────────────────────────────────────────────────────────────────────────────
// Completion Source Types
// ─────────────────────────────────────────────────────────────────────────────

/** Completion provided by Nix package installation */
export const NixPackageSource = Schema.Struct({
  type: Schema.Literal("nix-package"),
  packageName: Schema.String,
});

/** Completion provided by home-manager module integration */
export const HomeManagerSource = Schema.Struct({
  type: Schema.Literal("home-manager"),
  modulePath: Schema.String,
});

/** Completion can be generated via CLI command */
export const GenerateCommandSource = Schema.Struct({
  type: Schema.Literal("generate-command"),
  zsh: Schema.optional(Schema.String),
  bash: Schema.optional(Schema.String),
});

/** Manual completion file maintained by hand */
export const ManualSource = Schema.Struct({
  type: Schema.Literal("manual"),
  path: Schema.String,
});

/** No completion available for this tool */
export const NoneSource = Schema.Struct({
  type: Schema.Literal("none"),
  reason: Schema.optional(Schema.String),
});

/** Union of all completion sources */
export const CompletionSourceSchema = Schema.Union(
  NixPackageSource,
  HomeManagerSource,
  GenerateCommandSource,
  ManualSource,
  NoneSource
);

export type CompletionSource = typeof CompletionSourceSchema.Type;

// ─────────────────────────────────────────────────────────────────────────────
// Tool Categories
// ─────────────────────────────────────────────────────────────────────────────

export const ToolCategorySchema = Schema.Literal(
  "cloud",
  "containers",
  "kubernetes",
  "languages",
  "nix",
  "unix",
  "git",
  "quality",
  "infra",
  "database",
  "network",
  "security",
  "dev",
  "told"
);

export type ToolCategory = typeof ToolCategorySchema.Type;

// ─────────────────────────────────────────────────────────────────────────────
// Installation Source
// ─────────────────────────────────────────────────────────────────────────────

export const InstallSourceSchema = Schema.Literal("nix", "homebrew", "npm", "cargo", "manual");

export type InstallSource = typeof InstallSourceSchema.Type;

// ─────────────────────────────────────────────────────────────────────────────
// CLI Tool Definition
// ─────────────────────────────────────────────────────────────────────────────

export const CliToolSchema = Schema.Struct({
  /** Display name of the tool */
  name: Schema.String.pipe(Schema.minLength(1)),

  /** Actual command name (may differ from name, e.g., ripgrep -> rg) */
  command: Schema.String.pipe(Schema.minLength(1)),

  /** Tool category for organization */
  category: ToolCategorySchema,

  /** How the tool is installed */
  source: InstallSourceSchema,

  /** How completions are provided */
  completion: CompletionSourceSchema,

  /** Brief description of the tool */
  description: Schema.optional(Schema.String),
});

export type CliTool = typeof CliToolSchema.Type;

// ─────────────────────────────────────────────────────────────────────────────
// Coverage Report
// ─────────────────────────────────────────────────────────────────────────────

export const CoverageReportSchema = Schema.Struct({
  generatedAt: Schema.String,
  total: Schema.Number,
  coverage: Schema.Record({
    key: Schema.String,
    value: Schema.Number,
  }),
  byCategory: Schema.Record({
    key: ToolCategorySchema,
    value: Schema.Number,
  }),
  missing: Schema.Array(
    Schema.Struct({
      name: Schema.String,
      category: ToolCategorySchema,
      reason: Schema.optional(Schema.String),
    })
  ),
});

export type CoverageReport = typeof CoverageReportSchema.Type;

// ─────────────────────────────────────────────────────────────────────────────
// Helper Functions
// ─────────────────────────────────────────────────────────────────────────────

/** Create a tool with nix-package completion */
export const nixTool = (
  name: string,
  command: string,
  category: ToolCategory,
  packageName: string,
  description?: string
): CliTool => ({
  name,
  command,
  category,
  source: "nix",
  completion: { type: "nix-package", packageName },
  description,
});

/** Create a tool with home-manager integration */
export const hmTool = (
  name: string,
  command: string,
  category: ToolCategory,
  modulePath: string,
  description?: string
): CliTool => ({
  name,
  command,
  category,
  source: "nix",
  completion: { type: "home-manager", modulePath },
  description,
});

/** Create a tool that can generate completions */
export const genTool = (
  name: string,
  command: string,
  category: ToolCategory,
  source: InstallSource,
  zsh?: string,
  bash?: string,
  description?: string
): CliTool => ({
  name,
  command,
  category,
  source,
  completion: { type: "generate-command", zsh, bash },
  description,
});

/** Create a tool with no completion */
export const noCompTool = (
  name: string,
  command: string,
  category: ToolCategory,
  source: InstallSource,
  reason?: string,
  description?: string
): CliTool => ({
  name,
  command,
  category,
  source,
  completion: { type: "none", reason },
  description,
});
