#!/usr/bin/env bun
/**
 * Unified Polish - Consolidated PostToolUse formatter
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
 *
 * Key optimization: All formatters run in PARALLEL via Promise.all()
 * This consolidation reduces shell spawns from 9 → 1 per Write/Edit operation.
 */

import { spawn } from 'bun';
import { emitContinue } from './lib/hook-logging';

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

// Nix → nixfmt-rfc-style (December 2025 standard)
const nixFiles = filesByExt.get('nix') || [];
if (nixFiles.length > 0) {
  tasks.push(runFormatter(['nixfmt'], nixFiles));
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

// Output success for PostToolUse
emitContinue();
