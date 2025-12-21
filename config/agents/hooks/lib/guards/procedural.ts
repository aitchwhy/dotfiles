/**
 * Procedural Guards - Guards that need file system or command parsing
 *
 * Guards: 1 (bash safety), 2 (commits), 3 (forbidden files),
 *         8 (TDD), 9-10 (DevOps), 11-12 (advisory), 28-31 (config/stack),
 *         32 (secrets detection - absorbed from secrets-audit.ts)
 */

import { existsSync, appendFileSync } from 'node:fs';
import { type GuardResult } from '../types';

// =============================================================================
// Guard 1: Bash Safety
// =============================================================================

export function checkBashSafety(command: string): GuardResult {
  if (command.includes('rm -rf /') || command.includes('rm -rf ~')) {
    return { ok: false, error: 'BLOCKED: Dangerous recursive delete command detected.' };
  }
  return { ok: true };
}

// =============================================================================
// Guard 2: Conventional Commits
// =============================================================================

const CONVENTIONAL_COMMIT_REGEX = /^(feat|fix|refactor|test|docs|chore|perf|ci)(\([a-z0-9-]+\))?!?:\s+[a-z]/;
const VALID_COMMIT_TYPES = ['feat', 'fix', 'refactor', 'test', 'docs', 'chore', 'perf', 'ci'];

function extractCommitMessage(command: string): string | null {
  const doubleQuoteMatch = command.match(/git\s+commit\s+.*-m\s+"([^"]+)"/);
  if (doubleQuoteMatch?.[1]) return doubleQuoteMatch[1];

  const singleQuoteMatch = command.match(/git\s+commit\s+.*-m\s+'([^']+)'/);
  if (singleQuoteMatch?.[1]) return singleQuoteMatch[1];

  const heredocMatch = command.match(/git\s+commit\s+.*-m\s+"\$\(cat\s+<<['"]?(\w+)['"]?\n([\s\S]*?)\n\1/);
  if (heredocMatch?.[2]) return heredocMatch[2].trim().split('\n')[0] ?? null;

  return null;
}

export function checkConventionalCommit(command: string): GuardResult {
  if (!/git\s+commit\s+.*-m\s+/.test(command)) return { ok: true };

  const message = extractCommitMessage(command);
  if (!message) return { ok: true };

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
    };
  }

  return { ok: true };
}

// =============================================================================
// Guard 3: Forbidden Files
// =============================================================================

type ForbiddenFile = {
  readonly pattern: string | RegExp;
  readonly reason: string;
  readonly alternative: string;
};

const FORBIDDEN_FILES: readonly ForbiddenFile[] = [
  { pattern: 'package-lock.json', reason: 'Use pnpm', alternative: 'pnpm install' },
  { pattern: 'yarn.lock', reason: 'Use pnpm', alternative: 'pnpm install' },
  { pattern: 'bun.lock', reason: 'Use pnpm', alternative: 'pnpm install' },
  { pattern: 'bun.lockb', reason: 'Use pnpm', alternative: 'pnpm install' },
  { pattern: /\.eslintrc(\.(js|cjs|mjs|json|yaml|yml))?$/, reason: 'Use Biome', alternative: 'biome.json' },
  { pattern: /eslint\.config\.(js|cjs|mjs|ts)$/, reason: 'Use Biome', alternative: 'biome.json' },
  { pattern: /\.prettierrc(\.(js|cjs|mjs|json|yaml|yml))?$/, reason: 'Use Biome', alternative: 'biome.json' },
  { pattern: /prettier\.config\.(js|cjs|mjs|ts)$/, reason: 'Use Biome', alternative: 'biome.json' },
  { pattern: /jest\.config\.(js|cjs|mjs|ts|json)$/, reason: 'Use Vitest', alternative: 'vitest.config.ts' },
  { pattern: /prisma\/schema\.prisma$/, reason: 'Use Drizzle', alternative: 'drizzle.config.ts' },
  { pattern: /^process-compose\.(ya?ml)$/, reason: 'Use Docker Compose', alternative: 'docker compose up' },
  { pattern: /^\.env$/, reason: 'Use Pulumi ESC', alternative: 'esc env open org/proj/dev' },
];

