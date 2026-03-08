/**
 * Quality System Schemas - Effect Schema SSOT
 *
 * CLI tools schemas used by procedural guards.
 */

// ═══════════════════════════════════════════════════════════════════════════
// CLI Tools (Modern Replacements)
// ═══════════════════════════════════════════════════════════════════════════

export {
  type BatFlags,
  BatFlagsSchema,
  type EzaFlags,
  EzaFlagsSchema,
  type FdFlags,
  FdFlagsSchema,
  type FlagMapping,
  // Helpers
  findIncompatibleFlags,
  formatFlagTranslations,
  // Constants
  LEGACY_FLAG_MAPPINGS,
  type LegacyCommand,
  // Types
  type RipgrepFlags,
  // Schemas
  RipgrepFlagsSchema,
} from './cli-tools.js'
