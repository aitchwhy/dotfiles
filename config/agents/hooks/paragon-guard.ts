#!/usr/bin/env bun
/**
 * PARAGON Guard v3.3 - Enforcement System PreToolUse gatekeeper
 *
 * Guards (39 total - all blocking except 11, 12, 35, 38):
 *
 * Tier 1: Original Guards (1-14)
 * 1. Bash safety - blocks dangerous rm -rf commands
 * 2. Conventional commits - validates git commit messages
 * 3. Forbidden files - blocks package-lock.json, eslint config, Docker files, etc.
 * 4. Forbidden imports - blocks express, prisma, zod/v3, GCP OTEL exporters, dd-trace
 * 5. Any type detector - blocks TypeScript `any` usage
 * 6. z.infer detector - blocks z.infer<>, z.input<>, z.output<> (use satisfies pattern)
 * 7. No-mock enforcer - blocks jest.mock, vi.mock, Mock*Live patterns
 *    NOTE: Layer.succeed() is ALLOWED for dependency injection
 * 8. TDD enforcer - requires test file before source code
 * 9. DevOps files - blocks docker-compose.yml, Dockerfile, .dockerignore
 * 10. DevOps commands - blocks docker-compose, docker build, npm run dev
 * 11. Flake patterns - advisory warnings for flake.nix best practices
 * 12. Port registry - advisory warnings for undeclared ports
 * 13. Assumption language - blocks "should work", "probably", "I think", etc.
 * 14. Throw detector - blocks throw in non-invariant contexts
 *
 * Tier 2: Clean Code Guards (15-17) - Uncle Bob
 * 15. No comments - blocks unnecessary inline comments
 * 16. Meaningful names - blocks cryptic abbreviations, Hungarian notation
 * 17. No commented-out code - blocks dead code in comments
 *
 * Tier 3: Extended Clean Code Guards (18-25) - Uncle Bob + SOLID
 * 18. Function arguments - blocks >3 positional parameters
 * 19. Law of Demeter - blocks method chain violations (a.b().c().d())
 * 20. Function size - blocks functions >20 lines
 * 21. Cyclomatic complexity - blocks functions with >10 branches
 * 22. Switch on type - blocks switch(x.type) anti-pattern
 * 23. Null returns - blocks return null (use Option/Result)
 * 24. Interface segregation - blocks large interfaces (>7 members)
 * 25. Deep nesting - blocks >3 indent levels
 *
 * Tier 5: Configuration Centralization (28-30) - Nix files
 * 28. No hardcoded ports - blocks port = 3000 outside lib/config/
 * 30. No hardcoded URLs - blocks localhost:3000 outside lib/config/
 * (Guard 29 Split-brain is cross-file, handled by sig-config MCP tool)
 *
 * Tier 6: Stack Compliance (31) - package.json
 * 31. Stack compliance - blocks forbidden deps (lodash, express, prisma, etc.)
 *
 * Tier 7: Parse-at-Boundary (32-39) - TypeScript files
 * 32. Optional chaining in non-boundary - blocks x?.y chains in domain code
 * 33. Nullish coalescing in non-boundary - blocks x ?? y in domain code
 * 34. Null check then assert - blocks if (x === null) ... x! pattern
 * 35. Type assertions (advisory) - warns on 'as Type' usage
 * 36. Non-null assert without narrowing - blocks x! without type guard
 * 37. Nullable union in context - blocks string | null in Context/State types
 * 38. Truthiness check (advisory) - warns on if (value) implicit checks
 * 39. Undefined check in domain - blocks === undefined in domain code
 *
 * Infinite Loop Prevention:
 * - Violation batching: all issues reported at once
 * - Per-file cooldown: 30s between checks on same file
 * - Max iterations: 3 guard-triggered edits per file per session
 * - Guard groups: related guards skip if sibling fired
 * - Bypass: .paragon-skip, .paragon-skip-{N}, .paragon-refactoring
 *
 * Observability standard: Datadog + OTEL 2.x via OTLP proto exporters.
 * See: paragon skill for full guard matrix.
 */

import { z } from 'zod';
import { appendFileSync, mkdirSync, existsSync, readFileSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';
import {
  approve as hookApprove,
  block as hookBlock,
  logError as hookLogError,
} from './lib/hook-logging';

// ============================================================================
// Infinite Loop Prevention System
// ============================================================================

type GuardViolation = {
  readonly guard: number;
  readonly file: string;
  readonly line?: number;
  readonly message: string;
};

const GUARD_COOLDOWNS = new Map<string, number>();
const COOLDOWN_MS = 30_000;

const ITERATION_COUNTS = new Map<string, number>();
const MAX_ITERATIONS = 3;

const FIRED_GUARD_GROUPS = new Map<string, Set<string>>();

const GUARD_GROUPS: Record<string, number[]> = {
  naming: [14, 16, 18],
  structure: [20, 21, 25],
  patterns: [19, 22, 23],
  comments: [15, 17],
};

function getGuardGroup(guardNum: number): string | null {
  for (const [group, guards] of Object.entries(GUARD_GROUPS)) {
    if (guards.includes(guardNum)) return group;
  }
  return null;
}

function shouldSkipGuard(filePath: string, guardNum: number): boolean {
  const group = getGuardGroup(guardNum);
  if (!group) return false;

  const fileKey = filePath;
  const firedGroups = FIRED_GUARD_GROUPS.get(fileKey);
  if (!firedGroups) return false;

  return firedGroups.has(group) && !firedGroups.has(`guard-${guardNum}`);
}

function markGuardFired(filePath: string, guardNum: number): void {
  const group = getGuardGroup(guardNum);
  if (!group) return;

  const fileKey = filePath;
  if (!FIRED_GUARD_GROUPS.has(fileKey)) {
    FIRED_GUARD_GROUPS.set(fileKey, new Set());
  }
  FIRED_GUARD_GROUPS.get(fileKey)?.add(group);
  FIRED_GUARD_GROUPS.get(fileKey)?.add(`guard-${guardNum}`);
}

function shouldSkipDueToCooldown(filePath: string): boolean {
  const lastCheck = GUARD_COOLDOWNS.get(filePath);
  if (lastCheck && Date.now() - lastCheck < COOLDOWN_MS) {
    return true;
  }
  GUARD_COOLDOWNS.set(filePath, Date.now());
  return false;
}

function shouldAllowDueToMaxIterations(filePath: string): boolean {
  const count = (ITERATION_COUNTS.get(filePath) || 0) + 1;
  ITERATION_COUNTS.set(filePath, count);
  return count > MAX_ITERATIONS;
}

function checkBypassFiles(guardNum?: number): boolean {
  if (existsSync('.paragon-skip')) return true;
  if (existsSync('.paragon-refactoring')) return true;
  if (guardNum && existsSync(`.paragon-skip-${guardNum}`)) return true;
  return false;
}

function formatBatchedViolations(violations: GuardViolation[]): string {
  if (violations.length === 0) return '';
  if (violations.length === 1) return violations[0]?.message || '';

  const header = `PARAGON GUARD: ${violations.length} violations detected\n\n`;
  const body = violations
    .map((v, i) => `[${i + 1}] Guard ${v.guard}${v.line ? ` (line ${v.line})` : ''}\n${v.message}`)
    .join('\n\n---\n\n');

  return header + body + '\n\nFix ALL issues before proceeding.';
}

// ============================================================================
// Performance Metrics
// ============================================================================

type PerfMetric = {
  readonly timestamp: string;
  readonly hook: 'paragon-guard';
  readonly tool: string;
  readonly file: string;
  readonly duration_ms: number;
  readonly result: 'approve' | 'block';
  readonly guards_checked: number;
};

const METRICS_DIR = join(homedir(), '.claude-metrics');
const PERF_LOG = join(METRICS_DIR, 'perf.jsonl');

function logPerf(metric: PerfMetric): void {
  try {
    if (!existsSync(METRICS_DIR)) {
      mkdirSync(METRICS_DIR, { recursive: true });
    }
    appendFileSync(PERF_LOG, JSON.stringify(metric) + '\n');
  } catch {
    // Fail silently - don't block on metrics
  }
}

// ============================================================================
// Input Types (TypeScript first, schema satisfies type)
// ============================================================================

type HookInput = {
  readonly hook_event_name: 'PreToolUse';
  readonly session_id: string;
  readonly tool_name: string;
  readonly tool_input: {
    readonly file_path?: string;
    readonly content?: string;
    readonly new_string?: string;
    readonly command?: string;
    readonly [key: string]: unknown;
  };
};

const HookInputSchema = z.object({
  hook_event_name: z.literal('PreToolUse'),
  session_id: z.string(),
  tool_name: z.string(),
  tool_input: z
    .object({
      file_path: z.string().optional(),
      content: z.string().optional(),
      new_string: z.string().optional(),
      command: z.string().optional(),
    })
    .passthrough(),
}) satisfies z.ZodType<HookInput>;

// ============================================================================
// Output Helpers
// ============================================================================

function allow(): void {
  hookApprove();
}

function block(reason: string): void {
  hookBlock(reason);
}

// ============================================================================
// 1. BASH SAFETY
// ============================================================================

function checkBashSafety(command: string): string | null {
  if (command.includes('rm -rf /') || command.includes('rm -rf ~')) {
    return 'BLOCKED: Dangerous recursive delete command detected.';
  }
  return null;
}

// ============================================================================
// 2. CONVENTIONAL COMMIT VALIDATION
// ============================================================================

const VALID_COMMIT_TYPES = ['feat', 'fix', 'refactor', 'test', 'docs', 'chore', 'perf', 'ci'];
const CONVENTIONAL_COMMIT_REGEX =
  /^(feat|fix|refactor|test|docs|chore|perf|ci)(\([a-z0-9-]+\))?!?:\s+[a-z]/;

function isGitCommitWithMessage(command: string): boolean {
  return /git\s+commit\s+.*-m\s+/.test(command);
}

function extractCommitMessage(command: string): string | null {
  const doubleQuoteMatch = command.match(/git\s+commit\s+.*-m\s+"([^"]+)"/);
  if (doubleQuoteMatch) return doubleQuoteMatch[1] || null;

  const singleQuoteMatch = command.match(/git\s+commit\s+.*-m\s+'([^']+)'/);
  if (singleQuoteMatch) return singleQuoteMatch[1] || null;

  const heredocMatch = command.match(
    /git\s+commit\s+.*-m\s+"\$\(cat\s+<<['"]?(\w+)['"]?\n([\s\S]*?)\n\1/
  );
  if (heredocMatch?.[2]) {
    return heredocMatch[2].trim().split('\n')[0] || null;
  }

  return null;
}

function checkConventionalCommit(command: string): string | null {
  if (!isGitCommitWithMessage(command)) return null;

  const message = extractCommitMessage(command);
  if (!message) return null;

  if (!CONVENTIONAL_COMMIT_REGEX.test(message)) {
    return `CONVENTIONAL COMMIT VIOLATION

Invalid: '${message.substring(0, 50)}${message.length > 50 ? '...' : ''}'

Expected format: type(scope): description (lowercase first letter)

Valid types: ${VALID_COMMIT_TYPES.join(', ')}

Examples:
  feat(auth): add OAuth2 login
  fix(api): handle null response
  chore: update dependencies`;
  }

  return null;
}

// ============================================================================
// 3. FORBIDDEN FILES
// ============================================================================

interface ForbiddenFile {
  pattern: string | RegExp;
  reason: string;
  alternative: string;
}

