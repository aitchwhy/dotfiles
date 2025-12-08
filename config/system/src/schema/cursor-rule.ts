/**
 * CursorRule Schema
 *
 * Defines the structure for Cursor IDE rules (.mdc files).
 * Follows Cursor's rule format with YAML frontmatter.
 */
import { z } from 'zod'

/**
 * Kebab-case rule name (e.g., 'cursor-rules', 'dev-workflow')
 */
export const RuleName = z
  .string()
  .regex(/^[a-z][a-z0-9-]*$/, 'Must be kebab-case')
  .brand('RuleName')

export type RuleName = z.infer<typeof RuleName>

/**
 * Glob pattern for file matching
 */
export const GlobPattern = z
  .string()
  .min(1)
  .describe('Glob pattern like "**/*.ts" or ".cursor/rules/*.mdc"')

/**
 * MDC cross-reference link
 * Format: [label](mdc:path/to/file)
 */
export const CrossReference = z.object({
  label: z.string(),
  path: z.string(),
})

export type CrossReference = z.infer<typeof CrossReference>

/**
 * Code example with language and optional good/bad annotation
 */
export const CodeExample = z.object({
  language: z.string().default('typescript'),
  code: z.string(),
  annotation: z.enum(['good', 'bad', 'neutral']).default('neutral'),
  description: z.string().optional(),
})

export type CodeExample = z.infer<typeof CodeExample>

/**
 * CursorRule - defines a single .mdc rule file
 */
export const CursorRule = z.object({
  // Metadata (YAML frontmatter)
  name: RuleName,
  description: z
    .string()
    .min(10)
    .max(200)
    .describe('Clear, one-line description of what the rule enforces'),
  globs: z.array(GlobPattern).min(1).describe('File patterns this rule applies to'),
  alwaysApply: z.boolean().default(false).describe('Whether to always apply regardless of context'),

  // Content sections
  requirements: z.array(z.string()).optional().describe('Bullet points of specific requirements'),
  examples: z.array(CodeExample).optional().describe('Code examples demonstrating the rule'),
  antiPatterns: z.array(CodeExample).optional().describe('Examples of what NOT to do'),
  references: z
    .array(CrossReference)
    .optional()
    .describe('Cross-references to other rules or files'),

  // Raw markdown content (for complex rules)
  content: z.string().optional().describe('Raw markdown content for the rule body'),
})

export type CursorRule = z.infer<typeof CursorRule>

/**
 * Collection of all cursor rules
 */
export const CursorRuleCollection = z.record(RuleName, CursorRule)

export type CursorRuleCollection = z.infer<typeof CursorRuleCollection>
