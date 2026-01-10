/**
 * CLI Tool Completions SSOT
 * Single Source of Truth for shell completion management
 */

// Export schemas
export {
  type CliTool,
  CliToolSchema,
  type CompletionSource,
  CompletionSourceSchema,
  type CoverageReport,
  CoverageReportSchema,
  type InstallSource,
  InstallSourceSchema,
  type ToolCategory,
  ToolCategorySchema,
  // Helper functions
  genTool,
  hmTool,
  nixTool,
  noCompTool,
} from "./schemas";

// Export tools
export { ALL_TOOLS } from "./tools";
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
} from "./tools";
