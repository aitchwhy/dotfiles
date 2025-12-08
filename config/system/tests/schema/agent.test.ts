/**
 * ClaudeAgent Schema Tests
 *
 * Tests for Claude Code specialized agent schema validation.
 */
import { describe, expect, test } from 'bun:test'

// These imports will fail until we implement the module (RED phase)
import {
  AgentName,
  AgentPrinciple,
  ClaudeAgent,
  type ClaudeAgent as ClaudeAgentType,
  ClaudeModel,
  ExampleInteraction,
} from '@/schema/agent'

describe('ClaudeAgent Schema', () => {
  describe('AgentName', () => {
    test('accepts valid kebab-case names', () => {
      expect(AgentName.safeParse('test-writer').success).toBe(true)
      expect(AgentName.safeParse('debugger').success).toBe(true)
      expect(AgentName.safeParse('code-reviewer').success).toBe(true)
    })

    test('rejects invalid names', () => {
      expect(AgentName.safeParse('TestWriter').success).toBe(false)
      expect(AgentName.safeParse('test_writer').success).toBe(false)
    })
  })

  describe('ClaudeModel', () => {
    test('accepts valid model names', () => {
      expect(ClaudeModel.safeParse('opus').success).toBe(true)
      expect(ClaudeModel.safeParse('sonnet').success).toBe(true)
      expect(ClaudeModel.safeParse('haiku').success).toBe(true)
    })

    test('applies default of sonnet', () => {
      const result = ClaudeModel.safeParse(undefined)
      expect(result.success).toBe(true)
      if (result.success) {
        expect(result.data).toBe('sonnet')
      }
    })

    test('rejects invalid model names', () => {
      expect(ClaudeModel.safeParse('gpt-4').success).toBe(false)
      expect(ClaudeModel.safeParse('claude').success).toBe(false)
    })
  })

  describe('AgentPrinciple', () => {
    test('parses valid principle', () => {
      const result = AgentPrinciple.safeParse({
        title: 'Test First',
        description: 'Always write tests before implementation',
      })
      expect(result.success).toBe(true)
    })
  })

  describe('ExampleInteraction', () => {
    test('parses valid example', () => {
      const result = ExampleInteraction.safeParse({
        input: 'Write a test for the auth module',
        output:
          'I will create auth.test.ts with coverage for login, logout, and session management.',
      })
      expect(result.success).toBe(true)
    })
  })

  describe('ClaudeAgent', () => {
    const validAgent: ClaudeAgentType = {
      name: 'test-writer' as ClaudeAgentType['name'],
      description: 'Generates comprehensive test suites using TDD principles',
      tools: ['Read', 'Write', 'Bash'] as ClaudeAgentType['tools'],
      model: 'sonnet',
      systemPrompt: `You are a test writer agent. You specialize in writing comprehensive tests
following TDD principles: Red, Green, Refactor. You write tests before implementation.`,
    }

    test('parses minimal valid agent', () => {
      const result = ClaudeAgent.safeParse(validAgent)
      expect(result.success).toBe(true)
    })

    test('applies default model', () => {
      const agentWithoutModel = {
        ...validAgent,
        model: undefined,
      }
      const result = ClaudeAgent.safeParse(agentWithoutModel)
      expect(result.success).toBe(true)
      if (result.success) {
        expect(result.data.model).toBe('sonnet')
      }
    })

    test('parses agent with principles', () => {
      const result = ClaudeAgent.safeParse({
        ...validAgent,
        principles: [
          { title: 'Test First', description: 'Write tests before code' },
          { title: 'High Coverage', description: 'Aim for comprehensive coverage' },
        ],
      })
      expect(result.success).toBe(true)
      if (result.success) {
        expect(result.data.principles).toHaveLength(2)
      }
    })

    test('parses agent with example interactions', () => {
      const result = ClaudeAgent.safeParse({
        ...validAgent,
        exampleInteractions: [
          {
            input: 'Test the auth module',
            output: 'Creating auth.test.ts with login/logout tests',
          },
        ],
      })
      expect(result.success).toBe(true)
    })

    test('rejects agent with short description', () => {
      const result = ClaudeAgent.safeParse({
        ...validAgent,
        description: 'Too short',
      })
      expect(result.success).toBe(false)
    })

    test('rejects agent with short systemPrompt', () => {
      const result = ClaudeAgent.safeParse({
        ...validAgent,
        systemPrompt: 'Too short',
      })
      expect(result.success).toBe(false)
    })

    test('rejects agent with empty tools', () => {
      const result = ClaudeAgent.safeParse({
        ...validAgent,
        tools: [],
      })
      expect(result.success).toBe(false)
    })
  })
})