const FORBIDDEN_FILES: ForbiddenFile[] = [
  // Package manager lockfiles - use Bun
  { pattern: 'package-lock.json', reason: 'Use Bun', alternative: 'bun install' },
  { pattern: 'yarn.lock', reason: 'Use Bun', alternative: 'bun install' },
  { pattern: 'pnpm-lock.yaml', reason: 'Use Bun', alternative: 'bun install' },
  // Linting - use Biome
  { pattern: /\.eslintrc(\.(js|cjs|mjs|json|yaml|yml))?$/, reason: 'Use Biome', alternative: 'biome.json' },
  { pattern: /eslint\.config\.(js|cjs|mjs|ts)$/, reason: 'Use Biome', alternative: 'biome.json' },
  { pattern: /\.prettierrc(\.(js|cjs|mjs|json|yaml|yml))?$/, reason: 'Use Biome', alternative: 'biome.json' },
  { pattern: /prettier\.config\.(js|cjs|mjs|ts)$/, reason: 'Use Biome', alternative: 'biome.json' },
  // Testing - use Bun test
  { pattern: /jest\.config\.(js|cjs|mjs|ts|json)$/, reason: 'Use Bun test', alternative: 'bun test' },
  // ORM - use Drizzle
  { pattern: /prisma\/schema\.prisma$/, reason: 'Use Drizzle', alternative: 'drizzle.config.ts' },
  // DevOps - use process-compose and nix2container (Guard 9)
  { pattern: /^docker-compose\.(ya?ml)$/, reason: 'Use process-compose for local orchestration', alternative: 'process-compose.yaml' },
  { pattern: /^Dockerfile(\..*)?$/, reason: 'Use nix2container for OCI images', alternative: 'nix build .#container-<name>' },
  { pattern: '.dockerignore', reason: 'Not needed with nix2container', alternative: 'Nix handles build context automatically' },
];

function checkForbiddenFiles(filePath: string): string | null {
  const fileName = filePath.split('/').pop() || '';

  for (const forbidden of FORBIDDEN_FILES) {
    if (typeof forbidden.pattern === 'string') {
      if (fileName === forbidden.pattern || filePath.endsWith(forbidden.pattern)) {
        return `FORBIDDEN FILE: ${fileName}

Reason: ${forbidden.reason} instead of this file
Alternative: ${forbidden.alternative}

See lib/versions.nix for approved tools.`;
      }
    } else {
      if (forbidden.pattern.test(fileName) || forbidden.pattern.test(filePath)) {
        return `FORBIDDEN FILE: ${fileName}

Reason: ${forbidden.reason} instead of this file
Alternative: ${forbidden.alternative}

See lib/versions.nix for approved tools.`;
      }
    }
  }
  return null;
}

// ============================================================================
// 4. FORBIDDEN IMPORTS
// ============================================================================

interface ForbiddenImport {
  patterns: RegExp[];
  package: string;
  alternative: string;
  docs?: string;
}

