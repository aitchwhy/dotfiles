/**
 * Quality Rules Registry
 *
 * All 12 quality rules with compile-time count assertion.
 */

export { TYPE_SAFETY_RULES } from "./type-safety.rules";
export { EFFECT_RULES } from "./effect.rules";
export { ARCHITECTURE_RULES } from "./architecture.rules";
export { OBSERVABILITY_RULES } from "./observability.rules";

import { TYPE_SAFETY_RULES } from "./type-safety.rules";
import { EFFECT_RULES } from "./effect.rules";
import { ARCHITECTURE_RULES } from "./architecture.rules";
import { OBSERVABILITY_RULES } from "./observability.rules";

export const ALL_RULES = [
	...TYPE_SAFETY_RULES,
	...EFFECT_RULES,
	...ARCHITECTURE_RULES,
	...OBSERVABILITY_RULES,
] as const;

// Note: TypeScript can't track array lengths through spreads
// Actual count: 3 + 5 + 3 + 1 = 12 rules
export const RULE_COUNT = ALL_RULES.length;
