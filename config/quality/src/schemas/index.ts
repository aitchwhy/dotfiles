/**
 * Quality System Schemas - Effect Schema SSOT
 *
 * These are the SOURCE OF TRUTH. The official JSON Schema at
 * schemastore.org is used for CI drift detection only.
 *
 * Decoders never throw:
 * - decodeXxx returns Effect (use in Effect.gen)
 * - decodeXxxEither returns Either (use in sync contexts)
 */
import { Schema } from 'effect'

// ═══════════════════════════════════════════════════════════════════════════
// Skills
// ═══════════════════════════════════════════════════════════════════════════

export const SkillFrontmatterSchema = Schema.Struct({
  name: Schema.String.pipe(Schema.minLength(1)),
  description: Schema.String,
  allowedTools: Schema.optional(Schema.Array(Schema.String)),
  tokenBudget: Schema.optional(Schema.Number.pipe(Schema.positive())),
})

export const SkillSectionSchema = Schema.Struct({
  heading: Schema.String,
  content: Schema.String,
})

export const SkillDefinitionSchema = Schema.Struct({
  frontmatter: SkillFrontmatterSchema,
  sections: Schema.Array(SkillSectionSchema),
})

// Types derived FROM schema (Effect Schema as SSOT)
export type SkillFrontmatter = typeof SkillFrontmatterSchema.Type
export type SkillSection = typeof SkillSectionSchema.Type
export type SkillDefinition = typeof SkillDefinitionSchema.Type

// Branded type with Schema.brand (not manual cast)
export const SkillNameSchema = Schema.String.pipe(Schema.minLength(1), Schema.brand('SkillName'))
export type SkillName = typeof SkillNameSchema.Type

// Constructor function for backward compatibility
export const SkillName = Schema.decodeSync(SkillNameSchema)

// Decoders (Effect-native, never throw)
export const decodeSkill = Schema.decodeUnknown(SkillDefinitionSchema)

// For sync contexts that can't use Effect runtime — returns Either, NEVER throws
export const decodeSkillEither = Schema.decodeUnknownEither(SkillDefinitionSchema)

// ═══════════════════════════════════════════════════════════════════════════
// Personas
// ═══════════════════════════════════════════════════════════════════════════

export const ModelChoiceSchema = Schema.Literal('sonnet', 'opus', 'haiku')
export type ModelChoice = typeof ModelChoiceSchema.Type

export const PersonaDefinitionSchema = Schema.Struct({
  name: Schema.String.pipe(Schema.minLength(1)),
  description: Schema.String,
  model: Schema.optional(ModelChoiceSchema),
  color: Schema.optional(Schema.String),
  systemPrompt: Schema.String,
})

export type PersonaDefinition = typeof PersonaDefinitionSchema.Type

// Branded type with Schema.brand (not manual cast)
export const PersonaNameSchema = Schema.String.pipe(
  Schema.minLength(1),
  Schema.brand('PersonaName'),
)
export type PersonaName = typeof PersonaNameSchema.Type

// Constructor function for backward compatibility
export const PersonaName = Schema.decodeSync(PersonaNameSchema)

// Decoders (Effect-native, never throw)
export const decodePersona = Schema.decodeUnknown(PersonaDefinitionSchema)
export const decodePersonaEither = Schema.decodeUnknownEither(PersonaDefinitionSchema)

// ═══════════════════════════════════════════════════════════════════════════
// Rules
// ═══════════════════════════════════════════════════════════════════════════

export const RuleSeveritySchema = Schema.Literal('error', 'warning', 'info')
export type RuleSeverity = typeof RuleSeveritySchema.Type

export const RuleCategorySchema = Schema.Literal(
  'type-safety',
  'effect-ts',
  'effect',
  'architecture',
  'observability',
  'security',
  'testing',
)
export type RuleCategory = typeof RuleCategorySchema.Type

export const QualityRuleSchema = Schema.Struct({
  id: Schema.String.pipe(Schema.minLength(1)),
  name: Schema.String,
  category: RuleCategorySchema,
  severity: RuleSeveritySchema,
  message: Schema.String,
  patterns: Schema.Array(Schema.String).pipe(Schema.minItems(1)),
  antiPattern: Schema.optional(Schema.String),
  fix: Schema.optional(Schema.String),
  note: Schema.optional(Schema.String),
  enabled: Schema.optional(Schema.Boolean),
})

export type QualityRule = typeof QualityRuleSchema.Type

// Branded type with Schema.brand (not manual cast)
export const RuleIdSchema = Schema.String.pipe(Schema.minLength(1), Schema.brand('RuleId'))
export type RuleId = typeof RuleIdSchema.Type

// Constructor function for backward compatibility
export const RuleId = Schema.decodeSync(RuleIdSchema)

// Decoders (Effect-native, never throw)
export const decodeRule = Schema.decodeUnknown(QualityRuleSchema)
export const decodeRuleEither = Schema.decodeUnknownEither(QualityRuleSchema)

// ═══════════════════════════════════════════════════════════════════════════
// CLI Tools (Modern Replacements)
// ═══════════════════════════════════════════════════════════════════════════

export {
  type BatFlags,
  BatFlagsSchema,
  type EzaFlags,
  EzaFlagsSchema,
  type FdFlags,
  FdFlagsSchema,
  type FlagMapping,
  // Helpers
  findIncompatibleFlags,
  formatFlagTranslations,
  // Constants
  LEGACY_FLAG_MAPPINGS,
  type LegacyCommand,
  // Types
  type RipgrepFlags,
  // Schemas
  RipgrepFlagsSchema,
} from './cli-tools.js'
