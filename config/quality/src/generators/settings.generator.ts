/**
 * Settings Generator
 *
 * Generates Claude Code settings.json.
 */

import { Effect } from "effect";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import type { PersonaDefinition, SkillDefinition } from "../schemas";

type ClaudeSettings = {
	readonly hooks: {
		readonly PreToolUse: readonly { readonly command: string }[];
	};
	readonly agents: readonly {
		readonly name: string;
		readonly description: string;
		readonly model: string;
	}[];
};

const generateSettings = (
	skills: readonly SkillDefinition[],
	personas: readonly PersonaDefinition[],
	hookPath: string,
): ClaudeSettings => ({
	hooks: {
		PreToolUse: [{ command: `bun "${hookPath}"` }],
	},
	agents: personas.map((p) => ({
		name: p.name,
		description: p.description,
		model: p.model,
	})),
});

export const generateSettingsFile = (
	skills: readonly SkillDefinition[],
	personas: readonly PersonaDefinition[],
	hookPath: string,
	outDir: string,
) =>
	Effect.gen(function* () {
		const settings = generateSettings(skills, personas, hookPath);
		const filePath = path.join(outDir, "settings.json");

		yield* Effect.tryPromise(() =>
			fs.writeFile(filePath, JSON.stringify(settings, null, 2)),
		);

		yield* Effect.log(`Generated: ${filePath}`);
		return filePath;
	});
