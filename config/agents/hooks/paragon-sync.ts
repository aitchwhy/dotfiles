#!/usr/bin/env bun
/**
 * paragon-sync - Cross-project SSOT Validation
 *
 * Validates that a target project complies with dotfiles SSOT:
 * - Version registry (versions.json)
 * - Forbidden dependencies
 * - Forbidden files
 *
 * Usage: bun run paragon-sync.ts [target-dir]
 *
 * Exit codes:
 *   0 - All checks passed
 *   1 - Violations found (blocking)
 */

import { readFileSync, existsSync } from "node:fs"
import { join, resolve } from "node:path"
import { homedir } from "node:os"

type ViolationCategory = "version" | "forbidden-dep" | "forbidden-file"
type ViolationSeverity = "error" | "warning"

type Violation = {
  readonly category: ViolationCategory
  readonly severity: ViolationSeverity
  readonly message: string
  readonly file?: string
}

const DOTFILES_ROOT = join(homedir(), "dotfiles")
const VERSIONS_JSON = join(DOTFILES_ROOT, "config/quality/versions.json")

/**
 * Forbidden dependencies with replacement suggestions
 */
const FORBIDDEN_DEPS: Record<string, string> = {
  lodash: "Use native Array/Object methods or Effect utilities",
  "lodash-es": "Use native Array/Object methods or Effect utilities",
  express: "Use Effect Platform HTTP instead (@effect/platform)",
  fastify: "Use Effect Platform HTTP instead (@effect/platform)",
  koa: "Use Effect Platform HTTP instead (@effect/platform)",
  prisma: "Use Drizzle ORM instead (type-safe, SQL-first)",
  "@prisma/client": "Use Drizzle ORM instead (type-safe, SQL-first)",
  jest: "Use Vitest instead (Vite-native, faster)",
  mocha: "Use Vitest instead (Vite-native, faster)",
  eslint: "Use Biome or OXLint instead (faster, unified)",
  prettier: "Use Biome instead (unified format + lint)",
  webpack: "Use Vite instead (ESM-native, faster)",
  parcel: "Use Vite instead (ESM-native, faster)",
  axios: "Use Effect HttpClient or native fetch",
  "node-fetch": "Use native fetch (built into Node 18+)",
  moment: "Use Temporal API or date-fns",
}

/**
 * Forbidden files that indicate tooling drift
 */
const FORBIDDEN_FILES = [
  "package-lock.json",
  ".eslintrc",
  ".eslintrc.js",
  ".eslintrc.json",
  ".eslintrc.cjs",
  ".eslintrc.mjs",
  ".eslintrc.yml",
  ".eslintrc.yaml",
  ".prettierrc",
  ".prettierrc.js",
  ".prettierrc.json",
  ".prettierrc.yml",
  ".prettierrc.yaml",
  "prettier.config.js",
  "prettier.config.cjs",
  "jest.config.js",
  "jest.config.ts",
  "jest.config.mjs",
  ".babelrc",
  "babel.config.js",
]

function main(): void {
  const targetDir = resolve(process.argv[2] ?? process.cwd())
  const violations: Violation[] = []

  console.log(`\n[paragon-sync] Validating: ${targetDir}\n`)

  // Load SSOT versions
  if (!existsSync(VERSIONS_JSON)) {
    console.error(`SSOT versions.json not found at: ${VERSIONS_JSON}`)
    process.exit(1)
  }

  const ssotVersions = JSON.parse(readFileSync(VERSIONS_JSON, "utf-8"))
  const npmVersions: Record<string, string> = ssotVersions.npm ?? {}

  console.log(`SSOT: ${VERSIONS_JSON}`)
  console.log(`Frozen: ${ssotVersions.meta?.frozen ?? "unknown"}\n`)

  // Check package.json
  const pkgPath = join(targetDir, "package.json")
  if (existsSync(pkgPath)) {
    violations.push(...checkPackageJson(pkgPath, npmVersions))
  }

  // Check for forbidden files
  for (const file of FORBIDDEN_FILES) {
    const filePath = join(targetDir, file)
    if (existsSync(filePath)) {
      violations.push({
        category: "forbidden-file",
        severity: "error",
        message: `Forbidden file: ${file}`,
        file,
      })
    }
  }

  // Output results
  const errors = violations.filter((v) => v.severity === "error")
  const warnings = violations.filter((v) => v.severity === "warning")

  if (errors.length > 0) {
    console.log("ERRORS:")
    for (const v of errors) {
      console.log(`  ${v.message}`)
    }
  }

  if (warnings.length > 0) {
    console.log("\nWARNINGS:")
    for (const v of warnings) {
      console.log(`  ${v.message}`)
    }
  }

  if (violations.length === 0) {
    console.log("PASS: All SSOT checks passed")
    process.exit(0)
  } else if (errors.length > 0) {
    console.log(`\nFAIL: ${errors.length} errors, ${warnings.length} warnings`)
    process.exit(1)
  } else {
    console.log(`\nWARN: ${warnings.length} warnings (non-blocking)`)
    process.exit(0)
  }
}

function checkPackageJson(
  pkgPath: string,
  ssotVersions: Record<string, string>
): Violation[] {
  const violations: Violation[] = []

  try {
    const pkg = JSON.parse(readFileSync(pkgPath, "utf-8"))
    const allDeps = {
      ...(pkg.dependencies ?? {}),
      ...(pkg.devDependencies ?? {}),
    }

    // Check forbidden dependencies
    for (const [dep, reason] of Object.entries(FORBIDDEN_DEPS)) {
      if (allDeps[dep]) {
        violations.push({
          category: "forbidden-dep",
          severity: "error",
          message: `Forbidden: ${dep} - ${reason}`,
          file: "package.json",
        })
      }
    }

    // Check version drift
    for (const [dep, version] of Object.entries(allDeps)) {
      const expected = ssotVersions[dep]
      if (expected) {
        // Normalize versions (remove ^ ~ etc)
        const expectedClean = expected.replace(/^[\^~]/, "")
        const actualClean = (version as string).replace(/^[\^~]/, "")

        if (expectedClean !== actualClean) {
          violations.push({
            category: "version",
            severity: "warning",
            message: `Drift: ${dep} (${version} -> ${expected})`,
            file: "package.json",
          })
        }
      }
    }
  } catch {
    // Skip invalid package.json
  }

  return violations
}

main()
