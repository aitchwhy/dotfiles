/**
 * Commands Validation Tests
 *
 * Validates all command .md files have correct structure and frontmatter.
 */

import { describe, expect, test } from 'bun:test';
import { parseFrontmatter, validateCommand } from '../src/schemas/resources';

const COMMANDS_DIR = `${import.meta.dir}/../../commands`;

// All command files
const COMMAND_NAMES = [
  'commit',
  'debug',
  'evolve',
  'feature',
  'fix',
  'new-project',
  'nix-rebuild',
  'nix-search',
  'plan',
  'pr',
  'review',
  'signet',
  'sync',
  'tdd',
  'validate',
  'verify',
];

describe('Commands Validation', () => {
  describe('inventory', () => {
    test('all expected commands exist', async () => {
      for (const name of COMMAND_NAMES) {
        const file = Bun.file(`${COMMANDS_DIR}/${name}.md`);
        const exists = await file.exists();
        expect(exists).toBe(true);
      }
    });

    test('no unexpected command files', async () => {
      const glob = new Bun.Glob('*.md');
      const files: string[] = [];
      for await (const file of glob.scan({ cwd: COMMANDS_DIR })) {
        const commandName = file.replace('.md', '');
        files.push(commandName);
      }

      // All found commands should be in our list
      for (const found of files) {
        expect(COMMAND_NAMES).toContain(found);
      }
    });
  });

  describe('frontmatter validation', () => {
    test.each(COMMAND_NAMES)('command /%s has valid frontmatter', async (name) => {
      const file = Bun.file(`${COMMANDS_DIR}/${name}.md`);
      const content = await file.text();

      const result = validateCommand(content);
      if (!result.success) {
        console.error(`Command ${name} validation failed:`, result.error.issues);
      }
      expect(result.success).toBe(true);
    });
  });

  describe('content requirements', () => {
    test.each(COMMAND_NAMES)('command /%s has description', async (name) => {
      const file = Bun.file(`${COMMANDS_DIR}/${name}.md`);
      const content = await file.text();

      const { frontmatter } = parseFrontmatter(content);
      expect(frontmatter['description']).toBeDefined();
      expect(typeof frontmatter['description']).toBe('string');
      expect((frontmatter['description'] as string).length).toBeGreaterThan(0);
    });

    test.each(COMMAND_NAMES)('command /%s has body content', async (name) => {
      const file = Bun.file(`${COMMANDS_DIR}/${name}.md`);
      const content = await file.text();

      const { body } = parseFrontmatter(content);
      // Body should have meaningful content
      expect(body.trim().length).toBeGreaterThan(10);
    });
  });
});
