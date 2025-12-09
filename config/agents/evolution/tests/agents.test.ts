/**
 * Agents Validation Tests
 *
 * Validates all agent .md files have correct structure and frontmatter.
 */

import { describe, expect, test } from 'bun:test';
import { validateAgent, parseFrontmatter } from '../src/schemas/resources';

const AGENTS_DIR = `${import.meta.dir}/../../agents`;

// All agent files
const AGENT_NAMES = ['code-reviewer', 'debugger', 'doc-writer', 'refactorer', 'test-writer'];

describe('Agents Validation', () => {
  describe('inventory', () => {
    test('all expected agents exist', async () => {
      for (const name of AGENT_NAMES) {
        const file = Bun.file(`${AGENTS_DIR}/${name}.md`);
        const exists = await file.exists();
        expect(exists).toBe(true);
      }
    });

    test('no unexpected agent files', async () => {
      const glob = new Bun.Glob('*.md');
      const files: string[] = [];
      for await (const file of glob.scan({ cwd: AGENTS_DIR })) {
        const agentName = file.replace('.md', '');
        files.push(agentName);
      }

      // All found agents should be in our list
      for (const found of files) {
        expect(AGENT_NAMES).toContain(found);
      }
    });
  });

  describe('frontmatter validation', () => {
    test.each(AGENT_NAMES)('agent %s has valid frontmatter', async (name) => {
      const file = Bun.file(`${AGENTS_DIR}/${name}.md`);
      const content = await file.text();

      const result = validateAgent(content);
      if (!result.success) {
        console.error(`Agent ${name} validation failed:`, result.error.issues);
      }
      expect(result.success).toBe(true);
    });
  });

  describe('content requirements', () => {
    test.each(AGENT_NAMES)('agent %s has description', async (name) => {
      const file = Bun.file(`${AGENTS_DIR}/${name}.md`);
      const content = await file.text();

      const { frontmatter } = parseFrontmatter(content);
      expect(frontmatter.description).toBeDefined();
      expect(typeof frontmatter.description).toBe('string');
      expect((frontmatter.description as string).length).toBeGreaterThan(0);
    });

    test.each(AGENT_NAMES)('agent %s has body content', async (name) => {
      const file = Bun.file(`${AGENTS_DIR}/${name}.md`);
      const content = await file.text();

      const { body } = parseFrontmatter(content);
      // Body should have meaningful content (agent prompt)
      expect(body.trim().length).toBeGreaterThan(50);
    });
  });
});
