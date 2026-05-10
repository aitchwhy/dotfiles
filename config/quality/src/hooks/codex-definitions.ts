/**
 * Codex Hook Definitions
 *
 * SSOT for Codex CLI hook configurations. Parallel to `definitions.ts`,
 * keyed by Codex event names (PascalCase).
 *
 * The codex generator (`src/generators/codex/hooks.generator.ts`) reads this
 * and emits `[[hooks.<Event>]]` blocks into `generated/codex/config.toml`.
 *
 * Reference: https://developers.openai.com/codex/hooks
 * Verified events (per `codex-rs/protocol/src/protocol.rs::HookEventName`,
 * v0.130): `PreToolUse, PermissionRequest, PostToolUse, PreCompact,
 * PostCompact, SessionStart, UserPromptSubmit, Stop`.
 *
 * Matcher syntax differs from Claude Code:
 *   Claude: glob-OR, e.g. "Write|Edit|Bash|Grep"
 *   Codex:  regex on tool_name, e.g. "^(apply_patch|Bash|Grep)$"
 *
 * Tool name differences:
 *   - Codex uses `apply_patch` as the single edit tool (replaces Claude's
 *     `Edit|Write|MultiEdit`). Per PR #18391, apply_patch fires PreToolUse +
 *     PostToolUse hooks in v0.130+.
 *   - `Bash` and `Grep` names match.
 *   - MCP tools follow `mcp__<server>__<tool>` namespace.
 */

// =============================================================================
// Types
// =============================================================================

export type CodexHookType = 'command'

export interface CodexHookEntry {
  readonly type: CodexHookType
  readonly command: string
  readonly timeout: number
  readonly statusMessage?: string
}

export interface CodexMatcherHookGroup {
  /** Regex matched against tool_name. Omit for events that don't have a tool. */
  readonly matcher?: string
  readonly hooks: readonly CodexHookEntry[]
}

export interface CodexHookDefinitions {
  readonly PreToolUse?: readonly CodexMatcherHookGroup[]
  readonly PostToolUse?: readonly CodexMatcherHookGroup[]
  readonly PermissionRequest?: readonly CodexMatcherHookGroup[]
  readonly SessionStart?: readonly CodexMatcherHookGroup[]
  readonly UserPromptSubmit?: readonly CodexMatcherHookGroup[]
  readonly Stop?: readonly CodexMatcherHookGroup[]
  readonly PreCompact?: readonly CodexMatcherHookGroup[]
  readonly PostCompact?: readonly CodexMatcherHookGroup[]
}

export const ALL_CODEX_HOOK_EVENTS = [
  'PreToolUse',
  'PostToolUse',
  'PermissionRequest',
  'SessionStart',
  'UserPromptSubmit',
  'Stop',
  'PreCompact',
  'PostCompact',
] as const

export type CodexHookEvent = (typeof ALL_CODEX_HOOK_EVENTS)[number]

// =============================================================================
// Path Helpers
// =============================================================================

const qualityHook = (name: string) => `bun "$HOME/dotfiles/config/quality/src/hooks/${name}"`

// =============================================================================
// Hook Definitions
// =============================================================================

/**
 * Codex hook routing. The same `pre-tool-use.ts` / `unified-polish.ts` /
 * `session-init.ts` scripts run for Codex — `lib/hook-input-codex.ts`
 * adapts the stdin payload (T3 deliverable; T10 modifies the hook scripts
 * to call the adapter when CODEX_HOME is set).
 *
 * NOTE: PreCompact / PostCompact are enumerated but not yet wired to any
 * script — leave the empty array as a documentation anchor for future work
 * (e.g., a hook that scrubs sensitive context before compaction).
 */
export const CODEX_HOOK_DEFINITIONS: CodexHookDefinitions = {
  PreToolUse: [
    {
      // apply_patch replaces Claude's Write|Edit|MultiEdit.
      // Bash and Grep keep the same names.
      matcher: '^(apply_patch|Bash|Grep)$',
      hooks: [
        {
          type: 'command',
          command: qualityHook('pre-tool-use.ts'),
          timeout: 5,
          statusMessage: 'Pre-tool guards',
        },
      ],
    },
  ],

  PostToolUse: [
    {
      // Codex's single edit path is apply_patch — one matcher replaces the
      // Claude Write|Edit|MultiEdit glob.
      matcher: '^apply_patch$',
      hooks: [
        {
          type: 'command',
          command: qualityHook('unified-polish.ts'),
          timeout: 120,
          statusMessage: 'Polish (format, lint, types, ast-grep)',
        },
      ],
    },
    {
      // Package.json enforcement — match any apply_patch and let the script
      // check tool_input.file_path (extracted by hook-input-codex adapter).
      matcher: '^apply_patch$',
      hooks: [
        {
          type: 'command',
          command: qualityHook('enforce-packages.ts'),
          timeout: 10,
          statusMessage: 'Package.json enforcement',
        },
      ],
    },
    // No darwin-rebuild post-switch GC hook: Codex's `Stop` is per-turn,
    // not per-process, so the gc lives in the `just switch` recipe / a
    // darwin LaunchAgent rather than as a Codex hook.
  ],

  SessionStart: [
    {
      hooks: [
        {
          type: 'command',
          command: qualityHook('session-init.ts'),
          timeout: 10,
          statusMessage: 'Session init',
        },
      ],
    },
  ],

  // Future placeholders — empty arrays documented; generator skips empty events.
  Stop: [],
  UserPromptSubmit: [],
  PermissionRequest: [],
  PreCompact: [],
  PostCompact: [],
}
