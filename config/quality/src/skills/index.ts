/**
 * Skills Registry
 *
 * All 24 skills with compile-time count assertion.
 */

export { apiContractSkill } from './api-contract.skill'
export { devopsPatternsSkill } from './devops-patterns.skill'
export { effectClockPatternsSkill } from './effect-clock-patterns.skill'
export { effectResilienceSkill } from './effect-resilience.skill'
export { effectTsSkill } from './effect-ts.skill'
export { effectXstateSkill } from './effect-xstate.skill'
export { ghaOidcPatternsSkill } from './gha-oidc-patterns.skill'
export { hexagonalSkill } from './hexagonal.skill'
export { mcpOptimizationSkill } from './mcp-optimization.skill'
export { nixPatternsSkill } from './nix-patterns.skill'
export { observabilitySkill } from './observability.skill'
export { optionPatternsSkill } from './option-patterns.skill'
export { paragonSkill } from './paragon.skill'
export { parseBoundarySkill } from './parse-boundary.skill'
export { planningPatternsSkill } from './planning-patterns.skill'
export { pulumiEscSkill } from './pulumi-esc.skill'
export { refMcpSkill } from './ref-mcp.skill'
export { repomixSkill } from './repomix.skill'
export { semanticCodebaseSkill } from './semantic-codebase.skill'
export { stateMachinesSkill } from './state-machines.skill'
export { testingSkill } from './testing.skill'
export { typeBoundaryPatternsSkill } from './type-boundary-patterns.skill'
export { typeSafetySkill } from './type-safety.skill'
export { zeroEnvironmentAwarenessSkill } from './zero-environment-awareness.skill'

import { apiContractSkill } from './api-contract.skill'
import { devopsPatternsSkill } from './devops-patterns.skill'
import { effectClockPatternsSkill } from './effect-clock-patterns.skill'
import { effectResilienceSkill } from './effect-resilience.skill'
import { effectTsSkill } from './effect-ts.skill'
import { effectXstateSkill } from './effect-xstate.skill'
import { ghaOidcPatternsSkill } from './gha-oidc-patterns.skill'
import { hexagonalSkill } from './hexagonal.skill'
import { mcpOptimizationSkill } from './mcp-optimization.skill'
import { nixPatternsSkill } from './nix-patterns.skill'
import { observabilitySkill } from './observability.skill'
import { optionPatternsSkill } from './option-patterns.skill'
import { paragonSkill } from './paragon.skill'
import { parseBoundarySkill } from './parse-boundary.skill'
import { planningPatternsSkill } from './planning-patterns.skill'
import { pulumiEscSkill } from './pulumi-esc.skill'
import { refMcpSkill } from './ref-mcp.skill'
import { repomixSkill } from './repomix.skill'
import { semanticCodebaseSkill } from './semantic-codebase.skill'
import { stateMachinesSkill } from './state-machines.skill'
import { testingSkill } from './testing.skill'
import { typeBoundaryPatternsSkill } from './type-boundary-patterns.skill'
import { typeSafetySkill } from './type-safety.skill'
import { zeroEnvironmentAwarenessSkill } from './zero-environment-awareness.skill'

export const ALL_SKILLS = [
  apiContractSkill,
  devopsPatternsSkill,
  effectClockPatternsSkill,
  effectResilienceSkill,
  effectTsSkill,
  effectXstateSkill,
  ghaOidcPatternsSkill,
  hexagonalSkill,
  mcpOptimizationSkill,
  nixPatternsSkill,
  observabilitySkill,
  optionPatternsSkill,
  paragonSkill,
  parseBoundarySkill,
  planningPatternsSkill,
  pulumiEscSkill,
  refMcpSkill,
  repomixSkill,
  semanticCodebaseSkill,
  stateMachinesSkill,
  testingSkill,
  typeBoundaryPatternsSkill,
  typeSafetySkill,
  zeroEnvironmentAwarenessSkill,
] as const

// Compile-time assertion: exactly 24 skills
type AssertLength<T extends readonly unknown[], N extends number> = T['length'] extends N
  ? true
  : never

const _assertSkillCount: AssertLength<typeof ALL_SKILLS, 24> = true
void _assertSkillCount
