/**
 * AtomicGitSentinel Hook Tests
 *
 * Tests for the auto-committing PostToolUse hook.
 * This hook REPLACES semantic-commit-sentinel.ts.
 *
 * Run: bun test config/claude-code/evolution/hooks/atomic-git-sentinel.test.ts
 */
import { afterEach, beforeEach, describe, expect, test } from 'bun:test'
import { execSync } from 'node:child_process'
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'

// =============================================================================
// Test Utilities
// =============================================================================

interface HookOutput {
  continue: boolean
  additionalContext?: string
}

async function runHook(
  cwd: string,
  eventName: string,
  toolName?: string,
  toolInput?: Record<string, unknown>
): Promise<HookOutput> {
  const hookPath = join(import.meta.dir, 'atomic-git-sentinel.ts')

  const input = JSON.stringify({
    hook_event_name: eventName,
    session_id: 'test-session',
    tool_name: toolName,
    tool_input: toolInput || {},
    cwd,
  })

  const proc = Bun.spawn(['bun', 'run', hookPath], {
    stdin: new Blob([input]),
    stdout: 'pipe',
    stderr: 'pipe',
    cwd,
    env: { ...process.env, HOME: process.env.HOME },
  })

  const output = await new Response(proc.stdout).text()
  await proc.exited

  try {
    return JSON.parse(output.trim())
  } catch {
    return { continue: true }
  }
}

function initTestRepo(dir: string): void {
  execSync('git init', { cwd: dir, stdio: 'pipe' })
  execSync('git config user.email "test@test.com"', { cwd: dir, stdio: 'pipe' })
  execSync('git config user.name "Test User"', { cwd: dir, stdio: 'pipe' })
  // Initial commit required for diff to work
  writeFileSync(join(dir, '.gitkeep'), '')
  execSync('git add . && git commit -m "chore: initial commit"', { cwd: dir, stdio: 'pipe' })
}

function getLastCommitMessage(dir: string): string {
  return execSync('git log -1 --format=%s', { cwd: dir, encoding: 'utf-8' }).trim()
}

function getCommitCount(dir: string): number {
  const output = execSync('git rev-list --count HEAD', { cwd: dir, encoding: 'utf-8' }).trim()
  return parseInt(output, 10)
}

// =============================================================================
// Tests
// =============================================================================

