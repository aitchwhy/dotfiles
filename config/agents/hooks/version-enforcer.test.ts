/**
 * Tests for version-enforcer.ts hook
 *
 * Red phase: Define expected behavior before implementation
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

describe('VersionEnforcer Hook', () => {
  let tempDir: string;

  beforeEach(() => {
    tempDir = mkdtempSync(join(tmpdir(), 'version-enforcer-test-'));
  });

  afterEach(() => {
    rmSync(tempDir, { recursive: true, force: true });
  });

  describe('compareVersions', () => {
    // We'll test via the hook behavior since compareVersions is internal

    test('detects outdated zod version', async () => {
      // Create package.json with old zod
      const pkgJson = {
        name: 'test-project',
        dependencies: {
          zod: '^3.24.0', // Below minimum 4.0.0
        },
      };
      writeFileSync(join(tempDir, 'package.json'), JSON.stringify(pkgJson));

      const result = await runHook(tempDir);
      expect(result.continue).toBe(true);
      expect(result.additionalContext).toContain('zod');
      expect(result.additionalContext).toContain('3.24.0');
    });

    test('passes when all versions meet minimum', async () => {
      const pkgJson = {
        name: 'test-project',
        dependencies: {
          zod: '^4.1.13',
          typescript: '^5.9.3',
        },
        devDependencies: {
          '@biomejs/biome': '^2.3.8',
        },
      };
      writeFileSync(join(tempDir, 'package.json'), JSON.stringify(pkgJson));

      const result = await runHook(tempDir);
      expect(result.continue).toBe(true);
      expect(result.additionalContext).toBeUndefined();
    });

    test('handles missing package.json gracefully', async () => {
      // No package.json in tempDir
      const result = await runHook(tempDir);
      expect(result.continue).toBe(true);
      expect(result.additionalContext).toBeUndefined();
    });

    test('only runs on SessionStart events', async () => {
      const pkgJson = {
        name: 'test-project',
        dependencies: { zod: '^3.0.0' }, // Outdated
      };
      writeFileSync(join(tempDir, 'package.json'), JSON.stringify(pkgJson));

      // Simulate PostToolUse event (should be ignored)
      const result = await runHook(tempDir, 'PostToolUse');
      expect(result.continue).toBe(true);
      expect(result.additionalContext).toBeUndefined();
    });

    test('handles multiple outdated dependencies', async () => {
      const pkgJson = {
        name: 'test-project',
        dependencies: {
          zod: '^3.24.0',
          react: '^18.0.0',
          hono: '^3.0.0',
        },
      };
      writeFileSync(join(tempDir, 'package.json'), JSON.stringify(pkgJson));

      const result = await runHook(tempDir);
      expect(result.continue).toBe(true);
      expect(result.additionalContext).toContain('zod');
      expect(result.additionalContext).toContain('react');
      expect(result.additionalContext).toContain('hono');
    });
  });
});

/**
 * Helper to run the hook with simulated input
 */
async function runHook(
  cwd: string,
  eventName = 'SessionStart'
): Promise<{ continue: boolean; additionalContext?: string }> {
  const hookPath = join(import.meta.dir, 'version-enforcer.ts');

  const input = JSON.stringify({
    hook_event_name: eventName,
    session_id: 'test-session',
    cwd,
  });

  const proc = Bun.spawn(['bun', 'run', hookPath], {
    stdin: new Blob([input]),
    stdout: 'pipe',
    stderr: 'pipe',
  });

  const output = await new Response(proc.stdout).text();
  await proc.exited;

  try {
    return JSON.parse(output.trim());
  } catch {
    return { continue: true };
  }
}
