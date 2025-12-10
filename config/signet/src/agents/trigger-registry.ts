/**
 * Trigger Registry
 *
 * Defines rules for automatic agent/skill activation based on context.
 * Replaces manual slash command invocation with intelligent triggering.
 */
import { Schema } from 'effect'

// =============================================================================
// Trigger Types
// =============================================================================

/** Context signal that can trigger an agent/skill */
export type ContextSignal =
  | { readonly type: 'prompt_keyword'; readonly keywords: readonly string[] }
  | { readonly type: 'file_pattern'; readonly patterns: readonly string[] }
  | { readonly type: 'output_pattern'; readonly patterns: readonly string[] }
  | { readonly type: 'git_state'; readonly states: readonly GitState[] }
  | { readonly type: 'always' }

export type GitState = 'staged_changes' | 'unstaged_changes' | 'merge_conflict' | 'rebase_in_progress'

/** Target to activate when triggered */
export type TriggerTarget =
  | { readonly type: 'agent'; readonly name: string }
  | { readonly type: 'skill'; readonly name: string }

/** Complete trigger rule */
export type TriggerRule = {
  readonly id: string
  readonly description: string
  readonly signals: readonly ContextSignal[]
  readonly target: TriggerTarget
  readonly priority: number // Higher = more important
}

// =============================================================================
// Trigger Registry Definition
// =============================================================================

export const TRIGGER_REGISTRY: readonly TriggerRule[] = [
  // ---------------------------------------------------------------------------
  // Agent Triggers (from deprecated commands)
  // ---------------------------------------------------------------------------
  {
    id: 'debugger-on-error',
    description: 'Activate debugger agent when error patterns detected in output',
    signals: [
      {
        type: 'output_pattern',
        patterns: [
          'Error:',
          'error\\[',
          'FAILED',
          'panic:',
          'Traceback',
          'Exception:',
          'TypeError:',
          'ReferenceError:',
        ],
      },
    ],
    target: { type: 'agent', name: 'debugger' },
    priority: 90,
  },
  {
    id: 'fixer-on-test-failure',
    description: 'Activate fixer agent when test failures detected',
    signals: [
      {
        type: 'output_pattern',
        patterns: ['FAIL ', 'test failed', '\\d+ failing', 'AssertionError'],
      },
    ],
    target: { type: 'agent', name: 'fixer' },
    priority: 85,
  },
  {
    id: 'feature-on-implement',
    description: 'Activate feature agent when implementation requested',
    signals: [
      {
        type: 'prompt_keyword',
        keywords: ['implement', 'add feature', 'create', 'build', 'develop'],
      },
    ],
    target: { type: 'agent', name: 'feature' },
    priority: 70,
  },
  {
    id: 'code-reviewer-on-diff',
    description: 'Activate code reviewer when git diff detected',
    signals: [
      { type: 'git_state', states: ['staged_changes', 'unstaged_changes'] },
      { type: 'prompt_keyword', keywords: ['review', 'PR', 'pull request'] },
    ],
    target: { type: 'agent', name: 'code-reviewer' },
    priority: 75,
  },

  // ---------------------------------------------------------------------------
  // Skill Triggers (from deprecated commands)
  // ---------------------------------------------------------------------------
  {
    id: 'tdd-on-test-file',
    description: 'Activate TDD patterns skill when working with test files',
    signals: [
      {
        type: 'file_pattern',
        patterns: ['*.test.ts', '*.spec.ts', '*_test.go', 'test_*.py'],
      },
    ],
    target: { type: 'skill', name: 'tdd-patterns' },
    priority: 80,
  },
  {
    id: 'verification-always',
    description: 'Verification-first skill is always active',
    signals: [{ type: 'always' }],
    target: { type: 'skill', name: 'verification-first' },
    priority: 100,
  },
  {
    id: 'commit-on-staged',
    description: 'Activate commit patterns when staged changes exist',
    signals: [
      { type: 'git_state', states: ['staged_changes'] },
      { type: 'prompt_keyword', keywords: ['commit', 'save changes'] },
    ],
    target: { type: 'skill', name: 'commit-patterns' },
    priority: 85,
  },
  {
    id: 'planning-on-complex',
    description: 'Activate planning patterns for complex tasks',
    signals: [
      {
        type: 'prompt_keyword',
        keywords: [
          'plan',
          'design',
          'architect',
          'strategy',
          'approach',
          'how should',
          'refactor',
          'migrate',
        ],
      },
    ],
    target: { type: 'skill', name: 'planning-patterns' },
    priority: 75,
  },
  {
    id: 'typescript-on-ts-files',
    description: 'Activate TypeScript patterns skill for TS files',
    signals: [{ type: 'file_pattern', patterns: ['*.ts', '*.tsx'] }],
    target: { type: 'skill', name: 'typescript-patterns' },
    priority: 60,
  },
  {
    id: 'zod-on-schema',
    description: 'Activate Zod patterns when schema files detected',
    signals: [
      { type: 'file_pattern', patterns: ['*schema*.ts', '*validator*.ts'] },
      { type: 'prompt_keyword', keywords: ['schema', 'validate', 'zod'] },
    ],
    target: { type: 'skill', name: 'zod-patterns' },
    priority: 65,
  },
  {
    id: 'result-on-error-handling',
    description: 'Activate Result patterns for error handling contexts',
    signals: [
      {
        type: 'prompt_keyword',
        keywords: ['error handling', 'Result', 'Either', 'fallible'],
      },
    ],
    target: { type: 'skill', name: 'result-patterns' },
    priority: 70,
  },
  {
    id: 'nix-on-nix-files',
    description: 'Activate Nix patterns for Nix files',
    signals: [{ type: 'file_pattern', patterns: ['*.nix', 'flake.lock'] }],
    target: { type: 'skill', name: 'nix-darwin-patterns' },
    priority: 60,
  },
  {
    id: 'signet-on-signet-files',
    description: 'Activate Signet patterns in Signet codebase',
    signals: [{ type: 'file_pattern', patterns: ['config/signet/**/*.ts'] }],
    target: { type: 'skill', name: 'signet-patterns' },
    priority: 65,
  },
] as const

