/**
 * Integration Tests
 *
 * Validates the quality system's remaining components.
 */

import { describe, expect, it } from 'vitest'
import { FORBIDDEN_PACKAGES, getNpmVersion, isForbidden, STACK } from '../src/stack'

describe('Quality System Integration', () => {
  describe('stack SSOT', () => {
    it('has npm versions', () => {
      expect(Object.keys(STACK.npm).length).toBeGreaterThan(10)
    })

    it('getNpmVersion returns correct version', () => {
      expect(getNpmVersion('effect')).toBe(STACK.npm.effect)
    })

    it('has forbidden packages', () => {
      expect(FORBIDDEN_PACKAGES.length).toBeGreaterThan(0)
    })

    it('isForbidden detects known forbidden package', () => {
      const result = isForbidden('lodash')
      expect(result).toBeTruthy()
    })

    it('isForbidden returns undefined for allowed package', () => {
      expect(isForbidden('effect')).toBeUndefined()
    })
  })
})
