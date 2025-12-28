/**
 * Personas Registry
 *
 * All 14 personas with compile-time count assertion.
 */

export { codeReviewerPersona } from './code-reviewer.persona'
export { criticPersona } from './critic.persona'
export { debuggerPersona } from './debugger.persona'
export { docWriterPersona } from './doc-writer.persona'
export { effectArchitectPersona } from './effect-architect.persona'
export { effectTsExpertPersona } from './effect-ts-expert.persona'
export { nixDarwinExpertPersona } from './nix-darwin-expert.persona'
export { refactorerPersona } from './refactorer.persona'
export { reliabilityEngineerPersona } from './reliability-engineer.persona'
export { securityAuditorPersona } from './security-auditor.persona'
export { synthesizerPersona } from './synthesizer.persona'
export { testArchitectPersona } from './test-architect.persona'
export { testWriterPersona } from './test-writer.persona'
export { typeGuardianPersona } from './type-guardian.persona'

import { codeReviewerPersona } from './code-reviewer.persona'
import { criticPersona } from './critic.persona'
import { debuggerPersona } from './debugger.persona'
import { docWriterPersona } from './doc-writer.persona'
import { effectArchitectPersona } from './effect-architect.persona'
import { effectTsExpertPersona } from './effect-ts-expert.persona'
import { nixDarwinExpertPersona } from './nix-darwin-expert.persona'
import { refactorerPersona } from './refactorer.persona'
import { reliabilityEngineerPersona } from './reliability-engineer.persona'
import { securityAuditorPersona } from './security-auditor.persona'
import { synthesizerPersona } from './synthesizer.persona'
import { testArchitectPersona } from './test-architect.persona'
import { testWriterPersona } from './test-writer.persona'
import { typeGuardianPersona } from './type-guardian.persona'

export const ALL_PERSONAS = [
  codeReviewerPersona,
  criticPersona,
  debuggerPersona,
  docWriterPersona,
  effectArchitectPersona,
  effectTsExpertPersona,
  nixDarwinExpertPersona,
  refactorerPersona,
  reliabilityEngineerPersona,
  securityAuditorPersona,
  synthesizerPersona,
  testArchitectPersona,
  testWriterPersona,
  typeGuardianPersona,
] as const

// Compile-time assertion: exactly 14 personas
type AssertLength<T extends readonly unknown[], N extends number> = T['length'] extends N
  ? true
  : never

const _assertPersonaCount: AssertLength<typeof ALL_PERSONAS, 14> = true
void _assertPersonaCount