// =============================================================================
// Schema Definitions
// =============================================================================

export const ContextSignalSchema = Schema.Union(
  Schema.Struct({
    type: Schema.Literal('prompt_keyword'),
    keywords: Schema.Array(Schema.String),
  }),
  Schema.Struct({
    type: Schema.Literal('file_pattern'),
    patterns: Schema.Array(Schema.String),
  }),
  Schema.Struct({
    type: Schema.Literal('output_pattern'),
    patterns: Schema.Array(Schema.String),
  }),
  Schema.Struct({
    type: Schema.Literal('git_state'),
    states: Schema.Array(
      Schema.Literal('staged_changes', 'unstaged_changes', 'merge_conflict', 'rebase_in_progress')
    ),
  }),
  Schema.Struct({ type: Schema.Literal('always') })
)

export const TriggerTargetSchema = Schema.Union(
  Schema.Struct({ type: Schema.Literal('agent'), name: Schema.String }),
  Schema.Struct({ type: Schema.Literal('skill'), name: Schema.String })
)

export const TriggerRuleSchema = Schema.Struct({
  id: Schema.String,
  description: Schema.String,
  signals: Schema.Array(ContextSignalSchema),
  target: TriggerTargetSchema,
  priority: Schema.Number,
})

// =============================================================================
// Utility Functions
// =============================================================================

/** Get all rules sorted by priority (highest first) */
export const getRulesByPriority = (): readonly TriggerRule[] =>
  [...TRIGGER_REGISTRY].sort((a, b) => b.priority - a.priority)

/** Get rules for a specific target type */
export const getRulesByTargetType = (type: 'agent' | 'skill'): readonly TriggerRule[] =>
  TRIGGER_REGISTRY.filter((rule) => rule.target.type === type)

/** Get rule by ID */
export const getRuleById = (id: string): TriggerRule | undefined =>
  TRIGGER_REGISTRY.find((rule) => rule.id === id)
