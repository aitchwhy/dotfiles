/**
 * Schema validation tests
 *
 * Validates that the Effect schemas correctly parse version strings
 * and reject invalid inputs.
 */

import { Either, Schema } from 'effect'
import { describe, expect, it } from 'vitest'
import { InfraVersionsSchema, RuntimeVersionsSchema, StackDefinitionSchema } from './schema'
import { STACK } from './versions'

describe('Stack Schema', () => {
  it('STACK satisfies StackDefinitionSchema', () => {
    const result = Schema.decodeUnknownEither(StackDefinitionSchema)(STACK)
    expect(Either.isRight(result)).toBe(true)
  })

  it('RuntimeVersionsSchema validates valid versions', () => {
    const valid = {
      pnpm: '9.15.4',
      node: '25.2.1',
      uv: '0.5.1',
      volta: '2.0.1',
    }
    const result = Schema.decodeUnknownEither(RuntimeVersionsSchema)(valid)
    expect(Either.isRight(result)).toBe(true)
  })

  it('RuntimeVersionsSchema rejects invalid semver', () => {
    const invalid = {
      pnpm: 'not-a-version',
      node: '25.2.1',
      uv: '0.5.1',
      volta: '2.0.1',
    }
    const result = Schema.decodeUnknownEither(RuntimeVersionsSchema)(invalid)
    expect(Either.isLeft(result)).toBe(true)
  })

  it('InfraVersionsSchema validates valid versions', () => {
    const valid = {
      pulumi: '3.210.0',
      'pulumi-aws': '7.14.0',
      'pulumi-awsx': '3.1.0',
      'docker-compose': '2.32.0',
      tailscale: '1.78.0',
    }
    const result = Schema.decodeUnknownEither(InfraVersionsSchema)(valid)
    expect(Either.isRight(result)).toBe(true)
  })
})
