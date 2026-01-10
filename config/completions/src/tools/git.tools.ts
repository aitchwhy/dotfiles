/**
 * Git & GitHub Tools
 */
import type { CliTool } from "../schemas";
import { hmTool, nixTool } from "../schemas";

export const gitTools: readonly CliTool[] = [
  // Core git
  hmTool("git", "git", "git", "programs.git", "Version control"),
  nixTool("git-lfs", "git-lfs", "git", "git-lfs", "Git Large File Storage"),

  // GitHub
  nixTool("gh", "gh", "git", "gh", "GitHub CLI"),

  // Git TUI/helpers
  nixTool("lazygit", "lazygit", "git", "lazygit", "Git TUI"),
  nixTool("delta", "delta", "git", "delta", "Git diff viewer"),
  nixTool("commitizen", "cz", "git", "commitizen", "Commit message helper"),
  nixTool("lefthook", "lefthook", "git", "lefthook", "Git hooks manager"),
] as const;
