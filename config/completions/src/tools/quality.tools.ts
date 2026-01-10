/**
 * Code Quality & Formatting Tools
 */
import type { CliTool } from "../schemas";
import { nixTool } from "../schemas";

export const qualityTools: readonly CliTool[] = [
  // JavaScript/TypeScript
  nixTool("biome", "biome", "quality", "biome", "JS/TS formatter + linter"),

  // Shell
  nixTool("shellcheck", "shellcheck", "quality", "shellcheck", "Shell script linter"),
  nixTool("shfmt", "shfmt", "quality", "shfmt", "Shell script formatter"),

  // Nix
  nixTool("nixfmt", "nixfmt", "quality", "nixfmt-rfc-style", "Nix formatter (RFC style)"),
  nixTool("deadnix", "deadnix", "quality", "deadnix", "Find dead Nix code"),
  nixTool("statix", "statix", "quality", "statix", "Nix linter"),

  // Multi-language
  nixTool("treefmt", "treefmt", "quality", "treefmt", "Multi-language formatter"),

  // Other
  nixTool("markdownlint", "markdownlint", "quality", "markdownlint-cli", "Markdown linter"),
  nixTool("yamllint", "yamllint", "quality", "yamllint", "YAML linter"),
  nixTool("hadolint", "hadolint", "quality", "hadolint", "Dockerfile linter"),
] as const;
