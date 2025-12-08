/**
 * ClaudeAgent Schema
 *
 * Defines specialized agents for Claude Code (test-writer, debugger, etc.).
 * Agents have their own model preferences and tool restrictions.
 */
import { z } from 'zod'
import { ToolPermission } from './skill'

/**
 * Agent name - kebab-case
 */
export const AgentName = z
  .string()
  .regex(/^[a-z][a-z0-9-]*$/, 'Must be kebab-case')
  .brand('AgentName')

export type AgentName = z.infer<typeof AgentName>

/**
 * Claude model identifier
 */
export const ClaudeModel = z.enum(['opus', 'sonnet', 'haiku']).default('sonnet')

export type ClaudeModel = z.infer<typeof ClaudeModel>

/**
 * Agent principle
 */
export const AgentPrinciple = z.object({
  title: z.string(),
  description: z.string(),
})

export type AgentPrinciple = z.infer<typeof AgentPrinciple>

/**
 * Example interaction
 */
export const ExampleInteraction = z.object({
  input: z.string(),
  output: z.string(),
})

export type ExampleInteraction = z.infer<typeof ExampleInteraction>

/**
 * ClaudeAgent - defines a specialized agent
 */
export const ClaudeAgent = z.object({
  // Frontmatter
  name: AgentName,
  description: z.string().min(20).max(200).describe('Description of agent purpose'),
  tools: z.array(ToolPermission).min(1).describe('Tools this agent can use'),
  model: ClaudeModel.describe('Preferred Claude model'),

  // System prompt content
  systemPrompt: z.string().min(50).describe('Core system prompt defining agent behavior'),
  principles: z.array(AgentPrinciple).optional().describe('Guiding principles for the agent'),
  exampleInteractions: z.array(ExampleInteraction).optional(),
})

export type ClaudeAgent = z.infer<typeof ClaudeAgent>

/**
 * Collection of all agents
 */
export const AgentCollection = z.record(AgentName, ClaudeAgent)

export type AgentCollection = z.infer<typeof AgentCollection>
