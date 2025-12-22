/**
 * Personas Registry
 *
 * All 6 personas with compile-time count assertion.
 */

export { effectArchitectPersona } from "./effect-architect.persona";
export { typeGuardianPersona } from "./type-guardian.persona";
export { reliabilityEngineerPersona } from "./reliability-engineer.persona";
export { testArchitectPersona } from "./test-architect.persona";
export { debuggerPersona } from "./debugger.persona";
export { securityAuditorPersona } from "./security-auditor.persona";

import { effectArchitectPersona } from "./effect-architect.persona";
import { typeGuardianPersona } from "./type-guardian.persona";
import { reliabilityEngineerPersona } from "./reliability-engineer.persona";
import { testArchitectPersona } from "./test-architect.persona";
import { debuggerPersona } from "./debugger.persona";
import { securityAuditorPersona } from "./security-auditor.persona";

export const ALL_PERSONAS = [
	effectArchitectPersona,
	typeGuardianPersona,
	reliabilityEngineerPersona,
	testArchitectPersona,
	debuggerPersona,
	securityAuditorPersona,
] as const;

// Compile-time assertion: exactly 6 personas
type AssertLength<T extends readonly unknown[], N extends number> =
	T["length"] extends N ? true : never;

const _assertPersonaCount: AssertLength<typeof ALL_PERSONAS, 6> = true;
void _assertPersonaCount;
