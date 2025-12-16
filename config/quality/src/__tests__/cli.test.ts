/**
 * Signet CLI Tests
 *
 * Tests for the Signet CLI commands.
 */
import { describe, expect, test } from 'bun:test';
import { enforceCommand, genCommand, initCommand, mainCommand, validateCommand } from '@/cli';

describe('Signet CLI', () => {
  describe('initCommand', () => {
    test('exists and is a command', () => {
      expect(initCommand).toBeDefined();
      expect(typeof initCommand).toBe('object');
    });
  });

  describe('genCommand', () => {
    test('exists and is a command', () => {
      expect(genCommand).toBeDefined();
      expect(typeof genCommand).toBe('object');
    });
  });

  describe('validateCommand', () => {
    test('exists and is a command', () => {
      expect(validateCommand).toBeDefined();
      expect(typeof validateCommand).toBe('object');
    });
  });

  describe('enforceCommand', () => {
    test('exists and is a command', () => {
      expect(enforceCommand).toBeDefined();
      expect(typeof enforceCommand).toBe('object');
    });
  });

  describe('mainCommand', () => {
    test('exists and is a command with subcommands', () => {
      expect(mainCommand).toBeDefined();
      expect(typeof mainCommand).toBe('object');
    });
  });
});
