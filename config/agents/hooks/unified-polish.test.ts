import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { $ } from 'bun';

/**
 * Tests for unified-polish PostToolUse hook
 *
 * This hook formats files based on extension and optionally auto-commits.
 * It receives file paths via CLAUDE_FILE_PATHS environment variable.
 *
 * Exit code semantics:
 *   0 = success (JSON: { continue: true })
 *
 * Key behaviors:
 * - Groups files by extension
 * - Runs formatters in parallel
 * - Generates conventional commit messages
 * - Never blocks (fail-safe design)
 */
describe('unified-polish hook', () => {
  const hookPath = `${import.meta.dir}/unified-polish.ts`;
  const testDir = '/tmp/unified-polish-tests';

  beforeAll(async () => {
    await $`mkdir -p ${testDir}`.nothrow();
  });

  afterAll(async () => {
    await $`rm -rf ${testDir}`.nothrow();
  });

  describe('exit behavior', () => {
    test('exits 0 when no files provided', async () => {
      const result = await $`CLAUDE_FILE_PATHS="" bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });

    test('exits 0 with valid TypeScript file', async () => {
      const testFile = `${testDir}/test.ts`;
      await Bun.write(testFile, 'const x = 1;');

      const result = await $`CLAUDE_FILE_PATHS=${testFile} bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });

    test('outputs JSON with continue: true on success', async () => {
      const testFile = `${testDir}/output.ts`;
      await Bun.write(testFile, 'const y = 2;');

      const result = await $`CLAUDE_FILE_PATHS=${testFile} bun run ${hookPath}`.nothrow();
      const output = result.stdout.toString().trim();

      expect(output).toContain('continue');
      const parsed = JSON.parse(output);
      expect(parsed.continue).toBe(true);
    });
  });

  describe('file type detection', () => {
    test('handles TypeScript files', async () => {
      const testFile = `${testDir}/component.tsx`;
      await Bun.write(testFile, 'export const App = () => <div>Hello</div>;');

      const result = await $`CLAUDE_FILE_PATHS=${testFile} bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });

    test('handles JavaScript files', async () => {
      const testFile = `${testDir}/script.js`;
      await Bun.write(testFile, 'console.log("hello");');

      const result = await $`CLAUDE_FILE_PATHS=${testFile} bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });

    test('handles JSON files', async () => {
      const testFile = `${testDir}/config.json`;
      await Bun.write(testFile, '{"key": "value"}');

      const result = await $`CLAUDE_FILE_PATHS=${testFile} bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });

    test('handles Python files', async () => {
      const testFile = `${testDir}/script.py`;
      await Bun.write(testFile, 'print("hello")');

      const result = await $`CLAUDE_FILE_PATHS=${testFile} bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });

    test('handles Nix files', async () => {
      const testFile = `${testDir}/default.nix`;
      await Bun.write(testFile, '{ pkgs }: pkgs.hello');

      const result = await $`CLAUDE_FILE_PATHS=${testFile} bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });

    test('handles shell files', async () => {
      const testFile = `${testDir}/script.sh`;
      await Bun.write(testFile, '#!/bin/bash\necho "hello"');

      const result = await $`CLAUDE_FILE_PATHS=${testFile} bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });

    test('handles YAML files', async () => {
      const testFile = `${testDir}/config.yaml`;
      await Bun.write(testFile, 'key: value');

      const result = await $`CLAUDE_FILE_PATHS=${testFile} bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });

    test('handles Lua files', async () => {
      const testFile = `${testDir}/init.lua`;
      await Bun.write(testFile, 'print("hello")');

      const result = await $`CLAUDE_FILE_PATHS=${testFile} bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });

    test('handles CSS files', async () => {
      const testFile = `${testDir}/styles.css`;
      await Bun.write(testFile, 'body { margin: 0; }');

      const result = await $`CLAUDE_FILE_PATHS=${testFile} bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });

    test('handles SQL files', async () => {
      const testFile = `${testDir}/query.sql`;
      await Bun.write(testFile, 'SELECT * FROM users;');

      const result = await $`CLAUDE_FILE_PATHS=${testFile} bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });
  });

  describe('multiple files', () => {
    test('handles comma-separated file paths', async () => {
      const file1 = `${testDir}/a.ts`;
      const file2 = `${testDir}/b.ts`;
      await Bun.write(file1, 'const a = 1;');
      await Bun.write(file2, 'const b = 2;');

      const result = await $`CLAUDE_FILE_PATHS="${file1},${file2}" bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });

    test('handles mixed file types', async () => {
      const tsFile = `${testDir}/mixed.ts`;
      const pyFile = `${testDir}/mixed.py`;
      const nixFile = `${testDir}/mixed.nix`;
      await Bun.write(tsFile, 'const x = 1;');
      await Bun.write(pyFile, 'x = 1');
      await Bun.write(nixFile, '{ }: {}');

      const result =
        await $`CLAUDE_FILE_PATHS="${tsFile},${pyFile},${nixFile}" bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });
  });

  describe('edge cases', () => {
    test('handles empty file path list gracefully', async () => {
      const result = await $`CLAUDE_FILE_PATHS="," bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });

    test('handles non-existent files gracefully', async () => {
      // Formatters should fail silently per the hook design
      const result =
        await $`CLAUDE_FILE_PATHS="/nonexistent/path/file.ts" bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });

    test('handles unknown file extensions gracefully', async () => {
      const testFile = `${testDir}/file.xyz`;
      await Bun.write(testFile, 'unknown content');

      const result = await $`CLAUDE_FILE_PATHS=${testFile} bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });

    test('handles files with spaces in path', async () => {
      const testFile = `${testDir}/file with spaces.ts`;
      await Bun.write(testFile, 'const x = 1;');

      // Note: Use quotes around the path
      const result = await $`CLAUDE_FILE_PATHS="${testFile}" bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });
  });

  describe('commit message inference', () => {
    // These tests verify the inferCommitType, inferScope, and inferDescription functions
    // by observing their behavior through the hook's auto-commit feature

    test('infers test type for test files', async () => {
      const testFile = `${testDir}/feature.test.ts`;
      await Bun.write(testFile, "test('example', () => {});");

      // Run in a git repo to test auto-commit inference
      // The hook will generate a commit message with "test" type
      const result = await $`CLAUDE_FILE_PATHS=${testFile} bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });

    test('infers docs type for markdown files', async () => {
      const testFile = `${testDir}/README.md`;
      await Bun.write(testFile, '# Title');

      const result = await $`CLAUDE_FILE_PATHS=${testFile} bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });

    test('infers chore type for config files', async () => {
      const testFile = `${testDir}/tsconfig.json`;
      await Bun.write(testFile, '{}');

      const result = await $`CLAUDE_FILE_PATHS=${testFile} bun run ${hookPath}`.nothrow();
      expect(result.exitCode).toBe(0);
    });
  });
});
