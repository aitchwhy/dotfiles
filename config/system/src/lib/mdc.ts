/**
 * MDC Generator
 *
 * Generates .mdc cursor rule files from TypeScript CursorRule definitions.
 * Output format matches Cursor's rule format with YAML frontmatter.
 */
import type { CodeExample, CursorRule } from '@/schema'

/**
 * Generate YAML frontmatter for a cursor rule
 */
export function generateMdcFrontmatter(rule: CursorRule): string {
  const lines = [
    '---',
    `description: ${rule.description}`,
    `globs: ${rule.globs.join(', ')}`,
    `alwaysApply: ${rule.alwaysApply}`,
    '---',
  ]
  return lines.join('\n')
}

/**
 * Generate a single code example with DO/DON'T annotation
 */
function generateCodeExample(example: CodeExample): string {
  const lines: string[] = []
  const language = example.language ?? 'typescript'

  lines.push(`\`\`\`${language}`)

  // Add annotation comment if present
  if (example.annotation === 'good' && example.description) {
    lines.push(`// ✅ DO: ${example.description}`)
  } else if (example.annotation === 'bad' && example.description) {
    lines.push(`// ❌ DON'T: ${example.description}`)
  }

  lines.push(example.code)
  lines.push('```')

  return lines.join('\n')
}

/**
 * Generate complete .mdc file content from a CursorRule definition
 */
export function generateCursorRuleMarkdown(rule: CursorRule): string {
  const parts: string[] = []

  // Frontmatter
  parts.push(generateMdcFrontmatter(rule))
  parts.push('')

  // Raw content takes precedence (for complex rules)
  if (rule.content) {
    parts.push(rule.content)
    return parts.join('\n')
  }

  // Requirements as bold bullet points
  if (rule.requirements && rule.requirements.length > 0) {
    for (const req of rule.requirements) {
      parts.push(`- **${req}**`)
    }
    parts.push('')
  }

  // Code examples
  if (rule.examples && rule.examples.length > 0) {
    parts.push('- **Code Examples:**')
    for (const example of rule.examples) {
      parts.push(`  ${generateCodeExample(example).split('\n').join('\n  ')}`)
    }
    parts.push('')
  }

  // Anti-patterns
  if (rule.antiPatterns && rule.antiPatterns.length > 0) {
    parts.push('- **Anti-Patterns to Avoid:**')
    for (const antiPattern of rule.antiPatterns) {
      parts.push(`  ${generateCodeExample(antiPattern).split('\n').join('\n  ')}`)
    }
    parts.push('')
  }

  // Cross-references
  if (rule.references && rule.references.length > 0) {
    parts.push('- **References:**')
    for (const ref of rule.references) {
      parts.push(`  - [${ref.label}](mdc:${ref.path})`)
    }
    parts.push('')
  }

  return parts.join('\n')
}
