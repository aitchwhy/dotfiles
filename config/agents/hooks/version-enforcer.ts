#!/usr/bin/env bun
/**
 * Version Enforcer Hook - Warns if project dependencies are below minimum versions
 *
 * Trigger: SessionStart
 * Mode: Warn only (non-blocking)
 *
 * Checks package.json in current working directory against minimum versions
 * from VERSIONS.md. Returns warnings in additionalContext.
 */

import { existsSync, readFileSync } from 'node:fs';

// Minimum acceptable versions (from VERSIONS.md)
const MIN_VERSIONS: Record<string, string> = {
  bun: '1.3.0',
  typescript: '5.9.0',
  zod: '4.0.0',
  biome: '2.3.0',
  effect: '3.19.0',
  '@biomejs/biome': '2.3.0',
  hono: '4.0.0',
  react: '19.0.0',
  'react-dom': '19.0.0',
};

interface HookInput {
  hook_event_name: string;
  session_id: string;
  cwd?: string;
}

interface HookOutput {
  continue: boolean;
  additionalContext?: string;
}

/**
 * Compare two semver versions
 * Returns: -1 if a < b, 0 if a == b, 1 if a > b
 */
function compareVersions(a: string, b: string): number {
  const normalize = (v: string) =>
    v
      .replace(/^[\^~>=<]+/, '')
      .split('.')
      .map((n) => Number.parseInt(n, 10) || 0);

  const pa = normalize(a);
  const pb = normalize(b);

  for (let i = 0; i < 3; i++) {
    const va = pa[i] || 0;
    const vb = pb[i] || 0;
    if (va > vb) return 1;
    if (va < vb) return -1;
  }
  return 0;
}

async function main(): Promise<void> {
  // Parse input from stdin
  let input: HookInput;
  try {
    const rawInput = await Bun.stdin.text();
    if (!rawInput.trim()) {
      output({ continue: true });
      return;
    }
    input = JSON.parse(rawInput);
  } catch {
    output({ continue: true });
    return;
  }

  // Only run on SessionStart
  if (input.hook_event_name !== 'SessionStart') {
    output({ continue: true });
    return;
  }

  const cwd = input.cwd || process.cwd();
  const pkgPath = `${cwd}/package.json`;

  // Skip if no package.json
  if (!existsSync(pkgPath)) {
    output({ continue: true });
    return;
  }

  // Check versions
  const warnings: string[] = [];
  try {
    const pkg = JSON.parse(readFileSync(pkgPath, 'utf-8'));
    const deps = { ...pkg.dependencies, ...pkg.devDependencies };

    for (const [name, minVersion] of Object.entries(MIN_VERSIONS)) {
      const installed = deps[name];
      if (installed && compareVersions(installed, minVersion) < 0) {
        warnings.push(`${name}: ${installed} < ${minVersion} (minimum)`);
      }
    }
  } catch {
    // Can't read package.json - continue silently
    output({ continue: true });
    return;
  }

  // Return result
  if (warnings.length > 0) {
    output({
      continue: true,
      additionalContext: `⚠️ Version warnings in ${cwd}:\n${warnings.map((w) => `  - ${w}`).join('\n')}\n\nRun: bun update to upgrade dependencies.`,
    });
  } else {
    output({ continue: true });
  }
}

function output(result: HookOutput): void {
  console.log(JSON.stringify(result));
}

main().catch(() => {
  output({ continue: true });
});
