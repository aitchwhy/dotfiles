/**
 * Procedural Guards - Guards that need file system or command parsing
 *
 * Guards: 1 (bash safety), 2 (commits), 3 (forbidden files),
 *         8 (TDD), 9-10 (DevOps), 11-12 (advisory), 27 (CLI tools),
 *         28-30 (config centralization), 32 (secrets detection), 33 (hook bypass),
 *         34 (scaffolding enforcement), 51 (zero environment awareness),
 *         52-55 (Effect-XState integration)
 *
 * Note: Guard 31 (stack compliance) consolidated to pre-tool-use.ts using src/stack SSOT
 *
 * Modernized to use Effect for FS operations (no sync FS).
 */

import { FileSystem } from '@effect/platform'
import { Effect } from 'effect'
import {
  findIncompatibleFlags,
  formatFlagTranslations,
  LEGACY_FLAG_MAPPINGS,
  type LegacyCommand,
} from '../../../schemas/cli-tools.js'
import type { GuardResult } from '../effect-hook'

// =============================================================================
// Pre-compiled Regex Patterns (Jan 2026 Optimization)
// Moving inline patterns to module scope for performance
// =============================================================================

/** File extension patterns - used frequently in Write/Edit guards */
const FILE_EXT = {
  typescript: /\.(ts|tsx|js|jsx|mjs|cjs)$/,
  typescriptStrict: /\.(ts|tsx)$/,
  tsx: /\.(tsx)$/,
  nix: /\.nix$/,
  test: /\.(test|spec)\.[jt]sx?$/,
} as const

/** Git commit patterns */
const GIT_COMMIT = {
  hasCommit: /git\s+commit\s+.*-m\s+/,
  extractDouble: /git\s+commit\s+.*-m\s+"([^"]+)"/,
  extractSingle: /git\s+commit\s+.*-m\s+'([^']+)'/,
  extractHeredoc: /git\s+commit\s+.*-m\s+"\$\(cat\s+<<['"]?(\w+)['"]?\n([\s\S]*?)\n\1/,
} as const

