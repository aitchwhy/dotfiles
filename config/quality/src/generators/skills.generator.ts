/**
 * Skills Generator
 *
 * Transforms SkillDefinition → SKILL.md files.
 */

import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import { Effect } from 'effect';
import type { SkillDefinition } from '../schemas';

const generateSkillMarkdown = (skill: SkillDefinition): string => {
  const { frontmatter, sections } = skill;

  const yaml = [
    '---',
    `name: ${frontmatter.name}`,
    `description: ${frontmatter.description}`,
    frontmatter.allowedTools ? `allowed-tools: ${frontmatter.allowedTools.join(', ')}` : null,
    frontmatter.tokenBudget ? `token-budget: ${frontmatter.tokenBudget}` : null,
    '---',
  ]
    .filter(Boolean)
    .join('\n');

  const content = sections.map((s) => `## ${s.heading}\n\n${s.content.trim()}`).join('\n\n');

  return `${yaml}\n\n# ${frontmatter.name}\n\n${content}\n`;
};

export const generateSkill = (skill: SkillDefinition, outDir: string) =>
  Effect.gen(function* () {
    const markdown = generateSkillMarkdown(skill);
    const skillDir = path.join(outDir, 'skills', skill.frontmatter.name);
    const filePath = path.join(skillDir, 'SKILL.md');

    yield* Effect.tryPromise(() => fs.mkdir(skillDir, { recursive: true }));
    yield* Effect.tryPromise(() => fs.writeFile(filePath, markdown));

    yield* Effect.log(`Generated: ${filePath}`);
    return filePath;
  });

export const generateAllSkills = (skills: readonly SkillDefinition[], outDir: string) =>
  Effect.gen(function* () {
    const results: string[] = [];
    for (const skill of skills) {
      const filePath = yield* generateSkill(skill, outDir);
      results.push(filePath);
    }
    return results;
  });
