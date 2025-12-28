/**
 * End-to-End Tests
 *
 * Verifies that artifacts for ALL providers (Claude, Cursor, Gemini)
 * are generated correctly.
 */
import * as fs from 'node:fs'
import * as path from 'node:path'
import { describe, expect, it } from 'vitest'

const BRAIN_ROOT = path.join(__dirname, '..')
const GENERATED_ROOT = path.join(BRAIN_ROOT, 'generated')

describe('Multi-Provider Generation E2E', () => {
  describe('Cursor IDE (.mdc rules)', () => {
    const rulesDir = path.join(GENERATED_ROOT, 'cursor/rules')

    it('creates the rules directory', () => {
      expect(fs.existsSync(rulesDir)).toBe(true)
    })

    it('generates core rules as .mdc files', () => {
      const effectRule = path.join(rulesDir, 'effect-ts.mdc')
      expect(fs.existsSync(effectRule)).toBe(true)

      const content = fs.readFileSync(effectRule, 'utf-8')
      expect(content).toContain('---') // Frontmatter
      expect(content).toContain('globs: *.ts')
      expect(content).toContain('# effect-ts')
    })

    it('generates a substantial number of rules', () => {
      const files = fs.readdirSync(rulesDir)
      const mdcFiles = files.filter((f) => f.endsWith('.mdc'))
      expect(mdcFiles.length).toBeGreaterThan(10)
    })
  })

  describe('Gemini / Antigravity (GEMINI.md)', () => {
    const geminiDir = path.join(GENERATED_ROOT, 'gemini')
    const geminiFile = path.join(geminiDir, 'GEMINI.md')

    it('creates the gemini directory', () => {
      expect(fs.existsSync(geminiDir)).toBe(true)
    })

    it('generates GEMINI.md', () => {
      expect(fs.existsSync(geminiFile)).toBe(true)
    })

    it('contains all key sections', () => {
      const content = fs.readFileSync(geminiFile, 'utf-8')
      expect(content).toContain('# System Instructions (Gemini/Antigravity)')
      expect(content).toContain('## Personas')
      expect(content).toContain('### code-reviewer')
      expect(content).toContain('nix flake check') // Check for verification commands
    })

    it('is a large file (concatenation of everything)', () => {
      const content = fs.readFileSync(geminiFile, 'utf-8')
      // It should be huge because it has all personas and skills
      expect(content.length).toBeGreaterThan(10000)
    })
  })
})