/** Command parsing patterns */
const CMD_PARSE = {
  extractCommand: /^(?:[A-Z_]+=\S+\s+)*(\w+)/,
  xstateHook: /use(Machine|Actor)\s*\(/,
} as const

// =============================================================================
// Guard 1: Bash Safety
// =============================================================================

export function checkBashSafety(command: string): GuardResult {
  if (command.includes('rm -rf /') || command.includes('rm -rf ~')) {
    return { ok: false, error: 'BLOCKED: Dangerous recursive delete command detected.' }
  }
  return { ok: true }
}

// =============================================================================
// Guard 33: Hook Bypass Prevention
// =============================================================================

const HOOK_BYPASS_PATTERNS = [
  { pattern: /\bLEFTHOOK=0\b/, name: 'LEFTHOOK=0' },
  { pattern: /\bHUSKY=0\b/, name: 'HUSKY=0' },
  { pattern: /--no-verify\b/, name: '--no-verify' },
  { pattern: /\bgit\s+commit\s+.*-n\b/, name: '-n (no-verify shorthand)' },
] as const

export function checkHookBypass(command: string): GuardResult {
  for (const { pattern, name } of HOOK_BYPASS_PATTERNS) {
    if (pattern.test(command)) {
      return {
        ok: false,
        error: `Guard 33: HOOK BYPASS BLOCKED

Detected: ${name}
Command: ${command.substring(0, 60)}${command.length > 60 ? '...' : ''}

Hook bypasses defeat PARAGON enforcement.

Legitimate alternatives:
1. Use lefthook skip configuration (skip: merge, skip: rebase)
2. Create lefthook-local.yml for local overrides
3. Fix the underlying issue instead of bypassing

See: config/agents/skills/paragon/references/bypasses.md`,
      }
    }
  }

  return { ok: true }
}

// =============================================================================
// Guard 2: Conventional Commits
// =============================================================================

const CONVENTIONAL_COMMIT_REGEX =
  /^(feat|fix|refactor|test|docs|chore|perf|ci)(\([a-z0-9-]+\))?!?:\s+[a-z]/
const VALID_COMMIT_TYPES = ['feat', 'fix', 'refactor', 'test', 'docs', 'chore', 'perf', 'ci']

function extractCommitMessage(command: string): string | null {
  const doubleQuoteMatch = command.match(GIT_COMMIT.extractDouble)
  if (doubleQuoteMatch?.[1]) return doubleQuoteMatch[1]

  const singleQuoteMatch = command.match(GIT_COMMIT.extractSingle)
  if (singleQuoteMatch?.[1]) return singleQuoteMatch[1]

  const heredocMatch = command.match(GIT_COMMIT.extractHeredoc)
  if (heredocMatch?.[2]) return heredocMatch[2].trim().split('\n')[0] ?? null

  return null
}

export function checkConventionalCommit(command: string): GuardResult {
  if (!GIT_COMMIT.hasCommit.test(command)) return { ok: true }

  const message = extractCommitMessage(command)
  if (!message) return { ok: true }

  if (!CONVENTIONAL_COMMIT_REGEX.test(message)) {
    return {
      ok: false,
      error: `CONVENTIONAL COMMIT VIOLATION

Invalid: '${message.substring(0, 50)}${message.length > 50 ? '...' : ''}'

Expected: type(scope): description (lowercase first letter)
Types: ${VALID_COMMIT_TYPES.join(', ')}

Examples:
  feat(auth): add OAuth2 login
  fix(api): handle null response`,
    }
  }

  return { ok: true }
}

// =============================================================================
// Guard 3: Forbidden Files
// =============================================================================

type ForbiddenFile = {
  readonly pattern: string | RegExp
  readonly reason: string
  readonly alternative: string
}

const FORBIDDEN_FILES: readonly ForbiddenFile[] = [
  { pattern: 'package-lock.json', reason: 'Use pnpm', alternative: 'pnpm install' },
  { pattern: 'yarn.lock', reason: 'Use pnpm', alternative: 'pnpm install' },
  { pattern: 'bun.lock', reason: 'Use pnpm', alternative: 'pnpm install' },
  { pattern: 'bun.lockb', reason: 'Use pnpm', alternative: 'pnpm install' },
  {
    pattern: /\.eslintrc(\.(js|cjs|mjs|json|yaml|yml))?$/,
    reason: 'Use Biome',
    alternative: 'biome.json',
  },
  { pattern: /eslint\.config\.(js|cjs|mjs|ts)$/, reason: 'Use Biome', alternative: 'biome.json' },
  {
    pattern: /\.prettierrc(\.(js|cjs|mjs|json|yaml|yml))?$/,
    reason: 'Use Biome',
    alternative: 'biome.json',
  },
  { pattern: /prettier\.config\.(js|cjs|mjs|ts)$/, reason: 'Use Biome', alternative: 'biome.json' },
  {
    pattern: /jest\.config\.(js|cjs|mjs|ts|json)$/,
    reason: 'Use Vitest',
    alternative: 'vitest.config.ts',
  },
  { pattern: /prisma\/schema\.prisma$/, reason: 'Use Drizzle', alternative: 'drizzle.config.ts' },
  {
    pattern: /^process-compose\.(ya?ml)$/,
    reason: 'Use Docker Compose',
    alternative: 'docker compose up',
  },
  { pattern: /^\.env$/, reason: 'Use Pulumi ESC', alternative: 'esc env open org/proj/dev' },
]

export function checkForbiddenFiles(filePath: string): GuardResult {
  const fileName = filePath.split('/').pop() ?? ''

  for (const forbidden of FORBIDDEN_FILES) {
    const matches =
      typeof forbidden.pattern === 'string'
        ? fileName === forbidden.pattern || filePath.endsWith(forbidden.pattern)
        : forbidden.pattern.test(fileName) || forbidden.pattern.test(filePath)

    if (matches) {
      return {
        ok: false,
        error: `FORBIDDEN FILE: ${fileName}\n\nReason: ${forbidden.reason}\nAlternative: ${forbidden.alternative}`,
      }
    }
  }

  return { ok: true }
}

// =============================================================================
// Guard 8: TDD Enforcer (Effect-based)
// =============================================================================

type LanguageConfig = {
  readonly extensions: readonly string[]
  readonly testPatterns: readonly RegExp[]
  readonly getTestPaths: (sourcePath: string) => string[]
}

const LANGUAGES: Record<string, LanguageConfig> = {
  typescript: {
    extensions: ['.ts', '.tsx'],
    testPatterns: [/\.test\.[tj]sx?$/, /\.spec\.[tj]sx?$/, /_test\.[tj]sx?$/, /\.e2e\.[tj]sx?$/],
    getTestPaths: (sourcePath: string) => {
      const dir = sourcePath.replace(/\/[^/]+$/, '')
      const base = sourcePath.replace(/^.*\//, '').replace(/\.[^.]+$/, '')
      const ext = sourcePath.match(/\.[^.]+$/)?.[0] ?? '.ts'
      return [
        `${dir}/${base}.test${ext}`,
        `${dir}/${base}.spec${ext}`,
        `${dir}/__tests__/${base}.test${ext}`,
      ]
    },
  },
  python: {
    extensions: ['.py'],
    testPatterns: [/^test_.*\.py$/, /.*_test\.py$/],
    getTestPaths: (sourcePath: string) => {
      const dir = sourcePath.replace(/\/[^/]+$/, '')
      const base = sourcePath.replace(/^.*\//, '').replace(/\.py$/, '')
      return [`${dir}/test_${base}.py`, `${dir}/${base}_test.py`]
    },
  },
}

const TDD_EXCLUDED_DIRS = [
  '/node_modules/',
  '/.git/',
  '/dist/',
  '/migrations/',
  '/scripts/',
  '/__pycache__/',
]
const TDD_EXCLUDED_FILES = [/^__init__\.py$/, /\.config\.[tj]sx?$/, /\.d\.ts$/, /index\.[tj]sx?$/]

function getLanguage(path: string): LanguageConfig | null {
  for (const config of Object.values(LANGUAGES)) {
    if (config.extensions.some((ext) => path.endsWith(ext))) return config
  }
  return null
}

function isTestFile(path: string, language: LanguageConfig): boolean {
  const fileName = path.replace(/^.*\//, '')
  return language.testPatterns.some((p) => p.test(fileName) || p.test(path))
}

/** Effect-based TDD check - requires FileSystem service */
export const checkTDDEffect = (filePath: string) =>
  Effect.gen(function* () {
    const language = getLanguage(filePath)
    if (!language) return { ok: true } as GuardResult

    if (TDD_EXCLUDED_DIRS.some((dir) => filePath.includes(dir))) return { ok: true } as GuardResult

    const fileName = filePath.replace(/^.*\//, '')
    if (TDD_EXCLUDED_FILES.some((p) => p.test(fileName))) return { ok: true } as GuardResult

    if (isTestFile(filePath, language)) return { ok: true } as GuardResult

    const fs = yield* FileSystem.FileSystem

    // Check for .tdd-skip bypass
    const hasBypass = yield* fs.exists('.tdd-skip')
    if (hasBypass) {
      return { ok: true, warnings: ['TDD bypassed via .tdd-skip'] } as GuardResult
    }

    // Check if any test file exists
    const testPaths = language.getTestPaths(filePath)
    for (const p of testPaths) {
      const testExists = yield* fs.exists(p)
      if (testExists) return { ok: true } as GuardResult
    }

    return {
      ok: false,
      error: `TDD VIOLATION: No test file for ${fileName}

Write the test FIRST (Red phase):
${testPaths
  .slice(0, 3)
  .map((p) => `  - ${p}`)
  .join('\n')}

Bypass: touch .tdd-skip`,
    } as GuardResult
  })

/** Synchronous TDD check - for non-Effect contexts (skips FS checks) */
export function checkTDD(filePath: string): GuardResult {
  const language = getLanguage(filePath)
  if (!language) return { ok: true }

  if (TDD_EXCLUDED_DIRS.some((dir) => filePath.includes(dir))) return { ok: true }

  const fileName = filePath.replace(/^.*\//, '')
  if (TDD_EXCLUDED_FILES.some((p) => p.test(fileName))) return { ok: true }

  if (isTestFile(filePath, language)) return { ok: true }

  // In sync mode, we skip the FS checks and allow
  // Full TDD enforcement happens at commit time via lefthook
  return { ok: true, warnings: ['TDD enforcement deferred to commit hook'] }
}

// =============================================================================
// Guards 9-10: DevOps Files and Commands
// =============================================================================

/**
 * Directories where bun is allowed (quality system uses bun internally)
 */
const BUN_ALLOWED_PATHS = ['config/quality', 'dotfiles/config/quality'] as const

function isBunAllowed(command: string): boolean {
  return BUN_ALLOWED_PATHS.some((path) => command.includes(path))
}

export function checkDevOpsCommands(command: string): GuardResult {
  const forbidden = [
    {
      pattern: /\bprocess-compose\s+(up|start)\b/,
      alt: 'docker compose up',
      checkBunException: false,
    },
    {
      pattern: /\bbun\s+(run|test|install)\b/,
      alt: 'pnpm run / vitest / pnpm install',
      checkBunException: true,
    },
    {
      pattern: /\b(npm|yarn)\s+run\s+(dev|start|serve)\b/,
      alt: 'docker compose up',
      checkBunException: false,
    },
    { pattern: /\bnpm\s+start\b/, alt: 'docker compose up', checkBunException: false },
  ]

  for (const { pattern, alt, checkBunException } of forbidden) {
    if (pattern.test(command)) {
      // Allow bun commands in config/quality (brain system uses bun)
      if (checkBunException && isBunAllowed(command)) {
        return { ok: true }
      }

      return {
        ok: false,
        error: `DEVOPS VIOLATION\n\nAlternative: ${alt}\n\nUse Docker Compose for local orchestration.`,
      }
    }
  }

  return { ok: true }
}

// =============================================================================
// Guard 27: Modern CLI Tools (Legacy Syntax Detection)
// =============================================================================

/**
 * Detects when legacy CLI tool flags are used with aliased modern tools.
 * Shell aliases transform: grep→rg, find→fd, ls→eza
 *
 * Examples blocked:
 * - `grep --include="*.ts"` (rg uses --glob/-g)
 * - `find . -name "*.ts"` (fd uses positional pattern)
 * - `grep -r pattern` (rg is recursive by default)
 */
export function checkModernCLITools(command: string): GuardResult {
  // Extract the base command (first word, ignoring env vars)
  const cmdMatch = command.match(CMD_PARSE.extractCommand)
  if (!cmdMatch?.[1]) return { ok: true }

  const baseCmd = cmdMatch[1] as string

  // Check if this is a legacy command that's aliased
  if (!Object.hasOwn(LEGACY_FLAG_MAPPINGS, baseCmd)) {
    return { ok: true }
  }

  const legacyCmd = baseCmd as LegacyCommand
  const incompatible = findIncompatibleFlags(legacyCmd, command)

  if (incompatible.length === 0) {
    return { ok: true }
  }

  const mapping = LEGACY_FLAG_MAPPINGS[legacyCmd]
  const translations = formatFlagTranslations(legacyCmd)

  return {
    ok: false,
    error: `Guard 27: LEGACY CLI SYNTAX

Command: ${command.substring(0, 60)}${command.length > 60 ? '...' : ''}
Problem: Incompatible flags for ${mapping.modern} (aliased from ${legacyCmd})

Incompatible: ${incompatible.join(', ')}

Options:
1. Use MCP tool: mcp__ripgrep__search (if searching)
2. Use native ${mapping.modern} syntax:

Flag translation (${legacyCmd} → ${mapping.modern}):
${translations}`,
  }
}

// =============================================================================
// Guards 11-12: Flake Patterns & Port Registry (Advisory)
// =============================================================================

export function checkFlakePatterns(content: string, filePath: string): GuardResult {
  if (!filePath.endsWith('flake.nix')) return { ok: true }

  const warnings: string[] = []

  if (!content.includes('flake-parts')) {
    warnings.push('Consider flake-parts for modular composition')
  }
  if (content.includes('forAllSystems') || content.includes('lib.genAttrs')) {
    warnings.push('forAllSystems deprecated - use flake-parts perSystem')
  }
  if (
    content.includes('mkShell') &&
    !content.includes('pre-commit') &&
    !content.includes('git-hooks')
  ) {
    warnings.push('Consider git-hooks.nix for pre-commit integration')
  }

  if (warnings.length > 0) {
    return { ok: true, warnings }
  }
  return { ok: true }
}

const KNOWN_PORTS = new Set([
  22, 41641, 9100, 9080, 6379, 5432, 7233, 3000, 3001, 8233, 4317, 4318, 9090, 3100, 3200,
])

export function checkPortRegistry(content: string, filePath: string): GuardResult {
  if (!filePath.endsWith('.nix')) return { ok: true }
  if (!filePath.includes('/modules/') && !filePath.includes('/services/')) return { ok: true }

  const portMatches = content.matchAll(/\bport\s*=\s*(\d{2,5})\b/gi)
  const unknownPorts: number[] = []

  for (const match of portMatches) {
    const port = parseInt(match[1] ?? '0', 10)
    if (port > 0 && !KNOWN_PORTS.has(port)) {
      unknownPorts.push(port)
    }
  }

  if (unknownPorts.length > 0) {
    return { ok: true, warnings: [`Port(s) ${unknownPorts.join(', ')} not in lib/ports.nix`] }
  }

  return { ok: true }
}

// =============================================================================
// Guards 28-30: Configuration Centralization
// =============================================================================

function isConfigAllowedPath(filePath: string): boolean {
  return (
    filePath.includes('lib/config/') ||
    filePath.includes('lib/ports') ||
    filePath.endsWith('.test.ts') ||
    filePath.endsWith('.spec.ts')
  )
}

export function checkHardcodedPorts(content: string, filePath: string): GuardResult {
  if (!filePath.endsWith('.nix')) return { ok: true }
  if (isConfigAllowedPath(filePath)) return { ok: true }

  const portPattern = /\bport\s*=\s*(\d{4,5})\b/g
  const matches = [...content.matchAll(portPattern)]

  if (matches.length > 0 && !content.includes('ports.')) {
    return {
      ok: false,
      error: `Guard 28: Hardcoded port detected. Use ports.* reference from lib/config/`,
    }
  }

  return { ok: true }
}

export function checkHardcodedUrls(content: string, filePath: string): GuardResult {
  if (!filePath.endsWith('.nix')) return { ok: true }
  if (isConfigAllowedPath(filePath)) return { ok: true }

  const urlPattern = /localhost:\d{4,5}/g
  if (urlPattern.test(content) && !content.includes('urls.') && !content.includes('services.')) {
    return {
      ok: false,
      error: `Guard 30: Hardcoded localhost URL. Use urls.* reference from lib/config/`,
    }
  }

  return { ok: true }
}

// =============================================================================
// Guard 32: Secrets Detection
// =============================================================================

const SECRETS_PATTERNS: readonly { name: string; pattern: RegExp }[] = [
  { name: 'PRIVATE_KEY', pattern: /-----BEGIN\s+(RSA\s+|EC\s+)?PRIVATE KEY-----/ },
  { name: 'AWS_ACCESS_KEY', pattern: /AKIA[0-9A-Z]{16}/ },
  { name: 'GITHUB_PAT', pattern: /ghp_[A-Za-z0-9]{36}/ },
  { name: 'GITHUB_OAUTH', pattern: /gho_[A-Za-z0-9]{36}/ },
  { name: 'GITHUB_FINE_PAT', pattern: /github_pat_[A-Za-z0-9]{22}_[A-Za-z0-9]{59}/ },
  { name: 'OPENAI_KEY', pattern: /sk-[A-Za-z0-9]{48}/ },
  { name: 'OPENAI_PROJECT', pattern: /sk-proj-[A-Za-z0-9]{48}/ },
  { name: 'SLACK_TOKEN', pattern: /xox[baprs]-[A-Za-z0-9-]+/ },
  { name: 'STRIPE_LIVE', pattern: /sk_live_[A-Za-z0-9]{24,}/ },
  { name: 'STRIPE_PK', pattern: /pk_live_[A-Za-z0-9]{24,}/ },
]

const SECRETS_ALLOWED_PATHS = [
  '.enc',
  '/secrets/',
  '.example',
  '.template',
  'SKILL.md',
  '.test.',
  '.spec.',
]

export function checkSecrets(content: string, filePath: string): GuardResult {
  // Skip allowed paths
  if (SECRETS_ALLOWED_PATHS.some((p) => filePath.includes(p))) {
    return { ok: true }
  }

  for (const { name, pattern } of SECRETS_PATTERNS) {
    const match = content.match(pattern)
    if (match) {
      const masked = `${match[0].substring(0, 8)}...`
      return {
        ok: false,
        error: `Guard 32: SECRETS DETECTED\n\nType: ${name}\nMatch: ${masked}\nFile: ${filePath}\n\nFix: Use Pulumi ESC for secrets, not code.`,
      }
    }
  }

  return { ok: true }
}

// =============================================================================
// Guard 31: Stack Compliance - CONSOLIDATED
// Now uses SSOT from src/stack/forbidden.ts via checkForbiddenPackages in pre-tool-use.ts
// =============================================================================

// =============================================================================
// Guard 34: REMOVED (Jan 2026)
// Scaffolding enforcement was too restrictive for legitimate directory creation.
// Copier templates remain available via: /copier-template skill
// =============================================================================

// =============================================================================
// Guard 51: Zero Environment Awareness (IoC Behavior Injection)
// =============================================================================

/**
 * Environment variable names and patterns that indicate environment awareness.
 * Code should receive behavior flags (showStackTraces: false) not check environments.
 */
const ENV_CONDITIONAL_PATTERNS: readonly { pattern: RegExp; name: string }[] = [
  // Direct environment variable names
  { pattern: /\bNODE_ENV\b/, name: 'NODE_ENV' },
  { pattern: /\bENVIRONMENT\b/, name: 'ENVIRONMENT' },
  { pattern: /\bIS_PROD(UCTION)?\b/, name: 'IS_PROD/IS_PRODUCTION' },
  { pattern: /\bIS_DEV(ELOPMENT)?\b/, name: 'IS_DEV/IS_DEVELOPMENT' },
  { pattern: /\bIS_TEST\b/, name: 'IS_TEST' },
  // import.meta.env patterns
  { pattern: /import\.meta\.env\.MODE/, name: 'import.meta.env.MODE' },
  { pattern: /import\.meta\.env\.DEV/, name: 'import.meta.env.DEV' },
  { pattern: /import\.meta\.env\.PROD/, name: 'import.meta.env.PROD' },
  // String comparisons with environment names
  { pattern: /===\s*['"]production['"]/, name: '=== "production"' },
  { pattern: /===\s*['"]development['"]/, name: '=== "development"' },
  { pattern: /===\s*['"]test['"]/, name: '=== "test"' },
  { pattern: /!==\s*['"]production['"]/, name: '!== "production"' },
  { pattern: /!==\s*['"]development['"]/, name: '!== "development"' },
  { pattern: /!==\s*['"]test['"]/, name: '!== "test"' },
]

/**
 * Paths where environment checks are allowed (documentation, tests, skill files)
 */
const ENV_CHECK_ALLOWED_PATHS = [
  '.test.ts',
  '.spec.ts',
  '.test.tsx',
  '.spec.tsx',
  'SKILL.md',
  '/skills/',
  '/templates/',
  '/examples/',
  '.md',
] as const

export function checkZeroEnvironmentAwareness(content: string, filePath: string): GuardResult {
  // Skip allowed paths (tests, docs, skills, templates)
  if (ENV_CHECK_ALLOWED_PATHS.some((p) => filePath.includes(p))) {
    return { ok: true }
  }

  // Only check TypeScript/JavaScript files
  if (!FILE_EXT.typescript.test(filePath)) {
    return { ok: true }
  }

  for (const { pattern, name } of ENV_CONDITIONAL_PATTERNS) {
    if (pattern.test(content)) {
      return {
        ok: false,
        error: `Guard 51: ZERO ENVIRONMENT AWARENESS VIOLATION

Detected: ${name}
File: ${filePath}

Code must not check environment variables to determine behavior.
Instead, inject behavior flags via Config service:

  // BAD - environment awareness
  if (process.env.NODE_ENV === 'production') { ... }

  // GOOD - behavior injection via Config service
  class Config extends Context.Tag("Config")<Config, {
    showStackTraces: boolean;
    logLevel: "debug" | "info" | "warn" | "error";
  }>() {}

  const cfg = yield* Config;
  if (cfg.showStackTraces) { ... }

Config must be loaded from external files or CLI args, not process.env.

See: zero-environment-awareness skill`,
      }
    }
  }

  return { ok: true }
}

// =============================================================================
// Guards 52-55: Effect-XState Integration
// =============================================================================

/**
 * Paths where Effect-XState guards are skipped (tests, docs, skills)
 */
const EFFECT_XSTATE_ALLOWED_PATHS = [
  '.test.ts',
  '.spec.ts',
  '.test.tsx',
  '.spec.tsx',
  'SKILL.md',
  '/skills/',
  '/templates/',
  '/examples/',
  '.md',
] as const

function isEffectXstateExcluded(filePath: string): boolean {
  return EFFECT_XSTATE_ALLOWED_PATHS.some((p) => filePath.includes(p))
}

/**
 * Guard 52: No Effect.runPromise().then/.catch
 * Loses typed errors - use runPromiseExit + Exit.isFailure instead
 */
export function checkRunPromiseThenCatch(content: string, filePath: string): GuardResult {
  if (isEffectXstateExcluded(filePath)) return { ok: true }
  if (!FILE_EXT.typescriptStrict.test(filePath)) return { ok: true }

  // Check for Effect.runPromise followed by .then or .catch
  const pattern = /Effect\.runPromise\([^)]+\)\s*\.(then|catch)\s*\(/
  if (pattern.test(content)) {
    return {
      ok: false,
      error: `Guard 52: EFFECT.RUNPROMISE().THEN/.CATCH BANNED

File: ${filePath}

Effect.runPromise().then/.catch loses typed errors.

BAD:
  Effect.runPromise(myEffect).then(r => ...).catch(e => String(e))

GOOD:
  const exit = await Effect.runPromiseExit(myEffect)
  if (Exit.isFailure(exit)) {
    const cause = exit.cause  // Typed Cause<E>
  }

See: effect-xstate skill`,
    }
  }

  return { ok: true }
}

/**
 * Guard 53: No useRef for XState-owned state
 * Refs near useMachine/useActor indicate split-brain state
 */
export function checkRefForMachineState(content: string, filePath: string): GuardResult {
  if (isEffectXstateExcluded(filePath)) return { ok: true }
  if (!FILE_EXT.tsx.test(filePath)) return { ok: true }

  // Check if file uses XState hooks
  const hasXstateHook = CMD_PARSE.xstateHook.test(content)
  if (!hasXstateHook) return { ok: true }

  // Check for suspicious useRef patterns (not DOM refs)
  const suspiciousRefPatterns = [
    /useRef<string/,
    /useRef<number/,
    /useRef<boolean/,
    /useRef<.*\|.*null/,
    /useRef<.*Token/i,
    /useRef<.*Response/i,
    /useRef<.*Data/i,
    /useRef<.*Result/i,
  ]

  for (const pattern of suspiciousRefPatterns) {
    if (pattern.test(content)) {
      return {
        ok: true,
        warnings: [
          `Guard 53 (advisory): useRef near XState detected in ${filePath}. ` +
            'If storing API responses/tokens/state, move to machine context instead.',
        ],
      }
    }
  }

  return { ok: true }
}

/**
 * Guard 54: No useEffect + Effect.runPromise
 * Bypasses XState's invoke system - use fromPromise actor instead
 */
export function checkUseEffectRunPromise(content: string, filePath: string): GuardResult {
  if (isEffectXstateExcluded(filePath)) return { ok: true }
  if (!FILE_EXT.tsx.test(filePath)) return { ok: true }

  // Check for useEffect containing Effect.runPromise
  const useEffectPattern = /useEffect\s*\(\s*(?:async\s*)?\(\s*\)\s*=>\s*\{[^}]*Effect\.runPromise/s
  if (useEffectPattern.test(content)) {
    return {
      ok: false,
      error: `Guard 54: USEEFFECT + EFFECT.RUNPROMISE BANNED

File: ${filePath}

useEffect + Effect.runPromise bypasses XState's invoke system.

BAD:
  useEffect(() => {
    Effect.runPromise(fetchData).then(d => send({ type: "DONE", d }))
  }, [])

GOOD:
  const fetchActor = fromPromise(async ({ input }) => {
    const exit = await Effect.runPromiseExit(fetchData(input))
    if (Exit.isFailure(exit)) throw exit.cause
    return exit.value
  })

  // In machine:
  invoke: { src: 'fetchActor', onDone: ..., onError: ... }

See: effect-xstate skill`,
    }
  }

  return { ok: true }
}

/**
 * Guard 55: No String(err) error conversion
 * Loses typed error information - preserve Cause types
 */
export function checkStringErrorConversion(content: string, filePath: string): GuardResult {
  if (isEffectXstateExcluded(filePath)) return { ok: true }
  if (!FILE_EXT.typescriptStrict.test(filePath)) return { ok: true }

  // Check for String(err) or err.message in catch-like contexts
  const patterns = [
    /\.catch\s*\([^)]*=>\s*[^)]*String\s*\(\s*(err|error|e)\s*\)/,
    /\.catch\s*\([^)]*=>\s*[^)]*\.(message|toString\(\))/,
    /catch\s*\([^)]*\)\s*\{[^}]*String\s*\(\s*(err|error|e)\s*\)/,
  ]

  for (const pattern of patterns) {
    if (pattern.test(content)) {
      return {
        ok: true,
        warnings: [
          `Guard 55 (advisory): String(err) detected in ${filePath}. ` +
            'Consider preserving Effect Cause types instead of converting to string.',
        ],
      }
    }
  }

  return { ok: true }
}

// =============================================================================
// Main Entry Point
// =============================================================================

export function runProceduralGuards(
  toolName: string,
  toolInput: { file_path?: string; content?: string; command?: string },
): GuardResult {
  const { file_path: filePath, content, command } = toolInput

  // Bash guards
  if (toolName === 'Bash' && command) {
    const bashResult = checkBashSafety(command)
    if (!bashResult.ok) return bashResult

    // Guard 33: Hook bypass prevention
    const hookBypassResult = checkHookBypass(command)
    if (!hookBypassResult.ok) return hookBypassResult

    const commitResult = checkConventionalCommit(command)
    if (!commitResult.ok) return commitResult

    const devOpsResult = checkDevOpsCommands(command)
    if (!devOpsResult.ok) return devOpsResult

    // Guard 27: Legacy CLI tool syntax detection
    const cliToolsResult = checkModernCLITools(command)
    if (!cliToolsResult.ok) return cliToolsResult

    // Guard 34: REMOVED - Scaffolding enforcement was too restrictive
    // Copier templates are still available but not enforced
  }

  // Write/Edit guards
  if ((toolName === 'Write' || toolName === 'Edit') && filePath) {
    const forbiddenResult = checkForbiddenFiles(filePath)
    if (!forbiddenResult.ok) return forbiddenResult

    // TDD check (sync version - full enforcement at commit time)
    const tddResult = checkTDD(filePath)
    if (!tddResult.ok) return tddResult

    // Config centralization (Nix)
    if (content) {
      // Secrets detection (Guard 32)
      const secretsResult = checkSecrets(content, filePath)
      if (!secretsResult.ok) return secretsResult

      // Guard 51: Zero Environment Awareness (IoC behavior injection)
      const envAwarenessResult = checkZeroEnvironmentAwareness(content, filePath)
      if (!envAwarenessResult.ok) return envAwarenessResult

      // Guards 52-55: Effect-XState Integration
      const runPromiseResult = checkRunPromiseThenCatch(content, filePath)
      if (!runPromiseResult.ok) return runPromiseResult

      const useEffectRunPromiseResult = checkUseEffectRunPromise(content, filePath)
      if (!useEffectRunPromiseResult.ok) return useEffectRunPromiseResult

      const portsResult = checkHardcodedPorts(content, filePath)
      if (!portsResult.ok) return portsResult

      const urlsResult = checkHardcodedUrls(content, filePath)
      if (!urlsResult.ok) return urlsResult

      // Guard 31: Stack compliance handled by checkForbiddenPackages in pre-tool-use.ts

      // Advisory guards (collect warnings)
      const warnings: string[] = []

      const flakeResult = checkFlakePatterns(content, filePath)
      if (flakeResult.ok && flakeResult.warnings) {
        warnings.push(...flakeResult.warnings)
      }

      const portResult = checkPortRegistry(content, filePath)
      if (portResult.ok && portResult.warnings) {
        warnings.push(...portResult.warnings)
      }

      // Guards 53, 55: Advisory Effect-XState checks
      const refMachineResult = checkRefForMachineState(content, filePath)
      if (refMachineResult.ok && refMachineResult.warnings) {
        warnings.push(...refMachineResult.warnings)
      }

      const stringErrorResult = checkStringErrorConversion(content, filePath)
      if (stringErrorResult.ok && stringErrorResult.warnings) {
        warnings.push(...stringErrorResult.warnings)
      }

      if (warnings.length > 0) {
        return { ok: true, warnings }
      }
    }
  }

  return { ok: true }
}
