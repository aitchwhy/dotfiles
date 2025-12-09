#!/usr/bin/env bun
/**
 * AtomicGitSentinel - Auto-commits logical units after file operations
 *
 * Trigger: PostToolUse on Write/Edit/MultiEdit operations
 * Mode: Execute (commits automatically, NEVER pushes)
 *
 * REPLACES: semantic-commit-sentinel.ts (which only proposed commits at Stop)
 *
 * Behavior:
 * 1. Detects changes via `git status --porcelain` after Write/Edit/MultiEdit
 * 2. Generates conventional commit message from file changes
 * 3. Executes `git add . && git commit -m "..."` automatically
 * 4. NEVER pushes (user privilege only)
 */

import { execSync } from 'node:child_process'

interface HookInput {
  hook_event_name: string
  session_id: string
  tool_name?: string
  tool_input?: Record<string, unknown>
  cwd?: string
}

interface HookOutput {
  continue: boolean
  additionalContext?: string
}

interface FileChange {
  path: string
  directory: string
  filename: string
  status: 'added' | 'modified' | 'deleted'
  isTest: boolean
  isConfig: boolean
  isDoc: boolean
}

// =============================================================================
// Commit Message Generation
// =============================================================================

/**
 * Infer commit type from file changes
 */
function inferCommitType(files: FileChange[]): string {
  const allTests = files.every((f) => f.isTest)
  const allDocs = files.every((f) => f.isDoc)
  const allConfigs = files.every((f) => f.isConfig)
  const allAdded = files.every((f) => f.status === 'added')
  const hasTests = files.some((f) => f.isTest)

  if (allTests) return 'test'
  if (allDocs) return 'docs'
  if (allConfigs) return 'chore'

  // New files = feature
  if (allAdded) return 'feat'

  // Source + test = feature
  if (hasTests) return 'feat'

  // Default for modifications
  return 'feat'
}

/**
 * Infer scope from file paths
 */
function inferScope(files: FileChange[]): string {
  const dirs = [...new Set(files.map((f) => f.directory))]

  if (dirs.length === 1 && dirs[0]) {
    const parts = dirs[0].split('/').filter(Boolean)
    if (parts.includes('hooks')) return 'hooks'
    if (parts.includes('layers')) return 'layers'
    if (parts.includes('generators')) return 'gen'
    if (parts.includes('enforcers')) return 'enforce'
    if (parts.includes('tests')) return 'test'
    if (parts.includes('src')) return parts[parts.length - 1] || 'src'
    return parts[parts.length - 1] || 'root'
  }

  return 'root'
}

/**
 * Generate conventional commit message from file changes
 */
function generateCommitMessage(files: FileChange[]): string {
  const type = inferCommitType(files)
  const scope = inferScope(files)

  // Generate description from filenames
  const names = files.map((f) =>
    f.filename
      .replace(/\.(ts|tsx|js|jsx|test|spec|md|json|nix|yaml|yml)$/g, '')
      .replace(/\.test$/, '')
      .replace(/\.spec$/, '')
  )
  const uniqueNames = [...new Set(names)].slice(0, 3)

  let description: string
  if (files.length === 1) {
    description = `update ${uniqueNames[0]}`
  } else if (uniqueNames.length <= 3) {
    description = `update ${uniqueNames.join(', ')}`
  } else {
    description = `update ${files.length} files`
  }

  return `${type}(${scope}): ${description}`
}

// =============================================================================
// Git Status Parsing
// =============================================================================

/**
 * Parse git status --porcelain output to get changed files
 */
function parseGitStatus(statusOutput: string): FileChange[] {
  const files: FileChange[] = []

  for (const line of statusOutput.split('\n')) {
    if (!line.trim()) continue

    // Format: XY PATH or XY ORIG -> PATH
    const statusCode = line.substring(0, 2)
    let path = line.substring(3).trim()

    // Handle renames: old -> new
    if (path.includes(' -> ')) {
      path = path.split(' -> ')[1]!
    }

    // Determine status
    let status: 'added' | 'modified' | 'deleted' = 'modified'
    if (statusCode.includes('A') || statusCode.includes('?')) status = 'added'
    if (statusCode.includes('D')) status = 'deleted'

    const parts = path.split('/')
    const filename = parts[parts.length - 1] || path
    const directory = parts.slice(0, -1).join('/')

    files.push({
      path,
      directory,
      filename,
      status,
      isTest: /\.(test|spec)\.(ts|tsx|js|jsx)$/.test(filename),
      isConfig:
        /\.(json|yaml|yml|toml|nix)$/.test(filename) ||
        filename.startsWith('.') ||
        filename === 'package.json' ||
        filename === 'tsconfig.json',
      isDoc: /\.(md|mdx|txt|rst)$/.test(filename),
    })
  }

  return files
}

// =============================================================================
// Main Hook Logic
// =============================================================================

async function main(): Promise<void> {
  let input: HookInput

  try {
    const rawInput = await Bun.stdin.text()
    if (!rawInput.trim()) {
      output({ continue: true })
      return
    }
    input = JSON.parse(rawInput)
  } catch {
    output({ continue: true })
    return
  }

  // Only trigger on PostToolUse
  if (input.hook_event_name !== 'PostToolUse') {
    output({ continue: true })
    return
  }

  // Only trigger on Write/Edit/MultiEdit
  const triggerTools = ['Write', 'Edit', 'MultiEdit']
  if (!input.tool_name || !triggerTools.includes(input.tool_name)) {
    output({ continue: true })
    return
  }

  const cwd = input.cwd || process.cwd()

  // Verify we're in a git repo
  try {
    execSync('git rev-parse --git-dir', { cwd, stdio: 'pipe' })
  } catch {
    output({ continue: true })
    return
  }

  // Get status of all changes (both staged and unstaged)
  let statusOutput: string
  try {
    statusOutput = execSync('git status --porcelain', { cwd, encoding: 'utf-8' }).trim()
  } catch {
    output({ continue: true })
    return
  }

  // No changes to commit
  if (!statusOutput) {
    output({ continue: true })
    return
  }

  // Parse changes
  const files = parseGitStatus(statusOutput)
  if (files.length === 0) {
    output({ continue: true })
    return
  }

  // Generate commit message
  const commitMessage = generateCommitMessage(files)

  // Execute atomic commit (add + commit, NEVER push)
  try {
    execSync('git add .', { cwd, stdio: 'pipe' })

    // Use heredoc-style commit to handle special characters
    const escapedMessage = commitMessage.replace(/"/g, '\\"')
    execSync(`git commit -m "${escapedMessage}"`, { cwd, stdio: 'pipe' })

    output({
      continue: true,
      additionalContext: `Committed: ${commitMessage}`,
    })
  } catch (e) {
    // Commit failed (maybe pre-commit hook blocked it, or nothing to commit)
    const errorMessage = e instanceof Error ? e.message : String(e)

    // Check if it's just "nothing to commit"
    if (errorMessage.includes('nothing to commit')) {
      output({ continue: true })
      return
    }

    output({
      continue: true,
      additionalContext: `Auto-commit skipped: ${errorMessage.slice(0, 100)}`,
    })
  }
}

function output(result: HookOutput): void {
  console.log(JSON.stringify(result))
}

main().catch(() => {
  output({ continue: true })
})
