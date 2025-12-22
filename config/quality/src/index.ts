/**
 * Quality System
 *
 * TypeScript-first code quality enforcement for Claude Code.
 */

// Schemas
export type {
	SkillName,
	PersonaName,
	RuleId,
	SkillFrontmatter,
	SkillSection,
	SkillDefinition,
	ModelChoice,
	PersonaDefinition,
	RuleSeverity,
	RuleCategory,
	QualityRule,
} from "./schemas";

export {
	decodeSkill,
	decodeSkillEither,
	decodePersona,
	decodePersonaEither,
	decodeRule,
	decodeRuleEither,
} from "./schemas";

// Rules
export { ALL_RULES, TYPE_SAFETY_RULES, EFFECT_RULES } from "./rules";
export { ARCHITECTURE_RULES, OBSERVABILITY_RULES } from "./rules";

// Skills
export { ALL_SKILLS } from "./skills";

// Personas
export { ALL_PERSONAS } from "./personas";

// Stack
export { STACK, getNpmVersion, isForbidden, FORBIDDEN_PACKAGES } from "./stack";

// Generators
export {
	generateAllSkills,
	generateAllPersonas,
	generateRules,
	generateSettingsFile,
} from "./generators";
