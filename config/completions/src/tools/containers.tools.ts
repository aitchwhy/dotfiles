/**
 * Container Tools
 * Colima, Docker, Dive
 */
import type { CliTool } from "../schemas";
import { genTool, nixTool } from "../schemas";

export const containerTools: readonly CliTool[] = [
  genTool(
    "colima",
    "colima",
    "containers",
    "homebrew",
    "colima completion zsh",
    "colima completion bash",
    "Container runtime for macOS (VZ)"
  ),
  genTool(
    "docker",
    "docker",
    "containers",
    "homebrew",
    "docker completion zsh",
    "docker completion bash",
    "Docker CLI"
  ),
  nixTool("dive", "dive", "containers", "dive", "Docker image layer analyzer"),
] as const;
