/**
 * Stack versions tests
 *
 * Validates that the STACK object is well-formed
 * and helper functions work correctly.
 */
import { describe, expect, it } from 'vitest'
import { Either } from 'effect'
import {
  getDrift,
  getNpmVersion,
  getNpmVersions,
  isVersionMatch,
  STACK,
  validateStack,
} from './versions'

describe('Stack Versions', () => {
  it('STACK has required sections', () => {
    expect(STACK.meta).toBeDefined()
    expect(STACK.runtime).toBeDefined()
    expect(STACK.frontend).toBeDefined()
    expect(STACK.backend).toBeDefined()
    expect(STACK.infra).toBeDefined()
    expect(STACK.testing).toBeDefined()
    expect(STACK.npm).toBeDefined()
  })

  it('validateStack returns Right for valid STACK', () => {
    const result = validateStack()
    expect(Either.isRight(result)).toBe(true)
  })

  it('getNpmVersion returns correct version', () => {
    expect(getNpmVersion('typescript')).toBe(STACK.npm.typescript)
    expect(getNpmVersion('effect')).toBe(STACK.npm.effect)
  })

  it('getNpmVersions returns all npm versions', () => {
    const versions = getNpmVersions()
    expect(versions['typescript']).toBe(STACK.npm.typescript)
    expect(Object.keys(versions).length).toBeGreaterThan(0)
  })

  it('isVersionMatch returns true for matching versions', () => {
    expect(isVersionMatch('typescript', STACK.npm.typescript)).toBe(true)
  })

  it('isVersionMatch returns false for mismatched versions', () => {
    expect(isVersionMatch('typescript', '0.0.0')).toBe(false)
  })

  it('isVersionMatch returns true for unknown packages', () => {
    expect(isVersionMatch('unknown-package', '1.0.0')).toBe(true)
  })

  it('getDrift returns empty array for matching deps', () => {
    const drift = getDrift({ typescript: STACK.npm.typescript })
    expect(drift).toEqual([])
  })

  it('getDrift returns drift for mismatched deps', () => {
    const drift = getDrift({ typescript: '0.0.0' })
    expect(drift).toHaveLength(1)
    expect(drift[0]?.pkg).toBe('typescript')
    expect(drift[0]?.expected).toBe(STACK.npm.typescript)
    expect(drift[0]?.actual).toBe('0.0.0')
  })

  it('runtime has pnpm instead of bun', () => {
    expect(STACK.runtime.pnpm).toBeDefined()
    expect((STACK.runtime as Record<string, unknown>)['bun']).toBeUndefined()
  })

  it('infra has docker-compose instead of process-compose', () => {
    expect(STACK.infra['docker-compose']).toBeDefined()
    expect((STACK.infra as Record<string, unknown>)['process-compose']).toBeUndefined()
  })
})
