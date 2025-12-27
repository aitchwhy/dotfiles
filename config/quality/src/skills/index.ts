/**
 * Skills Registry
 *
 * All 9 skills with compile-time count assertion.
 */

export { apiContractSkill } from './api-contract.skill'
export { effectTsSkill } from './effect-ts.skill'
export { hexagonalSkill } from './hexagonal.skill'
export { observabilitySkill } from './observability.skill'
export { parseBoundarySkill } from './parse-boundary.skill'
export { qualityRulesSkill } from './quality-rules.skill'
export { stateMachinesSkill } from './state-machines.skill'
export { testingSkill } from './testing.skill'
export { typeSafetySkill } from './type-safety.skill'

import { apiContractSkill } from './api-contract.skill'
import { effectTsSkill } from './effect-ts.skill'
import { hexagonalSkill } from './hexagonal.skill'
import { observabilitySkill } from './observability.skill'
import { parseBoundarySkill } from './parse-boundary.skill'
import { qualityRulesSkill } from './quality-rules.skill'
import { stateMachinesSkill } from './state-machines.skill'
import { testingSkill } from './testing.skill'
import { typeSafetySkill } from './type-safety.skill'

export const ALL_SKILLS = [
  effectTsSkill,
  hexagonalSkill,
  apiContractSkill,
  observabilitySkill,
  typeSafetySkill,
  parseBoundarySkill,
  testingSkill,
  stateMachinesSkill,
  qualityRulesSkill,
] as const

// Compile-time assertion: exactly 9 skills
type AssertLength<T extends readonly unknown[], N extends number> = T['length'] extends N
  ? true
  : never

const _assertSkillCount: AssertLength<typeof ALL_SKILLS, 9> = true
void _assertSkillCount
