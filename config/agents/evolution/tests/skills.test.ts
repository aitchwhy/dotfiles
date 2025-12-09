/**
 * Skills Validation Tests
 *
 * Validates all skill SKILL.md files have correct structure and frontmatter.
 */

import { describe, expect, test } from 'bun:test';
import { parseFrontmatter, validateSkill } from '../src/schemas/resources';

const SKILLS_DIR = `${import.meta.dir}/../../skills`;

// All skill directories
const SKILL_NAMES = [
  'clean-code',
  'ember-patterns',
  'hono-workers',
  'livekit-agents',
  'nix-darwin-patterns',
  'observability-patterns',
  'repomix-patterns',
  'result-patterns',
  'signet-patterns',
  'tanstack-patterns',
  'tdd-patterns',
  'twelve-factor',
  'typescript-patterns',
  'verification-first',
  'zod-patterns',
];

describe('Skills Validation', () => {
  describe('inventory', () => {
    test('all expected skills exist', async () => {
      for (const name of SKILL_NAMES) {
        const file = Bun.file(`${SKILLS_DIR}/${name}/SKILL.md`);
        const exists = await file.exists();
        expect(exists).toBe(true);
      }
    });

    test('no unexpected skill directories', async () => {
      const glob = new Bun.Glob('*/SKILL.md');
      const files: string[] = [];
      for await (const file of glob.scan({ cwd: SKILLS_DIR })) {
        const skillName = file.replace('/SKILL.md', '');
        files.push(skillName);
      }

      // All found skills should be in our list
      for (const found of files) {
        expect(SKILL_NAMES).toContain(found);
      }
    });
  });

  describe('frontmatter validation', () => {
    test.each(SKILL_NAMES)('skill %s has valid frontmatter', async (name) => {
      const file = Bun.file(`${SKILLS_DIR}/${name}/SKILL.md`);
      const content = await file.text();

      const result = validateSkill(content);
      if (!result.success) {
        console.error(`Skill ${name} validation failed:`, result.error.issues);
      }
      expect(result.success).toBe(true);
    });
  });

  describe('content requirements', () => {
    test.each(SKILL_NAMES)('skill %s has description', async (name) => {
      const file = Bun.file(`${SKILLS_DIR}/${name}/SKILL.md`);
      const content = await file.text();

      const { frontmatter } = parseFrontmatter(content);
      expect(frontmatter['description']).toBeDefined();
      expect(typeof frontmatter['description']).toBe('string');
      expect((frontmatter['description'] as string).length).toBeGreaterThan(0);
    });

    test.each(SKILL_NAMES)('skill %s has body content', async (name) => {
      const file = Bun.file(`${SKILLS_DIR}/${name}/SKILL.md`);
      const content = await file.text();

      const { body } = parseFrontmatter(content);
      // Body should have meaningful content (not just whitespace)
      expect(body.trim().length).toBeGreaterThan(10);
    });
  });
});
