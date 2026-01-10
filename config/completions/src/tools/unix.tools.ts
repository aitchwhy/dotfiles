/**
 * Modern Unix Replacement Tools
 */
import type { CliTool } from "../schemas";
import { hmTool, nixTool } from "../schemas";

export const unixTools: readonly CliTool[] = [
  // Modern replacements (via nix packages)
  nixTool("ripgrep", "rg", "unix", "ripgrep", "Fast grep replacement"),
  nixTool("fd", "fd", "unix", "fd", "Fast find replacement"),
  nixTool("sd", "sd", "unix", "sd", "Fast sed replacement"),
  nixTool("dust", "dust", "unix", "dust", "Intuitive du replacement"),
  nixTool("hexyl", "hexyl", "unix", "hexyl", "Binary hex viewer"),
  nixTool("ouch", "ouch", "unix", "ouch", "Archive tool"),

  // Home-manager managed
  hmTool("eza", "eza", "unix", "programs.eza", "Modern ls replacement"),
  hmTool("zoxide", "z", "unix", "programs.zoxide", "Smart directory jumper"),
  hmTool("bat", "bat", "unix", "programs.bat", "Cat with syntax highlighting"),
  hmTool("fzf", "fzf", "unix", "programs.fzf", "Fuzzy finder"),
  hmTool("atuin", "atuin", "unix", "programs.atuin", "Shell history sync"),
  hmTool("direnv", "direnv", "unix", "programs.direnv", "Environment management"),
] as const;
