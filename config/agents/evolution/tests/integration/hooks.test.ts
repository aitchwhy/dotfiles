/**
 * Hook Integration Tests
 *
 * End-to-end tests for all Claude Code hooks.
 * These tests verify hooks work correctly with actual stdin/stdout.
 */

import { describe, expect, test } from 'bun:test';

const HOOKS_DIR = `${import.meta.dir}/../../../hooks`;

// Helper to run a TypeScript hook with given input
async function runHook(
  hookFile: string,
  input: object
): Promise<{ decision: string; reason?: string; exitCode: number }> {
  const inputJson = JSON.stringify(input);
  const proc = Bun.spawn(['bun', 'run', `${HOOKS_DIR}/${hookFile}`], {
    stdin: new Response(inputJson),
    stdout: 'pipe',
    stderr: 'pipe',
  });

  const output = await new Response(proc.stdout).text();
  const exitCode = await proc.exited;

  try {
    return { ...JSON.parse(output.trim()), exitCode };
  } catch {
    return { decision: 'approve', reason: `Parse error: ${output}`, exitCode };
  }
}

describe('Hook Integration Tests', () => {
  // unified-guard.ts consolidated all PreToolUse guards:
  // - conventional-commit.ts
  // - forbidden-files.ts
  // - forbidden-imports.ts
  // - any-type-detector.ts
  // - tdd-enforcer.ts
  const unifiedGuard = 'unified-guard.ts';

  describe('conventional commit (unified-guard)', () => {
    test('allows valid conventional commit', async () => {
      const result = await runHook(unifiedGuard, {
        hook_event_name: 'PreToolUse',
        session_id: 'test',
        tool_name: 'Bash',
        tool_input: { command: 'git commit -m "feat(api): add user endpoint"' },
      });
      expect(result.decision).toBe('approve');
    });

    test('blocks invalid commit message', async () => {
      const result = await runHook(unifiedGuard, {
        hook_event_name: 'PreToolUse',
        session_id: 'test',
        tool_name: 'Bash',
        tool_input: { command: 'git commit -m "fixed stuff"' },
      });
      expect(result.decision).toBe('block');
      expect(result.reason).toContain('CONVENTIONAL COMMIT');
    });

    test('blocks uppercase first letter after colon', async () => {
      const result = await runHook(unifiedGuard, {
        hook_event_name: 'PreToolUse',
        session_id: 'test',
        tool_name: 'Bash',
        tool_input: { command: 'git commit -m "feat: Add new feature"' },
      });
      expect(result.decision).toBe('block');
    });

    test('allows lowercase first letter after colon', async () => {
      const result = await runHook(unifiedGuard, {
        hook_event_name: 'PreToolUse',
        session_id: 'test',
        tool_name: 'Bash',
        tool_input: { command: 'git commit -m "feat: add new feature"' },
      });
      expect(result.decision).toBe('approve');
    });

    test('allows non-git commands', async () => {
      const result = await runHook(unifiedGuard, {
        hook_event_name: 'PreToolUse',
        session_id: 'test',
        tool_name: 'Bash',
        tool_input: { command: 'ls -la' },
      });
      expect(result.decision).toBe('approve');
    });
  });

  describe('forbidden files (unified-guard)', () => {
    test('blocks package-lock.json', async () => {
      const result = await runHook(unifiedGuard, {
        hook_event_name: 'PreToolUse',
        session_id: 'test',
        tool_name: 'Write',
        tool_input: { file_path: '/project/package-lock.json' },
      });
      expect(result.decision).toBe('block');
    });

    test('allows package.json', async () => {
      const result = await runHook(unifiedGuard, {
        hook_event_name: 'PreToolUse',
        session_id: 'test',
        tool_name: 'Write',
        tool_input: { file_path: '/project/package.json' },
      });
      expect(result.decision).toBe('approve');
    });

    test('blocks .eslintrc files', async () => {
      const result = await runHook(unifiedGuard, {
        hook_event_name: 'PreToolUse',
        session_id: 'test',
        tool_name: 'Write',
        tool_input: { file_path: '/project/.eslintrc.json' },
      });
      expect(result.decision).toBe('block');
    });
  });

  describe('forbidden imports (unified-guard)', () => {
    // Use index.ts which is excluded from TDD enforcement
    test('allows normal TypeScript code', async () => {
      const result = await runHook(unifiedGuard, {
        hook_event_name: 'PreToolUse',
        session_id: 'test',
        tool_name: 'Write',
        tool_input: {
          file_path: '/project/src/index.ts',
          content: 'import { z } from "zod";\nimport { Hono } from "hono";',
        },
      });
      expect(result.decision).toBe('approve');
    });
  });

  describe('any type detector (unified-guard)', () => {
    // Use index.ts which is excluded from TDD enforcement
    test('blocks explicit any type', async () => {
      const result = await runHook(unifiedGuard, {
        hook_event_name: 'PreToolUse',
        session_id: 'test',
        tool_name: 'Write',
        tool_input: {
          file_path: '/project/src/index.ts',
          content: 'const x: any = 5;',
        },
      });
      expect(result.decision).toBe('block');
    });

    test('allows unknown type', async () => {
      const result = await runHook(unifiedGuard, {
        hook_event_name: 'PreToolUse',
        session_id: 'test',
        tool_name: 'Write',
        tool_input: {
          file_path: '/project/src/index.ts',
          content: 'const x: unknown = 5;',
        },
      });
      expect(result.decision).toBe('approve');
    });

    test('allows any in comments', async () => {
      const result = await runHook(unifiedGuard, {
        hook_event_name: 'PreToolUse',
        session_id: 'test',
        tool_name: 'Write',
        tool_input: {
          file_path: '/project/src/index.ts',
          content: '// TODO: fix any type later\nconst x: string = "test";',
        },
      });
      expect(result.decision).toBe('approve');
    });
  });

  describe('tdd enforcer (unified-guard)', () => {
    test('allows test files', async () => {
      const result = await runHook(unifiedGuard, {
        hook_event_name: 'PreToolUse',
        session_id: 'test',
        tool_name: 'Write',
        tool_input: { file_path: '/project/src/user.test.ts' },
      });
      expect(result.decision).toBe('approve');
    });

    test('allows excluded paths', async () => {
      const result = await runHook(unifiedGuard, {
        hook_event_name: 'PreToolUse',
        session_id: 'test',
        tool_name: 'Write',
        tool_input: { file_path: '/project/node_modules/lodash/index.ts' },
      });
      expect(result.decision).toBe('approve');
    });

    test('allows non-source files', async () => {
      const result = await runHook(unifiedGuard, {
        hook_event_name: 'PreToolUse',
        session_id: 'test',
        tool_name: 'Write',
        tool_input: { file_path: '/project/README.md' },
      });
      expect(result.decision).toBe('approve');
    });
  });

  describe('enforce-versions.ts', () => {
    const hookFile = 'enforce-versions.ts';

    test('runs without error for valid package.json', async () => {
      const result = await runHook(hookFile, {
        hook_event_name: 'PostToolUse',
        session_id: 'test',
        tool_name: 'Write',
        tool_input: { file_path: '/tmp/package.json' },
        tool_output: { success: true },
      });
      // Should allow (PostToolUse hooks inform, don't block)
      expect(result.exitCode).toBe(0);
    });
  });

  describe('cross-hook consistency', () => {
    test('unified-guard handles missing input gracefully', async () => {
      const result = await runHook(unifiedGuard, {});
      // Should allow when input is malformed
      expect(result.decision).toBe('approve');
    });

    test('unified-guard handles wrong tool gracefully', async () => {
      const result = await runHook(unifiedGuard, {
        hook_event_name: 'PreToolUse',
        session_id: 'test',
        tool_name: 'UnknownTool',
        tool_input: {},
      });
      // Should allow for unknown tools
      expect(result.decision).toBe('approve');
    });
  });
});
