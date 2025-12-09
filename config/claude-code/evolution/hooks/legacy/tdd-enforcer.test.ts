/**
 * TDD Enforcer Hook Tests
 *
 * Tests the hook's input parsing and output behavior.
 * Pattern detection is covered in tests/verification.test.ts
 */
import { describe, expect, test } from 'bun:test';

describe('TDD Enforcer Hook', () => {
  const HOOK_PATH = './tdd-enforcer.ts';

  // Helper to run the hook with given input
  async function runHook(input: object): Promise<{ decision: string; reason?: string }> {
    const inputJson = JSON.stringify(input);
    const proc = Bun.spawn(['bun', 'run', HOOK_PATH], {
      stdin: new Response(inputJson),
      stdout: 'pipe',
      stderr: 'pipe',
      cwd: import.meta.dir,
    });

    const output = await new Response(proc.stdout).text();
    await proc.exited;

    try {
      return JSON.parse(output.trim());
    } catch {
      return { decision: 'allow', reason: `Parse error: ${output}` };
    }
  }

  describe('input validation', () => {
    test('allows when tool is not Write/Edit/MultiEdit', async () => {
      const result = await runHook({
        hook_event_name: 'PreToolUse',
        session_id: 'test-session',
        tool_name: 'Read',
        tool_input: { file_path: '/src/user.ts' },
      });
      expect(result.decision).toBe('allow');
    });

    test('allows when no file_path provided', async () => {
      const result = await runHook({
        hook_event_name: 'PreToolUse',
        session_id: 'test-session',
        tool_name: 'Write',
        tool_input: {},
      });
      expect(result.decision).toBe('allow');
    });

    test('allows when invalid JSON input', async () => {
      const proc = Bun.spawn(['bun', 'run', HOOK_PATH], {
        stdin: new Response('not json'),
        stdout: 'pipe',
        stderr: 'pipe',
        cwd: import.meta.dir,
      });

      const output = await new Response(proc.stdout).text();
      await proc.exited;

      const result = JSON.parse(output.trim());
      expect(result.decision).toBe('allow');
    });
  });

  describe('file type detection', () => {
    test('allows non-source files (markdown)', async () => {
      const result = await runHook({
        hook_event_name: 'PreToolUse',
        session_id: 'test-session',
        tool_name: 'Write',
        tool_input: { file_path: '/docs/README.md' },
      });
      expect(result.decision).toBe('allow');
    });

    test('allows JSON config files', async () => {
      const result = await runHook({
        hook_event_name: 'PreToolUse',
        session_id: 'test-session',
        tool_name: 'Write',
        tool_input: { file_path: '/package.json' },
      });
      expect(result.decision).toBe('allow');
    });

    test('allows SQL files', async () => {
      const result = await runHook({
        hook_event_name: 'PreToolUse',
        session_id: 'test-session',
        tool_name: 'Write',
        tool_input: { file_path: '/migrations/001.sql' },
      });
      expect(result.decision).toBe('allow');
    });
  });

  describe('excluded paths', () => {
    const EXCLUDED_PATHS = [
      '/project/node_modules/lodash/index.ts',
      '/project/.git/hooks/pre-commit',
      '/project/dist/bundle.js',
      '/project/migrations/001.ts',
      '/project/__pycache__/module.py',
      '/project/.venv/lib/site.py',
      '/project/vendor/pkg/errors.go',
      '/project/target/debug/main.rs',
      '/project/scripts/deploy.ts',
    ];

    test.each(EXCLUDED_PATHS)('allows excluded path: %s', async (path) => {
      const result = await runHook({
        hook_event_name: 'PreToolUse',
        session_id: 'test-session',
        tool_name: 'Write',
        tool_input: { file_path: path },
      });
      expect(result.decision).toBe('allow');
    });
  });

  describe('excluded files', () => {
    const EXCLUDED_FILES = [
      '/app/__init__.py',
      '/tests/conftest.py',
      '/setup.py',
      '/cmd/main.go',
      '/src/mod.rs',
      '/src/lib.rs',
      '/types/global.d.ts',
      '/src/index.ts',
      '/components/index.tsx',
      '/src/vite.config.ts',
    ];

    test.each(EXCLUDED_FILES)('allows excluded file: %s', async (path) => {
      const result = await runHook({
        hook_event_name: 'PreToolUse',
        session_id: 'test-session',
        tool_name: 'Write',
        tool_input: { file_path: path },
      });
      expect(result.decision).toBe('allow');
    });
  });

  describe('test file detection', () => {
    const TEST_FILES = [
      '/src/user.test.ts',
      '/src/auth.spec.tsx',
      '/tests/test_user.py',
      '/pkg/handler_test.go',
      '/src/lib_test.rs',
      '/scripts/deploy.bats',
      '/src/__tests__/utils.test.ts',
    ];

    test.each(TEST_FILES)('allows test file: %s', async (path) => {
      const result = await runHook({
        hook_event_name: 'PreToolUse',
        session_id: 'test-session',
        tool_name: 'Write',
        tool_input: { file_path: path },
      });
      expect(result.decision).toBe('allow');
    });
  });

  describe('block behavior', () => {
    // Note: These tests verify blocking for files that don't have corresponding tests.
    // In a real codebase, the test file would exist. Here we use temp paths that won't exist.

    test('blocks TypeScript source without test', async () => {
      const result = await runHook({
        hook_event_name: 'PreToolUse',
        session_id: 'test-session',
        tool_name: 'Write',
        tool_input: { file_path: '/tmp/nonexistent/user.ts' },
      });
      expect(result.decision).toBe('block');
      expect(result.reason).toContain('TDD VIOLATION');
      expect(result.reason).toContain('TypeScript/JavaScript');
    });

    test('blocks Python source without test', async () => {
      const result = await runHook({
        hook_event_name: 'PreToolUse',
        session_id: 'test-session',
        tool_name: 'Write',
        tool_input: { file_path: '/tmp/nonexistent/user.py' },
      });
      expect(result.decision).toBe('block');
      expect(result.reason).toContain('TDD VIOLATION');
      expect(result.reason).toContain('Python');
    });

    test('blocks Go source without test', async () => {
      const result = await runHook({
        hook_event_name: 'PreToolUse',
        session_id: 'test-session',
        tool_name: 'Write',
        tool_input: { file_path: '/tmp/nonexistent/handler.go' },
      });
      expect(result.decision).toBe('block');
      expect(result.reason).toContain('TDD VIOLATION');
      expect(result.reason).toContain('Go');
    });

    test('block message includes expected test paths', async () => {
      const result = await runHook({
        hook_event_name: 'PreToolUse',
        session_id: 'test-session',
        tool_name: 'Write',
        tool_input: { file_path: '/tmp/nonexistent/feature.ts' },
      });
      expect(result.decision).toBe('block');
      expect(result.reason).toContain('feature.test.ts');
      expect(result.reason).toContain('Write the test FIRST');
    });
  });

  describe('tool name handling', () => {
    test('handles Write tool', async () => {
      const result = await runHook({
        hook_event_name: 'PreToolUse',
        session_id: 'test-session',
        tool_name: 'Write',
        tool_input: { file_path: '/tmp/nonexistent/user.ts' },
      });
      expect(result.decision).toBe('block');
    });

    test('handles Edit tool', async () => {
      const result = await runHook({
        hook_event_name: 'PreToolUse',
        session_id: 'test-session',
        tool_name: 'Edit',
        tool_input: { file_path: '/tmp/nonexistent/user.ts' },
      });
      expect(result.decision).toBe('block');
    });

    test('handles MultiEdit tool', async () => {
      const result = await runHook({
        hook_event_name: 'PreToolUse',
        session_id: 'test-session',
        tool_name: 'MultiEdit',
        tool_input: { file_path: '/tmp/nonexistent/user.ts' },
      });
      expect(result.decision).toBe('block');
    });
  });
});
