/**
 * Markdown Generator
 *
 * Generates SKILL.md files from SystemSkill definitions.
 * Output format matches the existing SKILL.md structure.
 */
import type { Pattern, SkillSection, SystemSkill } from '@/schema'

/**
 * Generate YAML frontmatter for a skill
 */
export function generateFrontmatter(skill: SystemSkill): string {
  const lines = [
    '---',
    `name: ${skill.name}`,
    `description: ${skill.description}`,
    `allowed-tools: ${skill.allowedTools.join(', ')}`,
    '---',
  ]
  return lines.join('\n')
}

/**
 * Generate markdown for a single pattern
 */
function generatePattern(pattern: Pattern): string {
  const lines: string[] = []

  // Pattern title as H3
  lines.push(`### ${pattern.title}`)
  lines.push('')

  // Description if present
  if (pattern.description) {
    // Add colon at end if followed by code block (matches original format)
    const desc = pattern.code ? pattern.description.replace(/[.:;]?$/, ':') : pattern.description
    lines.push(desc)
    lines.push('')
  }

  // Code block if present
  if (pattern.code) {
    // Use empty language tag for 'text' to match original format
    const language = pattern.language === 'text' ? '' : (pattern.language ?? 'typescript')
    lines.push(`\`\`\`${language}`)
    lines.push(pattern.code)
    lines.push('```')
    lines.push('')
  }

  return lines.join('\n')
}

/**
 * Generate markdown for a section
 */
function generateSection(section: SkillSection): string {
  const lines: string[] = []

  // Section title as H2
  lines.push(`## ${section.title}`)
  lines.push('')

  // Either raw content or patterns
  if (section.content) {
    lines.push(section.content)
    lines.push('')
  } else if (section.patterns) {
    for (const pattern of section.patterns) {
      lines.push(generatePattern(pattern))
    }
  }

  return lines.join('\n')
}

/**
 * Generate complete SKILL.md from a SystemSkill definition
 */
export function generateSkillMarkdown(skill: SystemSkill): string {
  const parts: string[] = []

  // Frontmatter
  parts.push(generateFrontmatter(skill))
  parts.push('')

  // Sections
  for (const section of skill.sections) {
    parts.push(generateSection(section))
  }

  return parts.join('\n')
}
