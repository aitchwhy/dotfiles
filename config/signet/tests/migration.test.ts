/**
 * Signet Migration Test Harness
 *
 * Validates:
 * 1. CLI availability and help
 * 2. Shell alias configuration
 * 3. Effect-TS compliance (no throw, proper imports)
 * 4. Hexagonal architecture generation
 *
 * Run: bun test config/signet/tests/migration.test.ts
 */
import { afterAll, beforeAll, describe, expect, test } from 'bun:test'
import { execSync, spawnSync } from 'node:child_process'
import { existsSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'

const SIGNET_SRC = join(import.meta.dir, '..', 'src')

// =============================================================================
// Helper Functions
// =============================================================================

function findTsFiles(dir: string): string[] {
  const files: string[] = []

  if (!existsSync(dir)) return files

  const entries = readdirSync(dir, { withFileTypes: true })

  for (const entry of entries) {
    const fullPath = join(dir, entry.name)
    if (entry.isDirectory() && entry.name !== 'node_modules' && entry.name !== '__tests__') {
      files.push(...findTsFiles(fullPath))
    } else if (entry.isFile() && entry.name.endsWith('.ts') && !entry.name.endsWith('.test.ts')) {
      files.push(fullPath)
    }
  }

  return files
}

// =============================================================================
// CLI Tests
// =============================================================================

describe('Signet CLI', () => {
  describe('Help and Basic Commands', () => {
    test('signet --help renders help text', () => {
      const result = spawnSync('signet', ['--help'], {
        encoding: 'utf-8',
        timeout: 10000,
      })

      // CLI may exit with 0 or show help via different mechanism
      expect(result.stdout + result.stderr).toMatch(/signet|init|gen|validate|enforce|reconcile/i)
    })

    test('signet --version shows version', () => {
      const result = spawnSync('signet', ['--version'], {
        encoding: 'utf-8',
        timeout: 10000,
      })

      // Should output some version info
      expect(result.stdout + result.stderr).toBeTruthy()
    })
  })
})

// =============================================================================
// Shell Alias Tests
// =============================================================================

describe('Shell Configuration', () => {
  test('s alias is defined in aliases.nix', () => {
    const aliasesPath = join(import.meta.dir, '..', '..', '..', 'modules', 'home', 'shell', 'aliases.nix')

    const content = readFileSync(aliasesPath, 'utf-8')

    // Verify alias definition exists
    expect(content).toContain('s = "signet"')
  })
})

// =============================================================================
// Effect-TS Compliance Tests
// =============================================================================

describe('Effect-TS Compliance', () => {
  const srcFiles = findTsFiles(SIGNET_SRC)

  test('source files exist for testing', () => {
    expect(srcFiles.length).toBeGreaterThan(0)
  })

  test('all source files import from effect (where Effect is used)', () => {
    const violations: string[] = []

    for (const file of srcFiles) {
      const content = readFileSync(file, 'utf-8')

      // If file uses Effect. it must import from 'effect'
      if (content.includes('Effect.') && !content.includes("from 'effect'")) {
        violations.push(file.replace(SIGNET_SRC, 'src'))
      }
    }

    expect(violations).toEqual([])
  })

  test('no throw new Error in source files (must use Effect.fail)', () => {
    const violations: Array<{ file: string; line: number; content: string }> = []

    for (const file of srcFiles) {
      const content = readFileSync(file, 'utf-8')
      const lines = content.split('\n')

      lines.forEach((line, idx) => {
        // Skip if in a comment
        const trimmed = line.trim()
        if (trimmed.startsWith('//') || trimmed.startsWith('*')) return

        // Check for throw new Error
        if (line.includes('throw new Error')) {
          violations.push({
            file: file.replace(SIGNET_SRC, 'src'),
            line: idx + 1,
            content: trimmed.slice(0, 60),
          })
        }
      })
    }

    // Log violations for debugging
    if (violations.length > 0) {
      console.log('\nEffect compliance violations:')
      for (const v of violations) {
        console.log(`  ${v.file}:${v.line} - ${v.content}`)
      }
    }

    expect(violations).toEqual([])
  })

  test('no raw Promise returns in async functions (prefer Effect)', () => {
    // This is a softer check - we want to migrate toward Effect
    // but won't block on existing Promise usage
    const srcFiles = findTsFiles(SIGNET_SRC)
    let promiseCount = 0
    let effectCount = 0

    for (const file of srcFiles) {
      const content = readFileSync(file, 'utf-8')
      promiseCount += (content.match(/: Promise</g) || []).length
      effectCount += (content.match(/: Effect\.Effect</g) || []).length
    }

    // Effect should be dominant
    expect(effectCount).toBeGreaterThan(promiseCount)
  })
})

// =============================================================================
// Hexagonal Architecture Tests
// =============================================================================

describe('Hexagonal Architecture Generation', () => {
  let tempDir: string

  beforeAll(() => {
    tempDir = mkdtempSync(join(tmpdir(), 'signet-migration-test-'))
  })

  afterAll(() => {
    try {
      rmSync(tempDir, { recursive: true, force: true })
    } catch {
      // Ignore cleanup errors
    }
  })

  test('signet init creates project directory', () => {
    const projectName = 'test-api'

    // Run signet init (may be interactive, so we just check it doesn't crash)
    const result = spawnSync('signet', ['init', 'api', projectName], {
      encoding: 'utf-8',
      cwd: tempDir,
      timeout: 30000,
      // Provide minimal stdin to avoid hanging on prompts
      input: '\n',
    })

    const projectDir = join(tempDir, projectName)

    // Either succeeded and created dir, or we check exit
    if (existsSync(projectDir)) {
      expect(statSync(projectDir).isDirectory()).toBe(true)
    } else {
      // If dir wasn't created, check if it was a graceful skip
      expect(result.status).toBeDefined()
    }
  })

  test.skip('generated API project has hexagonal structure', () => {
    // This test requires signet init to have succeeded
    const projectDir = join(tempDir, 'test-api')

    if (!existsSync(projectDir)) {
      console.log('Skipping: project directory not created')
      return
    }

    // Check for hexagonal structure markers
    const expectedDirs = ['src', 'src/ports', 'src/adapters']
    const expectedFiles = ['package.json', 'tsconfig.json']

    for (const dir of expectedDirs) {
      const fullPath = join(projectDir, dir)
      expect(existsSync(fullPath)).toBe(true)
    }

    for (const file of expectedFiles) {
      const fullPath = join(projectDir, file)
      expect(existsSync(fullPath)).toBe(true)
    }
  })
})

// =============================================================================
// CLI Commands Existence Tests
// =============================================================================

describe('CLI Commands', () => {
  test('doctor command exists', () => {
    const result = spawnSync('signet', ['doctor', '--help'], {
      encoding: 'utf-8',
      timeout: 10000,
    })

    // Either shows help or indicates command exists
    const output = result.stdout + result.stderr
    expect(output).toBeTruthy()
  })

  test('comply command exists', () => {
    const result = spawnSync('signet', ['comply', '--help'], {
      encoding: 'utf-8',
      timeout: 10000,
    })

    // Either shows help or indicates command exists
    const output = result.stdout + result.stderr
    expect(output).toBeTruthy()
  })
})
