/**
 * Markdown Generator Tests
 *
 * Tests for generating SKILL.md from SystemSkill definitions.
 */
import { describe, expect, test } from 'bun:test'
import { generateFrontmatter, generateSkillMarkdown } from '@/lib/markdown'
import type { SystemSkill } from '@/schema'

describe('generateFrontmatter', () => {
  test('generates valid YAML frontmatter', () => {
    const skill = {
      name: 'test-skill',
      description: 'A test skill for validation',
      allowedTools: ['Read', 'Write'],
    }

    const result = generateFrontmatter(skill as unknown as SystemSkill)

    expect(result).toContain('---')
    expect(result).toContain('name: test-skill')
    expect(result).toContain('description: A test skill for validation')
    expect(result).toContain('allowed-tools: Read, Write')
  })

  test('converts allowedTools to comma-separated list', () => {
    const skill = {
      name: 'multi-tool',
      description: 'A skill with many tools',
      allowedTools: ['Read', 'Write', 'Edit', 'Grep', 'Glob'],
    }

    const result = generateFrontmatter(skill as unknown as SystemSkill)

    expect(result).toContain('allowed-tools: Read, Write, Edit, Grep, Glob')
  })
})

describe('generateSkillMarkdown', () => {
  test('generates complete markdown with frontmatter and sections', () => {
    const skill: SystemSkill = {
      name: 'test-skill' as SystemSkill['name'],
      description: 'A test skill for validation',
      allowedTools: ['Read', 'Write'] as SystemSkill['allowedTools'],
      sections: [
        {
          title: 'Test Section',
          patterns: [
            {
              title: 'Test Pattern',
              description: 'A pattern description',
              code: 'const x = 1;',
              language: 'typescript',
              annotation: 'do',
            },
          ],
        },
      ],
    }

    const result = generateSkillMarkdown(skill)

    // Check frontmatter
    expect(result).toMatch(/^---\n/)
    expect(result).toContain('name: test-skill')

    // Check section header
    expect(result).toContain('## Test Section')

    // Check pattern
    expect(result).toContain('### Test Pattern')
    expect(result).toContain('A pattern description')
    expect(result).toContain('```typescript')
    expect(result).toContain('const x = 1;')
    expect(result).toContain('```')
  })

  test('handles multiple sections', () => {
    const skill: SystemSkill = {
      name: 'multi-section' as SystemSkill['name'],
      description: 'Skill with multiple sections',
      allowedTools: ['Read'] as SystemSkill['allowedTools'],
      sections: [
        { title: 'First Section', patterns: [] },
        { title: 'Second Section', patterns: [] },
      ],
    }

    const result = generateSkillMarkdown(skill)

    expect(result).toContain('## First Section')
    expect(result).toContain('## Second Section')
  })

  test('handles patterns without code', () => {
    const skill: SystemSkill = {
      name: 'no-code' as SystemSkill['name'],
      description: 'Skill with description-only pattern',
      allowedTools: ['Read'] as SystemSkill['allowedTools'],
      sections: [
        {
          title: 'Section',
          patterns: [
            {
              title: 'Description Only',
              description: 'Just a description, no code',
              annotation: 'info',
            },
          ],
        },
      ],
    }

    const result = generateSkillMarkdown(skill)

    expect(result).toContain('### Description Only')
    expect(result).toContain('Just a description, no code')
    expect(result).not.toContain('```')
  })

  test('handles section with raw content instead of patterns', () => {
    const skill: SystemSkill = {
      name: 'raw-content' as SystemSkill['name'],
      description: 'Skill with raw content section',
      allowedTools: ['Read'] as SystemSkill['allowedTools'],
      sections: [
        {
          title: 'Raw Section',
          content: 'This is raw markdown content.\n\nWith multiple paragraphs.',
        },
      ],
    }

    const result = generateSkillMarkdown(skill)

    expect(result).toContain('## Raw Section')
    expect(result).toContain('This is raw markdown content.')
    expect(result).toContain('With multiple paragraphs.')
  })

  test('defaults language to typescript when not specified', () => {
    const skill: SystemSkill = {
      name: 'default-lang' as SystemSkill['name'],
      description: 'Skill with default language',
      allowedTools: ['Read'] as SystemSkill['allowedTools'],
      sections: [
        {
          title: 'Section',
          patterns: [
            {
              title: 'Pattern',
              code: 'const x = 1;',
              annotation: 'do',
            },
          ],
        },
      ],
    }

    const result = generateSkillMarkdown(skill)

    expect(result).toContain('```typescript')
  })
})

describe('clean-code skill generation', () => {
  test('generates markdown matching original SKILL.md structure', async () => {
    const { cleanCodeSkill } = await import('@/definitions/skills/clean-code')
    const result = generateSkillMarkdown(cleanCodeSkill)

    // Verify frontmatter matches original
    expect(result).toContain('name: clean-code')
    expect(result).toContain(
      'description: Clean code patterns for Nix and TypeScript. Explicit imports, Result types, function size limits. Apply to dotfiles and TypeScript projects.'
    )
    expect(result).toContain('allowed-tools: Read, Write, Edit, Grep, Glob')

    // Verify sections exist
    expect(result).toContain('## Nix-Specific Patterns')
    expect(result).toContain('## TypeScript Clean Code')
    expect(result).toContain('## File Organization')

    // Verify specific patterns
    expect(result).toContain('### Explicit Library Imports (Never `with lib;`)')
    expect(result).toContain('### Function Size Limits')
    expect(result).toContain('### Early Returns Over Nesting')
  })
})
