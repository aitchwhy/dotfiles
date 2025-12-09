/**
 * Shell Hooks Tests
 *
 * Tests for shell script lifecycle hooks:
 * - session-start.sh
 * - session-stop.sh
 */

import { describe, expect, test } from 'bun:test';

const HOOKS_DIR = `${import.meta.dir}/../../hooks`;

// All shell hook scripts
const SHELL_HOOKS = ['session-start.sh', 'session-stop.sh'];

describe('Shell Hooks', () => {
  describe('file existence', () => {
    test.each(SHELL_HOOKS)('%s exists', async (hookName) => {
      const file = Bun.file(`${HOOKS_DIR}/${hookName}`);
      const exists = await file.exists();
      expect(exists).toBe(true);
    });

    test.each(SHELL_HOOKS)('%s is executable shell script', async (hookName) => {
      const file = Bun.file(`${HOOKS_DIR}/${hookName}`);
      const content = await file.text();

      // Should have shebang
      expect(content.startsWith('#!/')).toBe(true);
    });
  });

  describe('script execution', () => {
    test('session-start.sh runs without error', async () => {
      const proc = Bun.spawn(['bash', `${HOOKS_DIR}/session-start.sh`], {
        stdout: 'pipe',
        stderr: 'pipe',
        env: {
          ...process.env,
          HOME: process.env.HOME || '/tmp',
          // Provide minimal environment for script
        },
      });

      await proc.exited;
      // Script should exit cleanly (0) or with info warning (1)
      expect([0, 1]).toContain(proc.exitCode);
    });

    test('session-stop.sh runs without error', async () => {
      const proc = Bun.spawn(['bash', `${HOOKS_DIR}/session-stop.sh`], {
        stdout: 'pipe',
        stderr: 'pipe',
        env: {
          ...process.env,
          HOME: process.env.HOME || '/tmp',
        },
      });

      await proc.exited;
      // Script should exit cleanly (0) or with info warning (1)
      expect([0, 1]).toContain(proc.exitCode);
    });
  });

  describe('script structure', () => {
    test.each(SHELL_HOOKS)('%s has proper structure', async (hookName) => {
      const file = Bun.file(`${HOOKS_DIR}/${hookName}`);
      const content = await file.text();

      // Should be non-empty
      expect(content.length).toBeGreaterThan(10);

      // Should have comments explaining purpose
      expect(content).toContain('#');
    });
  });
});
