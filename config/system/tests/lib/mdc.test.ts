/**
 * MDC Generator Tests
 *
 * Tests for generating .mdc cursor rule files from TypeScript definitions.
 */
import { describe, expect, test } from 'bun:test'
import { generateCursorRuleMarkdown, generateMdcFrontmatter } from '@/lib/mdc'
import type { CursorRule } from '@/schema'

describe('MDC Generator', () => {
  describe('generateMdcFrontmatter', () => {
    test('generates correct YAML frontmatter', () => {
      const rule: CursorRule = {
        name: 'test-rule' as CursorRule['name'],
        description: 'A test rule for demonstration',
        globs: ['**/*.ts', '**/*.tsx'],
        alwaysApply: true,
      }

      const frontmatter = generateMdcFrontmatter(rule)

      expect(frontmatter).toContain('---')
      expect(frontmatter).toContain('description: A test rule for demonstration')
      expect(frontmatter).toContain('globs: **/*.ts, **/*.tsx')
      expect(frontmatter).toContain('alwaysApply: true')
    })

    test('handles single glob pattern', () => {
      const rule: CursorRule = {
        name: 'single-glob' as CursorRule['name'],
        description: 'Rule with single glob',
        globs: ['.cursor/rules/*.mdc'],
        alwaysApply: false,
      }

      const frontmatter = generateMdcFrontmatter(rule)

      expect(frontmatter).toContain('globs: .cursor/rules/*.mdc')
      expect(frontmatter).toContain('alwaysApply: false')
    })
  })

  describe('generateCursorRuleMarkdown', () => {
    test('generates complete .mdc content with raw content', () => {
      const rule: CursorRule = {
        name: 'raw-content' as CursorRule['name'],
        description: 'Rule with raw markdown content',
        globs: ['**/*'],
        alwaysApply: true,
        content: `# Custom Content

This is raw markdown that should be preserved exactly.

- Bullet one
- Bullet two`,
      }

      const markdown = generateCursorRuleMarkdown(rule)

      expect(markdown).toContain('---')
      expect(markdown).toContain('description: Rule with raw markdown content')
      expect(markdown).toContain('# Custom Content')
      expect(markdown).toContain('- Bullet one')
    })

    test('generates .mdc content with requirements', () => {
      const rule: CursorRule = {
        name: 'with-requirements' as CursorRule['name'],
        description: 'Rule with requirements list',
        globs: ['**/*.ts'],
        alwaysApply: false,
        requirements: [
          'Always use explicit types',
          'Never use `any` keyword',
          'Prefer `const` over `let`',
        ],
      }

      const markdown = generateCursorRuleMarkdown(rule)

      expect(markdown).toContain('- **Always use explicit types**')
      expect(markdown).toContain('- **Never use `any` keyword**')
      expect(markdown).toContain('- **Prefer `const` over `let`**')
    })

    test('generates .mdc content with code examples', () => {
      const rule: CursorRule = {
        name: 'with-examples' as CursorRule['name'],
        description: 'Rule with code examples',
        globs: ['**/*.ts'],
        alwaysApply: false,
        examples: [
          {
            language: 'typescript',
            code: 'const x: number = 42;',
            annotation: 'good',
            description: 'Explicit type annotation',
          },
          {
            language: 'typescript',
            code: 'const x = 42;',
            annotation: 'bad',
            description: 'Missing type annotation',
          },
        ],
      }

      const markdown = generateCursorRuleMarkdown(rule)

      expect(markdown).toContain('```typescript')
      expect(markdown).toContain('// ✅ DO: Explicit type annotation')
      expect(markdown).toContain('const x: number = 42;')
      expect(markdown).toContain("// ❌ DON'T: Missing type annotation")
      expect(markdown).toContain('const x = 42;')
    })

    test('generates .mdc content with references', () => {
      const rule: CursorRule = {
        name: 'with-references' as CursorRule['name'],
        description: 'Rule with cross-references',
        globs: ['**/*'],
        alwaysApply: false,
        references: [
          { label: 'TypeScript Rules', path: '.cursor/rules/typescript.mdc' },
          { label: 'Main Config', path: 'tsconfig.json' },
        ],
      }

      const markdown = generateCursorRuleMarkdown(rule)

      expect(markdown).toContain('[TypeScript Rules](mdc:.cursor/rules/typescript.mdc)')
      expect(markdown).toContain('[Main Config](mdc:tsconfig.json)')
    })
  })
})
