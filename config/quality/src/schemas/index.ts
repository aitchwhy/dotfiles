/**
 * Quality System Schemas
 *
 * Type definitions for skills, personas, and rules.
 */

// ═══════════════════════════════════════════════════════════════════════════
// Skills
// ═══════════════════════════════════════════════════════════════════════════

export interface SkillSection {
	readonly heading: string;
	readonly content: string;
}

export interface SkillFrontmatter {
	readonly name: string;
	readonly description: string;
	readonly allowedTools?: readonly string[];
	readonly tokenBudget?: number;
}

export interface SkillDefinition {
	readonly frontmatter: SkillFrontmatter;
	readonly sections: readonly SkillSection[];
}

/** Branded type for skill names */
export type SkillName = string & { readonly _brand: "SkillName" };
export const SkillName = (name: string): SkillName => name as SkillName;

// ═══════════════════════════════════════════════════════════════════════════
// Personas
// ═══════════════════════════════════════════════════════════════════════════

/** Available model choices */
export type ModelChoice = "sonnet" | "opus" | "haiku";

export interface PersonaDefinition {
	readonly name: string;
	readonly description: string;
	readonly model?: ModelChoice;
	readonly color?: string;
	readonly systemPrompt: string;
}

/** Branded type for persona names */
export type PersonaName = string & { readonly _brand: "PersonaName" };
export const PersonaName = (name: string): PersonaName => name as PersonaName;

// ═══════════════════════════════════════════════════════════════════════════
// Rules
// ═══════════════════════════════════════════════════════════════════════════

/** Rule severity levels */
export type RuleSeverity = "error" | "warning" | "info";

/** Rule categories */
export type RuleCategory =
	| "type-safety"
	| "effect-ts"
	| "effect"
	| "architecture"
	| "observability"
	| "security"
	| "testing";

export interface QualityRule {
	readonly id: string;
	readonly name: string;
	readonly category: RuleCategory;
	readonly severity: RuleSeverity;
	readonly message: string;
	readonly patterns: readonly string[];
	readonly antiPattern?: string;
	readonly fix?: string;
	readonly note?: string;
	readonly enabled?: boolean;
}

/** Branded type for rule IDs */
export type RuleId = string & { readonly _brand: "RuleId" };
export const RuleId = (id: string): RuleId => id as RuleId;

// ═══════════════════════════════════════════════════════════════════════════
// Decoders (Simple validation functions)
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Decode and validate a skill definition
 */
export function decodeSkill(input: unknown): SkillDefinition {
	if (!isObject(input)) {
		throw new Error("Skill must be an object");
	}
	const obj = input as Record<string, unknown>;

	if (!isObject(obj["frontmatter"])) {
		throw new Error("Skill must have frontmatter");
	}
	const fm = obj["frontmatter"] as Record<string, unknown>;

	if (typeof fm["name"] !== "string") {
		throw new Error("Skill frontmatter must have name");
	}
	if (typeof fm["description"] !== "string") {
		throw new Error("Skill frontmatter must have description");
	}

	if (!Array.isArray(obj["sections"])) {
		throw new Error("Skill must have sections array");
	}

	return obj as unknown as SkillDefinition;
}

/**
 * Decode and validate a persona definition
 */
export function decodePersona(input: unknown): PersonaDefinition {
	if (!isObject(input)) {
		throw new Error("Persona must be an object");
	}
	const obj = input as Record<string, unknown>;

	if (typeof obj["name"] !== "string") {
		throw new Error("Persona must have name");
	}
	if (typeof obj["description"] !== "string") {
		throw new Error("Persona must have description");
	}
	if (typeof obj["systemPrompt"] !== "string") {
		throw new Error("Persona must have systemPrompt");
	}

	return obj as unknown as PersonaDefinition;
}

/**
 * Decode and validate a quality rule
 */
export function decodeRule(input: unknown): QualityRule {
	if (!isObject(input)) {
		throw new Error("Rule must be an object");
	}
	const obj = input as Record<string, unknown>;

	if (typeof obj["id"] !== "string") {
		throw new Error("Rule must have id");
	}
	if (typeof obj["name"] !== "string") {
		throw new Error("Rule must have name");
	}
	if (typeof obj["category"] !== "string") {
		throw new Error("Rule must have category");
	}
	if (typeof obj["severity"] !== "string") {
		throw new Error("Rule must have severity");
	}
	if (typeof obj["message"] !== "string") {
		throw new Error("Rule must have message");
	}
	if (!Array.isArray(obj["patterns"])) {
		throw new Error("Rule must have patterns array");
	}

	return obj as unknown as QualityRule;
}

// ═══════════════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════════════

function isObject(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null && !Array.isArray(value);
}
