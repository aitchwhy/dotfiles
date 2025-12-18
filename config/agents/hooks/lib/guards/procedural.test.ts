/**
 * Procedural Guards Tests
 *
 * Tests for file/command validation guards.
 */
import { describe, expect, test } from 'bun:test';
import {
  checkBashSafety,
  checkConventionalCommit,
  checkForbiddenFiles,
  checkDevOpsCommands,
  checkStackCompliance,
} from './procedural';

describe('Guard 1: Bash Safety', () => {
  test('blocks dangerous rm -rf /', () => {
    const result = checkBashSafety('rm -rf /');
    expect(result.ok).toBe(false);
  });

  test('allows safe commands', () => {
    const result = checkBashSafety('ls -la');
    expect(result.ok).toBe(true);
  });
});

describe('Guard 2: Conventional Commits', () => {
  test('accepts valid commit message', () => {
    const result = checkConventionalCommit('git commit -m "feat(auth): add login"');
    expect(result.ok).toBe(true);
  });

  test('rejects invalid commit message', () => {
    const result = checkConventionalCommit('git commit -m "Fixed stuff"');
    expect(result.ok).toBe(false);
  });
});

describe('Guard 3: Forbidden Files', () => {
  test('blocks bun.lock', () => {
    const result = checkForbiddenFiles('bun.lock');
    expect(result.ok).toBe(false);
  });

  test('blocks process-compose.yaml', () => {
    const result = checkForbiddenFiles('process-compose.yaml');
    expect(result.ok).toBe(false);
  });

  test('allows docker-compose.yml', () => {
    const result = checkForbiddenFiles('docker-compose.yml');
    expect(result.ok).toBe(true);
  });

  test('allows Dockerfile', () => {
    const result = checkForbiddenFiles('Dockerfile');
    expect(result.ok).toBe(true);
  });

  test('allows pnpm-lock.yaml', () => {
    const result = checkForbiddenFiles('pnpm-lock.yaml');
    expect(result.ok).toBe(true);
  });

  test('blocks package-lock.json', () => {
    const result = checkForbiddenFiles('package-lock.json');
    expect(result.ok).toBe(false);
  });

  test('blocks yarn.lock', () => {
    const result = checkForbiddenFiles('yarn.lock');
    expect(result.ok).toBe(false);
  });
});

describe('Guards 9-10: DevOps Commands', () => {
  test('allows docker compose up', () => {
    const result = checkDevOpsCommands('docker compose up');
    expect(result.ok).toBe(true);
  });

  test('allows docker build', () => {
    const result = checkDevOpsCommands('docker build .');
    expect(result.ok).toBe(true);
  });

  test('blocks process-compose up', () => {
    const result = checkDevOpsCommands('process-compose up');
    expect(result.ok).toBe(false);
  });

  test('blocks bun run', () => {
    const result = checkDevOpsCommands('bun run dev');
    expect(result.ok).toBe(false);
  });

  test('blocks bun test', () => {
    const result = checkDevOpsCommands('bun test');
    expect(result.ok).toBe(false);
  });
});

describe('Guard 31: Stack Compliance', () => {
  test('blocks bun dependency', () => {
    const packageJson = JSON.stringify({
      dependencies: { bun: '1.0.0' },
    });
    const result = checkStackCompliance(packageJson, 'package.json');
    expect(result.ok).toBe(false);
  });

  test('blocks @types/bun', () => {
    const packageJson = JSON.stringify({
      devDependencies: { '@types/bun': '1.0.0' },
    });
    const result = checkStackCompliance(packageJson, 'package.json');
    expect(result.ok).toBe(false);
  });

  test('allows valid dependencies', () => {
    const packageJson = JSON.stringify({
      dependencies: { effect: '3.0.0' },
    });
    const result = checkStackCompliance(packageJson, 'package.json');
    expect(result.ok).toBe(true);
  });
});
