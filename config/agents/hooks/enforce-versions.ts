#!/usr/bin/env bun
/**
 * Version Enforcer Hook
 *
 * PostToolUse hook that auto-corrects package.json versions on write.
 * Uses STACK from signet/src/stack as the single source of truth.
 *
 * Trigger: PostToolUse on Write to any package.json
 * Mode: Auto-correct with warning (PostToolUse cannot block)
 */

import { readFileSync, writeFileSync, existsSync } from 'node:fs'
import { join } from 'node:path'

// Import STACK from signet (absolute path for Bun)
let STACK: { npm: Record<string, string> }
try {
  const stackModule = await import(
    join(process.env.HOME ?? '', 'dotfiles/config/signet/src/stack/versions.ts')
  )
  STACK = stackModule.STACK
} catch {
  // Fallback to versions.json if STACK import fails
  const versionsPath = join(
    process.env.HOME ?? '',
    'dotfiles/config/signet/versions.json'
  )
  if (existsSync(versionsPath)) {
    STACK = JSON.parse(readFileSync(versionsPath, 'utf-8'))
  } else {
    STACK = { npm: {} }
  }
}

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

// Packages to enforce (only correct these - don't interfere with user choices)
// Synced with signet/src/stack/versions.ts npm section
const ENFORCED_PACKAGES = [
  // Core
  'zod',
  'typescript',
  '@biomejs/biome',
  '@types/bun',
  // Effect ecosystem
  'effect',
  '@effect/cli',
  '@effect/platform',
  '@effect/platform-node',
  // Backend
  'hono',
  'drizzle-orm',
  'drizzle-kit',
  // Frontend
  'react',
  'react-dom',
  '@tanstack/react-router',
  'tailwindcss',
  'xstate',
  '@xstate/react',
  // Testing
  'vitest',
  '@playwright/test',
  // Pulumi
  '@pulumi/pulumi',
  '@pulumi/gcp',
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

  // Use STACK.npm as source of truth
  const npmVersions = STACK.npm

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

Source: signet/src/stack/versions.ts (SSOT)`,
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
