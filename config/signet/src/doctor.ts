#!/usr/bin/env bun
/**
 * Signet Doctor - Version Alignment Checker
 *
 * Verifies that all package.json files in the dotfiles repo align with
 * the SSOT defined in versions.json.
 *
 * Usage: bun run src/doctor.ts
 *
 * Exit codes:
 *   0 - All versions aligned
 *   1 - Version drift detected
 */

import { readdir, readFile } from 'node:fs/promises';
import { join, relative } from 'node:path';

// SSOT location
const VERSIONS_PATH = join(import.meta.dir, '../versions.json');
const DOTFILES_ROOT = join(import.meta.dir, '../../..');

type VersionsJson = {
  meta: { frozen: string; updated: string; ssotVersion: string };
  npm: Record<string, string>;
  [key: string]: unknown;
};

type PackageJson = {
  name?: string;
  dependencies?: Record<string, string>;
  devDependencies?: Record<string, string>;
  peerDependencies?: Record<string, string>;
};

type Mismatch = {
  file: string;
  package: string;
  expected: string;
  actual: string;
  section: 'dependencies' | 'devDependencies' | 'peerDependencies';
};

/**
 * Recursively find all package.json files, excluding node_modules
 */
async function findPackageJsonFiles(dir: string): Promise<string[]> {
  const results: string[] = [];

  async function walk(currentDir: string): Promise<void> {
    const entries = await readdir(currentDir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = join(currentDir, entry.name);

      // Skip node_modules and hidden directories
      if (entry.isDirectory()) {
        if (entry.name === 'node_modules' || entry.name.startsWith('.')) {
          continue;
        }
        await walk(fullPath);
      } else if (entry.name === 'package.json') {
        results.push(fullPath);
      }
    }
  }

  await walk(dir);
  return results;
}

/**
 * Check a package.json against the SSOT versions
 */
function checkPackageJson(
  filePath: string,
  pkg: PackageJson,
  versions: Record<string, string>
): Mismatch[] {
  const mismatches: Mismatch[] = [];
  const sections = ['dependencies', 'devDependencies', 'peerDependencies'] as const;

  for (const section of sections) {
    const deps = pkg[section];
    if (!deps) continue;

    for (const [name, actual] of Object.entries(deps)) {
      const expected = versions[name];
      if (!expected) continue; // Not in SSOT, skip

      // Normalize versions for comparison
      const normalizedActual = actual.replace(/^[\^~]/, '');
      const isSemverRange = actual.startsWith('^') || actual.startsWith('~');

      if (normalizedActual !== expected) {
        mismatches.push({
          file: relative(DOTFILES_ROOT, filePath),
          package: name,
          expected,
          actual,
          section,
        });
      } else if (isSemverRange) {
        // Version matches but uses semver range (should be exact)
        mismatches.push({
          file: relative(DOTFILES_ROOT, filePath),
          package: name,
          expected,
          actual,
          section,
        });
      }
    }
  }

  return mismatches;
}

async function main(): Promise<void> {
  console.log('Signet Doctor - Version Alignment Check');
  console.log('=======================================\n');

  // Load SSOT
  const versionsContent = await readFile(VERSIONS_PATH, 'utf-8');
  const versions: VersionsJson = JSON.parse(versionsContent);

  console.log(`SSOT: versions.json (frozen: ${versions.meta.frozen}, updated: ${versions.meta.updated})`);
  console.log(`SSOT Version: ${versions.meta.ssotVersion}\n`);

  // Find all package.json files
  const packageJsonFiles = await findPackageJsonFiles(DOTFILES_ROOT);
  console.log(`Found ${packageJsonFiles.length} package.json file(s)\n`);

  // Check each file
  const allMismatches: Mismatch[] = [];

  for (const filePath of packageJsonFiles) {
    try {
      const content = await readFile(filePath, 'utf-8');
      const pkg: PackageJson = JSON.parse(content);
      const mismatches = checkPackageJson(filePath, pkg, versions.npm);
      allMismatches.push(...mismatches);
    } catch (error) {
      console.error(`Error reading ${relative(DOTFILES_ROOT, filePath)}: ${error}`);
    }
  }

  // Report results
  if (allMismatches.length === 0) {
    console.log('✓ All versions aligned with SSOT\n');
    process.exit(0);
  }

  console.log(`✗ Found ${allMismatches.length} version mismatch(es):\n`);

  // Group by file
  const byFile = new Map<string, Mismatch[]>();
  for (const m of allMismatches) {
    const existing = byFile.get(m.file) ?? [];
    existing.push(m);
    byFile.set(m.file, existing);
  }

  for (const [file, mismatches] of byFile) {
    console.log(`  ${file}:`);
    for (const m of mismatches) {
      console.log(`    ${m.package}: "${m.actual}" → should be "${m.expected}"`);
    }
    console.log('');
  }

  console.log('Run enforce-versions.ts hook or manually fix these mismatches.\n');
  process.exit(1);
}

main().catch((error) => {
  console.error('Doctor failed:', error);
  process.exit(1);
});
