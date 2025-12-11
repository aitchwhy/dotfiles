/**
 * Factory Smoke Test
 *
 * End-to-end test that validates signet init produces working projects.
 * Uses real file system operations (no mocks per hexagonal architecture).
 *
 * @packageDocumentation
 */

import { afterEach, beforeEach, describe, expect, test } from 'bun:test';
import { existsSync, mkdirSync, rmSync } from 'node:fs';
import { join } from 'node:path';

const TEMP_BASE = '/tmp/signet-factory-test';
const PROJECT_NAME = 'smoke-test-lib';

/**
 * Helper to run shell commands using Bun's native shell
 */
async function run(
  args: string[],
  cwd: string = TEMP_BASE,
): Promise<{ exitCode: number; stdout: string; stderr: string }> {
  const proc = Bun.spawn(args, {
    cwd,
    stdout: 'pipe',
    stderr: 'pipe',
    env: { ...process.env, PATH: process.env.PATH },
  });

  const stdout = await new Response(proc.stdout).text();
  const stderr = await new Response(proc.stderr).text();
  const exitCode = await proc.exited;

  return { exitCode, stdout, stderr };
}

/**
 * Ensure temp directory exists
 */
function ensureTempDir(): void {
  if (!existsSync(TEMP_BASE)) {
    mkdirSync(TEMP_BASE, { recursive: true });
  }
}

/**
 * Clean temp directory
 */
function cleanTempDir(): void {
  if (existsSync(TEMP_BASE)) {
    rmSync(TEMP_BASE, { recursive: true });
  }
}

describe('Factory Smoke Test', () => {
  const projectPath = join(TEMP_BASE, PROJECT_NAME);
  const signetPath = join(import.meta.dir, '../../src/cli.ts');

  beforeEach(() => {
    cleanTempDir();
    ensureTempDir();
  });

  afterEach(() => {
    cleanTempDir();
  });

  test('signet init library creates valid project structure', async () => {
    // Run signet init (use the local signet, not installed)
    const initResult = await run(['bun', 'run', signetPath, 'init', 'library', PROJECT_NAME]);

    expect(initResult.exitCode).toBe(0);

    // Verify essential files exist
    const essentialFiles = [
      'package.json',
      'tsconfig.json',
      'biome.json',
      'flake.nix',
      '.gitignore',
      '.envrc',
      'src/index.ts',
      'src/lib/result.ts',
    ];

    for (const file of essentialFiles) {
      const filePath = join(projectPath, file);
      expect(existsSync(filePath)).toBe(true);
    }
  });

  test('generated project installs dependencies', async () => {
    await run(['bun', 'run', signetPath, 'init', 'library', PROJECT_NAME]);

    // Run bun install
    const installResult = await run(['bun', 'install'], projectPath);
    expect(installResult.exitCode).toBe(0);

    // Verify node_modules created
    expect(existsSync(join(projectPath, 'node_modules'))).toBe(true);
  });

  test('generated project passes typecheck', async () => {
    await run(['bun', 'run', signetPath, 'init', 'library', PROJECT_NAME]);
    await run(['bun', 'install'], projectPath);

    // Run typecheck
    const typecheckResult = await run(['bun', 'run', 'typecheck'], projectPath);
    expect(typecheckResult.exitCode).toBe(0);
  });

  test('generated package.json has valid structure', async () => {
    await run(['bun', 'run', signetPath, 'init', 'library', PROJECT_NAME]);

    const pkgJson = await Bun.file(join(projectPath, 'package.json')).json();

    expect(pkgJson.name).toBe(PROJECT_NAME);
    expect(pkgJson.type).toBe('module');
    expect(pkgJson.scripts.typecheck).toBeDefined();
    expect(pkgJson.devDependencies.typescript).toBeDefined();
    expect(pkgJson.devDependencies['@biomejs/biome']).toBeDefined();
  });

  test('generated flake.nix is valid Nix syntax', async () => {
    await run(['bun', 'run', signetPath, 'init', 'library', PROJECT_NAME]);

    // Validate Nix syntax using nix-instantiate --parse
    const nixCheckResult = await run(
      ['nix-instantiate', '--parse', 'flake.nix'],
      projectPath,
    );
    expect(nixCheckResult.exitCode).toBe(0);
  });
});

describe('Factory: Project Types', () => {
  const projectTypes = ['library', 'api', 'ui', 'monorepo', 'infra'] as const;
  const signetPath = join(import.meta.dir, '../../src/cli.ts');

  beforeEach(() => {
    cleanTempDir();
    ensureTempDir();
  });

  afterEach(() => {
    cleanTempDir();
  });

  for (const projectType of projectTypes) {
    test(`signet init ${projectType} creates project with package.json`, async () => {
      const projectName = `smoke-${projectType}`;
      const result = await run(['bun', 'run', signetPath, 'init', projectType, projectName]);

      expect(result.exitCode).toBe(0);

      const projectPath = join(TEMP_BASE, projectName);
      expect(existsSync(join(projectPath, 'package.json'))).toBe(true);
    });
  }
});
