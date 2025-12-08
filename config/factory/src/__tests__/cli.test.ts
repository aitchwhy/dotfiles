/**
 * FCS CLI Tests
 *
 * Tests for the Factory CLI commands.
 */
import { describe, expect, test } from 'bun:test'
import { initCommand, genCommand, validateCommand, enforceCommand, mainCommand } from '@/cli'

describe('FCS CLI', () => {
  describe('initCommand', () => {
    test('exists and is a command', () => {
      expect(initCommand).toBeDefined()
      expect(typeof initCommand).toBe('object')
    })
  })

  describe('genCommand', () => {
    test('exists and is a command', () => {
      expect(genCommand).toBeDefined()
      expect(typeof genCommand).toBe('object')
    })
  })

  describe('validateCommand', () => {
    test('exists and is a command', () => {
      expect(validateCommand).toBeDefined()
      expect(typeof validateCommand).toBe('object')
    })
  })

  describe('enforceCommand', () => {
    test('exists and is a command', () => {
      expect(enforceCommand).toBeDefined()
      expect(typeof enforceCommand).toBe('object')
    })
  })

  describe('mainCommand', () => {
    test('exists and is a command with subcommands', () => {
      expect(mainCommand).toBeDefined()
      expect(typeof mainCommand).toBe('object')
    })
  })
})
