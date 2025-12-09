#!/usr/bin/env bun
/**
 * TDD Enforcer Hook - BLOCKS source edits without tests
 *
 * Trigger: PreToolUse on Write/Edit/MultiEdit
 * Mode: Strict (Block) - User chose hard enforcement
 *
 * Multi-language support:
 * - TypeScript/JavaScript: .test.ts, .spec.ts, __tests__/
 * - Python: test_*.py, *_test.py, tests/
 * - Go: *_test.go
 * - Rust: tests/*.rs, src/*_test.rs (note: inline tests are common)
 * - Shell: *.bats (optional enforcement)
 *
 * Checks if a corresponding test file exists before allowing source modifications.
 * Forces Red-Green-Refactor by requiring tests to exist first.
 */

import { z } from 'zod';

// Hook input schema matching Claude Code's PreToolUse event
const HookInputSchema = z.object({
  hook_event_name: z.literal('PreToolUse'),
  session_id: z.string(),
  tool_name: z.string(),
  tool_input: z
    .object({
      file_path: z.string().optional(),
    })
    .passthrough(),
});

// ============================================================================
// Language Configuration
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
        `${dir}/__tests__/${base}.spec${ext}`,
        `${dir.replace(/\/src\//, '/tests/')}/${base}.test${ext}`,
        `${dir.replace(/\/src\//, '/test/')}/${base}.test${ext}`,
      ];
    },
  },
  javascript: {
    extensions: ['.js', '.jsx', '.mjs', '.cjs'],
    testPatterns: [/\.test\.[jt]sx?$/, /\.spec\.[jt]sx?$/, /_test\.[jt]sx?$/, /\.e2e\.[jt]sx?$/],
    getTestPaths: (sourcePath: string) => {
      const dir = sourcePath.replace(/\/[^/]+$/, '');
      const base = sourcePath.replace(/^.*\//, '').replace(/\.[^.]+$/, '');
      const ext = sourcePath.match(/\.[^.]+$/)?.[0] || '.js';
      return [
        `${dir}/${base}.test${ext}`,
        `${dir}/${base}.spec${ext}`,
        `${dir}/__tests__/${base}.test${ext}`,
        `${dir}/__tests__/${base}.spec${ext}`,
        `${dir.replace(/\/src\//, '/tests/')}/${base}.test${ext}`,
      ];
    },
  },
  python: {
    extensions: ['.py'],
    testPatterns: [/^test_.*\.py$/, /.*_test\.py$/, /test\.py$/],
    getTestPaths: (sourcePath: string) => {
      const dir = sourcePath.replace(/\/[^/]+$/, '');
      const base = sourcePath.replace(/^.*\//, '').replace(/\.py$/, '');
      const fileName = sourcePath.replace(/^.*\//, '');
      return [
        // Same directory: test_module.py or module_test.py
        `${dir}/test_${base}.py`,
        `${dir}/${base}_test.py`,
        // tests/ directory (pytest convention)
        `${dir}/tests/test_${base}.py`,
        `${dir.replace(/\/src\//, '/tests/')}/test_${base}.py`,
        `${dir.replace(/\/src\//, '/test/')}/test_${base}.py`,
        // Parallel tests directory
        `${dir}/../tests/test_${base}.py`,
        // conftest.py indicates tests directory
        `${dir}/tests/${fileName}`,
      ];
    },
  },
  go: {
    extensions: ['.go'],
    testPatterns: [/_test\.go$/],
    getTestPaths: (sourcePath: string) => {
      const dir = sourcePath.replace(/\/[^/]+$/, '');
      const base = sourcePath.replace(/^.*\//, '').replace(/\.go$/, '');
      // Go tests MUST be in same directory with _test.go suffix
      return [`${dir}/${base}_test.go`];
    },
  },
  rust: {
    extensions: ['.rs'],
    testPatterns: [/_test\.rs$/, /^tests\/.*\.rs$/],
    getTestPaths: (sourcePath: string) => {
      const dir = sourcePath.replace(/\/[^/]+$/, '');
      const base = sourcePath.replace(/^.*\//, '').replace(/\.rs$/, '');
      // Rust has inline tests, but also integration tests in tests/
      return [
        `${dir}/${base}_test.rs`,
        `${dir}/tests/${base}.rs`,
        `${dir.replace(/\/src\//, '/tests/')}/${base}.rs`,
        `${dir}/../tests/${base}.rs`,
      ];
    },
  },
  shell: {
    extensions: ['.sh', '.bash', '.zsh'],
    testPatterns: [/\.bats$/, /_test\.sh$/, /\.test\.sh$/],
    getTestPaths: (sourcePath: string) => {
      const dir = sourcePath.replace(/\/[^/]+$/, '');
      const base = sourcePath.replace(/^.*\//, '').replace(/\.(sh|bash|zsh)$/, '');
      return [
        `${dir}/${base}.bats`,
        `${dir}/${base}_test.sh`,
        `${dir}/${base}.test.sh`,
        `${dir}/tests/${base}.bats`,
      ];
    },
  },
};

// ============================================================================
// Exclusions
// ============================================================================

// Directories to exclude from TDD enforcement
const EXCLUDED_DIRS = [
  '/node_modules/',
  '/.git/',
  '/dist/',
  '/build/',
  '/.next/',
  '/coverage/',
  '/migrations/', // DB migrations don't need unit tests
  '/scripts/', // One-off scripts often don't need tests
  '/__pycache__/',
  '/.venv/',
  '/venv/',
  '/vendor/', // Go vendor
  '/target/', // Rust build
  '/.cargo/',
  '/pkg/', // Go pkg
];

// Files to exclude (configuration, generated, etc.)
const EXCLUDED_FILES = [
  /^__init__\.py$/, // Python package markers
  /^conftest\.py$/, // Pytest configuration
  /^setup\.py$/, // Python setup
  /^main\.go$/, // Go entry points often tested via integration
  /^mod\.rs$/, // Rust module files
  /^lib\.rs$/, // Rust library roots
  /\.config\.[tj]sx?$/, // Config files
  /\.d\.ts$/, // TypeScript declarations
  /index\.[tj]sx?$/, // Index/barrel files (re-exports)
];

// ============================================================================
// Detection Functions
// ============================================================================

function getLanguage(path: string): LanguageConfig | null {
  for (const [, config] of Object.entries(LANGUAGES)) {
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

function isExcludedPath(path: string): boolean {
  return EXCLUDED_DIRS.some((dir) => path.includes(dir));
}

function isExcludedFile(path: string): boolean {
  const fileName = path.replace(/^.*\//, '');
  return EXCLUDED_FILES.some((pattern) => pattern.test(fileName));
}

async function testExists(sourcePath: string, language: LanguageConfig): Promise<boolean> {
  const testPaths = language.getTestPaths(sourcePath);
  for (const p of testPaths) {
    if (await Bun.file(p).exists()) return true;
  }

  // Special case for Rust: check if file has inline tests
  if (sourcePath.endsWith('.rs')) {
    try {
      const content = await Bun.file(sourcePath).text();
      if (content.includes('#[cfg(test)]') || content.includes('#[test]')) {
        return true; // Has inline tests
      }
    } catch {
      // File doesn't exist yet, no inline tests
    }
  }

  return false;
}

// ============================================================================
// Main Hook Logic
// ============================================================================

async function main() {
  let rawInput: string;
  try {
    rawInput = await Bun.stdin.text();
  } catch {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  let input: z.infer<typeof HookInputSchema>;
  try {
    input = HookInputSchema.parse(JSON.parse(rawInput));
  } catch {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // Only check file modification tools
  if (!['Write', 'Edit', 'MultiEdit'].includes(input.tool_name)) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  const filePath = input.tool_input.file_path;
  if (!filePath) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // Detect language
  const language = getLanguage(filePath);
  if (!language) {
    // Not a recognized source file (could be .md, .json, .sql, etc.)
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // Allow excluded directories
  if (isExcludedPath(filePath)) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // Allow excluded files
  if (isExcludedFile(filePath)) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // Allow test files themselves
  if (isTestFile(filePath, language)) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // Check if corresponding test exists
  if (await testExists(filePath, language)) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // BLOCK: No test file found
  const testPaths = language.getTestPaths(filePath);
  const fileName = filePath.split('/').pop() || filePath;

  // Detect language name for better error message
  let langName = 'this file';
  if (filePath.endsWith('.py')) langName = 'Python';
  else if (filePath.endsWith('.go')) langName = 'Go';
  else if (filePath.endsWith('.rs')) langName = 'Rust';
  else if (filePath.match(/\.[tj]sx?$/)) langName = 'TypeScript/JavaScript';
  else if (filePath.match(/\.(sh|bash|zsh)$/)) langName = 'Shell';

  console.log(
    JSON.stringify({
      decision: 'block',
      reason: `TDD VIOLATION: No test file found for ${fileName} (${langName}).

Write the test FIRST (Red phase), then implement the code.

Expected one of:
${testPaths
  .slice(0, 5)
  .map((p) => `  - ${p}`)
  .join('\n')}

TDD Cycle:
  1. RED: Write a failing test
  2. GREEN: Write minimal code to pass
  3. REFACTOR: Improve while green`,
    })
  );
}

main().catch((e) => {
  console.error('TDD Enforcer error:', e);
  console.log(JSON.stringify({ decision: 'allow' }));
});
