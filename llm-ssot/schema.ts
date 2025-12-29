import { Schema } from 'effect'

// Memory layers
export const MemoryLayer = Schema.Literal(
  'build-tooling',
  'auth-security', 
  'architecture',
  'dev-practices',
  'testing',
  'infrastructure'
)
export type MemoryLayer = Schema.Schema.Type<typeof MemoryLayer>

// Individual memory
export const Memory = Schema.Struct({
  id: Schema.Number.pipe(Schema.int(), Schema.between(1, 100)),
  layer: MemoryLayer,
  content: Schema.String.pipe(Schema.minLength(10)),
  enforcementType: Schema.Literal('block', 'warn', 'info'),
  patterns: Schema.Struct({
    detect: Schema.Array(Schema.String),  // Regex patterns to detect violations
    block: Schema.Array(Schema.String),   // Patterns that MUST be blocked
    suggest: Schema.Array(Schema.String), // Suggested replacements
  }),
  examples: Schema.Struct({
    bad: Schema.Array(Schema.String),
    good: Schema.Array(Schema.String),
  }),
})
export type Memory = Schema.Schema.Type<typeof Memory>

// Hook definition
export const Hook = Schema.Struct({
  name: Schema.String,
  type: Schema.Literal('PreToolUse', 'PostToolUse', 'PreCommit', 'PostCommit'),
  memoryIds: Schema.Array(Schema.Number),
  action: Schema.Literal('block', 'warn', 'transform'),
  patterns: Schema.Array(Schema.String),
  message: Schema.String,
})
export type Hook = Schema.Schema.Type<typeof Hook>

// Skill definition
export const Skill = Schema.Struct({
  name: Schema.String,
  description: Schema.String,
  memoryIds: Schema.Array(Schema.Number),
  content: Schema.String,
})
export type Skill = Schema.Schema.Type<typeof Skill>

// Agent configuration
export const AgentConfig = Schema.Struct({
  agent: Schema.Literal('claude-code', 'gemini', 'cursor', 'antigravity', 'aider', 'copilot'),
  memories: Schema.Array(Memory),
  hooks: Schema.Array(Hook),
  skills: Schema.Array(Skill),
  rules: Schema.Array(Schema.String),
})
export type AgentConfig = Schema.Schema.Type<typeof AgentConfig>

// Complete SSOT
export const SSOT = Schema.Struct({
  version: Schema.String,
  lastUpdated: Schema.String,
  memories: Schema.Array(Memory),
  hooks: Schema.Array(Hook),
  skills: Schema.Array(Skill),
  agents: Schema.Record({ key: Schema.String, value: AgentConfig }),
})
export type SSOT = Schema.Schema.Type<typeof SSOT>