const FORBIDDEN_IMPORTS: ForbiddenImport[] = [
  // ===========================================================================
  // FRAMEWORK BANS
  // ===========================================================================
  {
    patterns: [/from\s+['"]express['"]/, /require\s*\(\s*['"]express['"]\s*\)/],
    package: 'express',
    alternative: '@effect/platform (Effect Platform HTTP)',
    docs: 'https://effect.website/docs/platform/http-server',
  },
  {
    patterns: [/from\s+['"]fastify['"]/, /require\s*\(\s*['"]fastify['"]\s*\)/],
    package: 'fastify',
    alternative: '@effect/platform (Effect Platform HTTP)',
    docs: 'https://effect.website/docs/platform/http-server',
  },
  {
    patterns: [/from\s+['"]hono['"]/, /require\s*\(\s*['"]hono['"]\s*\)/],
    package: 'hono',
    alternative: '@effect/platform (Effect Platform HTTP)',
    docs: 'https://effect.website/docs/platform/http-server',
  },
  {
    patterns: [/from\s+['"]@prisma\/client['"]/, /require\s*\(\s*['"]@prisma\/client['"]\s*\)/],
    package: '@prisma/client',
    alternative: 'drizzle-orm',
    docs: 'https://orm.drizzle.team',
  },
  {
    patterns: [/from\s+['"]zod\/v3['"]/],
    package: 'zod/v3',
    alternative: 'zod (v4 is the default now)',
    docs: 'https://zod.dev',
  },
  // ===========================================================================
  // OBSERVABILITY BANS (Datadog + OTEL 2.x standard)
  // ===========================================================================
  {
    patterns: [/@google-cloud\/opentelemetry-cloud-trace-exporter/],
    package: '@google-cloud/opentelemetry-cloud-trace-exporter',
    alternative: '@opentelemetry/exporter-trace-otlp-proto → Datadog',
    docs: 'GCP-specific exporter causes split-brain observability',
  },
  {
    patterns: [/@google-cloud\/opentelemetry-cloud-monitoring-exporter/],
    package: '@google-cloud/opentelemetry-cloud-monitoring-exporter',
    alternative: '@opentelemetry/exporter-metrics-otlp-proto → Datadog',
    docs: 'GCP-specific exporter causes split-brain observability',
  },
  {
    patterns: [/["']dd-trace["']/],
    package: 'dd-trace',
    alternative: 'OpenTelemetry SDK with OTLP → Datadog Agent',
    docs: 'dd-trace does not work with Bun runtime',
  },
  {
    patterns: [/@opentelemetry\/exporter-trace-otlp-http/],
    package: '@opentelemetry/exporter-trace-otlp-http',
    alternative: '@opentelemetry/exporter-trace-otlp-proto (better performance)',
  },
  {
    patterns: [/@opentelemetry\/exporter-metrics-otlp-http/],
    package: '@opentelemetry/exporter-metrics-otlp-http',
    alternative: '@opentelemetry/exporter-metrics-otlp-proto (better performance)',
  },
];

// ============================================================================
// Content Preprocessing Cache
// ============================================================================

// Cache preprocessed content to avoid repeated processing
const contentCache = new Map<string, { stripped: string; strippedWithStrings: string }>();

function getPreprocessedContent(content: string): { stripped: string; strippedWithStrings: string } {
  const cached = contentCache.get(content);
  if (cached) return cached;

  const stripped = content.replace(/\/\/.*$/gm, '').replace(/\/\*[\s\S]*?\*\//g, '');
  const strippedWithStrings = stripped
    .replace(/'(?:[^'\\]|\\.)*'/g, "''")
    .replace(/"(?:[^"\\]|\\.)*"/g, '""')
    .replace(/`(?:[^`\\]|\\.)*`/g, '``');

  const result = { stripped, strippedWithStrings };
  contentCache.set(content, result);

  // Limit cache size to prevent memory growth
  if (contentCache.size > 10) {
    const firstKey = contentCache.keys().next().value;
    if (firstKey) contentCache.delete(firstKey);
  }

  return result;
}

function stripComments(code: string): string {
  return getPreprocessedContent(code).stripped;
}

function checkForbiddenImports(content: string, filePath: string): string | null {
  if (!/\.[jt]sx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;

  const cleanContent = stripComments(content);

  for (const forbidden of FORBIDDEN_IMPORTS) {
    for (const pattern of forbidden.patterns) {
      if (pattern.test(cleanContent)) {
        return `FORBIDDEN IMPORT: '${forbidden.package}' detected

Use ${forbidden.alternative} instead.
${forbidden.docs ? `Docs: ${forbidden.docs}` : ''}

This package is blocked by stack standards.
See lib/versions.nix for approved packages.`;
      }
    }
  }
  return null;
}

// ============================================================================
// 5. ANY TYPE DETECTOR
// ============================================================================

const ANY_TYPE_PATTERNS = [
  /:\s*any\b/,
  /\bas\s+any\b/,
  /<any\s*>/,
  /<any\s*,/,
  /,\s*any\s*>/,
  /\):\s*any\b/,
];

function stripCommentsAndStrings(code: string): string {
  return getPreprocessedContent(code).strippedWithStrings;
}

function checkAnyType(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;

  const cleanContent = stripCommentsAndStrings(content);
  const lines = cleanContent.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line) continue;

    for (const pattern of ANY_TYPE_PATTERNS) {
      if (pattern.test(line)) {
        const match = line.match(pattern);
        return `ANY TYPE VIOLATION: '${match?.[0]?.trim()}' detected (line ~${i + 1})

Use \`unknown\` + Zod parsing instead:

  const data: unknown = await fetch(...);
  const parsed = MySchema.parse(data);

Or use type guards:

  if (isUser(data)) {
    // data is now typed as User
  }

Zero \`any\` policy - see CLAUDE.md TypeScript Standards.`;
      }
    }
  }
  return null;
}

// ============================================================================
// 6. Z.INFER DETECTOR
// ============================================================================

const ZINFER_PATTERNS = [
  /z\.infer\s*</,
  /z\.input\s*</,
  /z\.output\s*</,
];

function checkZodInfer(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;

  const cleanContent = stripCommentsAndStrings(content);

  for (const pattern of ZINFER_PATTERNS) {
    if (pattern.test(cleanContent)) {
      return `ZOD INFER VIOLATION: z.infer<> detected

TypeScript type MUST be source of truth. Never derive types from schemas.

  // ❌ BLOCKED
  const schema = z.object({ name: z.string() });
  type User = z.infer<typeof schema>;

  // ✅ CORRECT - Type first, schema satisfies
  type User = { readonly name: string };
  const schema = z.object({ name: z.string() }) satisfies z.ZodType<User>;

See: zod-patterns skill for TypeScript-first Zod patterns.`;
    }
  }
  return null;
}

// ============================================================================
// 7. NO-MOCK ENFORCER (renumbered from 6)
// ============================================================================

const MOCK_PATTERNS: { pattern: RegExp; description: string }[] = [
  { pattern: /Mock[A-Z][a-zA-Z]*Live/, description: 'Mock*Live class' },
  { pattern: /jest\.mock\s*\(/, description: 'jest.mock()' },
  { pattern: /vi\.mock\s*\(/, description: 'vi.mock()' },
  { pattern: /sinon\.(stub|mock|spy|fake)\s*\(/, description: 'sinon.*()' },
  { pattern: /\.mockImplementation\s*\(/, description: '.mockImplementation()' },
  { pattern: /\.mockResolvedValue\s*\(/, description: '.mockResolvedValue()' },
  { pattern: /\.mockReturnValue\s*\(/, description: '.mockReturnValue()' },
  { pattern: /__mocks__\//, description: '__mocks__/ directory' },
  { pattern: /class\s+Fake[A-Z]/, description: 'Fake* class' },
  { pattern: /class\s+Stub[A-Z]/, description: 'Stub* class' },
];

function checkNoMocks(content: string, filePath: string): string | null {
  // Only check TS/JS files
  if (!/\.[jt]sx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;

  const cleanContent = stripCommentsAndStrings(content);

  for (const { pattern, description } of MOCK_PATTERNS) {
    if (pattern.test(cleanContent)) {
      return `NO-MOCK VIOLATION: ${description} detected

Use real adapters with service containers instead:

  // ❌ BLOCKED
  const mockStorage = new MockStorageLive();
  jest.mock('@/adapters/storage');

  // ✅ ALLOWED - Factory returns real MinIO in tests
  const storage = createStorageAdapter(); // Auto-detects MINIO_ENDPOINT

  // ✅ ALLOWED - Effect-TS Layer.succeed() for DI at composition root
  const TestLayer = Layer.succeed(Database, testDbService);
  // This is dependency injection, NOT mocking!

See: hexagonal-architecture skill for service container patterns.
Run: process-compose up (local) or use GitHub Actions services (CI).`;
    }
  }
  return null;
}

// ============================================================================
// 8. TDD ENFORCER
// ============================================================================

interface LanguageConfig {
  extensions: string[];
  testPatterns: RegExp[];
  getTestPaths: (sourcePath: string) => string[];
}

const LANGUAGES: Record<string, LanguageConfig> = {
  typescript: {
    extensions: ['.ts', '.tsx'],
    testPatterns: [/\.test\.[tj]sx?$/, /\.spec\.[tj]sx?$/, /_test\.[tj]sx?$/, /\.e2e\.[tj]sx?$/],
    getTestPaths: (sourcePath: string) => {
      const dir = sourcePath.replace(/\/[^/]+$/, '');
      const base = sourcePath.replace(/^.*\//, '').replace(/\.[^.]+$/, '');
      const ext = sourcePath.match(/\.[^.]+$/)?.[0] || '.ts';
      return [
        `${dir}/${base}.test${ext}`,
        `${dir}/${base}.spec${ext}`,
        `${dir}/__tests__/${base}.test${ext}`,
        `${dir.replace(/\/src\//, '/tests/')}/${base}.test${ext}`,
      ];
    },
  },
  javascript: {
    extensions: ['.js', '.jsx', '.mjs', '.cjs'],
    testPatterns: [/\.test\.[jt]sx?$/, /\.spec\.[jt]sx?$/, /_test\.[jt]sx?$/],
    getTestPaths: (sourcePath: string) => {
      const dir = sourcePath.replace(/\/[^/]+$/, '');
      const base = sourcePath.replace(/^.*\//, '').replace(/\.[^.]+$/, '');
      const ext = sourcePath.match(/\.[^.]+$/)?.[0] || '.js';
      return [
        `${dir}/${base}.test${ext}`,
        `${dir}/${base}.spec${ext}`,
        `${dir}/__tests__/${base}.test${ext}`,
      ];
    },
  },
  python: {
    extensions: ['.py'],
    testPatterns: [/^test_.*\.py$/, /.*_test\.py$/],
    getTestPaths: (sourcePath: string) => {
      const dir = sourcePath.replace(/\/[^/]+$/, '');
      const base = sourcePath.replace(/^.*\//, '').replace(/\.py$/, '');
      return [
        `${dir}/test_${base}.py`,
        `${dir}/${base}_test.py`,
        `${dir}/tests/test_${base}.py`,
        `${dir.replace(/\/src\//, '/tests/')}/test_${base}.py`,
      ];
    },
  },
  go: {
    extensions: ['.go'],
    testPatterns: [/_test\.go$/],
    getTestPaths: (sourcePath: string) => {
      const dir = sourcePath.replace(/\/[^/]+$/, '');
      const base = sourcePath.replace(/^.*\//, '').replace(/\.go$/, '');
      return [`${dir}/${base}_test.go`];
    },
  },
  rust: {
    extensions: ['.rs'],
    testPatterns: [/_test\.rs$/, /^tests\/.*\.rs$/],
    getTestPaths: (sourcePath: string) => {
      const dir = sourcePath.replace(/\/[^/]+$/, '');
      const base = sourcePath.replace(/^.*\//, '').replace(/\.rs$/, '');
      return [
        `${dir}/${base}_test.rs`,
        `${dir}/tests/${base}.rs`,
        `${dir.replace(/\/src\//, '/tests/')}/${base}.rs`,
      ];
    },
  },
  shell: {
    extensions: ['.sh', '.bash', '.zsh'],
    testPatterns: [/\.bats$/, /_test\.sh$/],
    getTestPaths: (sourcePath: string) => {
      const dir = sourcePath.replace(/\/[^/]+$/, '');
      const base = sourcePath.replace(/^.*\//, '').replace(/\.(sh|bash|zsh)$/, '');
      return [`${dir}/${base}.bats`, `${dir}/${base}_test.sh`];
    },
  },
};

const EXCLUDED_DIRS = [
  '/node_modules/',
  '/.git/',
  '/dist/',
  '/build/',
  '/.next/',
  '/coverage/',
  '/migrations/',
  '/scripts/',
  '/__pycache__/',
  '/.venv/',
  '/vendor/',
  '/target/',
];

const EXCLUDED_FILES = [
  /^__init__\.py$/,
  /^conftest\.py$/,
  /^setup\.py$/,
  /^main\.go$/,
  /^mod\.rs$/,
  /^lib\.rs$/,
  /\.config\.[tj]sx?$/,
  /\.d\.ts$/,
  /index\.[tj]sx?$/,
];

function getLanguage(path: string): LanguageConfig | null {
  for (const config of Object.values(LANGUAGES)) {
    if (config.extensions.some((ext) => path.endsWith(ext))) {
      return config;
    }
  }
  return null;
}

function isTestFile(path: string, language: LanguageConfig): boolean {
  const fileName = path.replace(/^.*\//, '');
  return language.testPatterns.some((p) => p.test(fileName) || p.test(path));
}

async function testExists(sourcePath: string, language: LanguageConfig): Promise<boolean> {
  const testPaths = language.getTestPaths(sourcePath);
  for (const p of testPaths) {
    if (await Bun.file(p).exists()) return true;
  }

  // Special case for Rust: inline tests
  if (sourcePath.endsWith('.rs')) {
    try {
      const content = await Bun.file(sourcePath).text();
      if (content.includes('#[cfg(test)]') || content.includes('#[test]')) {
        return true;
      }
    } catch {
      // File doesn't exist yet
    }
  }

  return false;
}

async function checkTDD(filePath: string): Promise<string | null> {
  const language = getLanguage(filePath);
  if (!language) return null;

  // Skip excluded directories
  if (EXCLUDED_DIRS.some((dir) => filePath.includes(dir))) return null;

  // Skip excluded files
  const fileName = filePath.replace(/^.*\//, '');
  if (EXCLUDED_FILES.some((pattern) => pattern.test(fileName))) return null;

  // Allow test files themselves
  if (isTestFile(filePath, language)) return null;

  // Check for .tdd-skip bypass file
  if (await Bun.file('.tdd-skip').exists()) return null;

  // Check if test exists
  if (await testExists(filePath, language)) return null;

  // BLOCK: No test file found
  const testPaths = language.getTestPaths(filePath);
  return `TDD VIOLATION: No test file found for ${fileName}

Write the test FIRST (Red phase), then implement the code.

Expected one of:
${testPaths.slice(0, 4).map((p) => `  - ${p}`).join('\n')}

TDD Cycle:
  1. RED: Write a failing test
  2. GREEN: Write minimal code to pass
  3. REFACTOR: Improve while green

To bypass TDD temporarily: touch .tdd-skip`;
}

// ============================================================================
// 10. DEVOPS COMMANDS (Guard 10)
// ============================================================================

interface ForbiddenCommand {
  pattern: RegExp;
  description: string;
  alternative: string;
}

const FORBIDDEN_COMMANDS: ForbiddenCommand[] = [
  // Docker Compose commands
  { pattern: /\bdocker-compose\s+(up|start|run|exec|build)\b/, description: 'docker-compose', alternative: 'process-compose up' },
  { pattern: /\bdocker\s+compose\s+(up|start|run|exec|build)\b/, description: 'docker compose', alternative: 'process-compose up' },
  // Docker build
  { pattern: /\bdocker\s+build\b/, description: 'docker build', alternative: 'nix build .#container-<name>' },
  // npm/bun/yarn/pnpm run dev|start|serve
  { pattern: /\b(npm|bun|yarn|pnpm)\s+run\s+(dev|start|serve)\b/, description: 'npm/bun/yarn/pnpm run dev|start|serve', alternative: 'process-compose up' },
  { pattern: /\bnpm\s+start\b/, description: 'npm start', alternative: 'process-compose up' },
];

function checkDevOpsCommands(command: string): string | null {
  for (const forbidden of FORBIDDEN_COMMANDS) {
    if (forbidden.pattern.test(command)) {
      return `DEVOPS VIOLATION: ${forbidden.description} detected

Alternative: ${forbidden.alternative}

Philosophy: localhost === CI === production
- Use process-compose for local development orchestration
- All services defined in process-compose.yaml
- Run: process-compose up (all) or process-compose up <service>

See: devops-patterns skill for correct approach.`;
    }
  }
  return null;
}

// ============================================================================
// 11. FLAKE PATTERNS (Guard 11 - Advisory)
// ============================================================================

function checkFlakePatterns(content: string, filePath: string): string[] {
  if (!filePath.endsWith('flake.nix')) return [];

  const warnings: string[] = [];

  // Check for flake-parts pattern (December 2025 standard)
  if (!content.includes('flake-parts')) {
    warnings.push('Consider flake-parts for modular composition (see nix-flake-parts skill)');
  }

  // Check for forAllSystems anti-pattern
  if (content.includes('forAllSystems') || content.includes('lib.genAttrs')) {
    warnings.push('forAllSystems is deprecated - use flake-parts perSystem instead');
  }

  // Check for legacy mkShell without hooks
  if (content.includes('mkShell') && !content.includes('pre-commit') && !content.includes('git-hooks')) {
    warnings.push('Consider git-hooks.nix for pre-commit integration');
  }

  // Check for missing follows
  if (content.includes('nix-darwin') && !content.includes('inputs.nixpkgs.follows')) {
    warnings.push('nix-darwin should follow nixpkgs to avoid version drift');
  }

  // Check for process-compose-flake
  if ((content.includes('process-compose') || content.includes('process.compose')) && !content.includes('process-compose-flake')) {
    warnings.push('Consider process-compose-flake for Nix-native service orchestration');
  }

  // Check for nix2container
  if ((content.includes('container') || content.includes('oci') || content.includes('docker')) && !content.includes('nix2container')) {
    warnings.push('Consider nix2container for OCI image generation');
  }

  return warnings;
}

// ============================================================================
// 12. PORT REGISTRY (Guard 12 - Advisory)
// ============================================================================

// Known ports from lib/ports.nix
const KNOWN_PORTS = new Set([
  22, 41641, 9100, 9080, // infrastructure
  6379, 5432, 7233, // databases
  3000, 3001, 8233, // development
  4317, 4318, // otel
  9090, 3100, 3200, // observability
]);

const NIX_PORT_PATTERNS = [
  /\bport\s*=\s*(\d{2,5})\b/gi,
  /\blistenPort\s*=\s*(\d+)\b/gi,
  /allowedTCPPorts\s*=\s*\[\s*([^\]]+)\]/gi,
];

function extractPorts(content: string): number[] {
  const ports: number[] = [];
  for (const pattern of NIX_PORT_PATTERNS) {
    const regex = new RegExp(pattern.source, pattern.flags);
    let match: RegExpExecArray | null;
    while ((match = regex.exec(content)) !== null) {
      if (match[1]) {
        const portStrings = match[1].split(/[\s,]+/);
        for (const ps of portStrings) {
          const port = parseInt(ps.trim(), 10);
          if (!isNaN(port) && port >= 1 && port <= 65535) {
            ports.push(port);
          }
        }
      }
    }
  }
  return [...new Set(ports)];
}

function checkPortRegistry(content: string, filePath: string): string[] {
  const warnings: string[] = [];
  const isModuleFile = filePath.includes('/modules/') || filePath.includes('/services/');
  const isProcessCompose = filePath.includes('process-compose');
  const isNix = filePath.endsWith('.nix');

  if (!isModuleFile && !isProcessCompose) return warnings;
  if (!isNix) return warnings;

  const foundPorts = extractPorts(content);
  const unknownPorts = foundPorts.filter((p) => !KNOWN_PORTS.has(p));

  if (unknownPorts.length > 0) {
    warnings.push(`Port(s) ${unknownPorts.join(', ')} not in lib/ports.nix. Add to registry or use ports.* reference.`);
  }

  if (isNix && foundPorts.length > 0 && !content.includes('ports.') && !content.includes('lib/ports')) {
    warnings.push('Consider: let ports = import ../../../lib/ports.nix; in { ... } for type-safe port references.');
  }

  return warnings;
}

// ============================================================================
// 13. ASSUMPTION LANGUAGE DETECTOR
// ============================================================================

const ASSUMPTION_PATTERNS: { pattern: RegExp; phrase: string }[] = [
  { pattern: /\bshould\s+(now\s+)?work/i, phrase: 'should work' },
  { pattern: /\bshould\s+fix/i, phrase: 'should fix' },
  { pattern: /\bthis\s+fixes/i, phrase: 'this fixes' },
  { pattern: /\bprobably\s+(works|fixed|correct)/i, phrase: 'probably' },
  { pattern: /\bI\s+think\s+(this|it)/i, phrase: 'I think' },
  { pattern: /\bmight\s+(work|fix|solve)/i, phrase: 'might' },
  { pattern: /\blikely\s+(fixed|works|correct)/i, phrase: 'likely' },
];

function checkAssumptionLanguage(content: string, filePath: string): string | null {
  if (!/\.[jt]sx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;

  // Check comments and strings where assumption language typically appears
  const commentMatches = content.match(/\/\/.*$|\/\*[\s\S]*?\*\/|`[^`]*`|"[^"]*"|'[^']*'/gm);
  const textToCheck = commentMatches?.join(' ') || '';

  for (const { pattern, phrase } of ASSUMPTION_PATTERNS) {
    if (pattern.test(textToCheck)) {
      return `ASSUMPTION LANGUAGE VIOLATION: "${phrase}" detected

Ban assumption language. Replace with evidence:

| BANNED | REQUIRED |
|--------|----------|
| "should work" | "verified via test" |
| "probably" | "confirmed by running" |
| "I think" | Evidence-based statements only |
| "might fix" | "UNVERIFIED: requires [test]" |

See: verification-first skill for evidence patterns.`;
    }
  }
  return null;
}

// ============================================================================
// 14. THROW DETECTOR (BLOCKING - Promoted from Advisory)
// ============================================================================

const THROW_PATTERNS = [/\bthrow\s+new\s+(Error|\w+Error)\s*\(/];

const INVARIANT_CONTEXTS = [/invariant/i, /unreachable/i, /assert/i, /exhaustive/i, /impossible/i, /never/i, /panic/i];

function checkThrowPatterns(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;

  const lines = content.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] || '';
    const hasThrow = THROW_PATTERNS.some((p) => p.test(line));
    if (!hasThrow) continue;

    const prevLine = lines[i - 1] || '';
    const nextLine = lines[i + 1] || '';
    const context = `${prevLine} ${line} ${nextLine}`;

    const isInvariant = INVARIANT_CONTEXTS.some((p) => p.test(context));
    if (!isInvariant) {
      return `THROW VIOLATION: throw statement detected (line ${i + 1})

Use Result types or Effect for expected failures:

  // ❌ BLOCKED - throw for expected errors
  if (!user) throw new Error("User not found");

  // ✅ CORRECT - Result type
  if (!user) return Err(notFound("User"));

  // ✅ CORRECT - Effect
  if (!user) return Effect.fail(new UserNotFoundError({ id }));

  // ✅ ALLOWED - Invariant contexts (exhaustive, unreachable, assert)
  throw new Error("unreachable: exhaustive switch");

See: result-patterns or effect-ts-patterns skill for error handling.`;
    }
  }

  return null;
}

// ============================================================================
// 15. NO COMMENTS (Uncle Bob's Clean Code)
// ============================================================================

function checkNoComments(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;

  const lines = content.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] || '';
    const trimmed = line.trim();

    if (!trimmed) continue;

    const inlineCommentMatch = line.match(/\/\/(.*)$/);
    if (inlineCommentMatch) {
      const commentText = inlineCommentMatch[1]?.trim() || '';

      if (/^(TODO|FIXME|NOTE|HACK|XXX|BUG|OPTIMIZE|REVIEW)[\s:]/i.test(commentText)) continue;
      if (/^(eslint-|@ts-|prettier-|biome-|tslint:)/.test(commentText)) continue;
      if (/as\s+\w/.test(line) && commentText.length < 40) continue;
      if (i === 0 && trimmed.startsWith('#!')) continue;

      return `CLEAN CODE VIOLATION: Unnecessary comment detected (line ${i + 1})

"${commentText.substring(0, 50)}${commentText.length > 50 ? '...' : ''}"

Uncle Bob's Clean Code: Comments are a failure to express yourself in code.
Code should be self-documenting through:
  - Meaningful variable names
  - Well-named functions that do one thing
  - Clear code structure

ALLOWED: TODO/FIXME/NOTE, JSDoc for exports, eslint/ts directives

See: Clean Code by Robert C. Martin, Chapter 4: Comments`;
    }

    if (trimmed.startsWith('/*') && !trimmed.startsWith('/**')) {
      if (i < 10 && /license|copyright|author|\(c\)/i.test(trimmed)) continue;

      return `CLEAN CODE VIOLATION: Block comment detected (line ${i + 1})

Uncle Bob's Clean Code: Don't use comments to explain bad code - rewrite it.

See: Clean Code by Robert C. Martin, Chapter 4: Comments`;
    }
  }

  return null;
}

// ============================================================================
// 16. MEANINGFUL NAMES (Uncle Bob's Clean Code)
// ============================================================================

const CRYPTIC_PATTERNS: { pattern: RegExp; description: string; suggestion: string }[] = [
  { pattern: /\b(const|let|var)\s+([a-hln-wA-Z])\s*[=:]/, description: 'Single-letter variable', suggestion: 'Use descriptive name' },
  { pattern: /\b(const|let|var)\s+(tmp|temp|ret|res|val|obj|arr|str|num|cnt|idx|ptr|buf|len|sz)\s*[=:]/, description: 'Cryptic abbreviation', suggestion: 'Use full descriptive name' },
  { pattern: /\b(const|let|var)\s+[a-z]*[ymd]{4,}[a-z]*\s*[=:]/, description: 'Date format variable name', suggestion: 'Use currentDate, formattedDate, etc.' },
  { pattern: /\b(const|let|var)\s+(str|int|bool|arr|obj|num|fn)[A-Z][a-zA-Z]*\s*[=:]/, description: 'Hungarian notation', suggestion: 'Drop type prefix' },
];

function checkMeaningfulNames(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;
  if (/\.(test|spec)\.[tj]sx?$/.test(filePath)) return null;

  const cleanContent = stripCommentsAndStrings(content);
  const lines = cleanContent.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] || '';

    for (const { pattern, description, suggestion } of CRYPTIC_PATTERNS) {
      const match = line.match(pattern);
      if (match) {
        const varName = match[2] || '';
        if (/^[ijkxyz_e]$/.test(varName)) continue;

        return `CLEAN CODE VIOLATION: ${description} '${varName}' (line ${i + 1})

Uncle Bob's Clean Code: Use Intention-Revealing Names

  const d = new Date();  ->  const createdAt = new Date();
  const tmp = ...        ->  const activeUsers = ...

${suggestion}

See: Clean Code by Robert C. Martin, Chapter 2: Meaningful Names`;
      }
    }
  }

  return null;
}

// ============================================================================
// 17. NO COMMENTED-OUT CODE (Uncle Bob's Clean Code)
// ============================================================================

const COMMENTED_CODE_PATTERNS = [
  /\/\/\s*(function|class|interface|type|const|let|var|import|export|return|if|for|while)\s+/,
  /\/\/\s*\w+\.\w+\s*\(/,
  /\/\/\s*\w+\s*=\s*[^=]/,
  /\/\/\s*<\w+/,
];

function checkCommentedOutCode(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;

  const lines = content.split('\n');
  let consecutiveCommentedCode = 0;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] || '';
    const trimmed = line.trim();

    const looksLikeCode = COMMENTED_CODE_PATTERNS.some(p => p.test(trimmed));

    if (looksLikeCode) {
      consecutiveCommentedCode++;

      if (COMMENTED_CODE_PATTERNS[0]?.test(trimmed) || COMMENTED_CODE_PATTERNS[3]?.test(trimmed)) {
        return `CLEAN CODE VIOLATION: Commented-out code detected (line ${i + 1})

"${trimmed.substring(0, 60)}${trimmed.length > 60 ? '...' : ''}"

Uncle Bob's Clean Code: Delete commented-out code. Git remembers.

  git log -p --all -S 'function_name'
  git show <commit>:<file>

See: Clean Code by Robert C. Martin, Chapter 4: Comments`;
      }

      if (consecutiveCommentedCode >= 2) {
        return `CLEAN CODE VIOLATION: Multiple lines of commented-out code (lines ${i - consecutiveCommentedCode + 2}-${i + 1})

Uncle Bob: Commented-out code is an abomination. DELETE IT.

See: Clean Code by Robert C. Martin, Chapter 4: Comments`;
      }
    } else {
      consecutiveCommentedCode = 0;
    }
  }

  return null;
}

// ============================================================================
// 18. FUNCTION ARGUMENTS (Uncle Bob's Clean Code - >3 params)
// ============================================================================

const FUNCTION_ARGS_PATTERN = /(?:function\s+\w+|(?:const|let|var)\s+\w+\s*=\s*(?:async\s+)?(?:function|\([^)]*\)\s*=>))\s*\(([^)]*)\)/g;

function countFunctionParams(paramString: string): number {
  if (!paramString.trim()) return 0;
  const params = paramString.split(',').filter((p) => p.trim() && !p.includes('...'));
  return params.length;
}

function checkFunctionArguments(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;
  if (/\.(test|spec)\.[tj]sx?$/.test(filePath)) return null;

  const cleanContent = stripCommentsAndStrings(content);
  const lines = cleanContent.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] || '';

    const funcMatch = line.match(/(?:function\s+(\w+)|(?:const|let|var)\s+(\w+)\s*=\s*(?:async\s+)?(?:function|\())\s*\(([^)]*)\)/);
    if (funcMatch) {
      const funcName = funcMatch[1] || funcMatch[2] || 'anonymous';
      const params = funcMatch[3] || '';
      const paramCount = countFunctionParams(params);

      if (paramCount > 3) {
        return `CLEAN CODE VIOLATION: Function '${funcName}' has ${paramCount} parameters (line ${i + 1})

Uncle Bob's Clean Code: Functions should have few arguments (ideally 0-2, max 3).

  // ❌ BLOCKED - Too many positional parameters
  function createUser(name, email, age, role, dept) { }

  // ✅ CORRECT - Object parameter pattern
  function createUser(params: { name: string; email: string; ... }) { }

  // ✅ CORRECT - Builder pattern
  User.builder().name("John").email("...").build()

See: Clean Code by Robert C. Martin, Chapter 3: Functions`;
      }
    }
  }
  return null;
}

// ============================================================================
// 19. LAW OF DEMETER (Uncle Bob's Clean Code)
// ============================================================================

const DEMETER_PATTERN = /\.\w+\([^)]*\)\.\w+\([^)]*\)\.\w+\(/;

const FLUENT_API_PATTERNS = [
  /\.pipe\(/,
  /\.then\(/,
  /\.catch\(/,
  /\.finally\(/,
  /Effect\./,
  /Layer\./,
  /Stream\./,
  /Option\./,
  /Either\./,
  /\.select\(/,
  /\.from\(/,
  /\.where\(/,
  /\.orderBy\(/,
  /\.filter\(/,
  /\.map\(/,
  /\.flatMap\(/,
  /\.reduce\(/,
];

function checkLawOfDemeter(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;
  if (/\.(test|spec)\.[tj]sx?$/.test(filePath)) return null;

  const cleanContent = stripCommentsAndStrings(content);
  const lines = cleanContent.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] || '';

    if (DEMETER_PATTERN.test(line)) {
      const isFluent = FLUENT_API_PATTERNS.some((p) => p.test(line));
      if (isFluent) continue;

      return `CLEAN CODE VIOLATION: Law of Demeter violation (line ${i + 1})

"${line.trim().substring(0, 60)}${line.trim().length > 60 ? '...' : ''}"

Uncle Bob's Clean Code: Only talk to your immediate friends.

  // ❌ BLOCKED - Chain of 3+ method calls
  const city = order.getCustomer().getAddress().getCity();

  // ✅ CORRECT - Direct access or delegation
  const city = order.getShippingCity();

  // ✅ ALLOWED - Fluent APIs (Effect, builders, array methods)
  const result = Effect.gen(...).pipe(Effect.map(...));

See: Clean Code by Robert C. Martin, Chapter 6: Objects and Data Structures`;
    }
  }
  return null;
}

// ============================================================================
// 20. FUNCTION SIZE (Uncle Bob's Clean Code - >20 lines)
// ============================================================================

function checkFunctionSize(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;
  if (/\.(test|spec)\.[tj]sx?$/.test(filePath)) return null;

  const lines = content.split('\n');
  let funcStart = -1;
  let funcName = '';
  let braceCount = 0;
  let inFunction = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] || '';

    const funcMatch = line.match(/(?:function\s+(\w+)|(?:const|let|var)\s+(\w+)\s*=\s*(?:async\s+)?(?:function|\([^)]*\)\s*=>))\s*[^{]*\{/);
    if (funcMatch && !inFunction) {
      funcStart = i;
      funcName = funcMatch[1] || funcMatch[2] || 'anonymous';
      braceCount = 1;
      inFunction = true;
      continue;
    }

    if (inFunction) {
      braceCount += (line.match(/\{/g) || []).length;
      braceCount -= (line.match(/\}/g) || []).length;

      if (braceCount === 0) {
        const funcLength = i - funcStart + 1;
        if (funcLength > 20) {
          return `CLEAN CODE VIOLATION: Function '${funcName}' is ${funcLength} lines (line ${funcStart + 1})

Uncle Bob's Clean Code: Functions should be small. Really small.
- First rule: Functions should be small
- Second rule: Functions should be smaller than that

  // ❌ BLOCKED - Function > 20 lines
  function processOrder() {
    // ... 25 lines of code
  }

  // ✅ CORRECT - Decomposed into smaller functions
  function processOrder() {
    const validated = validateOrder(order);
    const enriched = enrichOrder(validated);
    return persistOrder(enriched);
  }

See: Clean Code by Robert C. Martin, Chapter 3: Functions`;
        }
        inFunction = false;
        funcStart = -1;
      }
    }
  }
  return null;
}

// ============================================================================
// 21. CYCLOMATIC COMPLEXITY (>10 branches)
// ============================================================================

const BRANCH_KEYWORDS = /\b(if|else if|case|catch|while|for|\?\?|\|\||&&|\?)\b/g;

function checkCyclomaticComplexity(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;
  if (/\.(test|spec)\.[tj]sx?$/.test(filePath)) return null;

  const lines = content.split('\n');
  let funcStart = -1;
  let funcName = '';
  let braceCount = 0;
  let inFunction = false;
  let complexity = 1;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] || '';

    const funcMatch = line.match(/(?:function\s+(\w+)|(?:const|let|var)\s+(\w+)\s*=\s*(?:async\s+)?(?:function|\([^)]*\)\s*=>))\s*[^{]*\{/);
    if (funcMatch && !inFunction) {
      funcStart = i;
      funcName = funcMatch[1] || funcMatch[2] || 'anonymous';
      braceCount = 1;
      inFunction = true;
      complexity = 1;
      continue;
    }

    if (inFunction) {
      const branches = line.match(BRANCH_KEYWORDS);
      if (branches) {
        complexity += branches.length;
      }

      braceCount += (line.match(/\{/g) || []).length;
      braceCount -= (line.match(/\}/g) || []).length;

      if (braceCount === 0) {
        if (complexity > 10) {
          return `CLEAN CODE VIOLATION: Function '${funcName}' has cyclomatic complexity ${complexity} (line ${funcStart + 1})

Cyclomatic complexity > 10 indicates too many branches/paths.

  // ❌ BLOCKED - Too many branches
  function processInput(x) {
    if (a) { ... }
    else if (b) { ... }
    switch (c) { case 1: ... case 2: ... }
    // complexity = 12
  }

  // ✅ CORRECT - Decompose or use polymorphism
  function processInput(x) {
    const handler = handlers[x.type];
    return handler(x);
  }

See: Clean Code by Robert C. Martin, Chapter 3: Functions`;
        }
        inFunction = false;
        funcStart = -1;
        complexity = 1;
      }
    }
  }
  return null;
}

// ============================================================================
// 22. SWITCH ON TYPE (Use polymorphism instead)
// ============================================================================

const SWITCH_ON_TYPE_PATTERN = /switch\s*\(\s*\w+\.(type|kind|variant|tag)\s*\)/;

function checkSwitchOnType(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;
  if (/\.(test|spec)\.[tj]sx?$/.test(filePath)) return null;

  const cleanContent = stripCommentsAndStrings(content);
  const lines = cleanContent.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] || '';

    if (SWITCH_ON_TYPE_PATTERN.test(line)) {
      return `CLEAN CODE VIOLATION: Switch on type detected (line ${i + 1})

Uncle Bob's Clean Code: Replace switch statements with polymorphism.

  // ❌ BLOCKED - Switch on type field
  switch (shape.type) {
    case 'circle': return Math.PI * r * r;
    case 'square': return s * s;
  }

  // ✅ CORRECT - Polymorphism via methods
  interface Shape { area(): number; }
  class Circle implements Shape { area() { return Math.PI * r * r; } }

  // ✅ CORRECT - Handler map pattern
  const areaHandlers = {
    circle: (s) => Math.PI * s.r * s.r,
    square: (s) => s.side * s.side,
  };

See: Clean Code by Robert C. Martin, Chapter 3: Functions`;
    }
  }
  return null;
}

// ============================================================================
// 23. NULL RETURNS (Use Option/Result instead)
// ============================================================================

const NULL_RETURN_PATTERN = /return\s+null\s*;/;

function checkNullReturns(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;
  if (/\.(test|spec)\.[tj]sx?$/.test(filePath)) return null;

  const cleanContent = stripCommentsAndStrings(content);
  const lines = cleanContent.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] || '';

    if (NULL_RETURN_PATTERN.test(line)) {
      return `CLEAN CODE VIOLATION: return null detected (line ${i + 1})

Uncle Bob's Clean Code: Don't return null.

  // ❌ BLOCKED - Returning null
  function findUser(id): User | null {
    return user ?? null;
  }

  // ✅ CORRECT - Option type
  function findUser(id): Option<User> {
    return user ? Option.some(user) : Option.none();
  }

  // ✅ CORRECT - Effect with typed error
  function findUser(id): Effect<User, UserNotFoundError> {
    return user ? Effect.succeed(user) : Effect.fail(new UserNotFoundError());
  }

See: Clean Code by Robert C. Martin, Chapter 7: Error Handling`;
    }
  }
  return null;
}

// ============================================================================
// 24. INTERFACE SEGREGATION (SOLID - >7 members)
// ============================================================================

function checkInterfaceSegregation(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;

  const lines = content.split('\n');
  let interfaceStart = -1;
  let interfaceName = '';
  let braceCount = 0;
  let inInterface = false;
  let memberCount = 0;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] || '';

    const interfaceMatch = line.match(/(?:interface|type)\s+(\w+)\s*(?:extends\s+\w+\s*)?[={]/);
    if (interfaceMatch && !inInterface) {
      interfaceStart = i;
      interfaceName = interfaceMatch[1] || 'unknown';
      braceCount = line.includes('{') ? 1 : 0;
      inInterface = braceCount > 0;
      memberCount = 0;
      continue;
    }

    if (inInterface) {
      braceCount += (line.match(/\{/g) || []).length;
      braceCount -= (line.match(/\}/g) || []).length;

      if (line.includes(':') && !line.trim().startsWith('//')) {
        memberCount++;
      }

      if (braceCount === 0) {
        if (memberCount > 7) {
          return `SOLID VIOLATION: Interface '${interfaceName}' has ${memberCount} members (line ${interfaceStart + 1})

Interface Segregation Principle: Clients should not depend on interfaces they don't use.

  // ❌ BLOCKED - Fat interface
  interface Worker {
    work(): void;
    eat(): void;
    sleep(): void;
    code(): void;
    manage(): void;
    design(): void;
    test(): void;
    deploy(): void;  // 8 members
  }

  // ✅ CORRECT - Segregated interfaces
  interface Workable { work(): void; }
  interface Feedable { eat(): void; }
  interface Developer extends Workable { code(): void; test(): void; }

See: SOLID Principles - Interface Segregation`;
        }
        inInterface = false;
        interfaceStart = -1;
        memberCount = 0;
      }
    }
  }
  return null;
}

// ============================================================================
// 25. DEEP NESTING (>3 indent levels)
// ============================================================================

function checkDeepNesting(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;
  if (/\.(test|spec)\.[tj]sx?$/.test(filePath)) return null;

  const lines = content.split('\n');
  const INDENT_SIZE = 2;
  const MAX_INDENT = INDENT_SIZE * 4;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] || '';
    const match = line.match(/^(\s*)\S/);
    if (!match) continue;

    const indent = match[1]?.length || 0;

    if (indent >= MAX_INDENT && !line.trim().startsWith('//') && !line.trim().startsWith('*')) {
      const context = lines.slice(Math.max(0, i - 2), i + 1).join('\n');
      if (context.includes('if') || context.includes('for') || context.includes('while')) {
        return `CLEAN CODE VIOLATION: Deep nesting detected (line ${i + 1}, indent ${indent / INDENT_SIZE} levels)

Uncle Bob's Clean Code: Avoid deep nesting. Use guard clauses.

  // ❌ BLOCKED - Deep nesting
  if (user) {
    if (user.isActive) {
      if (user.hasPermission) {
        if (user.isVerified) {
          // level 4 - too deep
        }
      }
    }
  }

  // ✅ CORRECT - Guard clauses (early returns)
  if (!user) return;
  if (!user.isActive) return;
  if (!user.hasPermission) return;
  if (!user.isVerified) return;
  // proceed with logic

See: Clean Code by Robert C. Martin, Chapter 3: Functions`;
      }
    }
  }
  return null;
}

// ============================================================================
// 28-30. CONFIGURATION CENTRALIZATION (Nix files)
// ============================================================================

function isConfigAllowedPath(filePath: string): boolean {
  // Files in lib/config/ or lib/ports.nix are the SSOT - they can have hardcoded values
  return (
    filePath.includes('lib/config/') ||
    filePath.includes('lib/ports.nix') ||
    filePath.includes('/config/ports') ||
    filePath.includes('ports.nix')
  );
}

function checkHardcodedPorts(content: string, filePath: string): string | null {
  // Guard 28: No hardcoded ports outside lib/config/
  const lines = content.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] || '';
    const lineNum = i + 1;

    // Match: port = 3000; or ports = [ 22 ]; but not ports.infrastructure.ssh
    const portPattern = /(?<!ports\.[\w.]*)\b(port|ports)\s*=\s*\[?\s*(\d{2,5})\b/gi;
    let match;
    while ((match = portPattern.exec(line)) !== null) {
      const portNum = parseInt(match[2], 10);
      // Filter to likely port numbers (>= 22 and <= 65535)
      if (portNum >= 22 && portNum <= 65535) {
        return `GUARD 28: HARDCODED PORT DETECTED

File: ${filePath}:${lineNum}
Match: ${match[0]}

Hardcoded port ${portNum} found outside lib/config/.
All ports must be centralized in lib/config/ports.nix.

  // ❌ BLOCKED - Hardcoded port
  port = ${portNum};

  // ✅ CORRECT - Reference config
  port = cfg.ports.myService;

Bypass: Create .paragon-skip-28 file to skip this check.`;
      }
    }
  }

  return null;
}

function checkHardcodedUrls(content: string, filePath: string): string | null {
  // Guard 30: No hardcoded localhost URLs outside lib/config/
  const lines = content.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] || '';
    const lineNum = i + 1;

    const localhostPattern = /(?:localhost|127\.0\.0\.1):\d{2,5}/g;
    let match;
    while ((match = localhostPattern.exec(line)) !== null) {
      return `GUARD 30: HARDCODED LOCALHOST URL DETECTED

File: ${filePath}:${lineNum}
Match: ${match[0]}

Hardcoded localhost URL found outside lib/config/.
All service URLs must be centralized.

  // ❌ BLOCKED - Hardcoded URL
  url = "http://localhost:3000";

  // ✅ CORRECT - Reference config
  url = cfg.services.api.url;

Bypass: Create .paragon-skip-30 file to skip this check.`;
    }
  }

  return null;
}

// ============================================================================
// 31. STACK COMPLIANCE (package.json)
// ============================================================================

/** Forbidden dependencies - these have better alternatives */
const FORBIDDEN_DEPS: Record<string, string> = {
  // lodash -> Use native methods or Effect
  lodash: 'Use native Array/Object methods or Effect utilities',
  'lodash-es': 'Use native Array/Object methods or Effect utilities',
  underscore: 'Use native Array/Object methods or Effect utilities',
  // express -> Use Hono
  express: 'Use Hono instead (Web Standards, faster, smaller)',
  fastify: 'Use Hono instead (Web Standards, portable)',
  koa: 'Use Hono instead (Web Standards, portable)',
  // prisma -> Use Drizzle
  prisma: 'Use Drizzle ORM instead (type-safe, SQL-first)',
  '@prisma/client': 'Use Drizzle ORM instead (type-safe, SQL-first)',
  // mongoose -> Use Drizzle + PostgreSQL
  mongoose: 'Use Drizzle + PostgreSQL instead of MongoDB',
  // moment -> Use native Date or Temporal
  moment: 'Use native Date API or Temporal (Stage 3)',
  'moment-timezone': 'Use native Date API or Temporal (Stage 3)',
  // axios -> Use fetch (native)
  axios: 'Use native fetch() or Effect HttpClient',
  // jest -> Use Vitest
  jest: 'Use Vitest instead (Vite-native, faster)',
  '@jest/globals': 'Use Vitest instead (Vite-native, faster)',
  // eslint -> Use Biome or OXLint
  eslint: 'Use Biome or OXLint instead (faster, unified)',
  prettier: 'Use Biome instead (unified format + lint)',
  // redux -> Use XState or Zustand
  redux: 'Use XState (state machines) or Zustand (simple state)',
  '@reduxjs/toolkit': 'Use XState (state machines) or Zustand (simple state)',
  // webpack -> Use Vite
  webpack: 'Use Vite instead (ESM-native, faster)',
  'webpack-cli': 'Use Vite instead (ESM-native, faster)',
};

/** Key npm packages with enforced versions (from STACK.npm) */
const STACK_VERSIONS: Record<string, string> = {
  typescript: '5.9.3',
  effect: '3.19.9',
  zod: '4.1.13',
  react: '19.2.1',
  'react-dom': '19.2.1',
  '@biomejs/biome': '2.3.8',
  '@types/bun': '1.2.10',
  '@effect/cli': '0.72.1',
  '@effect/platform': '0.93.6',
  '@effect/platform-node': '0.103.0',
  'drizzle-orm': '0.45.0',
  'drizzle-kit': '0.30.0',
  '@tanstack/react-router': '1.140.0',
  tailwindcss: '4.1.17',
  xstate: '5.24.0',
  '@xstate/react': '5.0.0',
  vitest: '4.0.15',
  '@playwright/test': '1.57.0',
  'better-auth': '1.4.6',
};

function checkStackCompliance(content: string, filePath: string): string | null {
  if (!filePath.endsWith('package.json')) return null;
  if (filePath.includes('/node_modules/')) return null;

  // Parse package.json
  let pkg: {
    dependencies?: Record<string, string>;
    devDependencies?: Record<string, string>;
  };

  try {
    pkg = JSON.parse(content);
  } catch {
    return null; // Invalid JSON, let other tools handle
  }

  const allDeps = {
    ...(pkg.dependencies ?? {}),
    ...(pkg.devDependencies ?? {}),
  };

  const violations: string[] = [];

  // Check forbidden dependencies
  for (const [dep, reason] of Object.entries(FORBIDDEN_DEPS)) {
    if (allDeps[dep]) {
      violations.push(`  ❌ FORBIDDEN: ${dep} - ${reason}`);
    }
  }

  // Check version drift (advisory - don't block, just warn in message)
  const versionDrift: string[] = [];
  for (const [pkg, expected] of Object.entries(STACK_VERSIONS)) {
    const actual = allDeps[pkg];
    if (actual && !actual.includes(expected)) {
      versionDrift.push(`  ⚠️  ${pkg}: expected ^${expected}, got ${actual}`);
    }
  }

  if (violations.length > 0) {
    return `GUARD 31: STACK COMPLIANCE VIOLATION

File: ${filePath}

Forbidden dependencies detected:
${violations.join('\n')}

Remove these dependencies and use the recommended alternatives.
See: config/signet/src/stack/versions.ts for approved packages.

${versionDrift.length > 0 ? `\nVersion drift (advisory):\n${versionDrift.join('\n')}` : ''}

Bypass: Create .paragon-skip-31 file to skip this check.`;
  }

  return null;
}

// ============================================================================
// 32-36. PARSE-AT-BOUNDARY GUARDS (Tier 7)
// ============================================================================

/** Boundary files where optional chaining/nullish coalescing IS allowed */
const BOUNDARY_FILE_PATTERNS = [
  /\/api\/.*\.ts$/,           // API routes
  /\/lib\/.*-client\.ts$/,    // API clients
  /\.schema\.ts$/,            // Schema files
  /\/schemas?\//,             // Schema directories
  /\/parsers?\//,             // Parser directories
  /\.test\.ts$/,              // Test files
  /\.spec\.ts$/,              // Spec files
  /\/hooks\//,                // Hook files (like paragon-guard.ts)
];

function isBoundaryFile(path: string): boolean {
  return BOUNDARY_FILE_PATTERNS.some((p) => p.test(path));
}

/**
 * Guard 32: Optional Chaining in Non-Boundary Code
 * Detects optional chaining chains (x?.y?.z) in domain code
 */
function checkOptionalChainingDomain(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;
  if (isBoundaryFile(filePath)) return null;

  const cleanContent = stripCommentsAndStrings(content);
  const lines = cleanContent.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line) continue;
    if (line.trim().startsWith('import')) continue;
    if (line.trim().startsWith('export')) continue;

    // Detect optional chaining chains (x?.y?.z)
    const chainMatch = line.match(/(\w+)\?\.\w+\?\./);
    if (chainMatch) {
      return `GUARD 32: PARSE-AT-BOUNDARY VIOLATION - Optional Chaining Chain

File: ${filePath}:${i + 1}
Match: ${chainMatch[0]}

Optional chaining chain '${chainMatch[0]}' indicates unparsed data.
Parse at boundary instead.

  // ❌ BLOCKED - scattered null checks
  const name = context.user?.profile?.name?.trim();

  // ✅ CORRECT - parse at boundary, typed internally
  type Context = { user: { profile: { name: string } } };
  const parsed = Schema.decodeUnknownSync(ContextSchema)(raw);
  const name = parsed.user.profile.name.trim();

See: parse-boundary-patterns skill.
Bypass: Create .paragon-skip-32 file to skip this check.`;
    }

    // Detect domain context/input/data optional access
    const domainMatch = line.match(/(context|input|data)\.(\w+)\?\./);
    if (domainMatch) {
      return `GUARD 32: PARSE-AT-BOUNDARY VIOLATION - Domain Optional Access

File: ${filePath}:${i + 1}
Match: ${domainMatch[0]}

'${domainMatch[1]}.${domainMatch[2]}?.' indicates unparsed data.
Data should be fully typed after boundary parsing.

  // ❌ BLOCKED - nullable in domain code
  const phone = context.phone?.trim();

  // ✅ CORRECT - discriminated union
  type Context =
    | { phase: "idle" }
    | { phase: "active"; phone: string };

  if (context.phase === "active") {
    const phone = context.phone.trim();
  }

See: parse-boundary-patterns skill.
Bypass: Create .paragon-skip-32 file to skip this check.`;
    }
  }
  return null;
}

/**
 * Guard 33: Nullish Coalescing in Non-Boundary Code
 * Detects ?? usage in domain code (should use Schema defaults)
 */
function checkNullishCoalescingDomain(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;
  if (isBoundaryFile(filePath)) return null;

  const cleanContent = stripCommentsAndStrings(content);
  const lines = cleanContent.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line) continue;
    if (line.trim().startsWith('import')) continue;
    if (line.trim().startsWith('export')) continue;

    // Skip error message contexts and catch blocks
    if (line.includes('error') || line.includes('Error')) continue;
    if (line.includes('message')) continue;
    if (line.includes('catch')) continue;

    // Detect nullish coalescing on config/context/input
    const coalescingMatch = line.match(/(config|context|input|options|props|params)\.(\w+)\s*\?\?/);
    if (coalescingMatch) {
      return `GUARD 33: PARSE-AT-BOUNDARY VIOLATION - Nullish Coalescing

File: ${filePath}:${i + 1}
Match: ${coalescingMatch[0]}

'${coalescingMatch[1]}.${coalescingMatch[2]} ??' should have default at parse time.

  // ❌ BLOCKED - default at use site
  const port = config.port ?? 3000;

  // ✅ CORRECT - default at parse time
  const ConfigSchema = Schema.Struct({
    port: Schema.optional(Schema.Number, { default: () => 3000 }),
  });
  const config = parseConfig(raw);
  // Now: config.port is number (not number | undefined)

See: parse-boundary-patterns skill.
Bypass: Create .paragon-skip-33 file to skip this check.`;
    }
  }
  return null;
}

/**
 * Guard 34: Null Check Then Non-Null Assert
 * Detects if (x === null) followed by x! (indicates validation not parsing)
 */
function checkNullCheckThenAssert(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;

  const cleanContent = stripCommentsAndStrings(content);

  // Pattern: if (x === null) within 10 lines of x!
  const nullCheckPattern = /if\s*\(\s*(\w+(?:\.\w+)*)\s*===?\s*null\s*\)/g;
  let match;

  while ((match = nullCheckPattern.exec(cleanContent)) !== null) {
    const varName = match[1];
    const afterCheck = cleanContent.substring(match.index, match.index + 500);

    // Look for x! usage after null check
    const assertPattern = new RegExp(`\\b${varName.replace(/\./g, '\\.')}!`, 'g');
    if (assertPattern.test(afterCheck)) {
      const lineNum = cleanContent.substring(0, match.index).split('\n').length;
      return `GUARD 34: PARSE-AT-BOUNDARY VIOLATION - Null Check Then Assert

File: ${filePath}:${lineNum}
Variable: ${varName}

Null check followed by non-null assertion indicates validation not parsing.

  // ❌ BLOCKED - validation pattern
  if (context.phone === null) throw new Error("Phone required");
  const trimmed = context.phone!.trim();

  // ✅ CORRECT - discriminated union
  type Context =
    | { phase: "initial" }
    | { phase: "validated"; phone: string };

  if (context.phase === "validated") {
    const trimmed = context.phone.trim();  // TS knows phone exists
  }

See: parse-boundary-patterns skill.
Bypass: Create .paragon-skip-34 file to skip this check.`;
    }
  }
  return null;
}

/**
 * Guard 35: Type Assertions (Warning Only)
 * Detects 'as Type' assertions (should parse instead)
 */
function checkTypeAssertions(content: string, filePath: string): string[] {
  const warnings: string[] = [];

  if (!/\.tsx?$/.test(filePath)) return warnings;
  if (filePath.endsWith('.d.ts')) return warnings;
  if (filePath.includes('/node_modules/')) return warnings;
  if (isBoundaryFile(filePath)) return warnings;

  const cleanContent = stripCommentsAndStrings(content);
  const lines = cleanContent.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line) continue;
    if (line.trim().startsWith('import')) continue;

    // Detect 'as Type' but not 'as const'
    const asMatch = line.match(/\s+as\s+(?!const\b)([A-Z]\w*)/);
    if (asMatch) {
      warnings.push(
        `Guard 35 (Advisory): Type assertion 'as ${asMatch[1]}' at ${filePath}:${i + 1}. ` +
          `Consider parsing instead of asserting.`
      );
    }
  }
  return warnings;
}

/**
 * Guard 36: Non-Null Assertion Without Type Narrowing
 * Detects x! without preceding type guard
 */
function checkNonNullAssertWithoutNarrowing(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;

  const cleanContent = stripCommentsAndStrings(content);
  const lines = cleanContent.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line) continue;
    if (line.trim().startsWith('import')) continue;
    if (line.trim().startsWith('export')) continue;

    // Detect x! usage (not in strings since we stripped those)
    const assertMatch = line.match(/(\w+(?:\.\w+)*)!/);
    if (!assertMatch) continue;

    const varName = assertMatch[1];
    if (!varName) continue;

    // Skip common safe patterns
    if (varName === 'match') continue;  // Array.match()!
    if (varName.includes('getElementById')) continue;
    if (line.includes('.get(')) continue;  // Map.get()!
    if (line.includes('.find(')) continue; // Array.find()!

    // Check if there's a type guard on previous 5 lines
    const prevLines = lines.slice(Math.max(0, i - 5), i).join('\n');
    const baseVar = varName.split('.')[0];

    // Look for narrowing patterns
    const hasNarrowing =
      prevLines.includes(`${baseVar} !==`) ||
      prevLines.includes(`${baseVar} ===`) ||
      prevLines.includes(`typeof ${baseVar}`) ||
      prevLines.includes(`instanceof`) ||
      prevLines.includes(`.phase ===`) ||
      prevLines.includes(`.phase !==`) ||
      prevLines.includes(`.type ===`) ||
      prevLines.includes(`.type !==`) ||
      prevLines.includes(`.kind ===`) ||
      prevLines.includes(`.kind !==`) ||
      prevLines.includes(`"${baseVar}" in`);

    if (!hasNarrowing) {
      return `GUARD 36: PARSE-AT-BOUNDARY VIOLATION - Non-Null Assert Without Narrowing

File: ${filePath}:${i + 1}
Match: ${varName}!

Non-null assertion without type narrowing indicates unparsed data.

  // ❌ BLOCKED - asserting without narrowing
  const name = user.profile!.name;

  // ✅ CORRECT - type narrowing via discriminated union
  if (context.phase === "active") {
    const name = context.profile.name;  // TS knows it exists
  }

  // ✅ CORRECT - explicit check before assertion
  if (user.profile !== null) {
    const name = user.profile.name;  // TS narrowed via check
  }

See: parse-boundary-patterns skill.
Bypass: Create .paragon-skip-36 file to skip this check.`;
    }
  }
  return null;
}

// ============================================================================
// 37. NULLABLE UNION IN CONTEXT TYPES
// ============================================================================

/**
 * Guard 37: Nullable Union in Context Types
 * Detects type definitions with | null or | undefined in Context/State types
 */
const NULLABLE_UNION_PATTERNS = [
  /:\s*\w+\s*\|\s*null\b/,              // : Type | null
  /:\s*\w+\s*\|\s*undefined\b/,         // : Type | undefined
  /:\s*null\s*\|\s*\w+/,                // : null | Type
  /:\s*undefined\s*\|\s*\w+/,           // : undefined | Type
  /:\s*\w+<[^>]+>\s*\|\s*null\b/,       // : Generic<T> | null
  /:\s*\w+<[^>]+>\s*\|\s*undefined\b/,  // : Generic<T> | undefined
];

function checkNullableUnionContext(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;
  if (isBoundaryFile(filePath)) return null;

  const cleanContent = stripCommentsAndStrings(content);
  const lines = cleanContent.split('\n');

  let inContextType = false;
  let contextTypeName = '';
  let braceDepth = 0;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line) continue;

    // Check for type/interface declaration with Context/State/Machine/Store name
    const typeMatch = line.match(/\b(type|interface)\s+((\w*)(Context|State|Machine|Store)(\w*))\s*[={]/);
    if (typeMatch) {
      inContextType = true;
      contextTypeName = typeMatch[2];
      braceDepth = (line.match(/\{/g) || []).length - (line.match(/\}/g) || []).length;

      // Check the same line for nullable union
      for (const pattern of NULLABLE_UNION_PATTERNS) {
        if (pattern.test(line)) {
          const match = line.match(pattern);
          return `GUARD 37: PARSE-AT-BOUNDARY VIOLATION - Nullable Union in Context Type

File: ${filePath}:${i + 1}
Type: ${contextTypeName}
Match: ${match?.[0]}

Context/State types should use discriminated unions, not nullable fields.

  // ❌ BLOCKED - nullable field in context
  type Context = { phone: string | null; user: User | undefined }

  // ✅ CORRECT - discriminated union by phase
  type Context =
    | { phase: "idle" }
    | { phase: "active"; phone: string }
    | { phase: "authenticated"; phone: string; user: User }

See: parse-boundary-patterns skill.
Bypass: Create .paragon-skip-37 file to skip this check.`;
        }
      }
      continue;
    }

    if (inContextType) {
      braceDepth += (line.match(/\{/g) || []).length;
      braceDepth -= (line.match(/\}/g) || []).length;

      for (const pattern of NULLABLE_UNION_PATTERNS) {
        if (pattern.test(line)) {
          const match = line.match(pattern);
          return `GUARD 37: PARSE-AT-BOUNDARY VIOLATION - Nullable Union in Context Type

File: ${filePath}:${i + 1}
Type: ${contextTypeName}
Match: ${match?.[0]}

Context/State types should use discriminated unions, not nullable fields.

  // ❌ BLOCKED - nullable field in context
  type Context = { phone: string | null; user: User | undefined }

  // ✅ CORRECT - discriminated union by phase
  type Context =
    | { phase: "idle" }
    | { phase: "active"; phone: string }
    | { phase: "authenticated"; phone: string; user: User }

See: parse-boundary-patterns skill.
Bypass: Create .paragon-skip-37 file to skip this check.`;
        }
      }

      if (braceDepth <= 0) {
        inContextType = false;
        contextTypeName = '';
      }
    }
  }
  return null;
}

// ============================================================================
// 38. TRUTHINESS CHECK (Advisory - Warning Only)
// ============================================================================

/**
 * Guard 38: Implicit Truthiness Check (WARNING)
 * Detects if (value) instead of explicit type narrowing
 */
const BOOLEAN_PREFIXES = /^(is|has|should|can|will|does|did|was|were|are|ok|success|valid|enabled|disabled|active|loading|error|exists|found|done|ready|open|closed|visible|hidden|empty|selected|checked|focused|mounted|pending|resolved|rejected|completed|failed|running|stopped|paused|finished|initialized|authenticated|authorized|connected|disconnected|online|offline)/;

function checkTruthinessCheck(content: string, filePath: string): string[] {
  const warnings: string[] = [];

  if (!/\.tsx?$/.test(filePath)) return warnings;
  if (filePath.endsWith('.d.ts')) return warnings;
  if (filePath.includes('/node_modules/')) return warnings;
  if (isBoundaryFile(filePath)) return warnings;
  if (/\.(test|spec)\.[tj]sx?$/.test(filePath)) return warnings;

  const cleanContent = stripCommentsAndStrings(content);
  const lines = cleanContent.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line) continue;

    // Skip JSX conditional rendering
    if (line.includes('&&') && line.includes('<')) continue;
    if (line.includes('{') && line.includes('}') && line.includes('<')) continue;

    // Skip ternary expressions
    if (line.includes('?') && line.includes(':')) continue;

    // Check if (value) or if (!value)
    const ifMatch = line.match(/if\s*\(\s*(!?)([a-zA-Z_]\w*)\s*\)/);
    if (ifMatch) {
      const negation = ifMatch[1];
      const varName = ifMatch[2];
      if (!varName) continue;
      if (BOOLEAN_PREFIXES.test(varName)) continue;

      warnings.push(
        `Guard 38 (Advisory): Implicit truthiness check 'if (${negation}${varName})' at ${filePath}:${i + 1}. ` +
        `Consider explicit narrowing: if (${varName} ${negation ? '===' : '!=='} undefined)`
      );
    }
  }

  return warnings;
}

// ============================================================================
// 39. UNDEFINED CHECK IN DOMAIN CODE
// ============================================================================

/**
 * Guard 39: Undefined Check Pattern in Domain Code
 * Detects === undefined / !== undefined checks (indicates unparsed data)
 */
function checkUndefinedCheckDomain(content: string, filePath: string): string | null {
  if (!/\.tsx?$/.test(filePath)) return null;
  if (filePath.endsWith('.d.ts')) return null;
  if (filePath.includes('/node_modules/')) return null;
  if (isBoundaryFile(filePath)) return null;
  if (/\.(test|spec)\.[tj]sx?$/.test(filePath)) return null;

  const cleanContent = stripCommentsAndStrings(content);
  const lines = cleanContent.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line) continue;
    if (line.trim().startsWith('import')) continue;
    if (line.trim().startsWith('export type')) continue;
    if (line.trim().startsWith('export interface')) continue;

    // Skip error handling contexts
    if (line.includes('error') || line.includes('Error')) continue;
    if (line.includes('catch')) continue;

    // Skip type definitions
    if (line.includes('type ') && line.includes('=')) continue;
    if (line.includes('interface ')) continue;

    // Detect === undefined or !== undefined
    const undefinedMatch = line.match(/([\w.]+)\s*(===|!==)\s*undefined/);
    if (undefinedMatch) {
      const varName = undefinedMatch[1];
      const operator = undefinedMatch[2];
      if (!varName) continue;

      // Skip common safe patterns (function parameters, options objects)
      if (varName.includes('options.') || varName.includes('opts.')) continue;
      if (varName.includes('arg') || varName.includes('param')) continue;
      if (varName.includes('config.') || varName.includes('Config.')) continue;

      // Skip array method callbacks
      if (line.includes('.filter(') || line.includes('.find(') ||
          line.includes('.some(') || line.includes('.every(')) continue;

      return `GUARD 39: PARSE-AT-BOUNDARY VIOLATION - Undefined Check in Domain Code

File: ${filePath}:${i + 1}
Match: ${varName} ${operator} undefined

Undefined check indicates unparsed data. Parse at boundary with defaults:

  // ❌ BLOCKED - checking undefined in domain code
  if (config.port === undefined) { port = 3000 }
  if (user.email !== undefined) { sendEmail(user.email) }

  // ✅ CORRECT - parse at boundary with defaults
  const ConfigSchema = Schema.Struct({
    port: Schema.optional(Schema.Number, { default: () => 3000 }),
  });
  const config = Schema.decodeUnknownSync(ConfigSchema)(raw);
  // config.port is number (never undefined)

See: parse-boundary-patterns skill.
Bypass: Create .paragon-skip-39 file to skip this check.`;
    }

    // Detect typeof x === "undefined"
    const typeofMatch = line.match(/typeof\s+([\w.]+)\s*(===|!==)\s*["']undefined["']/);
    if (typeofMatch) {
      const varName = typeofMatch[1];
      const operator = typeofMatch[2];
      if (!varName) continue;

      return `GUARD 39: PARSE-AT-BOUNDARY VIOLATION - Typeof Undefined Check

File: ${filePath}:${i + 1}
Match: typeof ${varName} ${operator} "undefined"

Typeof undefined check indicates unparsed data. Parse at boundary instead.

See: parse-boundary-patterns skill.
Bypass: Create .paragon-skip-39 file to skip this check.`;
    }
  }

  return null;
}

// ============================================================================
// Main Hook Logic
// ============================================================================

async function main(): Promise<void> {
  const startTime = performance.now();
  let guardsChecked = 0;
  let result: 'approve' | 'block' = 'approve';

  let rawInput: string;
  try {
    rawInput = await Bun.stdin.text();
  } catch {
    allow();
    return;
  }

  let input: HookInput;
  try {
    input = HookInputSchema.parse(JSON.parse(rawInput));
  } catch {
    allow();
    return;
  }

  const { tool_name, tool_input } = input;
  const filePath = tool_input.file_path || '';
  const content = tool_input.content || tool_input.new_string || '';
  const command = tool_input.command || '';

  // ─────────────────────────────────────────────────────────────────────────
  // INFINITE LOOP PREVENTION: Check bypass files and cooldowns
  // ─────────────────────────────────────────────────────────────────────────
  if (checkBypassFiles()) {
    allow();
    return;
  }

  const skipDueToCooldown = filePath && shouldSkipDueToCooldown(filePath);
  const allowDueToMaxIterations = filePath && shouldAllowDueToMaxIterations(filePath);

  // Track and log performance on exit
  const logAndExit = (decision: 'approve' | 'block') => {
    result = decision;
    const duration = performance.now() - startTime;
    logPerf({
      timestamp: new Date().toISOString(),
      hook: 'paragon-guard',
      tool: tool_name,
      file: filePath || command.substring(0, 50),
      duration_ms: Math.round(duration * 100) / 100,
      result,
      guards_checked: guardsChecked,
    });
  };

  // ─────────────────────────────────────────────────────────────────────────
  // 1. BASH SAFETY (for Bash commands)
  // ─────────────────────────────────────────────────────────────────────────
  if (tool_name === 'Bash' && command) {
    guardsChecked++;
    const bashError = checkBashSafety(command);
    if (bashError) {
      logAndExit('block');
      block(bashError);
      return;
    }

    // Check conventional commit
    guardsChecked++;
    const commitError = checkConventionalCommit(command);
    if (commitError) {
      logAndExit('block');
      block(commitError);
      return;
    }

    // Check DevOps commands (Guard 10)
    guardsChecked++;
    const devOpsError = checkDevOpsCommands(command);
    if (devOpsError) {
      logAndExit('block');
      block(devOpsError);
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. FORBIDDEN FILES (for Write commands)
  // ─────────────────────────────────────────────────────────────────────────
  if (tool_name === 'Write' && filePath) {
    guardsChecked++;
    const fileError = checkForbiddenFiles(filePath);
    if (fileError) {
      logAndExit('block');
      block(fileError);
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. FORBIDDEN IMPORTS (for Write/Edit on TS/JS)
  // ─────────────────────────────────────────────────────────────────────────
  if ((tool_name === 'Write' || tool_name === 'Edit') && content && filePath) {
    guardsChecked++;
    const importError = checkForbiddenImports(content, filePath);
    if (importError) {
      logAndExit('block');
      block(importError);
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. ANY TYPE DETECTOR (for Write/Edit on TypeScript)
  // ─────────────────────────────────────────────────────────────────────────
  if ((tool_name === 'Write' || tool_name === 'Edit') && content && filePath) {
    guardsChecked++;
    const anyError = checkAnyType(content, filePath);
    if (anyError) {
      logAndExit('block');
      block(anyError);
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. Z.INFER DETECTOR (for Write/Edit on TypeScript)
  // ─────────────────────────────────────────────────────────────────────────
  if ((tool_name === 'Write' || tool_name === 'Edit') && content && filePath) {
    guardsChecked++;
    const zodError = checkZodInfer(content, filePath);
    if (zodError) {
      logAndExit('block');
      block(zodError);
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. NO-MOCK ENFORCER (for Write/Edit on TS/JS)
  // ─────────────────────────────────────────────────────────────────────────
  if ((tool_name === 'Write' || tool_name === 'Edit') && content && filePath) {
    guardsChecked++;
    const mockError = checkNoMocks(content, filePath);
    if (mockError) {
      logAndExit('block');
      block(mockError);
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 8. TDD ENFORCER (for Write/Edit/MultiEdit on source files)
  // ─────────────────────────────────────────────────────────────────────────
  if (['Write', 'Edit', 'MultiEdit'].includes(tool_name) && filePath) {
    guardsChecked++;
    const tddError = await checkTDD(filePath);
    if (tddError) {
      logAndExit('block');
      block(tddError);
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 11. FLAKE PATTERNS (Advisory - for Write/Edit on flake.nix)
  // ─────────────────────────────────────────────────────────────────────────
  const advisoryWarnings: string[] = [];

  if ((tool_name === 'Write' || tool_name === 'Edit') && content && filePath) {
    guardsChecked++;
    const flakeWarnings = checkFlakePatterns(content, filePath);
    advisoryWarnings.push(...flakeWarnings);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 12. PORT REGISTRY (Advisory - for Write/Edit on modules/*.nix)
  // ─────────────────────────────────────────────────────────────────────────
  if ((tool_name === 'Write' || tool_name === 'Edit') && content && filePath) {
    guardsChecked++;
    const portWarnings = checkPortRegistry(content, filePath);
    advisoryWarnings.push(...portWarnings);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 13. ASSUMPTION LANGUAGE (Blocking - for Write/Edit on TS/JS)
  // ─────────────────────────────────────────────────────────────────────────
  if ((tool_name === 'Write' || tool_name === 'Edit') && content && filePath) {
    guardsChecked++;
    const assumptionError = checkAssumptionLanguage(content, filePath);
    if (assumptionError) {
      logAndExit('block');
      block(assumptionError);
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 14. THROW DETECTOR (BLOCKING - for Write/Edit on TypeScript)
  // ─────────────────────────────────────────────────────────────────────────
  if ((tool_name === 'Write' || tool_name === 'Edit') && content && filePath) {
    guardsChecked++;
    const throwError = checkThrowPatterns(content, filePath);
    if (throwError) {
      logAndExit('block');
      block(throwError);
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 15. NO COMMENTS - Uncle Bob's Clean Code (BLOCKING)
  // ─────────────────────────────────────────────────────────────────────────
  if ((tool_name === 'Write' || tool_name === 'Edit') && content && filePath) {
    guardsChecked++;
    const commentError = checkNoComments(content, filePath);
    if (commentError) {
      logAndExit('block');
      block(commentError);
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 16. MEANINGFUL NAMES - Uncle Bob's Clean Code (BLOCKING)
  // ─────────────────────────────────────────────────────────────────────────
  if ((tool_name === 'Write' || tool_name === 'Edit') && content && filePath) {
    guardsChecked++;
    const nameError = checkMeaningfulNames(content, filePath);
    if (nameError) {
      logAndExit('block');
      block(nameError);
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 17. NO COMMENTED-OUT CODE - Uncle Bob's Clean Code (BLOCKING)
  // ─────────────────────────────────────────────────────────────────────────
  if ((tool_name === 'Write' || tool_name === 'Edit') && content && filePath) {
    guardsChecked++;
    const deadCodeError = checkCommentedOutCode(content, filePath);
    if (deadCodeError) {
      logAndExit('block');
      block(deadCodeError);
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GUARDS 18-25: Extended Clean Code (with infinite loop protection)
  // Skip if cooldown active or max iterations reached
  // ─────────────────────────────────────────────────────────────────────────
  if ((tool_name === 'Write' || tool_name === 'Edit') && content && filePath) {
    if (!skipDueToCooldown && !allowDueToMaxIterations) {
      // Guard 18: Function Arguments
      if (!checkBypassFiles(18) && !shouldSkipGuard(filePath, 18)) {
        guardsChecked++;
        const argsError = checkFunctionArguments(content, filePath);
        if (argsError) {
          markGuardFired(filePath, 18);
          logAndExit('block');
          block(argsError);
          return;
        }
      }

      // Guard 19: Law of Demeter
      if (!checkBypassFiles(19) && !shouldSkipGuard(filePath, 19)) {
        guardsChecked++;
        const demeterError = checkLawOfDemeter(content, filePath);
        if (demeterError) {
          markGuardFired(filePath, 19);
          logAndExit('block');
          block(demeterError);
          return;
        }
      }

      // Guard 20: Function Size
      if (!checkBypassFiles(20) && !shouldSkipGuard(filePath, 20)) {
        guardsChecked++;
        const sizeError = checkFunctionSize(content, filePath);
        if (sizeError) {
          markGuardFired(filePath, 20);
          logAndExit('block');
          block(sizeError);
          return;
        }
      }

      // Guard 21: Cyclomatic Complexity
      if (!checkBypassFiles(21) && !shouldSkipGuard(filePath, 21)) {
        guardsChecked++;
        const complexityError = checkCyclomaticComplexity(content, filePath);
        if (complexityError) {
          markGuardFired(filePath, 21);
          logAndExit('block');
          block(complexityError);
          return;
        }
      }

      // Guard 22: Switch on Type
      if (!checkBypassFiles(22) && !shouldSkipGuard(filePath, 22)) {
        guardsChecked++;
        const switchError = checkSwitchOnType(content, filePath);
        if (switchError) {
          markGuardFired(filePath, 22);
          logAndExit('block');
          block(switchError);
          return;
        }
      }

      // Guard 23: Null Returns
      if (!checkBypassFiles(23) && !shouldSkipGuard(filePath, 23)) {
        guardsChecked++;
        const nullError = checkNullReturns(content, filePath);
        if (nullError) {
          markGuardFired(filePath, 23);
          logAndExit('block');
          block(nullError);
          return;
        }
      }

      // Guard 24: Interface Segregation
      if (!checkBypassFiles(24) && !shouldSkipGuard(filePath, 24)) {
        guardsChecked++;
        const ispError = checkInterfaceSegregation(content, filePath);
        if (ispError) {
          markGuardFired(filePath, 24);
          logAndExit('block');
          block(ispError);
          return;
        }
      }

      // Guard 25: Deep Nesting
      if (!checkBypassFiles(25) && !shouldSkipGuard(filePath, 25)) {
        guardsChecked++;
        const nestingError = checkDeepNesting(content, filePath);
        if (nestingError) {
          markGuardFired(filePath, 25);
          logAndExit('block');
          block(nestingError);
          return;
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GUARDS 28-30: Configuration Centralization (for .nix files)
  // ─────────────────────────────────────────────────────────────────────────
  if ((tool_name === 'Write' || tool_name === 'Edit') && content && filePath) {
    if (filePath.endsWith('.nix') && !isConfigAllowedPath(filePath)) {
      // Guard 28: No Hardcoded Ports
      if (!checkBypassFiles(28)) {
        guardsChecked++;
        const portError = checkHardcodedPorts(content, filePath);
        if (portError) {
          logAndExit('block');
          block(portError);
          return;
        }
      }

      // Guard 30: No Hardcoded Localhost URLs
      if (!checkBypassFiles(30)) {
        guardsChecked++;
        const urlError = checkHardcodedUrls(content, filePath);
        if (urlError) {
          logAndExit('block');
          block(urlError);
          return;
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GUARD 31: Stack Compliance (for package.json)
  // ─────────────────────────────────────────────────────────────────────────
  if ((tool_name === 'Write' || tool_name === 'Edit') && content && filePath) {
    if (filePath.endsWith('package.json') && !checkBypassFiles(31)) {
      guardsChecked++;
      const stackError = checkStackCompliance(content, filePath);
      if (stackError) {
        logAndExit('block');
        block(stackError);
        return;
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GUARDS 32-36: Parse-at-Boundary (Tier 7)
  // ─────────────────────────────────────────────────────────────────────────
  if ((tool_name === 'Write' || tool_name === 'Edit') && content && filePath) {
    // Guard 32: Optional Chaining in Non-Boundary Code
    if (!checkBypassFiles(32)) {
      guardsChecked++;
      const optChainError = checkOptionalChainingDomain(content, filePath);
      if (optChainError) {
        logAndExit('block');
        block(optChainError);
        return;
      }
    }

    // Guard 33: Nullish Coalescing in Non-Boundary Code
    if (!checkBypassFiles(33)) {
      guardsChecked++;
      const nullishError = checkNullishCoalescingDomain(content, filePath);
      if (nullishError) {
        logAndExit('block');
        block(nullishError);
        return;
      }
    }

    // Guard 34: Null Check Then Non-Null Assert
    if (!checkBypassFiles(34)) {
      guardsChecked++;
      const nullAssertError = checkNullCheckThenAssert(content, filePath);
      if (nullAssertError) {
        logAndExit('block');
        block(nullAssertError);
        return;
      }
    }

    // Guard 35: Type Assertions (Advisory - warnings only)
    if (!checkBypassFiles(35)) {
      guardsChecked++;
      const typeAssertWarnings = checkTypeAssertions(content, filePath);
      advisoryWarnings.push(...typeAssertWarnings);
    }

    // Guard 36: Non-Null Assertion Without Narrowing
    if (!checkBypassFiles(36)) {
      guardsChecked++;
      const nonNullError = checkNonNullAssertWithoutNarrowing(content, filePath);
      if (nonNullError) {
        logAndExit('block');
        block(nonNullError);
        return;
      }
    }

    // Guard 37: Nullable Union in Context Types
    if (!checkBypassFiles(37)) {
      guardsChecked++;
      const nullableContextError = checkNullableUnionContext(content, filePath);
      if (nullableContextError) {
        logAndExit('block');
        block(nullableContextError);
        return;
      }
    }

    // Guard 38: Implicit Truthiness Check (Advisory - warnings only)
    if (!checkBypassFiles(38)) {
      guardsChecked++;
      const truthinessWarnings = checkTruthinessCheck(content, filePath);
      advisoryWarnings.push(...truthinessWarnings);
    }

    // Guard 39: Undefined Check in Domain Code
    if (!checkBypassFiles(39)) {
      guardsChecked++;
      const undefinedCheckError = checkUndefinedCheckDomain(content, filePath);
      if (undefinedCheckError) {
        logAndExit('block');
        block(undefinedCheckError);
        return;
      }
    }
  }

  // All checks passed - log performance and include advisory warnings if any
  logAndExit('approve');
  if (advisoryWarnings.length > 0) {
    hookApprove(advisoryWarnings.join(' | '));
  } else {
    allow();
  }
}

main().catch((e) => {
  hookLogError('paragon-guard', e);
  allow(); // Fail-open on error
});
