/**
 * Personas Registry
 *
 * All 6 personas with compile-time count assertion.
 */

export { debuggerPersona } from './debugger.persona'
export { effectArchitectPersona } from './effect-architect.persona'
export { reliabilityEngineerPersona } from './reliability-engineer.persona'
export { securityAuditorPersona } from './security-auditor.persona'
export { testArchitectPersona } from './test-architect.persona'
export { typeGuardianPersona } from './type-guardian.persona'

import { debuggerPersona } from './debugger.persona'
import { effectArchitectPersona } from './effect-architect.persona'
import { reliabilityEngineerPersona } from './reliability-engineer.persona'
import { securityAuditorPersona } from './security-auditor.persona'
import { testArchitectPersona } from './test-architect.persona'
import { typeGuardianPersona } from './type-guardian.persona'

export const ALL_PERSONAS = [
  effectArchitectPersona,
  typeGuardianPersona,
  reliabilityEngineerPersona,
  testArchitectPersona,
  debuggerPersona,
  securityAuditorPersona,
] as const

// Compile-time assertion: exactly 6 personas
type AssertLength<T extends readonly unknown[], N extends number> = T['length'] extends N
  ? true
  : never

const _assertPersonaCount: AssertLength<typeof ALL_PERSONAS, 6> = true
void _assertPersonaCount
