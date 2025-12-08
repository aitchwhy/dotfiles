/**
 * ClaudeCommand Schema Tests
 *
 * Tests for Claude Code slash command schema validation.
 */
import { describe, expect, test } from 'bun:test'

// These imports will fail until we implement the module (RED phase)
import {
  ClaudeCommand,
  type ClaudeCommand as ClaudeCommandType,
  CommandName,
  CommandStep,
} from '@/schema/command'

describe('ClaudeCommand Schema', () => {
  describe('CommandName', () => {
    test('accepts valid kebab-case names', () => {
      expect(CommandName.safeParse('commit').success).toBe(true)
      expect(CommandName.safeParse('validate').success).toBe(true)
      expect(CommandName.safeParse('nix-rebuild').success).toBe(true)
    })

    test('rejects invalid names', () => {
      expect(CommandName.safeParse('/commit').success).toBe(false) // leading slash
      expect(CommandName.safeParse('Commit').success).toBe(false) // PascalCase
      expect(CommandName.safeParse('validate_all').success).toBe(false) // snake_case
    })
  })

  describe('CommandStep', () => {
    test('parses minimal step', () => {
      const result = CommandStep.safeParse({
        title: 'Run tests',
      })
      expect(result.success).toBe(true)
      if (result.success) {
        expect(result.data.language).toBe('bash')
      }
    })

    test('parses step with command', () => {
      const result = CommandStep.safeParse({
        title: 'Run tests',
        description: 'Execute the test suite',
        command: 'bun test',
      })
      expect(result.success).toBe(true)
    })

    test('parses step with code block', () => {
      const result = CommandStep.safeParse({
        title: 'Example output',
        code: 'PASS: 42 tests',
        language: 'text',
      })
      expect(result.success).toBe(true)
    })
  })

  describe('ClaudeCommand', () => {
    const validCommand: ClaudeCommandType = {
      name: 'validate' as ClaudeCommandType['name'],
      description: 'Run full validation pipeline',
      allowedTools: ['Read', 'Bash'] as ClaudeCommandType['allowedTools'],
    }

    test('parses minimal valid command', () => {
      const result = ClaudeCommand.safeParse(validCommand)
      expect(result.success).toBe(true)
    })

    test('parses command with steps', () => {
      const result = ClaudeCommand.safeParse({
        ...validCommand,
        steps: [
          { title: 'Type check', command: 'tsc --noEmit' },
          { title: 'Lint', command: 'bunx biome check' },
          { title: 'Test', command: 'bun test' },
        ],
      })
      expect(result.success).toBe(true)
      if (result.success) {
        expect(result.data.steps).toHaveLength(3)
      }
    })

    test('parses command with rawContent', () => {
      const result = ClaudeCommand.safeParse({
        ...validCommand,
        rawContent: '## Notes\n\nAdditional command documentation',
      })
      expect(result.success).toBe(true)
    })

    test('rejects command with short description', () => {
      const result = ClaudeCommand.safeParse({
        ...validCommand,
        description: 'Short',
      })
      expect(result.success).toBe(false)
    })

    test('rejects command with empty allowedTools', () => {
      const result = ClaudeCommand.safeParse({
        ...validCommand,
        allowedTools: [],
      })
      expect(result.success).toBe(false)
    })
  })
})
