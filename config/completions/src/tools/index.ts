/**
 * CLI Tools Registry - Aggregates all tool definitions
 */
import type { CliTool } from "../schemas";
import { cloudTools } from "./cloud.tools";
import { containerTools } from "./containers.tools";
import { databaseTools } from "./database.tools";
import { devTools } from "./dev.tools";
import { gitTools } from "./git.tools";
import { infraTools } from "./infra.tools";
import { kubernetesTools } from "./kubernetes.tools";
import { languageTools } from "./languages.tools";
import { networkTools } from "./network.tools";
import { nixTools } from "./nix.tools";
import { qualityTools } from "./quality.tools";
import { securityTools } from "./security.tools";
import { toldTools } from "./told.tools";
import { unixTools } from "./unix.tools";

/**
 * All CLI tools with their completion sources
 * This is the SSOT for shell completion tracking
 */
export const ALL_TOOLS: readonly CliTool[] = [
  ...cloudTools,
  ...containerTools,
  ...kubernetesTools,
  ...languageTools,
  ...nixTools,
  ...unixTools,
  ...gitTools,
  ...qualityTools,
  ...infraTools,
  ...databaseTools,
  ...networkTools,
  ...securityTools,
  ...devTools,
  ...toldTools,
] as const;

// Re-export category arrays for direct access
export {
  cloudTools,
  containerTools,
  databaseTools,
  devTools,
  gitTools,
  infraTools,
  kubernetesTools,
  languageTools,
  networkTools,
  nixTools,
  qualityTools,
  securityTools,
  toldTools,
  unixTools,
};
