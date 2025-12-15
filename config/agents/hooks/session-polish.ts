#!/usr/bin/env bun
/**
 * Session Polish - Post-session validation hook
 *
 * Runs on Stop event for final validation (formatting handled by unified-polish.ts).
 *
 * 1. Get modified files from git (HEAD~1 diff)
 * 2. Run AST-grep validation (combined rules file - single invocation)
 * 3. Log violations to ~/.claude/enforcement.log
 *
 * NOTE: Formatters removed - unified-polish.ts handles PostToolUse formatting.
 */

import { spawn } from 'bun';
import { existsSync, appendFileSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { z } from 'zod';
import { emitContinue, logError } from './lib/hook-logging';

// ============================================================================
// Input Types
// ============================================================================

type HookInput = {
  readonly hook_event_name: 'Stop';
  readonly session_id: string;
  readonly cwd?: string;
};

const HookInputSchema = z.object({
  hook_event_name: z.literal('Stop'),
  session_id: z.string(),
  cwd: z.string().optional(),
}) satisfies z.ZodType<HookInput>;

// ============================================================================
// Configuration
// ============================================================================

const DOTFILES = process.env.DOTFILES || `${process.env.HOME}/dotfiles`;
const ENFORCEMENT_LOG = `${process.env.HOME}/.claude/enforcement.log`;
const COMBINED_RULES_FILE = `${DOTFILES}/config/agents/rules/paragon-combined.yaml`;

// ============================================================================
// Helpers
// ============================================================================

function log(message: string): void {
  const timestamp = new Date().toISOString();
  const logDir = dirname(ENFORCEMENT_LOG);
  if (!existsSync(logDir)) {
    mkdirSync(logDir, { recursive: true });
  }
  appendFileSync(ENFORCEMENT_LOG, `[${timestamp}] ${message}\n`);
}

async function runCommand(cmd: string[], cwd?: string): Promise<{ stdout: string; stderr: string; exitCode: number }> {
  try {
    const proc = spawn(cmd, {
      cwd,
      stdout: 'pipe',
      stderr: 'pipe',
    });
    const stdout = await new Response(proc.stdout).text();
    const stderr = await new Response(proc.stderr).text();
    const exitCode = await proc.exited;
    return { stdout, stderr, exitCode };
  } catch (e) {
    return { stdout: '', stderr: String(e), exitCode: 1 };
  }
}

// ============================================================================
// Get Modified Files
// ============================================================================

async function getModifiedFiles(cwd: string): Promise<string[]> {
  // Get files modified in the last commit or uncommitted changes
  const { stdout: staged } = await runCommand(['git', 'diff', '--cached', '--name-only'], cwd);
  const { stdout: unstaged } = await runCommand(['git', 'diff', '--name-only'], cwd);
  const { stdout: lastCommit } = await runCommand(['git', 'diff', '--name-only', 'HEAD~1'], cwd);

  const allFiles = new Set<string>();
  for (const line of [...staged.split('\n'), ...unstaged.split('\n'), ...lastCommit.split('\n')]) {
    const file = line.trim();
    if (file && existsSync(join(cwd, file))) {
      allFiles.add(join(cwd, file));
    }
  }
  return [...allFiles];
}

// ============================================================================
// AST-Grep Validation
// ============================================================================

interface Violation {
  rule: string;
  file: string;
  line: number;
  message: string;
}

async function validateWithAstGrep(files: string[], cwd: string): Promise<Violation[]> {
  const violations: Violation[] = [];

  // Only validate TypeScript files
  const tsFiles = files.filter((f) => f.endsWith('.ts') || f.endsWith('.tsx'));
  if (tsFiles.length === 0) return violations;

  // Use combined rules file (single invocation instead of O(rules × files))
  if (!existsSync(COMBINED_RULES_FILE)) return violations;

  // Run ast-grep with combined rules on all TypeScript files at once
  const { stdout, exitCode } = await runCommand(
    ['sg', 'scan', '--rule', COMBINED_RULES_FILE, '--json', ...tsFiles],
    cwd
  );

  if (exitCode === 0 && stdout.trim()) {
    try {
      const results = JSON.parse(stdout);
      if (Array.isArray(results)) {
        for (const match of results) {
          violations.push({
            rule: match.ruleId || 'paragon',
            file: match.file || '',
            line: match.range?.start?.line || 0,
            message: match.message || 'PARAGON violation',
          });
        }
      }
    } catch {
      // JSON parse error - skip
    }
  }

  return violations;
}

// ============================================================================
// Main
// ============================================================================

async function main(): Promise<void> {
  let rawInput: string;
  try {
    rawInput = await Bun.stdin.text();
  } catch {
    emitContinue();
    return;
  }

  if (!rawInput.trim()) {
    emitContinue();
    return;
  }

  let input: HookInput;
  try {
    input = HookInputSchema.parse(JSON.parse(rawInput));
  } catch {
    emitContinue();
    return;
  }

  const cwd = input.cwd || process.cwd();
  const sessionId = input.session_id;

  log(`Session ${sessionId} ended - starting polish`);

  // 1. Get modified files
  const modifiedFiles = await getModifiedFiles(cwd);
  if (modifiedFiles.length === 0) {
    log(`No modified files to polish`);
    emitContinue();
    return;
  }

  log(`Found ${modifiedFiles.length} modified files`);

  // 2. Run AST-grep validation (formatting already done by unified-polish.ts)
  const violations = await validateWithAstGrep(modifiedFiles, cwd);
  if (violations.length > 0) {
    log(`Found ${violations.length} PARAGON violations:`);
    for (const v of violations) {
      log(`  - ${v.rule}: ${v.file}:${v.line} - ${v.message}`);
    }
  }

  // 3. Report summary
  const summary = {
    filesChecked: modifiedFiles.length,
    violations: violations.length,
  };

  emitContinue({
    additionalContext: `Session validated: ${summary.filesChecked} files, ${summary.violations} violations logged`,
  });
}

main().catch((e) => {
  logError('session-polish', e);
  emitContinue();
});
