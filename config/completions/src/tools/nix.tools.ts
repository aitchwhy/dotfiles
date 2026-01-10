/**
 * Nix Development Tools
 */
import type { CliTool } from "../schemas";
import { nixTool } from "../schemas";

export const nixTools: readonly CliTool[] = [
  nixTool("nh", "nh", "nix", "nh", "Modern Nix helper"),
  nixTool("cachix", "cachix", "nix", "cachix", "Binary cache management"),
  nixTool("devenv", "devenv", "nix", "devenv", "Development environments"),
  nixTool("nixd", "nixd", "nix", "nixd", "Nix language server"),
  nixTool("nix-tree", "nix-tree", "nix", "nix-tree", "Nix dependency visualizer"),
  nixTool("nix-output-monitor", "nom", "nix", "nix-output-monitor", "Nix build output formatter"),
  nixTool("nix-diff", "nix-diff", "nix", "nix-diff", "Compare Nix derivations"),
  nixTool("nix-index", "nix-locate", "nix", "nix-index", "Nix package search"),
] as const;
