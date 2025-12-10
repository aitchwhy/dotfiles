#!/usr/bin/env bun
/**
 * sync-versions.ts
 *
 * Synchronizes version data between versions.json and versions.ts.
 * The TypeScript file (versions.ts) is the SSOT.
 *
 * Usage:
 *   bun scripts/sync-versions.ts          # Generate versions.json from versions.ts
 *   bun scripts/sync-versions.ts --check  # Validate they're in sync
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const SIGNET_DIR = join(import.meta.dir, '../config/signet');
const VERSIONS_JSON_PATH = join(SIGNET_DIR, 'versions.json');
const VERSIONS_TS_PATH = join(SIGNET_DIR, 'src/stack/versions.ts');

async function main() {
  const checkOnly = process.argv.includes('--check');

  // Import the STACK from versions.ts
  const { STACK } = await import(VERSIONS_TS_PATH);

  // Read current versions.json
  const currentJson = JSON.parse(readFileSync(VERSIONS_JSON_PATH, 'utf-8'));

  // Generate expected JSON from STACK
  const expectedJson = {
    meta: STACK.meta,
    runtime: STACK.runtime,
    frontend: STACK.frontend,
    backend: STACK.backend,
    infra: STACK.infra,
    testing: STACK.testing,
    python: STACK.python,
    databases: STACK.databases,
    services: STACK.services,
    observability: STACK.observability,
    nix: STACK.nix,
    npm: STACK.npm,
  };

  const expectedStr = JSON.stringify(expectedJson, null, 2);
  const currentStr = JSON.stringify(currentJson, null, 2);

  if (currentStr === expectedStr) {
    console.log('✅ versions.json is in sync with versions.ts');
    process.exit(0);
  }

  if (checkOnly) {
    console.error('❌ versions.json is out of sync with versions.ts');
    console.error('Run `bun scripts/sync-versions.ts` to fix');
    process.exit(1);
  }

  // Write updated versions.json
  writeFileSync(VERSIONS_JSON_PATH, expectedStr + '\n');
  console.log('✅ Updated versions.json from versions.ts');
}

main().catch((err) => {
  console.error('Error:', err);
  process.exit(1);
});
