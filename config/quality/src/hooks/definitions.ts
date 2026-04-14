/**
 * Hook Definitions
 *
 * SSOT for all Claude Code hook configurations.
 * settings.generator.ts reads this to generate settings.json.
 */

// =============================================================================
// Types
// =============================================================================

type HookType = 'command'

type HookEntry = {
  readonly type: HookType
  readonly command: string
  readonly timeout: number
}

type MatcherHookGroup = {
  readonly matcher?: string
  readonly hooks: readonly HookEntry[]
}

type HookDefinitions = {
  readonly PreToolUse: readonly MatcherHookGroup[]
  readonly PostToolUse: readonly MatcherHookGroup[]
  readonly SessionStart: readonly MatcherHookGroup[]
}

// =============================================================================
// Path Helpers
// =============================================================================

const qualityHook = (name: string) => `bun "$HOME/dotfiles/config/quality/src/hooks/${name}"`

// =============================================================================
// Hook Definitions
// =============================================================================

export const HOOK_DEFINITIONS: HookDefinitions = {
  PreToolUse: [
    {
      matcher: 'Write|Edit|Bash|Grep',
      hooks: [
        {
          type: 'command',
          command: qualityHook('pre-tool-use.ts'),
          timeout: 5,
        },
      ],
    },
  ],

  PostToolUse: [
    {
      matcher: 'Write|Edit|MultiEdit',
      hooks: [
        {
          type: 'command',
          command: qualityHook('unified-polish.ts'),
          timeout: 120,
        },
      ],
    },
    {
      matcher: 'Write(**/package.json)|Edit(**/package.json)',
      hooks: [
        {
          type: 'command',
          command: qualityHook('enforce-packages.ts'),
          timeout: 10,
        },
      ],
    },
    {
      matcher: 'Bash(darwin-rebuild switch:*)|Bash(sudo darwin-rebuild switch:*)',
      hooks: [
        {
          type: 'command',
          command: qualityHook('post-switch-gc.ts'),
          timeout: 120,
        },
      ],
    },
  ],

  SessionStart: [
    {
      hooks: [
        {
          type: 'command',
          command: qualityHook('session-init.ts'),
          timeout: 10,
        },
      ],
    },
    {
      hooks: [
        {
          type: 'command',
          command:
            'node ~/.claude/plugins/cache/caveman/caveman/*/hooks/caveman-activate.js 2>/dev/null || echo "OK"',
          timeout: 5,
        },
      ],
    },
  ],
} as const

// =============================================================================
// Exports for Generator
// =============================================================================

export type { HookDefinitions, HookEntry, MatcherHookGroup }
