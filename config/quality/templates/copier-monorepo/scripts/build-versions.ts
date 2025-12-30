/**
 * Generates versions.json from SSOT at copier copy time.
 * This ensures versions are NEVER stale.
 *
 * Run: tsx scripts/build-versions.ts
 */
import { writeFileSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

// Import from SSOT
import { STACK } from '../../../src/stack/versions.js'

const __dirname = dirname(fileURLToPath(import.meta.url))
const outPath = join(__dirname, '..', 'template', 'versions.json')

// Export npm versions for Copier templates
const versions = {
	...STACK.npm,
	// Include mobile section explicitly
	mobile: STACK.mobile,
	// Runtime versions
	pnpm: STACK.runtime.pnpm,
	node: STACK.runtime.node,
	// Meta for debugging
	_ssotVersion: STACK.meta.ssotVersion,
	_frozen: STACK.meta.frozen,
}

writeFileSync(outPath, JSON.stringify(versions, null, 2))

// Exit successfully (no console output needed)
process.exit(0)
