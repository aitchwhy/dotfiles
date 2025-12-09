#!/usr/bin/env bun
/**
 * Unified Polish - Consolidated PostToolUse formatter + auto-commit
 *
 * REPLACES:
 * - TypeScript/JS formatter (biome)
 * - Python formatter (ruff)
 * - Nix formatter (alejandra)
 * - JSON formatter (biome)
 * - Shell formatter (shfmt)
 * - YAML/TOML formatter (prettier)
 * - Lua formatter (stylua)
 * - CSS/SCSS formatter (prettier)
 * - SQL formatter (sql-formatter)
 * - atomic-git-sentinel.ts (auto-commit)
 *
 * Key optimization: All formatters run in PARALLEL via Promise.all()
 * This consolidation reduces shell spawns from 12 → 1 per Write/Edit operation.
 */

import { spawn, $ } from 'bun';

// ============================================================================
// Configuration
// ============================================================================

const filePaths = (process.env.CLAUDE_FILE_PATHS || '').split(',').filter(Boolean);

// Exit early if no files
if (filePaths.length === 0) {
  process.exit(0);
}

// Group files by extension for targeted formatting
const filesByExt = new Map<string, string[]>();
for (const path of filePaths) {
  const ext = path.split('.').pop()?.toLowerCase() || '';
  if (!filesByExt.has(ext)) {
    filesByExt.set(ext, []);
  }
  filesByExt.get(ext)!.push(path);
}

// ============================================================================
// Formatter Runners
// ============================================================================

async function runFormatter(cmd: string[], files: string[]): Promise<void> {
  if (files.length === 0) return;
  
  try {
    const proc = spawn([...cmd, ...files], {
      stderr: 'ignore',
      stdout: 'ignore',
    });
    await proc.exited;
  } catch {
    // Formatters should never block - fail silently
  }
}

// ============================================================================
// Format Tasks (Run in Parallel)
// ============================================================================

const tasks: Promise<void>[] = [];

// TypeScript/JavaScript/JSX/TSX → Biome
const tsJsFiles = [
  ...(filesByExt.get('ts') || []),
  ...(filesByExt.get('tsx') || []),
  ...(filesByExt.get('js') || []),
  ...(filesByExt.get('jsx') || []),
];
if (tsJsFiles.length > 0) {
  tasks.push(runFormatter(['bunx', '@biomejs/biome', 'check', '--write', '--unsafe'], tsJsFiles));
}

// JSON → Biome
const jsonFiles = filesByExt.get('json') || [];
if (jsonFiles.length > 0) {
  tasks.push(runFormatter(['bunx', '@biomejs/biome', 'check', '--write', '--unsafe'], jsonFiles));
}

// Python → Ruff format + lint
const pyFiles = filesByExt.get('py') || [];
if (pyFiles.length > 0) {
  tasks.push(
    (async () => {
      await runFormatter(['ruff', 'format'], pyFiles);
      await runFormatter(['ruff', 'check', '--fix'], pyFiles);
    })()
  );
}

// Nix → Alejandra (fallback to nixfmt)
const nixFiles = filesByExt.get('nix') || [];
if (nixFiles.length > 0) {
  tasks.push(
    (async () => {
      try {
        const proc = spawn(['alejandra', '--quiet', ...nixFiles], {
          stderr: 'ignore',
          stdout: 'ignore',
        });
        const exitCode = await proc.exited;
        if (exitCode !== 0) {
          // Fallback to nixfmt
          await runFormatter(['nixfmt'], nixFiles);
        }
      } catch {
        // Try nixfmt as fallback
        await runFormatter(['nixfmt'], nixFiles);
      }
    })()
  );
}

// Shell → shfmt
const shellFiles = [
  ...(filesByExt.get('sh') || []),
  ...(filesByExt.get('bash') || []),
  ...(filesByExt.get('zsh') || []),
];
if (shellFiles.length > 0) {
  tasks.push(runFormatter(['shfmt', '-w'], shellFiles));
}