export function checkForbiddenFiles(filePath: string): GuardResult {
  const fileName = filePath.split('/').pop() ?? '';

  for (const forbidden of FORBIDDEN_FILES) {
    const matches =
      typeof forbidden.pattern === 'string'
        ? fileName === forbidden.pattern || filePath.endsWith(forbidden.pattern)
        : forbidden.pattern.test(fileName) || forbidden.pattern.test(filePath);

    if (matches) {
      return {
        ok: false,
        error: `FORBIDDEN FILE: ${fileName}\n\nReason: ${forbidden.reason}\nAlternative: ${forbidden.alternative}`,
      };
    }
  }

  return { ok: true };
}

// =============================================================================
// Guard 8: TDD Enforcer
// =============================================================================

type LanguageConfig = {
  readonly extensions: readonly string[];
  readonly testPatterns: readonly RegExp[];
  readonly getTestPaths: (sourcePath: string) => string[];
};

const LANGUAGES: Record<string, LanguageConfig> = {
  typescript: {
    extensions: ['.ts', '.tsx'],
    testPatterns: [/\.test\.[tj]sx?$/, /\.spec\.[tj]sx?$/, /_test\.[tj]sx?$/, /\.e2e\.[tj]sx?$/],
    getTestPaths: (sourcePath: string) => {
      const dir = sourcePath.replace(/\/[^/]+$/, '');
      const base = sourcePath.replace(/^.*\//, '').replace(/\.[^.]+$/, '');
      const ext = sourcePath.match(/\.[^.]+$/)?.[0] ?? '.ts';
      return [`${dir}/${base}.test${ext}`, `${dir}/${base}.spec${ext}`, `${dir}/__tests__/${base}.test${ext}`];
    },
  },
  python: {
    extensions: ['.py'],
    testPatterns: [/^test_.*\.py$/, /.*_test\.py$/],
    getTestPaths: (sourcePath: string) => {
      const dir = sourcePath.replace(/\/[^/]+$/, '');
      const base = sourcePath.replace(/^.*\//, '').replace(/\.py$/, '');
      return [`${dir}/test_${base}.py`, `${dir}/${base}_test.py`];
    },
  },
};

const TDD_EXCLUDED_DIRS = ['/node_modules/', '/.git/', '/dist/', '/migrations/', '/scripts/', '/__pycache__/'];
const TDD_EXCLUDED_FILES = [/^__init__\.py$/, /\.config\.[tj]sx?$/, /\.d\.ts$/, /index\.[tj]sx?$/];

function getLanguage(path: string): LanguageConfig | null {
  for (const config of Object.values(LANGUAGES)) {
    if (config.extensions.some((ext) => path.endsWith(ext))) return config;
  }
  return null;
}

function isTestFile(path: string, language: LanguageConfig): boolean {
  const fileName = path.replace(/^.*\//, '');
  return language.testPatterns.some((p) => p.test(fileName) || p.test(path));
}

export function checkTDD(filePath: string): GuardResult {
  const language = getLanguage(filePath);
  if (!language) return { ok: true };

  if (TDD_EXCLUDED_DIRS.some((dir) => filePath.includes(dir))) return { ok: true };

  const fileName = filePath.replace(/^.*\//, '');
  if (TDD_EXCLUDED_FILES.some((p) => p.test(fileName))) return { ok: true };

  if (isTestFile(filePath, language)) return { ok: true };

  // Check for .tdd-skip bypass
  if (existsSync('.tdd-skip')) {
    // Audit trail for bypass
    const auditEntry = {
      timestamp: new Date().toISOString(),
      guard: 'tdd-enforcer',
      file: filePath,
      bypass: '.tdd-skip',
    };
    try {
      const auditPath = `${process.env.HOME}/.claude-metrics/tdd-bypass.jsonl`;
      appendFileSync(auditPath, JSON.stringify(auditEntry) + '\n');
    } catch {
      /* ignore audit failures */
    }
    return { ok: true, warnings: ['TDD bypassed via .tdd-skip'] };
  }

  // Check if test exists
  const testPaths = language.getTestPaths(filePath);
  for (const p of testPaths) {
    if (existsSync(p)) return { ok: true };
  }

  return {
    ok: false,
    error: `TDD VIOLATION: No test file for ${fileName}

Write the test FIRST (Red phase):
${testPaths.slice(0, 3).map((p) => `  - ${p}`).join('\n')}

Bypass: touch .tdd-skip`,
  };
}

// =============================================================================
// Guards 9-10: DevOps Files and Commands
// =============================================================================

export function checkDevOpsCommands(command: string): GuardResult {
  const forbidden = [
    { pattern: /\bprocess-compose\s+(up|start)\b/, alt: 'docker compose up' },
    { pattern: /\bbun\s+(run|test|install)\b/, alt: 'pnpm run / vitest / pnpm install' },
    { pattern: /\b(npm|yarn)\s+run\s+(dev|start|serve)\b/, alt: 'docker compose up' },
    { pattern: /\bnpm\s+start\b/, alt: 'docker compose up' },
  ];

  for (const { pattern, alt } of forbidden) {
    if (pattern.test(command)) {
      return { ok: false, error: `DEVOPS VIOLATION\n\nAlternative: ${alt}\n\nUse Docker Compose for local orchestration.` };
    }
  }

  return { ok: true };
}

// =============================================================================
// Guards 11-12: Flake Patterns & Port Registry (Advisory)
// =============================================================================

export function checkFlakePatterns(content: string, filePath: string): GuardResult {
  if (!filePath.endsWith('flake.nix')) return { ok: true };

  const warnings: string[] = [];

  if (!content.includes('flake-parts')) {
    warnings.push('Consider flake-parts for modular composition');
  }
  if (content.includes('forAllSystems') || content.includes('lib.genAttrs')) {
    warnings.push('forAllSystems deprecated - use flake-parts perSystem');
  }
  if (content.includes('mkShell') && !content.includes('pre-commit') && !content.includes('git-hooks')) {
    warnings.push('Consider git-hooks.nix for pre-commit integration');
  }

  return { ok: true, warnings: warnings.length > 0 ? warnings : undefined };
}

const KNOWN_PORTS = new Set([22, 41641, 9100, 9080, 6379, 5432, 7233, 3000, 3001, 8233, 4317, 4318, 9090, 3100, 3200]);

export function checkPortRegistry(content: string, filePath: string): GuardResult {
  if (!filePath.endsWith('.nix')) return { ok: true };
  if (!filePath.includes('/modules/') && !filePath.includes('/services/')) return { ok: true };

  const portMatches = content.matchAll(/\bport\s*=\s*(\d{2,5})\b/gi);
  const unknownPorts: number[] = [];

  for (const match of portMatches) {
    const port = parseInt(match[1] ?? '0', 10);
    if (port > 0 && !KNOWN_PORTS.has(port)) {
      unknownPorts.push(port);
    }
  }

  if (unknownPorts.length > 0) {
    return { ok: true, warnings: [`Port(s) ${unknownPorts.join(', ')} not in lib/ports.nix`] };
  }

  return { ok: true };
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
  );
}

export function checkHardcodedPorts(content: string, filePath: string): GuardResult {
  if (!filePath.endsWith('.nix')) return { ok: true };
  if (isConfigAllowedPath(filePath)) return { ok: true };

  const portPattern = /\bport\s*=\s*(\d{4,5})\b/g;
  const matches = [...content.matchAll(portPattern)];

  if (matches.length > 0 && !content.includes('ports.')) {
    return {
      ok: false,
      error: `Guard 28: Hardcoded port detected. Use ports.* reference from lib/config/`,
    };
  }

  return { ok: true };
}

export function checkHardcodedUrls(content: string, filePath: string): GuardResult {
  if (!filePath.endsWith('.nix')) return { ok: true };
  if (isConfigAllowedPath(filePath)) return { ok: true };

  const urlPattern = /localhost:\d{4,5}/g;
  if (urlPattern.test(content) && !content.includes('urls.') && !content.includes('services.')) {
    return {
      ok: false,
      error: `Guard 30: Hardcoded localhost URL. Use urls.* reference from lib/config/`,
    };
  }

  return { ok: true };
}

// =============================================================================
// Guard 32: Secrets Detection (absorbed from secrets-audit.ts)
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
];

const SECRETS_ALLOWED_PATHS = ['.enc', '/secrets/', '.example', '.template', 'SKILL.md', '.test.', '.spec.'];

export function checkSecrets(content: string, filePath: string): GuardResult {
  // Skip allowed paths
  if (SECRETS_ALLOWED_PATHS.some((p) => filePath.includes(p))) {
    return { ok: true };
  }

  for (const { name, pattern } of SECRETS_PATTERNS) {
    const match = content.match(pattern);
    if (match) {
      const masked = match[0].substring(0, 8) + '...';
      return {
        ok: false,
        error: `Guard 32: SECRETS DETECTED\n\nType: ${name}\nMatch: ${masked}\nFile: ${filePath}\n\nFix: Use Pulumi ESC for secrets, not code.`,
      };
    }
  }

  return { ok: true };
}

// =============================================================================
// Guard 31: Stack Compliance
// =============================================================================

const FORBIDDEN_DEPS = [
  'lodash',
  'underscore',
  'express',
  'fastify',
  'koa',
  'hono',
  '@prisma/client',
  'prisma',
  'sequelize',
  'typeorm',
  'mongoose',
  'axios',
  'node-fetch',
  'request',
  'winston',
  'pino',
  'bunyan',
  'chalk',
  'colors',
  'moment',
  'dayjs',
  'date-fns',
  'jest',
  '@jest/core',
  'mocha',
  'jasmine',
  'chai',
  'sinon',
  'bun',
  '@types/bun',
];

type PackageJson = {
  readonly dependencies?: Record<string, string>;
  readonly devDependencies?: Record<string, string>;
};

function parsePackageJson(content: string): PackageJson | null {
  try {
    const parsed: unknown = JSON.parse(content);
    if (typeof parsed !== 'object' || parsed === null) return null;
    return parsed as PackageJson;
  } catch {
    return null;
  }
}

export function checkStackCompliance(content: string, filePath: string): GuardResult {
  if (!filePath.endsWith('package.json')) return { ok: true };

  const pkg = parsePackageJson(content);
  if (!pkg) return { ok: true };

  const allDeps = { ...pkg.dependencies, ...pkg.devDependencies };
  const forbidden = Object.keys(allDeps).filter((dep) => FORBIDDEN_DEPS.includes(dep));

  if (forbidden.length > 0) {
    return {
      ok: false,
      error: `Guard 31: Forbidden dependencies: ${forbidden.join(', ')}\n\nSee stack.md for alternatives.`,
    };
  }

  return { ok: true };
}

// =============================================================================
// Main Entry Point
// =============================================================================

export function runProceduralGuards(
  toolName: string,
  toolInput: { file_path?: string; content?: string; command?: string }
): GuardResult {
  const { file_path: filePath, content, command } = toolInput;

  // Bash guards
  if (toolName === 'Bash' && command) {
    const bashResult = checkBashSafety(command);
    if (!bashResult.ok) return bashResult;

    const commitResult = checkConventionalCommit(command);
    if (!commitResult.ok) return commitResult;

    const devOpsResult = checkDevOpsCommands(command);
    if (!devOpsResult.ok) return devOpsResult;
  }

  // Write/Edit guards
  if ((toolName === 'Write' || toolName === 'Edit') && filePath) {
    const forbiddenResult = checkForbiddenFiles(filePath);
    if (!forbiddenResult.ok) return forbiddenResult;

    // TDD check
    const tddResult = checkTDD(filePath);
    if (!tddResult.ok) return tddResult;

    // Config centralization (Nix)
    if (content) {
      // Secrets detection (Guard 32)
      const secretsResult = checkSecrets(content, filePath);
      if (!secretsResult.ok) return secretsResult;

      const portsResult = checkHardcodedPorts(content, filePath);
      if (!portsResult.ok) return portsResult;

      const urlsResult = checkHardcodedUrls(content, filePath);
      if (!urlsResult.ok) return urlsResult;

      // Stack compliance (package.json)
      const stackResult = checkStackCompliance(content, filePath);
      if (!stackResult.ok) return stackResult;

      // Advisory guards (collect warnings)
      const warnings: string[] = [];

      const flakeResult = checkFlakePatterns(content, filePath);
      if (flakeResult.warnings) warnings.push(...flakeResult.warnings);

      const portResult = checkPortRegistry(content, filePath);
      if (portResult.warnings) warnings.push(...portResult.warnings);

      if (warnings.length > 0) {
        return { ok: true, warnings };
      }
    }
  }

  return { ok: true };
}
