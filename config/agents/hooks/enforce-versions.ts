#!/usr/bin/env bun
/**
 * Version Enforcer Hook
 *
 * PostToolUse hook that auto-corrects package.json versions on write.
 * Reads canonical versions from versions.json and corrects any
 * package.json that was just written with outdated or mismatched versions.
 *
 * Trigger: PostToolUse on Write to any package.json
 * Mode: Auto-correct with warning (PostToolUse cannot block)
 */

import { readFileSync, writeFileSync, existsSync } from 'node:fs'
import { join } from 'node:path'

// =============================================================================
// Types
// =============================================================================

interface HookInput {
  hook_event_name: string
  tool_name: string
  tool_input: {
    file_path?: string
    content?: string
  }
}

interface HookOutput {
  continue: boolean
  additionalContext?: string
}

// =============================================================================
// Configuration
// =============================================================================

const VERSIONS_PATH =
  process.env.SIGNET_VERSIONS ??
  join(process.env.HOME ?? '', 'dotfiles/config/signet/versions.json')

// Packages to enforce (only correct these - don't interfere with user choices)
const ENFORCED_PACKAGES = [
  'zod',
  'typescript',
  '@biomejs/biome',
  '@types/bun',
  'effect',
  'hono',
  'drizzle-orm',
  'react',
  'react-dom',
] as const

// =============================================================================
// Main Logic
// =============================================================================

async function main(): Promise<void> {
  let input: HookInput

  // Parse stdin
  try {
    const rawInput = await Bun.stdin.text()
    if (!rawInput.trim()) {
      return output({ continue: true })
    }
    input = JSON.parse(rawInput)
  } catch {
    // Fail-safe: on parse error, allow continuation
    return output({ continue: true })
  }

  // Only run on PostToolUse for Write to package.json
  if (input.hook_event_name !== 'PostToolUse') {
    return output({ continue: true })
  }

  if (input.tool_name !== 'Write') {
    return output({ continue: true })
  }

  const filePath = input.tool_input.file_path
  if (!filePath?.endsWith('package.json')) {
    return output({ continue: true })
  }

  // Load canonical versions
  if (!existsSync(VERSIONS_PATH)) {
    return output({ continue: true })
  }

  let versions: { npm: Record<string, string> }
  try {
    versions = JSON.parse(readFileSync(VERSIONS_PATH, 'utf-8'))
  } catch {
    return output({ continue: true })
  }

  const npmVersions = versions.npm

  // Read the just-written package.json
  let pkg: {
    dependencies?: Record<string, string>
    devDependencies?: Record<string, string>
  }
  try {
    pkg = JSON.parse(readFileSync(filePath, 'utf-8'))
  } catch {
    return output({ continue: true })
  }

  // Check and correct versions for enforced packages only
  const corrections: string[] = []

  for (const name of ENFORCED_PACKAGES) {
    const canonicalVersion = npmVersions[name]
    if (!canonicalVersion) continue

    // Check dependencies
    if (pkg.dependencies?.[name]) {
      const current = pkg.dependencies[name]
      if (!current.includes(canonicalVersion)) {
        corrections.push(`${name}: ${current} → ^${canonicalVersion}`)
        pkg.dependencies[name] = `^${canonicalVersion}`
      }
    }

    // Check devDependencies
    if (pkg.devDependencies?.[name]) {
      const current = pkg.devDependencies[name]
      if (!current.includes(canonicalVersion)) {
        corrections.push(`${name}: ${current} → ^${canonicalVersion}`)
        pkg.devDependencies[name] = `^${canonicalVersion}`
      }
    }
  }

  // Write corrected package.json if needed
  if (corrections.length > 0) {
    writeFileSync(filePath, JSON.stringify(pkg, null, 2) + '\n')
    return output({
      continue: true,
      additionalContext: `📦 Auto-corrected versions in ${filePath}:
${corrections.map((c) => `  • ${c}`).join('\n')}

Source: ${VERSIONS_PATH}`,
    })
  }

  output({ continue: true })
}

function output(result: HookOutput): void {
  console.log(JSON.stringify(result))
}

main().catch(() => {
  // Fail-safe: on any error, allow continuation
  output({ continue: true })
})
