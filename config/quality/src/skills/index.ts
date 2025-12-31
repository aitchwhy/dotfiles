/**
 * Skills Registry
 *
 * All 33 skills with compile-time count assertion.
 */

export { apiContractSkill } from './api-contract.skill'
export { codebaseExposureSkill } from './codebase-exposure.skill'
export { copierTemplateSkill } from './copier-template.skill'
export { devopsPatternsSkill } from './devops-patterns.skill'
export { effectClockPatternsSkill } from './effect-clock-patterns.skill'
export { effectResilienceSkill } from './effect-resilience.skill'
export { effectTsSkill } from './effect-ts.skill'
export { expoSkill } from './expo.skill'
export { ghaOidcPatternsSkill } from './gha-oidc-patterns.skill'
export { hexagonalSkill } from './hexagonal.skill'
export { livekitAgentsSkill } from './livekit-agents.skill'
export { motiSkill } from './moti.skill'
export { nativewindSkill } from './nativewind.skill'
export { mcpOptimizationSkill } from './mcp-optimization.skill'
export { nixConfigurationCentralizationSkill } from './nix-configuration-centralization.skill'
export { nixPatternsSkill } from './nix-patterns.skill'
export { observabilitySkill } from './observability.skill'
export { optionPatternsSkill } from './option-patterns.skill'
export { paragonSkill } from './paragon.skill'
export { parseBoundarySkill } from './parse-boundary.skill'
export { planningPatternsSkill } from './planning-patterns.skill'
export { pulumiEscSkill } from './pulumi-esc.skill'
export { qualityRulesSkill } from './quality-rules.skill'
export { reactNativeSkill } from './react-native.skill'
export { refMcpSkill } from './ref-mcp.skill'
export { repomixSkill } from './repomix.skill'
export { secretsManagementSkill } from './secrets-management.skill'
export { semanticCodebaseSkill } from './semantic-codebase.skill'
export { stateMachinesSkill } from './state-machines.skill'
export { testingSkill } from './testing.skill'
export { typeBoundaryPatternsSkill } from './type-boundary-patterns.skill'
export { typeSafetySkill } from './type-safety.skill'
export { upgradeSkill } from './upgrade.skill'
export { zeroEnvironmentAwarenessSkill } from './zero-environment-awareness.skill'

import { apiContractSkill } from './api-contract.skill'
import { codebaseExposureSkill } from './codebase-exposure.skill'
import { copierTemplateSkill } from './copier-template.skill'
import { devopsPatternsSkill } from './devops-patterns.skill'
import { effectClockPatternsSkill } from './effect-clock-patterns.skill'
import { effectResilienceSkill } from './effect-resilience.skill'
import { effectTsSkill } from './effect-ts.skill'
import { expoSkill } from './expo.skill'
import { ghaOidcPatternsSkill } from './gha-oidc-patterns.skill'
import { hexagonalSkill } from './hexagonal.skill'
import { livekitAgentsSkill } from './livekit-agents.skill'
import { mcpOptimizationSkill } from './mcp-optimization.skill'
import { motiSkill } from './moti.skill'
import { nativewindSkill } from './nativewind.skill'
import { nixConfigurationCentralizationSkill } from './nix-configuration-centralization.skill'
import { nixPatternsSkill } from './nix-patterns.skill'
import { observabilitySkill } from './observability.skill'
import { optionPatternsSkill } from './option-patterns.skill'
import { paragonSkill } from './paragon.skill'
import { parseBoundarySkill } from './parse-boundary.skill'
import { planningPatternsSkill } from './planning-patterns.skill'
import { pulumiEscSkill } from './pulumi-esc.skill'
import { qualityRulesSkill } from './quality-rules.skill'
import { reactNativeSkill } from './react-native.skill'
import { refMcpSkill } from './ref-mcp.skill'
import { repomixSkill } from './repomix.skill'
import { secretsManagementSkill } from './secrets-management.skill'
import { semanticCodebaseSkill } from './semantic-codebase.skill'
import { stateMachinesSkill } from './state-machines.skill'
import { testingSkill } from './testing.skill'
import { typeBoundaryPatternsSkill } from './type-boundary-patterns.skill'
import { typeSafetySkill } from './type-safety.skill'
import { upgradeSkill } from './upgrade.skill'
import { zeroEnvironmentAwarenessSkill } from './zero-environment-awareness.skill'

export const ALL_SKILLS = [
  apiContractSkill,
  codebaseExposureSkill,
  copierTemplateSkill,
  devopsPatternsSkill,
  effectClockPatternsSkill,
  effectResilienceSkill,
  effectTsSkill,
  expoSkill,
  ghaOidcPatternsSkill,
  hexagonalSkill,
  livekitAgentsSkill,
  mcpOptimizationSkill,
  motiSkill,
  nativewindSkill,
  nixConfigurationCentralizationSkill,
  nixPatternsSkill,
  observabilitySkill,
  optionPatternsSkill,
  paragonSkill,
  parseBoundarySkill,
  planningPatternsSkill,
  pulumiEscSkill,
  qualityRulesSkill,
  reactNativeSkill,
  refMcpSkill,
  repomixSkill,
  secretsManagementSkill,
  semanticCodebaseSkill,
  stateMachinesSkill,
  testingSkill,
  typeBoundaryPatternsSkill,
  typeSafetySkill,
  upgradeSkill,
  zeroEnvironmentAwarenessSkill,
] as const

// Compile-time assertion: exactly 34 skills
type AssertLength<T extends readonly unknown[], N extends number> = T['length'] extends N
  ? true
  : never

const _assertSkillCount: AssertLength<typeof ALL_SKILLS, 34> = true
void _assertSkillCount
