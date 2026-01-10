/**
 * Programming Languages & Runtime Tools
 */
import type { CliTool } from "../schemas";
import { nixTool } from "../schemas";

export const languageTools: readonly CliTool[] = [
  // Node.js ecosystem
  nixTool("nodejs", "node", "languages", "nodejs_25", "Node.js v25 runtime"),
  nixTool("pnpm", "pnpm", "languages", "nodePackages.pnpm", "Fast package manager"),
  nixTool("yarn", "yarn", "languages", "yarn-berry", "Yarn package manager"),
  nixTool("bun", "bun", "languages", "bun", "Fast JavaScript runtime"),
  nixTool("fnm", "fnm", "languages", "fnm", "Node.js version manager"),

  // Python
  nixTool("uv", "uv", "languages", "uv", "Python version/package manager"),

  // Go
  nixTool("go", "go", "languages", "go", "Go compiler"),
  nixTool("gopls", "gopls", "languages", "gopls", "Go language server"),
  nixTool("golangci-lint", "golangci-lint", "languages", "golangci-lint", "Go linter"),

  // Rust
  nixTool("rustup", "rustup", "languages", "rustup", "Rust toolchain manager"),
] as const;
