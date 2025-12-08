/**
 * Max Rigor Test Suite
 *
 * Comprehensive verification of Signet's formal architecture enforcement:
 * 1. Version Unity - All generated code uses versions.json as single source of truth
 * 2. Hexagonal Purity - Routes are framework-agnostic (no Hono in handlers)
 * 3. Hook Enforcement - Version auto-correction works correctly
 *
 * @see Operation Signet: Max Rigor Upgrade (December 2025)
 */
import { describe, test, expect, beforeEach, afterEach } from 'bun:test'
import { mkdtempSync, writeFileSync, readFileSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { Effect } from 'effect'

// Import from signet
import versions from '../../versions.json'
import { generateCore } from '../generators/core'
import { generateApi } from '../generators/api'
import { generateMonorepo } from '../generators/monorepo'
import { TemplateEngineLive } from '../layers/template-engine'

// =============================================================================
// Test Helpers
// =============================================================================

const runGenerator = <T>(effect: Effect.Effect<T, Error, unknown>) =>
  Effect.runPromise(effect.pipe(Effect.provide(TemplateEngineLive)))

const createSpec = (
  name: string,
  type: 'library' | 'api' | 'monorepo',
  database?: 'turso' | 'd1'
) => ({
  name,
  type,
  infra: { runtime: 'bun' as const, database },
  observability: { processCompose: true as const, metrics: false, debugger: 'vscode' as const },
})

// =============================================================================
// 1. VERSION UNITY TESTS
// =============================================================================

describe('Max Rigor: Version Unity', () => {
  test('versions.json contains all required npm packages', () => {
    const npmVersions = versions.npm as Record<string, string>
    const required = [
      'typescript',
      'zod',
      '@biomejs/biome',
      '@types/bun',
      'effect',
      'hono',
      'drizzle-orm',
      'react',
      'react-dom',
    ]

    for (const pkg of required) {
      expect(npmVersions[pkg]).toBeDefined()
      expect(npmVersions[pkg]).toMatch(/^\d+\.\d+\.\d+$/)
    }
  })

  test('zod is v4+ (not v3)', () => {
    const npmVersions = versions.npm as Record<string, string>
    const zodVersion = npmVersions['zod']
    const major = parseInt(zodVersion.split('.')[0], 10)
    expect(major).toBeGreaterThanOrEqual(4)
  })

  test('effect is v3.19+', () => {
    const npmVersions = versions.npm as Record<string, string>
    const effectVersion = npmVersions['effect']
    const [major, minor] = effectVersion.split('.').map(Number)
    expect(major).toBeGreaterThanOrEqual(3)
    if (major === 3) {
      expect(minor).toBeGreaterThanOrEqual(19)
    }
  })

  test('core generator produces package.json with versions.json zod', async () => {
    const spec = createSpec('test-project', 'library')
    const tree = await runGenerator(generateCore(spec))

    const pkgJson = JSON.parse(tree['package.json'])
    const npmVersions = versions.npm as Record<string, string>

    expect(pkgJson.dependencies.zod).toContain(npmVersions['zod'])
  })

  test('core generator uses versions.json typescript', async () => {
    const spec = createSpec('test-project', 'library')
    const tree = await runGenerator(generateCore(spec))

    const pkgJson = JSON.parse(tree['package.json'])
    const npmVersions = versions.npm as Record<string, string>

    expect(pkgJson.devDependencies.typescript).toContain(npmVersions['typescript'])
  })

  test('core generator uses versions.json biome', async () => {
    const spec = createSpec('test-project', 'library')
    const tree = await runGenerator(generateCore(spec))

    const pkgJson = JSON.parse(tree['package.json'])
    const npmVersions = versions.npm as Record<string, string>

    expect(pkgJson.devDependencies['@biomejs/biome']).toContain(npmVersions['@biomejs/biome'])
  })

  test('monorepo generator uses versions.json for root and shared packages', async () => {
    const spec = createSpec('test-mono', 'monorepo')
    const tree = await runGenerator(generateMonorepo(spec))

    const npmVersions = versions.npm as Record<string, string>

    // Root package.json
    const rootPkg = JSON.parse(tree['package.json'])
    expect(rootPkg.devDependencies['@biomejs/biome']).toContain(npmVersions['@biomejs/biome'])
    expect(rootPkg.devDependencies.typescript).toContain(npmVersions['typescript'])

    // Shared package.json
    const sharedPkg = JSON.parse(tree['packages/shared/package.json'])
    expect(sharedPkg.dependencies.zod).toContain(npmVersions['zod'])
  })
})

// =============================================================================
// 2. HEXAGONAL PURITY TESTS
// =============================================================================

describe('Max Rigor: Hexagonal Purity', () => {
  test('API handlers do NOT import Hono directly', async () => {
    const spec = createSpec('test-api', 'api')
    const tree = await runGenerator(generateApi(spec))

    // Check all files in handlers/ directory
    for (const [path, content] of Object.entries(tree)) {
      if (path.includes('handlers/') && path.endsWith('.ts')) {
        expect(content).not.toContain("from 'hono'")
        expect(content).not.toContain('from "hono"')
      }
    }
  })

  test('API handlers use Effect for business logic', async () => {
    const spec = createSpec('test-api', 'api')
    const tree = await runGenerator(generateApi(spec))

    const healthHandler = tree['src/handlers/health.ts']
    expect(healthHandler).toBeDefined()
    expect(healthHandler).toContain("import { Effect } from 'effect'")
    expect(healthHandler).toContain('Effect.succeed')
  })

  test('server.ts (composition root) IS allowed to import Hono', async () => {
    const spec = createSpec('test-api', 'api')
    const tree = await runGenerator(generateApi(spec))

    const serverTs = tree['src/server.ts']
    expect(serverTs).toBeDefined()
    expect(serverTs).toContain("from 'hono'")
    expect(serverTs).toContain('This is the ONLY file that should import Hono directly')
  })

  test('API generates ports with Context.Tag', async () => {
    const spec = createSpec('test-api', 'api', 'turso')
    const tree = await runGenerator(generateApi(spec))

    const databasePort = tree['src/ports/database.ts']
    expect(databasePort).toBeDefined()
    expect(databasePort).toContain('Context.Tag')
    expect(databasePort).toContain('class Database extends Context.Tag')
  })

  test('API generates adapters with Layer', async () => {
    const spec = createSpec('test-api', 'api', 'turso')
    const tree = await runGenerator(generateApi(spec))

    const tursoAdapter = tree['src/adapters/turso.ts']
    expect(tursoAdapter).toBeDefined()
    expect(tursoAdapter).toContain('Layer.succeed')
    expect(tursoAdapter).toContain('TursoLive')
  })

  test('server.ts wires Effect handlers to Hono routes', async () => {
    const spec = createSpec('test-api', 'api')
    const tree = await runGenerator(generateApi(spec))

    const serverTs = tree['src/server.ts']
    expect(serverTs).toContain('Runtime.runPromise')
    expect(serverTs).toContain('healthRoutes')
    expect(serverTs).toContain('route.handler')
  })
})

// =============================================================================
// 3. HOOK ENFORCEMENT TESTS
// =============================================================================

describe('Max Rigor: Hook Enforcement', () => {
  const hookPath = join(
    import.meta.dir,
    '../../../claude-code/evolution/hooks/enforce-versions.ts'
  )
  let tempDir: string
  let versionsPath: string

  beforeEach(() => {
    tempDir = mkdtempSync(join(tmpdir(), 'max-rigor-hook-test-'))
    versionsPath = join(tempDir, 'versions.json')

    // Use actual versions.json content
    writeFileSync(versionsPath, JSON.stringify(versions, null, 2))
  })

  afterEach(() => {
    rmSync(tempDir, { recursive: true, force: true })
  })

  test('hook auto-corrects outdated zod version to 4.1.13', async () => {
    const pkgPath = join(tempDir, 'package.json')
    const oldPkg = {
      name: 'test',
      dependencies: { zod: '^3.24.0' },
    }
    writeFileSync(pkgPath, JSON.stringify(oldPkg, null, 2))

    const input = JSON.stringify({
      hook_event_name: 'PostToolUse',
      tool_name: 'Write',
      tool_input: { file_path: pkgPath },
    })

    const proc = Bun.spawn(['bun', 'run', hookPath], {
      stdin: new Blob([input]),
      stdout: 'pipe',
      env: { ...process.env, SIGNET_VERSIONS: versionsPath },
    })

    await proc.exited
    const output = JSON.parse(await new Response(proc.stdout).text())

    expect(output.continue).toBe(true)
    expect(output.additionalContext).toContain('Auto-corrected')
    expect(output.additionalContext).toContain('zod')

    // Verify the actual file was corrected
    const updatedPkg = JSON.parse(readFileSync(pkgPath, 'utf-8'))
    const npmVersions = versions.npm as Record<string, string>
    expect(updatedPkg.dependencies.zod).toBe(`^${npmVersions['zod']}`)
  })

  test('hook does not modify packages not in enforced list', async () => {
    const pkgPath = join(tempDir, 'package.json')
    const pkg = {
      name: 'test',
      dependencies: {
        lodash: '^4.0.0',
        zod: '^4.1.13', // Already correct
      },
    }
    writeFileSync(pkgPath, JSON.stringify(pkg, null, 2))

    const input = JSON.stringify({
      hook_event_name: 'PostToolUse',
      tool_name: 'Write',
      tool_input: { file_path: pkgPath },
    })

    const proc = Bun.spawn(['bun', 'run', hookPath], {
      stdin: new Blob([input]),
      stdout: 'pipe',
      env: { ...process.env, SIGNET_VERSIONS: versionsPath },
    })

    await proc.exited
    const output = JSON.parse(await new Response(proc.stdout).text())

    expect(output.continue).toBe(true)
    expect(output.additionalContext).toBeUndefined() // No corrections

    // Lodash unchanged
    const updatedPkg = JSON.parse(readFileSync(pkgPath, 'utf-8'))
    expect(updatedPkg.dependencies.lodash).toBe('^4.0.0')
  })
})

// =============================================================================
// 4. INTEGRATION TESTS
// =============================================================================

describe('Max Rigor: Integration', () => {
  test('complete API project structure is valid', async () => {
    const spec = createSpec('ember-api', 'api', 'turso')
    const tree = await runGenerator(generateApi(spec))

    // Core files exist
    expect(tree['src/server.ts']).toBeDefined()
    expect(tree['src/index.ts']).toBeDefined()
    expect(tree['wrangler.toml']).toBeDefined()

    // Hexagonal structure exists
    expect(tree['src/handlers/health.ts']).toBeDefined()
    expect(tree['src/middleware/error.ts']).toBeDefined()
    expect(tree['src/ports/database.ts']).toBeDefined()
    expect(tree['src/adapters/turso.ts']).toBeDefined()

    // No forbidden patterns
    const allContent = Object.values(tree).join('\n')
    expect(allContent).not.toContain('any:')
    expect(allContent).not.toContain(': any')
  })

  test('handlers export route definitions with metadata', async () => {
    const spec = createSpec('test-api', 'api')
    const tree = await runGenerator(generateApi(spec))

    const healthHandler = tree['src/handlers/health.ts']

    // Must export route metadata for composition
    expect(healthHandler).toContain('healthRoutes')
    expect(healthHandler).toContain("method: 'GET'")
    expect(healthHandler).toContain("path: '/health'")
    expect(healthHandler).toContain('handler:')
  })
})