// YAML/TOML → Prettier
const yamlTomlFiles = [
  ...(filesByExt.get('yaml') || []),
  ...(filesByExt.get('yml') || []),
  ...(filesByExt.get('toml') || []),
];
if (yamlTomlFiles.length > 0) {
  tasks.push(runFormatter(['npx', 'prettier', '--write'], yamlTomlFiles));
}

// Lua → Stylua
const luaFiles = filesByExt.get('lua') || [];
if (luaFiles.length > 0) {
  tasks.push(runFormatter(['stylua'], luaFiles));
}

// CSS/SCSS → Prettier
const cssFiles = [
  ...(filesByExt.get('css') || []),
  ...(filesByExt.get('scss') || []),
];
if (cssFiles.length > 0) {
  tasks.push(runFormatter(['npx', 'prettier', '--write'], cssFiles));
}

// SQL → sql-formatter
const sqlFiles = filesByExt.get('sql') || [];
if (sqlFiles.length > 0) {
  tasks.push(runFormatter(['npx', 'sql-formatter', '--fix'], sqlFiles));
}

// ============================================================================
// Wait for all formatters to complete
// ============================================================================

await Promise.all(tasks);

// ============================================================================
// Auto-Commit (consolidated from atomic-git-sentinel.ts)
// ============================================================================

async function autoCommit(): Promise<void> {
  try {
    // Check if in git repo
    const gitCheck = await $`git rev-parse --git-dir`.quiet().nothrow();
    if (gitCheck.exitCode !== 0) return;

    // Check for changes
    const status = await $`git status --porcelain`.text();
    if (!status.trim()) return;

    // Stage all changed files
    await $`git add .`.quiet();

    // Generate commit message
    const message = generateCommitMessage(filePaths);

    // Commit (skip hooks to avoid recursion)
    await $`git commit -m ${message} --no-verify`.quiet().nothrow();
  } catch {
    // Auto-commit should never fail the hook
  }
}

function generateCommitMessage(files: string[]): string {
  const type = inferCommitType(files);
  const scope = inferScope(files);
  const description = inferDescription(files);
  return `${type}(${scope}): ${description}`;
}

function inferCommitType(files: string[]): string {
  const hasTests = files.some((f) => 
    f.includes('.test.') || f.includes('.spec.') || f.includes('_test.')
  );
  const allDocs = files.every((f) => f.endsWith('.md') || f.endsWith('.mdx'));
  const allConfigs = files.every((f) => 
    f.endsWith('.json') || f.endsWith('.yaml') || f.endsWith('.yml') ||
    f.endsWith('.toml') || f.endsWith('.nix') || f.startsWith('.')
  );

  if (hasTests) return 'test';
  if (allDocs) return 'docs';
  if (allConfigs) return 'chore';
  return 'feat';
}

function inferScope(files: string[]): string {
  const dirs = [...new Set(files.map((f) => {
    const parts = f.split('/').filter(Boolean);
    // Get meaningful directory
    if (parts.includes('hooks')) return 'hooks';
    if (parts.includes('layers')) return 'layers';
    if (parts.includes('src')) return parts[parts.indexOf('src') + 1] || 'src';
    return parts[parts.length - 2] || 'root';
  }))];

  if (dirs.length === 1) return dirs[0]!;
  return 'misc';
}

function inferDescription(files: string[]): string {
  const names = files.map((f) => {
    const name = f.split('/').pop() || f;
    return name
      .replace(/\.(ts|tsx|js|jsx|test|spec|md|json|nix|yaml|yml)$/g, '')
      .replace(/\.test$/, '')
      .replace(/\.spec$/, '');
  });

  const unique = [...new Set(names)].slice(0, 3);
  
  if (files.length === 1) {
    return `update ${unique[0]}`;
  } else if (unique.length <= 3) {
    return `update ${unique.join(', ')}`;
  } else {
    return `update ${files.length} files`;
  }
}

// Run auto-commit after formatting
await autoCommit();

// Output success for PostToolUse
console.log(JSON.stringify({ continue: true }));
