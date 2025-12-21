/**
 * Schema Tests
 *
 * Validates Effect Schema definitions.
 */

import { describe, expect, it } from "vitest";
import { Schema } from "effect";
import {
	SkillFrontmatter,
	PersonaDefinition,
	QualityRule,
	SkillName,
	PersonaName,
	RuleId,
} from "../src/schemas";

describe("Branded Types", () => {
	it("creates SkillName", () => {
		const name = SkillName("effect-ts");
		expect(name).toBe("effect-ts");
	});

	it("creates PersonaName", () => {
		const name = PersonaName("debugger");
		expect(name).toBe("debugger");
	});

	it("creates RuleId", () => {
		const id = RuleId("no-any");
		expect(id).toBe("no-any");
	});
});

describe("SkillFrontmatter Schema", () => {
	it("decodes valid frontmatter", () => {
		const input = {
			name: "test-skill",
			description: "A test skill",
			allowedTools: ["Read", "Write"],
			tokenBudget: 500,
		};

		const result = Schema.decodeUnknownSync(SkillFrontmatter)(input);
		expect(result.name).toBe("test-skill");
	});

	it("rejects invalid name pattern", () => {
		const input = {
			name: "Invalid Name",
			description: "A test skill",
		};

		expect(() => Schema.decodeUnknownSync(SkillFrontmatter)(input)).toThrow();
	});
});

describe("PersonaDefinition Schema", () => {
	it("decodes valid persona", () => {
		const input = {
			name: "test-persona",
			description: "A test persona",
			model: "sonnet",
			systemPrompt: "You are a test persona.",
		};

		const result = Schema.decodeUnknownSync(PersonaDefinition)(input);
		expect(result.model).toBe("sonnet");
	});

	it("rejects invalid model", () => {
		const input = {
			name: "test-persona",
			description: "A test persona",
			model: "gpt-4",
			systemPrompt: "You are a test persona.",
		};

		expect(() => Schema.decodeUnknownSync(PersonaDefinition)(input)).toThrow();
	});
});

describe("QualityRule Schema", () => {
	it("decodes valid rule", () => {
		const input = {
			id: "test-rule",
			name: "Test Rule",
			category: "type-safety",
			severity: "error",
			message: "This is a test rule",
			patterns: [": any"],
			fix: "Use unknown instead",
		};

		const result = Schema.decodeUnknownSync(QualityRule)(input);
		expect(result.severity).toBe("error");
	});
});
