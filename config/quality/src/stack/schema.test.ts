/**
 * Schema validation tests
 *
 * Validates that the Zod schemas correctly parse version strings
 * and reject invalid inputs.
 */
import { describe, expect, test } from 'bun:test';
import {
  runtimeVersionsSchema,
  infraVersionsSchema,
  npmVersionsSchema,
  stackDefinitionSchema,
} from './schema';
import { STACK } from './versions';

describe('Stack Schema', () => {
  test('STACK satisfies stackDefinitionSchema', () => {
    const result = stackDefinitionSchema.safeParse(STACK);
    expect(result.success).toBe(true);
  });

  test('runtimeVersionsSchema validates valid versions', () => {
    const valid = {
      pnpm: '9.15.4',
      node: '25.2.1',
      uv: '0.5.1',
      volta: '2.0.1',
    };
    const result = runtimeVersionsSchema.safeParse(valid);
    expect(result.success).toBe(true);
  });

  test('runtimeVersionsSchema rejects invalid semver', () => {
    const invalid = {
      pnpm: 'not-a-version',
      node: '25.2.1',
      uv: '0.5.1',
      volta: '2.0.1',
    };
    const result = runtimeVersionsSchema.safeParse(invalid);
    expect(result.success).toBe(false);
  });

  test('infraVersionsSchema validates valid versions', () => {
    const valid = {
      pulumi: '3.210.0',
      'pulumi-aws': '7.14.0',
      'pulumi-awsx': '3.1.0',
      'docker-compose': '2.32.0',
      tailscale: '1.78.0',
    };
    const result = infraVersionsSchema.safeParse(valid);
    expect(result.success).toBe(true);
  });
});
