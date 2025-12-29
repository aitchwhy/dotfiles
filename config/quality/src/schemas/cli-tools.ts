/**
 * CLI Tool Schemas - Effect Schema SSOT for Modern CLI Tools
 *
 * Shell aliases transform legacy → modern CLI:
 * - grep → rg (ripgrep)
 * - find → fd
 * - ls → eza
 * - cat → bat
 *
 * These schemas define the VALID flag patterns for modern tools.
 * Used by Guard 27 (checkModernCLITools) to catch incompatible legacy syntax.
 */
import { Schema } from 'effect'

// =============================================================================
// Ripgrep (rg) - replaces grep
// =============================================================================

/**
 * Valid ripgrep flags schema.
 * Key differences from grep:
 * - Uses --glob/-g instead of --include/--exclude
 * - Recursive by default (no -r/-R needed)
 * - Extended regex by default (no -E needed)
 */
export const RipgrepFlagsSchema = Schema.Struct({
  pattern: Schema.String,
  path: Schema.optional(Schema.String),
  glob: Schema.optional(Schema.String), // -g (NOT --include!)
  type: Schema.optional(Schema.String), // -t ts, -t py, etc.
  ignoreCase: Schema.optional(Schema.Boolean), // -i
  context: Schema.optional(Schema.Number), // -C
  beforeContext: Schema.optional(Schema.Number), // -B
  afterContext: Schema.optional(Schema.Number), // -A
  filesWithMatches: Schema.optional(Schema.Boolean), // -l
  count: Schema.optional(Schema.Boolean), // -c
  hidden: Schema.optional(Schema.Boolean), // --hidden
  multiline: Schema.optional(Schema.Boolean), // -U
})

export type RipgrepFlags = typeof RipgrepFlagsSchema.Type

// =============================================================================
// fd - replaces find
// =============================================================================

/**
 * Valid fd flags schema.
 * Key differences from find:
 * - Pattern is positional (fd "*.ts"), not -name "*.ts"
 * - Uses -t for type, not -type
 * - Uses -x/-X for exec, not -exec
 */
export const FdFlagsSchema = Schema.Struct({
  pattern: Schema.optional(Schema.String), // positional (NOT -name!)
  path: Schema.optional(Schema.String),
  extension: Schema.optional(Schema.String), // -e ts, -e py
  type: Schema.optional(Schema.Literal('f', 'd', 'l', 'x', 'e', 's', 'p')),
  hidden: Schema.optional(Schema.Boolean), // -H
  noIgnore: Schema.optional(Schema.Boolean), // -I
  exec: Schema.optional(Schema.String), // -x
  execBatch: Schema.optional(Schema.String), // -X
  maxDepth: Schema.optional(Schema.Number), // -d
})

export type FdFlags = typeof FdFlagsSchema.Type

// =============================================================================
// eza - replaces ls
// =============================================================================

/**
 * Valid eza flags schema.
 * Mostly compatible with ls, but some differences:
 * - Uses --tree instead of -R for recursive
 * - Has --git for git status integration
 * - Has --icons for file type icons
 */
export const EzaFlagsSchema = Schema.Struct({
  path: Schema.optional(Schema.String),
  long: Schema.optional(Schema.Boolean), // -l
  all: Schema.optional(Schema.Boolean), // -a
  tree: Schema.optional(Schema.Boolean), // --tree
  level: Schema.optional(Schema.Number), // -L (tree depth)
  git: Schema.optional(Schema.Boolean), // --git
  icons: Schema.optional(Schema.Boolean), // --icons
  sort: Schema.optional(Schema.Literal('name', 'size', 'time', 'modified')),
  header: Schema.optional(Schema.Boolean), // -h
})

export type EzaFlags = typeof EzaFlagsSchema.Type

// =============================================================================
// bat - replaces cat
// =============================================================================

/**
 * Valid bat flags schema.
 * Mostly compatible with cat for basic usage:
 * - Adds syntax highlighting
 * - Has -p for plain output (like cat)
 * - Has -r for range selection
 */
export const BatFlagsSchema = Schema.Struct({
  file: Schema.String,
  language: Schema.optional(Schema.String), // -l
  lineNumbers: Schema.optional(Schema.Boolean), // -n
  plain: Schema.optional(Schema.Boolean), // -p
  range: Schema.optional(Schema.String), // -r 10:20
  style: Schema.optional(Schema.String), // --style
  theme: Schema.optional(Schema.String), // --theme
})

export type BatFlags = typeof BatFlagsSchema.Type

// =============================================================================
// Legacy → Modern Flag Mapping (for guard error messages)
// =============================================================================

export type LegacyCommand = 'grep' | 'find' | 'ls' | 'cat'

export type FlagMapping = {
  readonly modern: string
  readonly incompatible: readonly string[]
  readonly translations: Readonly<Record<string, string>>
}

export const LEGACY_FLAG_MAPPINGS: Readonly<Record<LegacyCommand, FlagMapping>> = {
  grep: {
    modern: 'rg',
    incompatible: ['--include', '--exclude', '-r', '-R', '-E'],
    translations: {
      '--include': '--glob / -g',
      '--exclude': '--glob ! (negated glob)',
      '-r': '(default - recursive)',
      '-R': '(default - recursive)',
      '-E': '(default - extended regex)',
    },
  },
  find: {
    modern: 'fd',
    incompatible: ['-name', '-iname', '-type', '-exec'],
    translations: {
      '-name': 'positional pattern (fd "*.ts")',
      '-iname': '-i (case insensitive)',
      '-type f': '-t f',
      '-type d': '-t d',
      '-exec': '-x / -X',
    },
  },
  ls: {
    modern: 'eza',
    incompatible: [], // mostly compatible
    translations: {
      '-R': '--tree',
    },
  },
  cat: {
    modern: 'bat',
    incompatible: [], // cat alias removed for heredoc compatibility
    translations: {},
  },
} as const

// =============================================================================
// Guard Helpers
// =============================================================================

/**
 * Check if a command contains incompatible legacy flags.
 * Returns the list of incompatible flags found, or empty array if valid.
 */
export function findIncompatibleFlags(
  legacyCommand: LegacyCommand,
  commandString: string,
): readonly string[] {
  const mapping = LEGACY_FLAG_MAPPINGS[legacyCommand]
  return mapping.incompatible.filter((flag) => commandString.includes(flag))
}

/**
 * Generate a helpful error message for incompatible flags.
 */
export function formatFlagTranslations(legacyCommand: LegacyCommand): string {
  const mapping = LEGACY_FLAG_MAPPINGS[legacyCommand]
  const lines = Object.entries(mapping.translations).map(
    ([legacy, modern]) => `  ${legacy} → ${modern}`,
  )
  return lines.join('\n')
}
