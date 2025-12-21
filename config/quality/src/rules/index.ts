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

// Compile-time assertion: exactly 12 rules
type AssertLength<T extends readonly unknown[], N extends number> =
	T["length"] extends N ? true : never;

const _: AssertLength<typeof ALL_RULES, 12> = true;
