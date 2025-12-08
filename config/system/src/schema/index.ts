/**
 * Schema Index
 *
 * Re-exports all schemas for external consumption.
 */

export * from './agent'
export * from './command'
export * from './cursor-rule'
export * from './skill'

import type { AgentCollection } from './agent'
import type { CommandCollection } from './command'
// Combined manifest type
import type { CursorRuleCollection } from './cursor-rule'
import type { SkillCollection } from './skill'

export interface SystemManifest {
  readonly cursorRules: CursorRuleCollection
  readonly skills: SkillCollection
  readonly commands: CommandCollection
  readonly agents: AgentCollection
}
