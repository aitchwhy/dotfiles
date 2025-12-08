/**
 * SystemSkill Schema
 *
 * Defines Claude Code skills that provide domain-specific patterns.
 * Skills are invoked via `skill: "skill-name"` in Claude Code.
 */
import { z } from 'zod'

/**
 * Skill name - kebab-case identifier
 */
export const SkillName = z
  .string()
  .regex(/^[a-z][a-z0-9-]*$/, 'Must be kebab-case')
  .brand('SkillName')

export type SkillName = z.infer<typeof SkillName>

/**
 * Tool permission specification
 * Examples: "Read", "Write", "Edit", "Bash", "Bash(bun:*)"
 */
export const ToolPermission = z
  .string()
  .regex(/^(Read|Write|Edit|Grep|Glob|Bash|WebFetch|WebSearch)(\(.*\))?$/)
  .describe('Tool permission with optional pattern')

export type ToolPermission = z.infer<typeof ToolPermission>

/**
 * Pattern with do/don't annotation
 */
export const Pattern = z.object({
  title: z.string(),
  description: z.string().optional(),
  code: z.string().optional(),
  language: z.string().default('typescript'),
  annotation: z.enum(['do', 'dont', 'info']).default('info'),
})

export type Pattern = z.infer<typeof Pattern>

/**
 * Section within a skill
 */
export const SkillSection = z.object({
  title: z.string(),
  description: z.string().optional(),
  patterns: z.array(Pattern).optional(),
  content: z.string().optional(),
})

export type SkillSection = z.infer<typeof SkillSection>

/**
 * SystemSkill - defines a skill directory with SKILL.md
 */
export const SystemSkill = z.object({
  // Frontmatter
  name: SkillName,
  description: z.string().min(20).max(300).describe('Description shown in skill selection'),
  allowedTools: z.array(ToolPermission).min(1).describe('Tools this skill can use'),

  // Content
  sections: z.array(SkillSection).min(1).describe('Structured content sections'),

  // Optional raw content (for complex skills)
  rawContent: z.string().optional().describe('Raw markdown to append after structured sections'),
})

export type SystemSkill = z.infer<typeof SystemSkill>

/**
 * Collection of all skills
 */
export const SkillCollection = z.record(SkillName, SystemSkill)

export type SkillCollection = z.infer<typeof SkillCollection>
