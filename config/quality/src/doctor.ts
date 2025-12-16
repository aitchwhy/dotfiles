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
import { Effect, Logger } from 'effect';

// SSOT location
const VERSIONS_PATH = join(import.meta.dir, '../versions.json');
const DOTFILES_ROOT = join(import.meta.dir, '../../..');

// =============================================================================
// Types
// =============================================================================

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

// =============================================================================
// Helper Functions
// =============================================================================

/**
 * Recursively find all package.json files, excluding node_modules
 */
const findPackageJsonFiles = (dir: string): Effect.Effect<string[], Error> =>
  Effect.tryPromise({
    try: async () => {
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
    },
    catch: (e) => new Error(`Failed to find package.json files: ${e}`),
  });

/**
 * Check a package.json against the SSOT versions
 */
const checkPackageJson = (
  filePath: string,
  pkg: PackageJson,
  versions: Record<string, string>
): Mismatch[] => {
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
};

// =============================================================================
// Main Program
// =============================================================================

const program = Effect.gen(function* () {
  yield* Effect.log('Signet Doctor - Version Alignment Check');
  yield* Effect.log('=======================================\n');

  // Load SSOT
  const versionsContent = yield* Effect.tryPromise({
    try: () => readFile(VERSIONS_PATH, 'utf-8'),
    catch: (e) => new Error(`Failed to read versions.json: ${e}`),
  });
  const versions: VersionsJson = JSON.parse(versionsContent);

  yield* Effect.log(
    `SSOT: versions.json (frozen: ${versions.meta.frozen}, updated: ${versions.meta.updated})`
  );
  yield* Effect.log(`SSOT Version: ${versions.meta.ssotVersion}\n`);

  // Find all package.json files
  const packageJsonFiles = yield* findPackageJsonFiles(DOTFILES_ROOT);
  yield* Effect.log(`Found ${packageJsonFiles.length} package.json file(s)\n`);

  // Check each file
  const allMismatches: Mismatch[] = [];

  for (const filePath of packageJsonFiles) {
    const result = yield* Effect.either(
      Effect.tryPromise({
        try: () => readFile(filePath, 'utf-8'),
        catch: (e) => new Error(`Failed to read ${filePath}: ${e}`),
      })
    );

    if (result._tag === 'Left') {
      yield* Effect.logError(
        `Error reading ${relative(DOTFILES_ROOT, filePath)}: ${result.left.message}`
      );
      continue;
    }

    const pkg: PackageJson = JSON.parse(result.right);
    const mismatches = checkPackageJson(filePath, pkg, versions.npm);
    allMismatches.push(...mismatches);
  }

  // Report results
  if (allMismatches.length === 0) {
    yield* Effect.log('✓ All versions aligned with SSOT\n');
    return 0;
  }

  yield* Effect.log(`✗ Found ${allMismatches.length} version mismatch(es):\n`);

  // Group by file
  const byFile = new Map<string, Mismatch[]>();
  for (const m of allMismatches) {
    const existing = byFile.get(m.file) ?? [];
    existing.push(m);
    byFile.set(m.file, existing);
  }

  for (const [file, mismatches] of byFile) {
    yield* Effect.log(`  ${file}:`);
    for (const m of mismatches) {
      yield* Effect.log(`    ${m.package}: "${m.actual}" → should be "${m.expected}"`);
    }
    yield* Effect.log('');
  }

  yield* Effect.log('Run enforce-versions.ts hook or manually fix these mismatches.\n');
  return 1;
});

// =============================================================================
// Entry Point
// =============================================================================

Effect.runPromise(
  program.pipe(
    Effect.provide(Logger.pretty),
    Effect.catchAll((error) =>
      Effect.gen(function* () {
        yield* Effect.logError('Doctor failed', { error: error.message });
        return 1;
      })
    )
  )
).then((exitCode) => {
  process.exit(exitCode);
});
