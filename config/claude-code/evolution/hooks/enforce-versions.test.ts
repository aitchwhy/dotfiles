/**
 * Version Enforcer Hook Tests
 *
 * Tests for the PostToolUse hook that auto-corrects package.json versions.
 */
import { describe, test, expect, beforeEach, afterEach } from 'bun:test'
import { mkdtempSync, writeFileSync, readFileSync, rmSync, mkdirSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'

describe('enforce-versions hook', () => {
  const hookPath = join(import.meta.dir, 'enforce-versions.ts')
  let tempDir: string
  let versionsPath: string

  beforeEach(() => {
    // Create temp directory for test files
    tempDir = mkdtempSync(join(tmpdir(), 'enforce-versions-test-'))

    // Create mock versions.json
    versionsPath = join(tempDir, 'versions.json')
    const mockVersions = {
      npm: {
        zod: '4.1.13',
        typescript: '5.9.3',
        '@biomejs/biome': '2.3.8',
        '@types/bun': '1.2.10',
        effect: '3.19.9',
        hono: '4.10.7',
        'drizzle-orm': '0.45.0',
        react: '19.2.1',
        'react-dom': '19.2.1',
      },
      runtime: {
        bun: '1.3.4',
        node: '22.12.0',
      },
    }
    writeFileSync(versionsPath, JSON.stringify(mockVersions, null, 2))
  })

  afterEach(() => {
    rmSync(tempDir, { recursive: true, force: true })
  })

  test('allows non-Write tool calls', async () => {
    const input = JSON.stringify({
      hook_event_name: 'PostToolUse',
      tool_name: 'Read',
      tool_input: { file_path: '/some/file.ts' },
    })

    const proc = Bun.spawn(['bun', 'run', hookPath], {
      stdin: new Blob([input]),
      stdout: 'pipe',
      env: { ...process.env, SIGNET_VERSIONS: versionsPath },
    })

    await proc.exited
    const output = JSON.parse(await new Response(proc.stdout).text())

    expect(output.continue).toBe(true)
    expect(output.additionalContext).toBeUndefined()
  })

  test('allows non-package.json writes', async () => {
    const input = JSON.stringify({
      hook_event_name: 'PostToolUse',
      tool_name: 'Write',
      tool_input: { file_path: '/some/file.ts' },
    })

    const proc = Bun.spawn(['bun', 'run', hookPath], {
      stdin: new Blob([input]),
      stdout: 'pipe',
      env: { ...process.env, SIGNET_VERSIONS: versionsPath },
    })

    await proc.exited
    const output = JSON.parse(await new Response(proc.stdout).text())

    expect(output.continue).toBe(true)
    expect(output.additionalContext).toBeUndefined()
  })

  test('auto-corrects outdated zod version', async () => {
    // Create package.json with old zod version
    const pkgPath = join(tempDir, 'package.json')
    const oldPkg = {
      name: 'test-project',
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

    // Verify hook reported correction
    expect(output.continue).toBe(true)
    expect(output.additionalContext).toContain('Auto-corrected')
    expect(output.additionalContext).toContain('zod')

    // Verify file was updated
    const updatedPkg = JSON.parse(readFileSync(pkgPath, 'utf-8'))
    expect(updatedPkg.dependencies.zod).toBe('^4.1.13')
  })

  test('auto-corrects multiple outdated versions', async () => {
    const pkgPath = join(tempDir, 'package.json')
    const oldPkg = {
      name: 'test-project',
      dependencies: {
        zod: '^3.24.0',
        effect: '^3.0.0',
      },
      devDependencies: {
        typescript: '^5.0.0',
        '@biomejs/biome': '^1.0.0',
      },
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

    // Verify all versions were updated
    const updatedPkg = JSON.parse(readFileSync(pkgPath, 'utf-8'))
    expect(updatedPkg.dependencies.zod).toBe('^4.1.13')
    expect(updatedPkg.dependencies.effect).toBe('^3.19.9')
    expect(updatedPkg.devDependencies.typescript).toBe('^5.9.3')
    expect(updatedPkg.devDependencies['@biomejs/biome']).toBe('^2.3.8')
  })

  test('does not modify already correct versions', async () => {
    const pkgPath = join(tempDir, 'package.json')
    const correctPkg = {
      name: 'test-project',
      dependencies: { zod: '^4.1.13' },
      devDependencies: { typescript: '^5.9.3' },
    }
    writeFileSync(pkgPath, JSON.stringify(correctPkg, null, 2))

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

    // Should continue without additional context (no corrections)
    expect(output.continue).toBe(true)
    expect(output.additionalContext).toBeUndefined()
  })

  test('ignores non-enforced packages', async () => {
    const pkgPath = join(tempDir, 'package.json')
    const pkg = {
      name: 'test-project',
      dependencies: {
        lodash: '^4.0.0', // Not in enforced list
        zod: '^4.1.13', // Correct version
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
    expect(output.additionalContext).toBeUndefined()

    // Lodash should be unchanged
    const updatedPkg = JSON.parse(readFileSync(pkgPath, 'utf-8'))
    expect(updatedPkg.dependencies.lodash).toBe('^4.0.0')
  })

  test('handles malformed package.json gracefully', async () => {
    const pkgPath = join(tempDir, 'package.json')
    writeFileSync(pkgPath, 'not valid json {{{')

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

    // Should fail-safe and continue
    expect(output.continue).toBe(true)
  })

  test('handles missing versions.json gracefully', async () => {
    const pkgPath = join(tempDir, 'package.json')
    writeFileSync(pkgPath, JSON.stringify({ name: 'test', dependencies: { zod: '^3.0.0' } }))

    const input = JSON.stringify({
      hook_event_name: 'PostToolUse',
      tool_name: 'Write',
      tool_input: { file_path: pkgPath },
    })

    const proc = Bun.spawn(['bun', 'run', hookPath], {
      stdin: new Blob([input]),
      stdout: 'pipe',
      env: { ...process.env, SIGNET_VERSIONS: '/nonexistent/versions.json' },
    })

    await proc.exited
    const output = JSON.parse(await new Response(proc.stdout).text())

    // Should fail-safe and continue
    expect(output.continue).toBe(true)
  })
})
