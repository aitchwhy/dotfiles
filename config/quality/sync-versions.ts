#!/usr/bin/env bun
/**
 * sync-versions.ts - Sync package.json versions to STACK.ts SSOT
 *
 * Usage:
 *   bun run ~/dotfiles/config/quality/sync-versions.ts /path/to/project
 *   bun run ~/dotfiles/config/quality/sync-versions.ts /path/to/project --dry-run
 *
 * This script finds all package.json files in a project and updates
 * their dependency versions to match the STACK.ts SSOT.
 */
import { STACK, getDrift } from './src/stack/versions';
import { readFileSync, writeFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join, relative } from 'node:path';

const projectPath = process.argv[2];
const dryRun = process.argv.includes('--dry-run');

if (!projectPath) {
  process.stderr.write('Usage: bun run sync-versions.ts /path/to/project [--dry-run]\n');
  process.exit(1);
}

if (!existsSync(projectPath)) {
  process.stderr.write(`Error: Path does not exist: ${projectPath}\n`);
  process.exit(1);
}

/**
 * Recursively find all package.json files in a directory
 */
function findPackageJsons(dir: string): string[] {
  const results: string[] = [];
  let entries: string[];

  try {
    entries = readdirSync(dir);
  } catch {
    return results;
  }

  for (const entry of entries) {
    // Skip common directories that shouldn't be traversed
    if (
      entry === 'node_modules' ||
      entry.startsWith('.') ||
      entry === 'dist' ||
      entry === 'build' ||
      entry === 'coverage'
    ) {
      continue;
    }

    const fullPath = join(dir, entry);
    let stat;

    try {
      stat = statSync(fullPath);
    } catch {
      continue;
    }

    if (stat.isDirectory()) {
      results.push(...findPackageJsons(fullPath));
    } else if (entry === 'package.json') {
      results.push(fullPath);
    }
  }

  return results;
}

type SyncResult = {
  file: string;
  changes: Array<{ pkg: string; from: string; to: string }>;
};

/**
 * Sync a single package.json file to STACK versions
 */
function syncPackageJson(path: string): SyncResult {
  const content = JSON.parse(readFileSync(path, 'utf-8'));
  const changes: Array<{ pkg: string; from: string; to: string }> = [];

  const npmVersions = STACK.npm as Record<string, string>;

  const syncDeps = (deps: Record<string, string> | undefined) => {
    if (!deps) return;
    for (const [pkg, version] of Object.entries(deps)) {
      const stackVersion = npmVersions[pkg];
      // Only sync if:
      // 1. Package is in STACK
      // 2. Version differs
      // 3. Not a workspace reference
      if (stackVersion && version !== stackVersion && !version.startsWith('workspace:')) {
        changes.push({ pkg, from: version, to: stackVersion });
        if (!dryRun) {
          deps[pkg] = stackVersion;
        }
      }
    }
  };

  syncDeps(content.dependencies);
  syncDeps(content.devDependencies);
  syncDeps(content.peerDependencies);

  if (changes.length > 0 && !dryRun) {
    writeFileSync(path, JSON.stringify(content, null, 2) + '\n');
  }

  return { file: path, changes };
}

// Main execution
const modeLabel = dryRun ? '[DRY RUN] ' : '';
process.stdout.write(`${modeLabel}Syncing versions in ${projectPath} to STACK.ts...\n\n`);

const packageJsons = findPackageJsons(projectPath);

if (packageJsons.length === 0) {
  process.stdout.write('No package.json files found.\n');
  process.exit(0);
}

let totalChanges = 0;
let filesChanged = 0;

for (const pkg of packageJsons) {
  const result = syncPackageJson(pkg);
  if (result.changes.length > 0) {
    filesChanged++;
    const relativePath = relative(projectPath, result.file);
    process.stdout.write(`\x1b[36m${relativePath}\x1b[0m\n`);
    for (const change of result.changes) {
      process.stdout.write(`  \x1b[33m${change.pkg}\x1b[0m: ${change.from} \x1b[32m->\x1b[0m ${change.to}\n`);
      totalChanges++;
    }
  }
}

process.stdout.write('\n');
if (totalChanges === 0) {
  process.stdout.write('\x1b[32m✓ All versions are in sync with STACK.ts\x1b[0m\n');
} else if (dryRun) {
  process.stdout.write(`\x1b[33m⚠ Would update ${totalChanges} package(s) across ${filesChanged} file(s)\x1b[0m\n`);
  process.stdout.write('Run without --dry-run to apply changes.\n');
} else {
  process.stdout.write(`\x1b[32m✓ Updated ${totalChanges} package(s) across ${filesChanged} file(s)\x1b[0m\n`);
}
