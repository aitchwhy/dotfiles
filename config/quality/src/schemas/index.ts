/**
 * Quality System Schema Definitions
 *
 * TypeScript types are SSOT - Schema satisfies type (never infer from Schema)
 */

import { Brand, Schema } from "effect";

// =============================================================================
// Branded Types (compile-time safety)
// =============================================================================

export type SkillName = string & Brand.Brand<"SkillName">;
export const SkillName = Brand.nominal<SkillName>();

export type PersonaName = string & Brand.Brand<"PersonaName">;
export const PersonaName = Brand.nominal<PersonaName>();

export type RuleId = string & Brand.Brand<"RuleId">;
export const RuleId = Brand.nominal<RuleId>();

// =============================================================================
// Skill Schema
// =============================================================================

export type SkillFrontmatter = {
	readonly name: SkillName;
	readonly description: string;
	readonly allowedTools?: readonly string[];
	readonly tokenBudget?: number;
};

export const SkillFrontmatter = Schema.Struct({
	name: Schema.String.pipe(
		Schema.pattern(/^[a-z][a-z0-9-]*$/),
		Schema.maxLength(64),
		Schema.brand("SkillName"),
	),
	description: Schema.String.pipe(Schema.maxLength(1024)),
	allowedTools: Schema.optional(Schema.Array(Schema.String)),
	tokenBudget: Schema.optional(Schema.Number.pipe(Schema.between(100, 5000))),
}) satisfies Schema.Schema<SkillFrontmatter, unknown>;

export type SkillSection = {
	readonly heading: string;
	readonly content: string;
};

export const SkillSection = Schema.Struct({
	heading: Schema.String,
	content: Schema.String,
}) satisfies Schema.Schema<SkillSection, unknown>;

export type SkillDefinition = {
	readonly frontmatter: SkillFrontmatter;
	readonly sections: readonly SkillSection[];
};

export const SkillDefinition = Schema.Struct({
	frontmatter: SkillFrontmatter,
	sections: Schema.Array(SkillSection),
}) satisfies Schema.Schema<SkillDefinition, unknown>;

// =============================================================================
// Persona Schema
// =============================================================================

export type ModelChoice = "inherit" | "opus" | "sonnet" | "haiku";

export type PersonaDefinition = {
	readonly name: PersonaName;
	readonly description: string;
	readonly model: ModelChoice;
	readonly color?: string;
	readonly systemPrompt: string;
};

export const PersonaDefinition = Schema.Struct({
	name: Schema.String.pipe(
		Schema.pattern(/^[a-z][a-z0-9-]*$/),
		Schema.brand("PersonaName"),
	),
	description: Schema.String.pipe(Schema.maxLength(1024)),
	model: Schema.Literal("inherit", "opus", "sonnet", "haiku"),
	color: Schema.optional(Schema.String),
	systemPrompt: Schema.String,
}) satisfies Schema.Schema<PersonaDefinition, unknown>;

// =============================================================================
// Quality Rule Schema
// =============================================================================

export type RuleSeverity = "error" | "warning";
export type RuleCategory =
	| "type-safety"
	| "effect"
	| "architecture"
	| "observability";

export type QualityRule = {
	readonly id: RuleId;
	readonly name: string;
	readonly category: RuleCategory;
	readonly severity: RuleSeverity;
	readonly message: string;
	readonly patterns: readonly string[];
	readonly fix: string;
	readonly note?: string;
};

export const QualityRule = Schema.Struct({
	id: Schema.String.pipe(Schema.brand("RuleId")),
	name: Schema.String,
	category: Schema.Literal(
		"type-safety",
		"effect",
		"architecture",
		"observability",
	),
	severity: Schema.Literal("error", "warning"),
	message: Schema.String,
	patterns: Schema.Array(Schema.String),
	fix: Schema.String,
	note: Schema.optional(Schema.String),
}) satisfies Schema.Schema<QualityRule, unknown>;

// =============================================================================
// Decoders
// =============================================================================

export const decodeSkill = Schema.decodeUnknownSync(SkillDefinition);
export const decodePersona = Schema.decodeUnknownSync(PersonaDefinition);
export const decodeRule = Schema.decodeUnknownSync(QualityRule);
