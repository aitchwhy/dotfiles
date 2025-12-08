/**
 * Tests for semantic-commit-sentinel.ts hook
 *
 * Red phase: Define expected behavior before implementation
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { mkdtempSync, writeFileSync, rmSync, mkdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { execSync } from 'node:child_process';

describe('SemanticCommitSentinel Hook', () => {
  let tempDir: string;

  beforeEach(() => {
    tempDir = mkdtempSync(join(tmpdir(), 'commit-sentinel-test-'));
    // Initialize git repo
    execSync('git init', { cwd: tempDir, stdio: 'pipe' });
    execSync('git config user.email "test@test.com"', { cwd: tempDir, stdio: 'pipe' });
    execSync('git config user.name "Test"', { cwd: tempDir, stdio: 'pipe' });
  });

  afterEach(() => {
    rmSync(tempDir, { recursive: true, force: true });
  });

  describe('semantic clustering', () => {
    test('proposes commit when there are uncommitted changes', async () => {
      // Create a file and stage it
      writeFileSync(join(tempDir, 'index.ts'), 'export const foo = 1;');
      execSync('git add .', { cwd: tempDir, stdio: 'pipe' });

      const result = await runHook(tempDir);
      expect(result.continue).toBe(true);
      // Should propose a commit
      expect(result.additionalContext).toContain('Proposed commit');
    });

    test('returns nothing when working directory is clean', async () => {
      // Create and commit a file (use --no-verify to skip commit hooks)
      writeFileSync(join(tempDir, 'index.ts'), 'export const foo = 1;');
      execSync('git add .', { cwd: tempDir, stdio: 'pipe' });
      execSync('git commit --no-verify -m "chore: initial commit"', { cwd: tempDir, stdio: 'pipe' });

      const result = await runHook(tempDir);
      expect(result.continue).toBe(true);
      expect(result.additionalContext).toBeUndefined();
    });

    test('groups files in same directory as related', async () => {
      // Create multiple files in same directory
      mkdirSync(join(tempDir, 'src'));
      writeFileSync(join(tempDir, 'src/user.ts'), 'export class User {}');
      writeFileSync(join(tempDir, 'src/user.test.ts'), 'test("user", () => {});');
      execSync('git add .', { cwd: tempDir, stdio: 'pipe' });

      const result = await runHook(tempDir);
      expect(result.continue).toBe(true);
      expect(result.additionalContext).toContain('Proposed commit');
      // Should be a single semantic cluster
      expect(result.additionalContext).not.toContain('Multiple clusters');
    });

    test('infers feat type for new source files', async () => {
      writeFileSync(join(tempDir, 'feature.ts'), 'export const feature = {};');
      execSync('git add .', { cwd: tempDir, stdio: 'pipe' });

      const result = await runHook(tempDir);
      expect(result.continue).toBe(true);
      expect(result.additionalContext).toContain('feat');
    });

    test('infers test type for test files only', async () => {
      writeFileSync(join(tempDir, 'foo.test.ts'), 'test("foo", () => {});');
      execSync('git add .', { cwd: tempDir, stdio: 'pipe' });

      const result = await runHook(tempDir);
      expect(result.continue).toBe(true);
      expect(result.additionalContext).toContain('test');
    });

    test('only runs on Stop events', async () => {
      writeFileSync(join(tempDir, 'index.ts'), 'export const foo = 1;');
      execSync('git add .', { cwd: tempDir, stdio: 'pipe' });

      // Simulate SessionStart event (should be ignored)
      const result = await runHook(tempDir, 'SessionStart');
      expect(result.continue).toBe(true);
      expect(result.additionalContext).toBeUndefined();
    });
  });
});

/**
 * Helper to run the hook with simulated input
 */
async function runHook(
  cwd: string,
  eventName = 'Stop'
): Promise<{ continue: boolean; additionalContext?: string }> {
  const hookPath = join(import.meta.dir, 'semantic-commit-sentinel.ts');

  const input = JSON.stringify({
    hook_event_name: eventName,
    session_id: 'test-session',
    cwd,
  });

  const proc = Bun.spawn(['bun', 'run', hookPath], {
    stdin: new Blob([input]),
    stdout: 'pipe',
    stderr: 'pipe',
    cwd,
  });

  const output = await new Response(proc.stdout).text();
  await proc.exited;

  try {
    return JSON.parse(output.trim());
  } catch {
    return { continue: true };
  }
}
