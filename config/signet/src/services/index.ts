/**
 * Signet Services - Shared Domain Logic
 *
 * These services power MCP tools and can be used by hooks.
 * All services use Effect-TS patterns.
 */

export * from './guard';
// Re-export migrate without FORBIDDEN_DEPS to avoid conflict with stack
export {
  checkProject,
  type DriftItem,
  FORBIDDEN_FILES,
  fixProject,
  formatMigrateResult,
  type MigrateCheckResult,
  type MigrateFixResult,
} from './migrate';
export * from './stack';
