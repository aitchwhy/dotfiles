/**
 * Procedural Guards Tests - Guard 27 (Modern CLI Tools)
 */
import { describe, expect, test } from 'bun:test'
import { checkModernCLITools } from './procedural'

describe('Guard 27: checkModernCLITools', () => {
  describe('grep → rg aliases', () => {
    test('blocks --include flag (rg uses --glob)', () => {
      const result = checkModernCLITools('grep --include="*.ts" pattern')
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toContain('Guard 27')
        expect(result.error).toContain('--include')
        expect(result.error).toContain('--glob')
      }
    })

    test('blocks --exclude flag (rg uses --glob !)', () => {
      const result = checkModernCLITools('grep --exclude="*.test.ts" pattern')
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toContain('--exclude')
      }
    })

    test('blocks -r flag (rg is recursive by default)', () => {
      const result = checkModernCLITools('grep -r pattern src/')
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toContain('-r')
      }
    })

    test('blocks -R flag (rg is recursive by default)', () => {
      const result = checkModernCLITools('grep -R pattern src/')
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toContain('-R')
      }
    })

    test('blocks -E flag (rg uses extended regex by default)', () => {
      const result = checkModernCLITools('grep -E "pattern+" file')
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toContain('-E')
      }
    })

    test('allows valid grep command without incompatible flags', () => {
      const result = checkModernCLITools('grep pattern file.txt')
      expect(result.ok).toBe(true)
    })

    test('allows grep with -i flag (supported in rg)', () => {
      const result = checkModernCLITools('grep -i pattern file.txt')
      expect(result.ok).toBe(true)
    })
  })

  describe('find → fd aliases', () => {
    test('blocks -name flag (fd uses positional pattern)', () => {
      const result = checkModernCLITools('find . -name "*.ts"')
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toContain('-name')
        expect(result.error).toContain('positional pattern')
      }
    })

    test('blocks -iname flag (fd uses -i)', () => {
      const result = checkModernCLITools('find . -iname "*.ts"')
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toContain('-iname')
      }
    })

    test('blocks -type flag (fd uses -t)', () => {
      const result = checkModernCLITools('find . -type f')
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toContain('-type')
      }
    })

    test('blocks -exec flag (fd uses -x/-X)', () => {
      const result = checkModernCLITools('find . -name "*.ts" -exec rm {} \\;')
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toContain('-exec')
      }
    })

    test('allows valid find command without incompatible flags', () => {
      const result = checkModernCLITools('find .')
      expect(result.ok).toBe(true)
    })
  })

  describe('ls → eza aliases', () => {
    test('allows ls commands (mostly compatible)', () => {
      const result = checkModernCLITools('ls -la')
      expect(result.ok).toBe(true)
    })

    test('allows ls with tree-like flags', () => {
      const result = checkModernCLITools('ls --tree')
      expect(result.ok).toBe(true)
    })
  })

  describe('non-legacy commands', () => {
    test('allows rg with proper syntax', () => {
      const result = checkModernCLITools('rg -g "*.ts" pattern')
      expect(result.ok).toBe(true)
    })

    test('allows fd with proper syntax', () => {
      const result = checkModernCLITools('fd "*.ts" src/')
      expect(result.ok).toBe(true)
    })

    test('allows eza commands', () => {
      const result = checkModernCLITools('eza -la --git --icons')
      expect(result.ok).toBe(true)
    })

    test('allows unrelated commands', () => {
      const result = checkModernCLITools('git status')
      expect(result.ok).toBe(true)
    })

    test('allows commands with env vars prefix', () => {
      const result = checkModernCLITools('GIT_PAGER=cat git log')
      expect(result.ok).toBe(true)
    })
  })

  describe('edge cases', () => {
    test('handles empty command', () => {
      const result = checkModernCLITools('')
      expect(result.ok).toBe(true)
    })

    test('handles command with multiple env vars', () => {
      const result = checkModernCLITools('FOO=bar BAZ=qux grep pattern')
      expect(result.ok).toBe(true)
    })
  })
})