describe('AtomicGitSentinel Hook', () => {
  let tempDir: string

  beforeEach(() => {
    tempDir = mkdtempSync(join(tmpdir(), 'atomic-git-test-'))
    initTestRepo(tempDir)
  })

  afterEach(() => {
    try {
      rmSync(tempDir, { recursive: true, force: true })
    } catch {
      // Ignore cleanup errors
    }
  })

  describe('trigger conditions', () => {
    test('only triggers on PostToolUse event', async () => {
      writeFileSync(join(tempDir, 'test.ts'), 'export const x = 1;')
      const initialCount = getCommitCount(tempDir)

      // Should NOT trigger on other events
      await runHook(tempDir, 'PreToolUse', 'Write', { file_path: join(tempDir, 'test.ts') })
      await runHook(tempDir, 'SessionStart', 'Write', { file_path: join(tempDir, 'test.ts') })
      await runHook(tempDir, 'Stop', 'Write', { file_path: join(tempDir, 'test.ts') })

      expect(getCommitCount(tempDir)).toBe(initialCount)
    })

    test('only triggers on Write/Edit/MultiEdit tools', async () => {
      writeFileSync(join(tempDir, 'test.ts'), 'export const x = 1;')
      const initialCount = getCommitCount(tempDir)

      // Should NOT trigger on other tools
      await runHook(tempDir, 'PostToolUse', 'Read', { file_path: join(tempDir, 'test.ts') })
      await runHook(tempDir, 'PostToolUse', 'Grep', { pattern: 'x' })
      await runHook(tempDir, 'PostToolUse', 'Bash', { command: 'ls' })

      expect(getCommitCount(tempDir)).toBe(initialCount)
    })

    test('triggers on Write tool', async () => {
      writeFileSync(join(tempDir, 'feature.ts'), 'export const feature = true;')
      const initialCount = getCommitCount(tempDir)

      const result = await runHook(tempDir, 'PostToolUse', 'Write', {
        file_path: join(tempDir, 'feature.ts'),
      })

      expect(result.continue).toBe(true)
      expect(getCommitCount(tempDir)).toBe(initialCount + 1)
    })

    test('triggers on Edit tool', async () => {
      // Create and commit a file first
      writeFileSync(join(tempDir, 'existing.ts'), 'export const old = 1;')
      execSync('git add . && git commit -m "feat: add existing"', { cwd: tempDir, stdio: 'pipe' })

      // Modify the file
      writeFileSync(join(tempDir, 'existing.ts'), 'export const updated = 2;')
      const initialCount = getCommitCount(tempDir)

      const result = await runHook(tempDir, 'PostToolUse', 'Edit', {
        file_path: join(tempDir, 'existing.ts'),
      })

      expect(result.continue).toBe(true)
      expect(getCommitCount(tempDir)).toBe(initialCount + 1)
    })

    test('triggers on MultiEdit tool', async () => {
      writeFileSync(join(tempDir, 'multi.ts'), 'export const multi = true;')
      const initialCount = getCommitCount(tempDir)

      const result = await runHook(tempDir, 'PostToolUse', 'MultiEdit', {
        file_path: join(tempDir, 'multi.ts'),
      })

      expect(result.continue).toBe(true)
      expect(getCommitCount(tempDir)).toBe(initialCount + 1)
    })
  })

  describe('commit behavior', () => {
    test('does not commit when no changes exist', async () => {
      const initialCount = getCommitCount(tempDir)

      const result = await runHook(tempDir, 'PostToolUse', 'Write', {
        file_path: join(tempDir, 'nonexistent.ts'),
      })

      expect(result.continue).toBe(true)
      expect(getCommitCount(tempDir)).toBe(initialCount)
    })

    test('creates commit with conventional message', async () => {
      writeFileSync(join(tempDir, 'handler.ts'), 'export const handler = () => {};')

      await runHook(tempDir, 'PostToolUse', 'Write', {
        file_path: join(tempDir, 'handler.ts'),
      })

      const message = getLastCommitMessage(tempDir)
      // Should match conventional commit format: type(scope): description
      expect(message).toMatch(/^(feat|fix|test|docs|chore|refactor|perf|ci)\([^)]+\): .+$/)
    })

    test('never pushes (only commits locally)', async () => {
      writeFileSync(join(tempDir, 'local.ts'), 'export const local = true;')

      const result = await runHook(tempDir, 'PostToolUse', 'Write', {
        file_path: join(tempDir, 'local.ts'),
      })

      expect(result.continue).toBe(true)
      // No remote configured, push would fail - verify no error in additionalContext
      if (result.additionalContext) {
        expect(result.additionalContext.toLowerCase()).not.toContain('push')
      }
    })

    test('reports commit in additionalContext', async () => {
      writeFileSync(join(tempDir, 'report.ts'), 'export const report = true;')

      const result = await runHook(tempDir, 'PostToolUse', 'Write', {
        file_path: join(tempDir, 'report.ts'),
      })

      expect(result.additionalContext).toBeDefined()
      expect(result.additionalContext).toContain('Committed')
    })
  })

  describe('commit message inference', () => {
    test('infers feat for new source files', async () => {
      writeFileSync(join(tempDir, 'newfeature.ts'), 'export const feature = true;')

      await runHook(tempDir, 'PostToolUse', 'Write', {
        file_path: join(tempDir, 'newfeature.ts'),
      })

      const message = getLastCommitMessage(tempDir)
      expect(message).toMatch(/^feat\(/)
    })

    test('infers test for test files', async () => {
      writeFileSync(join(tempDir, 'user.test.ts'), 'test("user", () => {});')

      await runHook(tempDir, 'PostToolUse', 'Write', {
        file_path: join(tempDir, 'user.test.ts'),
      })

      const message = getLastCommitMessage(tempDir)
      expect(message).toMatch(/^test\(/)
    })

    test('infers docs for markdown files', async () => {
      writeFileSync(join(tempDir, 'README.md'), '# Project\n\nDocumentation')

      await runHook(tempDir, 'PostToolUse', 'Write', {
        file_path: join(tempDir, 'README.md'),
      })

      const message = getLastCommitMessage(tempDir)
      expect(message).toMatch(/^docs\(/)
    })

    test('infers chore for config files', async () => {
      writeFileSync(join(tempDir, 'tsconfig.json'), '{"compilerOptions": {}}')

      await runHook(tempDir, 'PostToolUse', 'Write', {
        file_path: join(tempDir, 'tsconfig.json'),
      })

      const message = getLastCommitMessage(tempDir)
      expect(message).toMatch(/^chore\(/)
    })

    test('includes filename in commit description', async () => {
      writeFileSync(join(tempDir, 'authentication.ts'), 'export const auth = {};')

      await runHook(tempDir, 'PostToolUse', 'Write', {
        file_path: join(tempDir, 'authentication.ts'),
      })

      const message = getLastCommitMessage(tempDir)
      expect(message.toLowerCase()).toContain('authentication')
    })
  })

  describe('error handling', () => {
    test('continues gracefully when not in git repo', async () => {
      const nonGitDir = mkdtempSync(join(tmpdir(), 'non-git-'))
      writeFileSync(join(nonGitDir, 'file.ts'), 'export const x = 1;')

      const result = await runHook(nonGitDir, 'PostToolUse', 'Write', {
        file_path: join(nonGitDir, 'file.ts'),
      })

      expect(result.continue).toBe(true)

      rmSync(nonGitDir, { recursive: true, force: true })
    })

    test('continues gracefully with malformed input', async () => {
      const hookPath = join(import.meta.dir, 'atomic-git-sentinel.ts')

      const proc = Bun.spawn(['bun', 'run', hookPath], {
        stdin: new Blob(['not valid json']),
        stdout: 'pipe',
        stderr: 'pipe',
        cwd: tempDir,
      })

      const output = await new Response(proc.stdout).text()
      await proc.exited

      const result = JSON.parse(output.trim())
      expect(result.continue).toBe(true)
    })

    test('continues gracefully with empty input', async () => {
      const hookPath = join(import.meta.dir, 'atomic-git-sentinel.ts')

      const proc = Bun.spawn(['bun', 'run', hookPath], {
        stdin: new Blob(['']),
        stdout: 'pipe',
        stderr: 'pipe',
        cwd: tempDir,
      })

      const output = await new Response(proc.stdout).text()
      await proc.exited

      const result = JSON.parse(output.trim())
      expect(result.continue).toBe(true)
    })
  })
})
