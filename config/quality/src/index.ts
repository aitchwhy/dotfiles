/**
 * Quality System
 *
 * TypeScript-first code quality enforcement for Claude Code.
 */

// Generators
export {
  generateAllPersonas,
  generateAllSkills,
  generateRules,
  generateSettingsFile,
} from './generators'
// Personas
export { ALL_PERSONAS } from './personas'
// Rules
export {
  ALL_RULES,
  ARCHITECTURE_RULES,
  EFFECT_RULES,
  OBSERVABILITY_RULES,
  TYPE_SAFETY_RULES,
} from './rules'
// Schemas
export type {
  ModelChoice,
  PersonaDefinition,
  PersonaName,
  QualityRule,
  RuleCategory,
  RuleId,
  RuleSeverity,
  SkillDefinition,
  SkillFrontmatter,
  SkillName,
  SkillSection,
} from './schemas'
export {
  decodePersona,
  decodePersonaEither,
  decodeRule,
  decodeRuleEither,
  decodeSkill,
  decodeSkillEither,
} from './schemas'
// Skills
export { ALL_SKILLS } from './skills'
// Stack
export { FORBIDDEN_PACKAGES, getNpmVersion, isForbidden, STACK } from './stack'
