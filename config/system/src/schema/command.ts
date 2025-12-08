/**
 * ClaudeCommand Schema
 *
 * Defines slash commands for Claude Code (e.g., /tdd, /validate).
 * Commands are single-file markdown with YAML frontmatter.
 */
import { z } from 'zod'
import { ToolPermission } from './skill'

/**
 * Command name - kebab-case without leading slash
 */
export const CommandName = z
  .string()
  .regex(/^[a-z][a-z0-9-]*$/, 'Must be kebab-case')
  .brand('CommandName')

export type CommandName = z.infer<typeof CommandName>

/**
 * Command step
 */
export const CommandStep = z.object({
  title: z.string(),
  description: z.string().optional(),
  command: z.string().optional().describe('Bash command to run'),
  code: z.string().optional().describe('Code block to display'),
  language: z.string().default('bash'),
})

export type CommandStep = z.infer<typeof CommandStep>

/**
 * ClaudeCommand - defines a slash command
 */
export const ClaudeCommand = z.object({
  // Frontmatter
  name: CommandName,
  description: z.string().min(10).max(100).describe('Short description shown in command list'),
  allowedTools: z.array(ToolPermission).min(1).describe('Tools this command can use'),

  // Content
  steps: z.array(CommandStep).optional().describe('Steps to execute'),

  // Optional raw content
  rawContent: z.string().optional(),
})

export type ClaudeCommand = z.infer<typeof ClaudeCommand>

/**
 * Collection of all commands
 */
export const CommandCollection = z.record(CommandName, ClaudeCommand)

export type CommandCollection = z.infer<typeof CommandCollection>
