#!/usr/bin/env bun
/**
 * Session Polish - Post-session auto-fix hook
 *
 * Runs on Stop event to ensure all modified files are compliant.
 *
 * 1. Get modified files from git (HEAD~1 diff)
 * 2. Run formatters in parallel (biome, alejandra, ruff, shfmt)
 * 3. Run AST-grep rules for skill validation
 * 4. Log violations to ~/.claude/enforcement.log
 * 5. Run sig-verify for 5-tier check
 */

import { spawn } from 'bun';
import { existsSync, appendFileSync, mkdirSync, readdirSync, readFileSync } from 'node:fs';
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
const AST_GREP_RULES_DIR = `${DOTFILES}/config/agents/rules/ast-grep`;

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

async function runFormatter(cmd: string[], files: string[], cwd?: string): Promise<void> {
  if (files.length === 0) return;
  try {
    const proc = spawn([...cmd, ...files], {
      cwd,
      stderr: 'ignore',
      stdout: 'ignore',
    });
    await proc.exited;
  } catch {
    // Formatters should never block
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
// Format Files
// ============================================================================

async function formatFiles(files: string[], cwd: string): Promise<void> {
  const filesByExt = new Map<string, string[]>();
  for (const path of files) {
    const ext = path.split('.').pop()?.toLowerCase() || '';
    if (!filesByExt.has(ext)) {
      filesByExt.set(ext, []);
    }
    filesByExt.get(ext)!.push(path);
  }

  const tasks: Promise<void>[] = [];

  // TypeScript/JavaScript → Biome
  const tsJsFiles = [
    ...(filesByExt.get('ts') || []),
    ...(filesByExt.get('tsx') || []),
    ...(filesByExt.get('js') || []),
    ...(filesByExt.get('jsx') || []),
  ];
  if (tsJsFiles.length > 0) {
    tasks.push(runFormatter(['bunx', '@biomejs/biome', 'check', '--write', '--unsafe'], tsJsFiles, cwd));
  }

  // Python → Ruff
  const pyFiles = filesByExt.get('py') || [];
  if (pyFiles.length > 0) {
    tasks.push(
      (async () => {
        await runFormatter(['ruff', 'format'], pyFiles, cwd);
        await runFormatter(['ruff', 'check', '--fix'], pyFiles, cwd);
      })()
    );
  }

  // Nix → nixfmt
  const nixFiles = filesByExt.get('nix') || [];
  if (nixFiles.length > 0) {
    tasks.push(runFormatter(['nixfmt'], nixFiles, cwd));
  }

  // Shell → shfmt
  const shellFiles = [...(filesByExt.get('sh') || []), ...(filesByExt.get('bash') || [])];
  if (shellFiles.length > 0) {
    tasks.push(runFormatter(['shfmt', '-w'], shellFiles, cwd));
  }

  await Promise.all(tasks);
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

  // Get all rule files
  if (!existsSync(AST_GREP_RULES_DIR)) return violations;

  const ruleFiles = readdirSync(AST_GREP_RULES_DIR).filter((f) => f.endsWith('.yml'));

  for (const ruleFile of ruleFiles) {
    const rulePath = join(AST_GREP_RULES_DIR, ruleFile);
    const ruleId = ruleFile.replace('.yml', '');

    // Run ast-grep with the rule
    for (const file of tsFiles) {
      const { stdout, exitCode } = await runCommand(
        ['sg', 'scan', '--rule', rulePath, '--json', file],
        cwd
      );

      if (exitCode === 0 && stdout.trim()) {
        try {
          const results = JSON.parse(stdout);
          if (Array.isArray(results)) {
            for (const match of results) {
              violations.push({
                rule: ruleId,
                file: file,
                line: match.range?.start?.line || 0,
                message: match.message || `Violation of ${ruleId}`,
              });
            }
          }
        } catch {
          // JSON parse error - skip
        }
      }
    }
  }

  return violations;
}

// ============================================================================
// Sig-Verify Integration
// ============================================================================

async function runSigVerify(cwd: string): Promise<{ passed: boolean; output: string }> {
  const sigVerifyPath = join(DOTFILES, 'config/signet/verify.ts');
  if (!existsSync(sigVerifyPath)) {
    return { passed: true, output: 'sig-verify not found, skipping' };
  }

  const { stdout, stderr, exitCode } = await runCommand(['bun', 'run', sigVerifyPath], cwd);
  return {
    passed: exitCode === 0,
    output: stdout || stderr,
  };
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

  // 2. Run formatters
  await formatFiles(modifiedFiles, cwd);
  log(`Formatters completed`);

  // 3. Run AST-grep validation
  const violations = await validateWithAstGrep(modifiedFiles, cwd);
  if (violations.length > 0) {
    log(`Found ${violations.length} skill violations:`);
    for (const v of violations) {
      log(`  - ${v.rule}: ${v.file}:${v.line} - ${v.message}`);
    }
  }

  // 4. Run sig-verify
  const sigResult = await runSigVerify(cwd);
  if (!sigResult.passed) {
    log(`sig-verify warnings: ${sigResult.output}`);
  }

  // 5. Report summary
  const summary = {
    filesPolished: modifiedFiles.length,
    violations: violations.length,
    sigVerifyPassed: sigResult.passed,
  };

  emitContinue({
    additionalContext: `Session polish: ${summary.filesPolished} files formatted, ${summary.violations} violations logged`,
  });
}

main().catch((e) => {
  logError('session-polish', e);
  emitContinue();
});
