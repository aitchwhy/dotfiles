/**
 * SystemSkill Schema Tests
 *
 * Tests for Claude Code skill schema validation.
 */
import { describe, expect, test } from 'bun:test'

// These imports will fail until we implement the module (RED phase)
import {
  Pattern,
  SkillName,
  SkillSection,
  SystemSkill,
  type SystemSkill as SystemSkillType,
  ToolPermission,
} from '@/schema/skill'

describe('SystemSkill Schema', () => {
  describe('SkillName', () => {
    test('accepts valid kebab-case names', () => {
      expect(SkillName.safeParse('clean-code').success).toBe(true)
      expect(SkillName.safeParse('typescript-patterns').success).toBe(true)
      expect(SkillName.safeParse('tdd-patterns').success).toBe(true)
    })

    test('rejects invalid names', () => {
      expect(SkillName.safeParse('CleanCode').success).toBe(false)
      expect(SkillName.safeParse('clean_code').success).toBe(false)
      expect(SkillName.safeParse('123-code').success).toBe(false)
    })
  })

  describe('ToolPermission', () => {
    test('accepts valid tool permissions', () => {
      expect(ToolPermission.safeParse('Read').success).toBe(true)
      expect(ToolPermission.safeParse('Write').success).toBe(true)
      expect(ToolPermission.safeParse('Edit').success).toBe(true)
      expect(ToolPermission.safeParse('Grep').success).toBe(true)
      expect(ToolPermission.safeParse('Glob').success).toBe(true)
      expect(ToolPermission.safeParse('Bash').success).toBe(true)
      expect(ToolPermission.safeParse('WebFetch').success).toBe(true)
      expect(ToolPermission.safeParse('WebSearch').success).toBe(true)
    })

    test('accepts tool permissions with patterns', () => {
      expect(ToolPermission.safeParse('Bash(bun:*)').success).toBe(true)
      expect(ToolPermission.safeParse('Bash(git:*)').success).toBe(true)
      expect(ToolPermission.safeParse('Write(*.ts)').success).toBe(true)
    })

    test('rejects invalid tool permissions', () => {
      expect(ToolPermission.safeParse('read').success).toBe(false) // lowercase
      expect(ToolPermission.safeParse('Execute').success).toBe(false) // unknown tool
      expect(ToolPermission.safeParse('').success).toBe(false) // empty
    })
  })

  describe('Pattern', () => {
    test('parses pattern with defaults', () => {
      const result = Pattern.safeParse({
        title: 'Use const',
      })
      expect(result.success).toBe(true)
      if (result.success) {
        expect(result.data.language).toBe('typescript')
        expect(result.data.annotation).toBe('info')
      }
    })

    test('parses full pattern', () => {
      const result = Pattern.safeParse({
        title: 'Explicit imports',
        description: 'Always use explicit imports',
        code: 'import { x } from "y"',
        language: 'typescript',
        annotation: 'do',
      })
      expect(result.success).toBe(true)
      if (result.success) {
        expect(result.data.annotation).toBe('do')
      }
    })
  })

  describe('SkillSection', () => {
    test('parses minimal section', () => {
      const result = SkillSection.safeParse({
        title: 'Core Patterns',
      })
      expect(result.success).toBe(true)
    })

    test('parses section with patterns', () => {
      const result = SkillSection.safeParse({
        title: 'TypeScript Patterns',
        description: 'Elite TypeScript patterns',
        patterns: [
          { title: 'Use branded types', annotation: 'do' },
          { title: 'Avoid any', annotation: 'dont' },
        ],
      })
      expect(result.success).toBe(true)
    })
  })

  describe('SystemSkill', () => {
    const validSkill: SystemSkillType = {
      name: 'clean-code' as SystemSkillType['name'],
      description: 'Clean code patterns for TypeScript and Nix',
      allowedTools: ['Read', 'Write', 'Edit', 'Grep', 'Glob'] as SystemSkillType['allowedTools'],
      sections: [
        {
          title: 'Core Patterns',
          patterns: [{ title: 'Use const', annotation: 'do' as const }],
        },
      ],
    }

    test('parses valid skill', () => {
      const result = SystemSkill.safeParse(validSkill)
      expect(result.success).toBe(true)
    })

    test('rejects skill with short description', () => {
      const result = SystemSkill.safeParse({
        ...validSkill,
        description: 'Too short',
      })
      expect(result.success).toBe(false)
    })

    test('rejects skill with empty allowedTools', () => {
      const result = SystemSkill.safeParse({
        ...validSkill,
        allowedTools: [],
      })
      expect(result.success).toBe(false)
    })

    test('rejects skill with empty sections', () => {
      const result = SystemSkill.safeParse({
        ...validSkill,
        sections: [],
      })
      expect(result.success).toBe(false)
    })

    test('parses skill with rawContent', () => {
      const result = SystemSkill.safeParse({
        ...validSkill,
        rawContent: '## Additional\n\nRaw markdown content',
      })
      expect(result.success).toBe(true)
      if (result.success) {
        expect(result.data.rawContent).toBe('## Additional\n\nRaw markdown content')
      }
    })
  })
})
