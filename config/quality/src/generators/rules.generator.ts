/**
 * Rules Generator
 *
 * Transforms QualityRule[] → rules markdown.
 */

import { Effect } from "effect";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import type { QualityRule } from "../schemas";

const generateRulesMarkdown = (rules: readonly QualityRule[]): string => {
	const byCategory = new Map<string, QualityRule[]>();

	for (const rule of rules) {
		const existing = byCategory.get(rule.category) ?? [];
		byCategory.set(rule.category, [...existing, rule]);
	}

	const sections = Array.from(byCategory.entries())
		.map(([category, categoryRules]) => {
			const rows = categoryRules
				.map(
					(r) =>
						`| ${r.id} | ${r.severity} | ${r.patterns.join(", ")} | ${r.fix} |`,
				)
				.join("\n");

			return `## ${category}\n\n| Rule | Severity | Patterns | Fix |\n|------|----------|----------|-----|\n${rows}`;
		})
		.join("\n\n");

	return `# Quality Rules\n\nTotal: ${rules.length} rules\n\n${sections}\n`;
};

export const generateRules = (rules: readonly QualityRule[], outDir: string) =>
	Effect.gen(function* () {
		const markdown = generateRulesMarkdown(rules);
		const rulesDir = path.join(outDir, "rules");
		const filePath = path.join(rulesDir, "RULES.md");

		yield* Effect.tryPromise(() => fs.mkdir(rulesDir, { recursive: true }));
		yield* Effect.tryPromise(() => fs.writeFile(filePath, markdown));

		yield* Effect.log(`Generated: ${filePath}`);
		return filePath;
	});
