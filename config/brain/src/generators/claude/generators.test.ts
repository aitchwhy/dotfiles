/**
 * Generator Tests
 *
 * Validates generators produce correct output.
 */
import * as fs from 'node:fs'
import * as path from 'node:path'
import { describe, expect, it } from 'vitest'

const GENERATED_DIR = path.join(__dirname, '../../../generated/claude')

describe('Generated Artifacts', () => {
  describe('memories.md', () => {
    const filePath = path.join(GENERATED_DIR, 'memories.md')

    it('exists', () => {
      expect(fs.existsSync(filePath)).toBe(true)
    })

    it('has substantial content', () => {
      const content = fs.readFileSync(filePath, 'utf-8')
      expect(content.length).toBeGreaterThan(1000)
    })

    it('has all category sections', () => {
      const content = fs.readFileSync(filePath, 'utf-8')
      expect(content).toContain('## Principles')
      expect(content).toContain('## Constraints')
      expect(content).toContain('## Patterns')
    })

    it('reports correct total', () => {
      const content = fs.readFileSync(filePath, 'utf-8')
      expect(content).toContain('35 memories')
    })
  })

  describe('critic-mode.md', () => {
    const filePath = path.join(GENERATED_DIR, 'critic-mode.md')

    it('exists', () => {
      expect(fs.existsSync(filePath)).toBe(true)
    })

    it('has substantial content', () => {
      const content = fs.readFileSync(filePath, 'utf-8')
      expect(content.length).toBeGreaterThan(500)
    })

    it('has phase sections', () => {
      const content = fs.readFileSync(filePath, 'utf-8')
      expect(content).toContain('## Planning Phase')
      expect(content).toContain('## Execution Phase')
    })

    it('reports correct total', () => {
      const content = fs.readFileSync(filePath, 'utf-8')
      expect(content).toContain('5 behaviors')
    })
  })

  describe('settings.json', () => {
    const filePath = path.join(GENERATED_DIR, 'settings.json')

    it('exists', () => {
      expect(fs.existsSync(filePath)).toBe(true)
    })

    it('is valid JSON', () => {
      const content = fs.readFileSync(filePath, 'utf-8')
      expect(() => JSON.parse(content)).not.toThrow()
    })

    it('has cleanupPeriodDays set to 99999', () => {
      const content = JSON.parse(fs.readFileSync(filePath, 'utf-8'))
      expect(content.cleanupPeriodDays).toBe(99999)
    })

    it('has permissions configured', () => {
      const content = JSON.parse(fs.readFileSync(filePath, 'utf-8'))
      expect(content.permissions).toBeDefined()
    })

    it('has hooks configured', () => {
      const content = JSON.parse(fs.readFileSync(filePath, 'utf-8'))
      expect(content.hooks).toBeDefined()
    })

    it('has agents configured', () => {
      const content = JSON.parse(fs.readFileSync(filePath, 'utf-8'))
      expect(content.agents).toBeDefined()
      expect(content.agents.length).toBeGreaterThan(0)
    })
  })
})
