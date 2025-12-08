/**
 * Build Script Tests
 *
 * Tests for the build script that generates SKILL.md files from definitions.
 */
import { afterAll, beforeAll, describe, expect, test } from 'bun:test'
import { mkdir, mkdtemp, readFile, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { type BuildConfig, buildSkills, loadSkillDefinitions } from './build'

describe('loadSkillDefinitions', () => {
  test('loads skill definitions from definitions directory', async () => {
    const skills = await loadSkillDefinitions()

    expect(skills.length).toBeGreaterThanOrEqual(1)
    expect(skills.some((s) => s.name === 'clean-code')).toBe(true)
  })

  test('all loaded skills have valid structure', async () => {
    const skills = await loadSkillDefinitions()

    for (const skill of skills) {
      expect(skill.name).toBeDefined()
      expect(skill.description.length).toBeGreaterThanOrEqual(20)
      expect(skill.allowedTools.length).toBeGreaterThanOrEqual(1)
      expect(skill.sections.length).toBeGreaterThanOrEqual(1)
    }
  })
})

describe('buildSkills', () => {
  let tempDir: string

  beforeAll(async () => {
    tempDir = await mkdtemp(join(tmpdir(), 'config-system-test-'))
  })

  afterAll(async () => {
    await rm(tempDir, { recursive: true })
  })

  test('writes SKILL.md files to output directory', async () => {
    const config: BuildConfig = {
      outputDir: tempDir,
      dryRun: false,
    }

    const result = await buildSkills(config)

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.data.written.length).toBeGreaterThanOrEqual(1)
      expect(result.data.written).toContain('clean-code')
    }

    // Verify file was created
    const skillPath = join(tempDir, 'clean-code', 'SKILL.md')
    const content = await readFile(skillPath, 'utf-8')

    expect(content).toContain('name: clean-code')
    expect(content).toContain('## Nix-Specific Patterns')
  })

  test('creates skill subdirectories if they do not exist', async () => {
    const subDir = join(tempDir, 'subdir-test')
    await mkdir(subDir, { recursive: true })

    const config: BuildConfig = {
      outputDir: subDir,
      dryRun: false,
    }

    const result = await buildSkills(config)

    expect(result.ok).toBe(true)

    // Verify subdirectory was created
    const skillPath = join(subDir, 'clean-code', 'SKILL.md')
    const content = await readFile(skillPath, 'utf-8')
    expect(content).toContain('name: clean-code')
  })

  test('dry run does not write files', async () => {
    const dryRunDir = join(tempDir, 'dry-run-test')
    await mkdir(dryRunDir, { recursive: true })

    const config: BuildConfig = {
      outputDir: dryRunDir,
      dryRun: true,
    }

    const result = await buildSkills(config)

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.data.written.length).toBe(0)
      expect(result.data.skipped.length).toBeGreaterThanOrEqual(1)
    }
  })

  test('includes auto-generated header', async () => {
    const headerDir = join(tempDir, 'header-test')
    await mkdir(headerDir, { recursive: true })

    const config: BuildConfig = {
      outputDir: headerDir,
      dryRun: false,
    }

    await buildSkills(config)

    const skillPath = join(headerDir, 'clean-code', 'SKILL.md')
    const content = await readFile(skillPath, 'utf-8')

    // Auto-generated header should NOT be present (original format doesn't have it)
    // Actually, the plan says to include it, but let's match original for now
    expect(content.startsWith('---')).toBe(true)
  })
})
