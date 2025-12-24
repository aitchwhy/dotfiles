/**
 * Schema validation tests
 *
 * Validates that the Effect schemas correctly parse version strings
 * and reject invalid inputs.
 */
import { describe, expect, test } from 'bun:test';
import { Either, Schema } from 'effect';
import { InfraVersionsSchema, RuntimeVersionsSchema, StackDefinitionSchema } from './schema';
import { STACK } from './versions';

describe('Stack Schema', () => {
  test('STACK satisfies StackDefinitionSchema', () => {
    const result = Schema.decodeUnknownEither(StackDefinitionSchema)(STACK);
    expect(Either.isRight(result)).toBe(true);
  });

  test('RuntimeVersionsSchema validates valid versions', () => {
    const valid = {
      pnpm: '9.15.4',
      node: '25.2.1',
      uv: '0.5.1',
      volta: '2.0.1',
    };
    const result = Schema.decodeUnknownEither(RuntimeVersionsSchema)(valid);
    expect(Either.isRight(result)).toBe(true);
  });

  test('RuntimeVersionsSchema rejects invalid semver', () => {
    const invalid = {
      pnpm: 'not-a-version',
      node: '25.2.1',
      uv: '0.5.1',
      volta: '2.0.1',
    };
    const result = Schema.decodeUnknownEither(RuntimeVersionsSchema)(invalid);
    expect(Either.isLeft(result)).toBe(true);
  });

  test('InfraVersionsSchema validates valid versions', () => {
    const valid = {
      pulumi: '3.210.0',
      'pulumi-aws': '7.14.0',
      'pulumi-awsx': '3.1.0',
      'docker-compose': '2.32.0',
      tailscale: '1.78.0',
    };
    const result = Schema.decodeUnknownEither(InfraVersionsSchema)(valid);
    expect(Either.isRight(result)).toBe(true);
  });
});
