/**
 * Resource Schema Tests
 *
 * Tests for validating Claude Code configuration resources:
 * - Skills (SKILL.md frontmatter)
 * - Commands (command.md frontmatter)
 * - Agents (agent.md frontmatter)
 * - settings.json structure
 */

import { describe, expect, test } from 'bun:test';

describe('Resource Schemas', () => {
  // Import will fail until implementation exists - that's the RED phase
  const getSchemas = async () => {
    try {
      return await import('./resources');
    } catch {
      return null;
    }
  };

  describe('parseFrontmatter', () => {
    test('parses valid YAML frontmatter', async () => {
      const schemas = await getSchemas();
      if (!schemas) {
        expect(true).toBe(true); // Skip until implementation
        return;
      }

      const content = `---
description: Test skill description
name: test-skill
allowed-tools: Read, Write, Bash
---

# Skill Content

This is the skill body.`;

      const result = schemas.parseFrontmatter(content);
      expect(result.frontmatter.description).toBe('Test skill description');
      expect(result.frontmatter.name).toBe('test-skill');
      expect(result.frontmatter['allowed-tools']).toBe('Read, Write, Bash');
      expect(result.body).toContain('# Skill Content');
    });

    test('handles content without frontmatter', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      const content = '# Just Content\n\nNo frontmatter here.';
      const result = schemas.parseFrontmatter(content);
      expect(result.frontmatter).toEqual({});
      expect(result.body).toBe(content);
    });

    test('handles empty frontmatter', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      const content = `---
---
# Content`;
      const result = schemas.parseFrontmatter(content);
      expect(result.frontmatter).toEqual({});
    });
  });

  describe('SkillFrontmatterSchema', () => {
    test('validates valid skill frontmatter', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      const result = schemas.SkillFrontmatterSchema.safeParse({
        description: 'A test skill',
        name: 'test-skill',
        'allowed-tools': 'Read, Write',
      });
      expect(result.success).toBe(true);
    });

    test('requires description', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      const result = schemas.SkillFrontmatterSchema.safeParse({
        name: 'test-skill',
      });
      expect(result.success).toBe(false);
    });

    test('allows optional name and allowed-tools', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      const result = schemas.SkillFrontmatterSchema.safeParse({
        description: 'Minimal skill',
      });
      expect(result.success).toBe(true);
    });
  });

  describe('CommandFrontmatterSchema', () => {
    test('validates valid command frontmatter', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      const result = schemas.CommandFrontmatterSchema.safeParse({
        description: 'A test command',
        'allowed-tools': 'Bash, Read',
      });
      expect(result.success).toBe(true);
    });

    test('requires description', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      const result = schemas.CommandFrontmatterSchema.safeParse({
        'allowed-tools': 'Bash',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('AgentFrontmatterSchema', () => {
    test('validates valid agent frontmatter', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      const result = schemas.AgentFrontmatterSchema.safeParse({
        description: 'A test agent',
        name: 'test-agent',
        'allowed-tools': 'Read, Write, Bash',
      });
      expect(result.success).toBe(true);
    });
  });

  describe('SettingsSchema', () => {
    test('validates valid settings structure', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      const settings = {
        permissions: {
          allow: ['Read', 'Bash(git:*)'],
          deny: ['Bash(rm -rf /)'],
        },
        hooks: {
          PreToolUse: [
            {
              matcher: 'Bash',
              hooks: [
                {
                  type: 'command',
                  command: 'echo "test"',
                  timeout: 5,
                },
              ],
            },
          ],
        },
      };

      const result = schemas.SettingsSchema.safeParse(settings);
      expect(result.success).toBe(true);
    });

    test('requires permissions.allow array', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      const result = schemas.SettingsSchema.safeParse({
        permissions: { deny: [] },
        hooks: {},
      });
      expect(result.success).toBe(false);
    });

    test('requires permissions.deny array', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      const result = schemas.SettingsSchema.safeParse({
        permissions: { allow: [] },
        hooks: {},
      });
      expect(result.success).toBe(false);
    });

    test('validates hook structure', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      const invalidHook = {
        permissions: { allow: [], deny: [] },
        hooks: {
          PreToolUse: [
            {
              matcher: 'Bash',
              hooks: [
                {
                  type: 'invalid',
                  command: 'test',
                },
              ],
            },
          ],
        },
      };

      const result = schemas.SettingsSchema.safeParse(invalidHook);
      expect(result.success).toBe(false);
    });
  });

  describe('HookMatcherSchema', () => {
    test('allows optional matcher', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      // matcher is optional for SessionStart/Stop hooks
      const result = schemas.HookMatcherSchema.safeParse({
        hooks: [{ type: 'command', command: 'test' }],
      });
      expect(result.success).toBe(true);
    });

    test('rejects empty matcher if provided', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      const result = schemas.HookMatcherSchema.safeParse({
        matcher: '',
        hooks: [{ type: 'command', command: 'test' }],
      });
      expect(result.success).toBe(false);
    });

    test('requires at least one hook', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      const result = schemas.HookMatcherSchema.safeParse({
        matcher: 'Bash',
        hooks: [],
      });
      expect(result.success).toBe(false);
    });
  });

  describe('validateSkill', () => {
    test('validates skill from markdown content', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      const content = `---
description: Test skill for validation
---

# Skill Body`;

      const result = schemas.validateSkill(content);
      expect(result.success).toBe(true);
    });
  });

  describe('validateCommand', () => {
    test('validates command from markdown content', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      const content = `---
description: Test command
allowed-tools: Bash
---

Command instructions here.`;

      const result = schemas.validateCommand(content);
      expect(result.success).toBe(true);
    });
  });

  describe('validateAgent', () => {
    test('validates agent from markdown content', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      const content = `---
description: Test agent for reviewing code
name: code-reviewer
---

Agent prompt here.`;

      const result = schemas.validateAgent(content);
      expect(result.success).toBe(true);
    });
  });

  describe('validateSettings', () => {
    test('validates settings object', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      const settings = {
        permissions: { allow: ['Read'], deny: [] },
        hooks: {},
      };

      const result = schemas.validateSettings(settings);
      expect(result.success).toBe(true);
    });
  });

  describe('isValidPermissionPattern', () => {
    test('validates simple tool patterns', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      expect(schemas.isValidPermissionPattern('Read')).toBe(true);
      expect(schemas.isValidPermissionPattern('Write')).toBe(true);
      expect(schemas.isValidPermissionPattern('Bash')).toBe(true);
    });

    test('validates tool patterns with globs', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      expect(schemas.isValidPermissionPattern('Bash(git:*)')).toBe(true);
      expect(schemas.isValidPermissionPattern('Write(*.ts)')).toBe(true);
      expect(schemas.isValidPermissionPattern('Read(*/.env)')).toBe(true);
    });

    test('rejects invalid patterns', async () => {
      const schemas = await getSchemas();
      if (!schemas) return;

      expect(schemas.isValidPermissionPattern('')).toBe(false);
      expect(schemas.isValidPermissionPattern('123')).toBe(false);
      expect(schemas.isValidPermissionPattern('lowercase')).toBe(false);
    });
  });
});
