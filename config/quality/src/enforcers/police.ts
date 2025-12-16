/**
 * Police Enforcer
 *
 * Validates project structure, naming conventions, and dependency hygiene.
 * Acts as the first line of defense for code quality.
 */
import { Effect } from 'effect';

// =============================================================================
// Types
// =============================================================================

export interface PoliceViolation {
  readonly rule: string;
  readonly severity: 'error' | 'warning';
  readonly message: string;
  readonly file?: string;
  readonly suggestion?: string;
}

export interface DependencyInfo {
  readonly dependencies: Record<string, string>;
  readonly devDependencies: Record<string, string>;
}

// =============================================================================
// Deprecated/Banned Packages
// =============================================================================

const DEPRECATED_PACKAGES = new Set([
  'request', // Use fetch or undici
  'moment', // Use date-fns or dayjs
  'lodash', // Use native methods or es-toolkit
  // MySQL BANNED - use PostgreSQL or Turso
  'mysql',
  'mysql2',
  // Outdated Nix packages (December 2025 policy)
  'mysql84', // MySQL banned
  'python312', // Use python314
  'python313', // Use python314
  'postgresql_14', // Use postgresql_18
  'postgresql_15', // Use postgresql_18
  'postgresql_16', // Use postgresql_18
  'postgresql_17', // Use postgresql_18
]);

const PREFER_BIOME_OVER = new Set([
  'eslint',
  'prettier',
  '@typescript-eslint/parser',
  '@typescript-eslint/eslint-plugin',
]);

const PREFER_BUN_OVER = new Set(['jest', 'mocha', 'vitest']);

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
    const violations: PoliceViolation[] = [];
    const fileSet = new Set(files);

    // Required files for all project types
    if (!fileSet.has('package.json')) {
      violations.push({
        rule: 'missing-package-json',
        severity: 'error',
        message: 'Missing package.json',
        suggestion: 'Run signet init to create project structure',
      });
    }

    // src directory for most project types
    if (projectType !== 'infra' && !files.some((f) => f.startsWith('src/'))) {
      violations.push({
        rule: 'missing-src',
        severity: 'error',
        message: 'Missing src/ directory',
        suggestion: 'Source code should be in src/ directory',
      });
    }

    // TypeScript config
    if (!fileSet.has('tsconfig.json')) {
      violations.push({
        rule: 'missing-tsconfig',
        severity: 'warning',
        message: 'Missing tsconfig.json',
        suggestion: 'Add TypeScript configuration',
      });
    }

    return violations;
  }).pipe(Effect.flatMap((fn) => Effect.succeed(fn())));

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
];

/**
 * Check file naming conventions
 */
export const checkNamingConventions = (
  files: readonly string[]
): Effect.Effect<readonly PoliceViolation[], never> =>
  Effect.succeed(() => {
    const violations: PoliceViolation[] = [];

    for (const file of files) {
      // Only check TypeScript files
      if (!file.endsWith('.ts') && !file.endsWith('.tsx')) continue;

      const fileName = file.split('/').pop() || file;

      // Skip if matches any valid pattern
      const isValid = VALID_FILE_PATTERNS.some((pattern) => pattern.test(fileName));

      if (!isValid) {
        violations.push({
          rule: 'invalid-file-name',
          severity: 'warning',
          message: `Invalid file name: ${fileName}`,
          file,
          suggestion: 'Use kebab-case (my-file.ts) or camelCase (myFile.ts)',
        });
      }
    }

    return violations;
  }).pipe(Effect.flatMap((fn) => Effect.succeed(fn())));

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
    const violations: PoliceViolation[] = [];
    const allDeps = { ...deps.dependencies, ...deps.devDependencies };

    for (const [pkg] of Object.entries(allDeps)) {
      // Check deprecated packages
      if (DEPRECATED_PACKAGES.has(pkg)) {
        violations.push({
          rule: 'deprecated-package',
          severity: 'warning',
          message: `Deprecated package: ${pkg}`,
          suggestion: getDeprecatedSuggestion(pkg),
        });
      }

      // Check ESLint/Prettier (prefer Biome)
      if (PREFER_BIOME_OVER.has(pkg)) {
        violations.push({
          rule: 'prefer-biome',
          severity: 'warning',
          message: `Consider Biome instead of ${pkg}`,
          suggestion: 'Biome provides faster linting and formatting',
        });
      }

      // Check Jest/Mocha (prefer Bun test)
      if (PREFER_BUN_OVER.has(pkg)) {
        violations.push({
          rule: 'prefer-bun-test',
          severity: 'warning',
          message: `Consider bun test instead of ${pkg}`,
          suggestion: 'Bun has a built-in test runner',
        });
      }
    }

    return violations;
  }).pipe(Effect.flatMap((fn) => Effect.succeed(fn())));

// =============================================================================
// Helpers
// =============================================================================

function getDeprecatedSuggestion(pkg: string): string {
  switch (pkg) {
    case 'request':
      return 'Use native fetch() or undici';
    case 'moment':
      return 'Use date-fns or dayjs';
    case 'lodash':
      return 'Use native methods or es-toolkit';
    // MySQL BANNED
    case 'mysql':
    case 'mysql2':
    case 'mysql84':
      return 'MySQL is BANNED. Use postgres (pg driver) or @libsql/client (Turso)';
    // Python policy: 3.14+ only
    case 'python312':
    case 'python313':
      return 'Use python314 (Python 3.14+). Older versions are not allowed.';
    // PostgreSQL policy: 18+ only
    case 'postgresql_14':
    case 'postgresql_15':
    case 'postgresql_16':
    case 'postgresql_17':
      return 'Use postgresql_18. PostgreSQL 18+ is required.';
    default:
      return 'Check npm for alternatives';
  }
}
