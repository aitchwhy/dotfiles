#!/usr/bin/env bun
/**
 * Unified Guard - Consolidated PreToolUse gatekeeper
 *
 * REPLACES:
 * - tdd-enforcer.ts
 * - forbidden-files.ts
 * - forbidden-imports.ts
 * - any-type-detector.ts
 * - conventional-commit.ts
 * - Bash safety inline check
 *
 * This consolidation reduces shell spawns from 6 → 1 per Write/Edit operation.
 */

import { z } from 'zod';

// ============================================================================
// Input Schema
// ============================================================================

const HookInputSchema = z.object({
  hook_event_name: z.literal('PreToolUse'),
  session_id: z.string(),
  tool_name: z.string(),
  tool_input: z
    .object({
      file_path: z.string().optional(),
      content: z.string().optional(), // Write
      new_string: z.string().optional(), // Edit
      command: z.string().optional(), // Bash
    })
    .passthrough(),
});

type HookInput = z.infer<typeof HookInputSchema>;

// ============================================================================
// Output Helpers
// ============================================================================

function allow(): void {
  console.log(JSON.stringify({ decision: 'allow' }));
}

function block(reason: string): void {
  console.log(JSON.stringify({ decision: 'block', reason }));
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
  { pattern: 'package-lock.json', reason: 'Use Bun', alternative: 'bun install' },
  { pattern: 'yarn.lock', reason: 'Use Bun', alternative: 'bun install' },
  { pattern: 'pnpm-lock.yaml', reason: 'Use Bun', alternative: 'bun install' },
  { pattern: /\.eslintrc(\.(js|cjs|mjs|json|yaml|yml))?$/, reason: 'Use Biome', alternative: 'biome.json' },
  { pattern: /eslint\.config\.(js|cjs|mjs|ts)$/, reason: 'Use Biome', alternative: 'biome.json' },
  { pattern: /\.prettierrc(\.(js|cjs|mjs|json|yaml|yml))?$/, reason: 'Use Biome', alternative: 'biome.json' },
  { pattern: /prettier\.config\.(js|cjs|mjs|ts)$/, reason: 'Use Biome', alternative: 'biome.json' },
  { pattern: /jest\.config\.(js|cjs|mjs|ts|json)$/, reason: 'Use Bun test', alternative: 'bun test' },
  { pattern: /prisma\/schema\.prisma$/, reason: 'Use Drizzle', alternative: 'drizzle.config.ts' },
];

function checkForbiddenFiles(filePath: string): string | null {
  const fileName = filePath.split('/').pop() || '';

  for (const forbidden of FORBIDDEN_FILES) {
    if (typeof forbidden.pattern === 'string') {
      if (fileName === forbidden.pattern || filePath.endsWith(forbidden.pattern)) {
        return `FORBIDDEN FILE: ${fileName}

Reason: ${forbidden.reason} instead of this file
Alternative: ${forbidden.alternative}

See VERSIONS.md for approved tools.`;
      }
    } else {
      if (forbidden.pattern.test(fileName) || forbidden.pattern.test(filePath)) {
        return `FORBIDDEN FILE: ${fileName}

Reason: ${forbidden.reason} instead of this file
Alternative: ${forbidden.alternative}

See VERSIONS.md for approved tools.`;
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
  {
    patterns: [/from\s+['"]express['"]/, /require\s*\(\s*['"]express['"]\s*\)/],
    package: 'express',
    alternative: 'hono',
    docs: 'https://hono.dev',
  },
  {
    patterns: [/from\s+['"]fastify['"]/, /require\s*\(\s*['"]fastify['"]\s*\)/],
    package: 'fastify',
    alternative: 'hono',
    docs: 'https://hono.dev',
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
];

function stripComments(code: string): string {
  code = code.replace(/\/\/.*$/gm, '');
  code = code.replace(/\/\*[\s\S]*?\*\//g, '');
  return code;
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
See VERSIONS.md for approved packages.`;
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
  code = code.replace(/\/\/.*$/gm, '');
  code = code.replace(/\/\*[\s\S]*?\*\//g, '');
  code = code.replace(/'(?:[^'\\]|\\.)*'/g, "''");
  code = code.replace(/"(?:[^"\\]|\\.)*"/g, '""');
  code = code.replace(/`(?:[^`\\]|\\.)*`/g, '``');
  return code;
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
// 6. TDD ENFORCER
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
// Main Hook Logic
// ============================================================================

async function main(): Promise<void> {
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
  // 1. BASH SAFETY (for Bash commands)
  // ─────────────────────────────────────────────────────────────────────────
  if (tool_name === 'Bash' && command) {
    const bashError = checkBashSafety(command);
    if (bashError) {
      block(bashError);
      return;
    }

    // Check conventional commit
    const commitError = checkConventionalCommit(command);
    if (commitError) {
      block(commitError);
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. FORBIDDEN FILES (for Write commands)
  // ─────────────────────────────────────────────────────────────────────────
  if (tool_name === 'Write' && filePath) {
    const fileError = checkForbiddenFiles(filePath);
    if (fileError) {
      block(fileError);
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. FORBIDDEN IMPORTS (for Write/Edit on TS/JS)
  // ─────────────────────────────────────────────────────────────────────────
  if ((tool_name === 'Write' || tool_name === 'Edit') && content && filePath) {
    const importError = checkForbiddenImports(content, filePath);
    if (importError) {
      block(importError);
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. ANY TYPE DETECTOR (for Write/Edit on TypeScript)
  // ─────────────────────────────────────────────────────────────────────────
  if ((tool_name === 'Write' || tool_name === 'Edit') && content && filePath) {
    const anyError = checkAnyType(content, filePath);
    if (anyError) {
      block(anyError);
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. TDD ENFORCER (for Write/Edit/MultiEdit on source files)
  // ─────────────────────────────────────────────────────────────────────────
  if (['Write', 'Edit', 'MultiEdit'].includes(tool_name) && filePath) {
    const tddError = await checkTDD(filePath);
    if (tddError) {
      block(tddError);
      return;
    }
  }

  // All checks passed
  allow();
}

main().catch((e) => {
  console.error('Unified Guard error:', e);
  allow(); // Fail-open on error
});
