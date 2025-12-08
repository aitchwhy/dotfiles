/**
 * Police Enforcer
 *
 * Validates project structure, naming conventions, and dependency hygiene.
 * Acts as the first line of defense for code quality.
 */
import { Effect } from 'effect'

// =============================================================================
// Types
// =============================================================================

export interface PoliceViolation {
  readonly rule: string
  readonly severity: 'error' | 'warning'
  readonly message: string
  readonly file?: string
  readonly suggestion?: string
}

export interface DependencyInfo {
  readonly dependencies: Record<string, string>
  readonly devDependencies: Record<string, string>
}

// =============================================================================
// Deprecated/Banned Packages
// =============================================================================

const DEPRECATED_PACKAGES = new Set([
  'request', // Use fetch or undici
  'moment', // Use date-fns or dayjs
  'lodash', // Use native methods or es-toolkit
])

const PREFER_BIOME_OVER = new Set([
  'eslint',
  'prettier',
  '@typescript-eslint/parser',
  '@typescript-eslint/eslint-plugin',
])

const PREFER_BUN_OVER = new Set(['jest', 'mocha', 'vitest'])

// =============================================================================
// Structure Checks
// =============================================================================

/**
 * Check project structure for required files
 */
export const checkStructure = (
  files: readonly string[],
  projectType: string
): Effect.Effect<readonly PoliceViolation[], never> =>
  Effect.succeed(() => {
    const violations: PoliceViolation[] = []
    const fileSet = new Set(files)

    // Required files for all project types
    if (!fileSet.has('package.json')) {
      violations.push({
        rule: 'missing-package-json',
        severity: 'error',
        message: 'Missing package.json',
        suggestion: 'Run signet init to create project structure',
      })
    }

    // src directory for most project types
    if (projectType !== 'infra' && !files.some((f) => f.startsWith('src/'))) {
      violations.push({
        rule: 'missing-src',
        severity: 'error',
        message: 'Missing src/ directory',
        suggestion: 'Source code should be in src/ directory',
      })
    }

    // TypeScript config
    if (!fileSet.has('tsconfig.json')) {
      violations.push({
        rule: 'missing-tsconfig',
        severity: 'warning',
        message: 'Missing tsconfig.json',
        suggestion: 'Add TypeScript configuration',
      })
    }

    return violations
  }).pipe(Effect.flatMap((fn) => Effect.succeed(fn())))

// =============================================================================
// Naming Convention Checks
// =============================================================================

// Valid patterns for TypeScript files
const VALID_FILE_PATTERNS = [
  /^[a-z][a-z0-9-]*\.tsx?$/, // kebab-case: my-component.ts
  /^[a-z][a-zA-Z0-9]*\.tsx?$/, // camelCase: myComponent.ts
  /^[A-Z][a-zA-Z0-9]*\.tsx?$/, // PascalCase: MyComponent.tsx (for components/classes)
  /^__[a-z]+__$/, // dunder directories: __tests__
  /^index\.tsx?$/, // index files
  /^[a-z][a-z0-9-]*\.test\.tsx?$/, // test files
  /^[a-z][a-z0-9-]*\.spec\.tsx?$/, // spec files
]

/**
 * Check file naming conventions
 */
export const checkNamingConventions = (
  files: readonly string[]
): Effect.Effect<readonly PoliceViolation[], never> =>
  Effect.succeed(() => {
    const violations: PoliceViolation[] = []

    for (const file of files) {
      // Only check TypeScript files
      if (!file.endsWith('.ts') && !file.endsWith('.tsx')) continue

      const fileName = file.split('/').pop() || file

      // Skip if matches any valid pattern
      const isValid = VALID_FILE_PATTERNS.some((pattern) => pattern.test(fileName))

      if (!isValid) {
        violations.push({
          rule: 'invalid-file-name',
          severity: 'warning',
          message: `Invalid file name: ${fileName}`,
          file,
          suggestion: 'Use kebab-case (my-file.ts) or camelCase (myFile.ts)',
        })
      }
    }

    return violations
  }).pipe(Effect.flatMap((fn) => Effect.succeed(fn())))

// =============================================================================
// Dependency Hygiene Checks
// =============================================================================

/**
 * Check for deprecated or banned dependencies
 */
export const checkDependencyHygiene = (
  deps: DependencyInfo
): Effect.Effect<readonly PoliceViolation[], never> =>
  Effect.succeed(() => {
    const violations: PoliceViolation[] = []
    const allDeps = { ...deps.dependencies, ...deps.devDependencies }

    for (const [pkg] of Object.entries(allDeps)) {
      // Check deprecated packages
      if (DEPRECATED_PACKAGES.has(pkg)) {
        violations.push({
          rule: 'deprecated-package',
          severity: 'warning',
          message: `Deprecated package: ${pkg}`,
          suggestion: getDeprecatedSuggestion(pkg),
        })
      }

      // Check ESLint/Prettier (prefer Biome)
      if (PREFER_BIOME_OVER.has(pkg)) {
        violations.push({
          rule: 'prefer-biome',
          severity: 'warning',
          message: `Consider Biome instead of ${pkg}`,
          suggestion: 'Biome provides faster linting and formatting',
        })
      }

      // Check Jest/Mocha (prefer Bun test)
      if (PREFER_BUN_OVER.has(pkg)) {
        violations.push({
          rule: 'prefer-bun-test',
          severity: 'warning',
          message: `Consider bun test instead of ${pkg}`,
          suggestion: 'Bun has a built-in test runner',
        })
      }
    }

    return violations
  }).pipe(Effect.flatMap((fn) => Effect.succeed(fn())))

// =============================================================================
// Helpers
// =============================================================================

function getDeprecatedSuggestion(pkg: string): string {
  switch (pkg) {
    case 'request':
      return 'Use native fetch() or undici'
    case 'moment':
      return 'Use date-fns or dayjs'
    case 'lodash':
      return 'Use native methods or es-toolkit'
    default:
      return 'Check npm for alternatives'
  }
}
