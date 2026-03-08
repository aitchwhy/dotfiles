/**
 * End-to-End Tests
 *
 * Verifies that settings.json is generated correctly.
 */
import * as fs from 'node:fs'
import * as path from 'node:path'
import { describe, expect, it } from 'vitest'

const GENERATED_ROOT = path.join(__dirname, '..', 'generated')

describe('Generation E2E', () => {
  describe('settings.json', () => {
    const settingsPath = path.join(GENERATED_ROOT, 'claude', 'settings.json')

    it('generates settings.json', () => {
      expect(fs.existsSync(settingsPath)).toBe(true)
    })

    it('is valid JSON with required keys', () => {
      const content = JSON.parse(fs.readFileSync(settingsPath, 'utf-8'))
      expect(content).toHaveProperty('hooks')
      expect(content).toHaveProperty('permissions')
      expect(content).toHaveProperty('model')
      expect(content.skipDangerousModePermissionPrompt).toBe(true)
    })

    it('has PreToolUse, PostToolUse, SessionStart hooks', () => {
      const content = JSON.parse(fs.readFileSync(settingsPath, 'utf-8'))
      expect(content.hooks).toHaveProperty('PreToolUse')
      expect(content.hooks).toHaveProperty('PostToolUse')
      expect(content.hooks).toHaveProperty('SessionStart')
    })

    it('does not have deleted hook events', () => {
      const content = JSON.parse(fs.readFileSync(settingsPath, 'utf-8'))
      expect(content.hooks).not.toHaveProperty('Stop')
      expect(content.hooks).not.toHaveProperty('UserPromptSubmit')
    })

    it('does not have MAX_THINKING_TOKENS env', () => {
      const content = JSON.parse(fs.readFileSync(settingsPath, 'utf-8'))
      expect(content).not.toHaveProperty('env')
    })
  })
})
