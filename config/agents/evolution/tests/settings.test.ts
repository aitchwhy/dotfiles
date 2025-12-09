/**
 * Settings.json Validation Tests
 *
 * Validates the Claude Code settings.json configuration file.
 */

import { describe, expect, test } from 'bun:test';
import { isValidPermissionPattern, validateSettings } from '../src/schemas/resources';

const SETTINGS_PATH = `${import.meta.dir}/../../settings.json`;
const HOOKS_DIR = `${import.meta.dir}/../../hooks`;

describe('Settings.json Validation', () => {
  let settings: unknown;

  // Load settings once for all tests
  test('settings.json exists and is valid JSON', async () => {
    const file = Bun.file(SETTINGS_PATH);
    const exists = await file.exists();
    expect(exists).toBe(true);

    settings = await file.json();
    expect(settings).toBeDefined();
  });

  describe('schema validation', () => {
    test('settings matches schema', async () => {
      if (!settings) {
        settings = await Bun.file(SETTINGS_PATH).json();
      }

      const result = validateSettings(settings);
      if (!result.success) {
        console.error('Settings validation failed:', result.error.issues);
      }
      expect(result.success).toBe(true);
    });
  });

  describe('permissions structure', () => {
    test('has permissions.allow array', async () => {
      if (!settings) {
        settings = await Bun.file(SETTINGS_PATH).json();
      }

      const s = settings as { permissions: { allow: string[] } };
      expect(Array.isArray(s.permissions.allow)).toBe(true);
      expect(s.permissions.allow.length).toBeGreaterThan(0);
    });

    test('has permissions.deny array', async () => {
      if (!settings) {
        settings = await Bun.file(SETTINGS_PATH).json();
      }

      const s = settings as { permissions: { deny: string[] } };
      expect(Array.isArray(s.permissions.deny)).toBe(true);
      expect(s.permissions.deny.length).toBeGreaterThan(0);
    });

    test('permission patterns have valid syntax', async () => {
      if (!settings) {
        settings = await Bun.file(SETTINGS_PATH).json();
      }

      const s = settings as { permissions: { allow: string[]; deny: string[] } };
      const allPatterns = [...s.permissions.allow, ...s.permissions.deny];

      for (const pattern of allPatterns) {
        const isValid = isValidPermissionPattern(pattern);
        if (!isValid) {
          console.log(`Invalid pattern: ${pattern}`);
        }
        expect(isValid).toBe(true);
      }
    });
  });

  describe('hooks structure', () => {
    test('has hooks object', async () => {
      if (!settings) {
        settings = await Bun.file(SETTINGS_PATH).json();
      }

      const s = settings as { hooks: object };
      expect(s.hooks).toBeDefined();
      expect(typeof s.hooks).toBe('object');
    });

    test('PreToolUse hooks are valid', async () => {
      if (!settings) {
        settings = await Bun.file(SETTINGS_PATH).json();
      }

      const s = settings as {
        hooks: { PreToolUse?: Array<{ matcher: string; hooks: unknown[] }> };
      };
      if (s.hooks.PreToolUse) {
        expect(Array.isArray(s.hooks.PreToolUse)).toBe(true);
        for (const hook of s.hooks.PreToolUse) {
          expect(hook.matcher).toBeDefined();
          expect(hook.hooks).toBeDefined();
          expect(Array.isArray(hook.hooks)).toBe(true);
        }
      }
    });

    test('PostToolUse hooks are valid', async () => {
      if (!settings) {
        settings = await Bun.file(SETTINGS_PATH).json();
      }

      const s = settings as {
        hooks: { PostToolUse?: Array<{ matcher: string; hooks: unknown[] }> };
      };
      if (s.hooks.PostToolUse) {
        expect(Array.isArray(s.hooks.PostToolUse)).toBe(true);
        for (const hook of s.hooks.PostToolUse) {
          expect(hook.matcher).toBeDefined();
          expect(hook.hooks).toBeDefined();
        }
      }
    });
  });

  describe('hook file references', () => {
    test('all hook commands reference existing files', async () => {
      if (!settings) {
        settings = await Bun.file(SETTINGS_PATH).json();
      }

      const s = settings as {
        hooks: {
          PreToolUse?: Array<{ hooks: Array<{ command: string }> }>;
          PostToolUse?: Array<{ hooks: Array<{ command: string }> }>;
          SessionStart?: Array<{ hooks: Array<{ command: string }> }>;
          Stop?: Array<{ hooks: Array<{ command: string }> }>;
        };
      };

      const allHooks = [
        ...(s.hooks.PreToolUse || []),
        ...(s.hooks.PostToolUse || []),
        ...(s.hooks.SessionStart || []),
        ...(s.hooks.Stop || []),
      ];

      for (const matcher of allHooks) {
        for (const hook of matcher.hooks) {
          const command = hook.command;

          // Extract file path from bun run commands
          const bunRunMatch = command.match(/bun run "([^"]+)"/);
          if (bunRunMatch) {
            const filePath = bunRunMatch[1]?.replace('$HOME/dotfiles/config/agents/hooks/', '');
            if (filePath && !filePath.includes('$')) {
              const fullPath = `${HOOKS_DIR}/${filePath}`;
              const file = Bun.file(fullPath);
              const exists = await file.exists();
              if (!exists) {
                console.log(`Missing hook file: ${fullPath}`);
              }
              expect(exists).toBe(true);
            }
          }

          // Extract file path from bash commands
          const bashMatch = command.match(/bash "([^"]+)"/);
          if (bashMatch) {
            const filePath = bashMatch[1]?.replace('$HOME/dotfiles/config/agents/hooks/', '');
            if (filePath && !filePath.includes('$')) {
              const fullPath = `${HOOKS_DIR}/${filePath}`;
              const file = Bun.file(fullPath);
              const exists = await file.exists();
              if (!exists) {
                console.log(`Missing hook file: ${fullPath}`);
              }
              expect(exists).toBe(true);
            }
          }
        }
      }
    });
  });

  describe('security rules', () => {
    test('dangerous commands are denied', async () => {
      if (!settings) {
        settings = await Bun.file(SETTINGS_PATH).json();
      }

      const s = settings as { permissions: { deny: string[] } };
      const denyList = s.permissions.deny;

      // Check for dangerous command patterns
      const hasRmRfRoot = denyList.some((p) => p.includes('rm -rf /'));
      const hasRmRfHome = denyList.some((p) => p.includes('rm -rf ~'));
      const hasSudo = denyList.some((p) => p.includes('sudo'));

      expect(hasRmRfRoot).toBe(true);
      expect(hasRmRfHome).toBe(true);
      expect(hasSudo).toBe(true);
    });

    test('sensitive files are protected', async () => {
      if (!settings) {
        settings = await Bun.file(SETTINGS_PATH).json();
      }

      const s = settings as { permissions: { deny: string[] } };
      const denyList = s.permissions.deny;

      // Check for sensitive file patterns
      const hasEnvProtection = denyList.some((p) => p.includes('.env'));
      const hasKeyProtection = denyList.some((p) => p.includes('.pem') || p.includes('.key'));

      expect(hasEnvProtection).toBe(true);
      expect(hasKeyProtection).toBe(true);
    });
  });
});
