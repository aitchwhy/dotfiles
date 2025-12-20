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
 * Full Effect pipeline - no try/catch.
 */

import { Effect, pipe } from "effect";
import { spawn } from 'bun';
import { existsSync, appendFileSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { emitContinue, logError } from './lib/hook-logging';
import { decodeStopInput, type StopInput } from './lib/types';

// ============================================================================
// Configuration
// ============================================================================

const DOTFILES = process.env.DOTFILES || `${process.env.HOME}/dotfiles`;
const ENFORCEMENT_LOG = `${process.env.HOME}/.claude/enforcement.log`;
const COMBINED_RULES_FILE = `${DOTFILES}/config/agents/rules/paragon-combined.yaml`;

// ============================================================================
// Logging (Effect-wrapped)
// ============================================================================

const log = (message: string): Effect.Effect<void, never, never> =>
  Effect.try(() => {
    const timestamp = new Date().toISOString();
    const logDir = dirname(ENFORCEMENT_LOG);
    if (!existsSync(logDir)) {
      mkdirSync(logDir, { recursive: true });
    }
    appendFileSync(ENFORCEMENT_LOG, `[${timestamp}] ${message}\n`);
  }).pipe(Effect.catchAll(() => Effect.void));

// ============================================================================
// Command Runner
// ============================================================================

const runCommand = (cmd: string[], cwd?: string): Effect.Effect<{ stdout: string; stderr: string; exitCode: number }, never, never> =>
  Effect.tryPromise({
    try: async () => {
      const proc = spawn(cmd, {
        cwd,
        stdout: 'pipe',
        stderr: 'pipe',
      });
      const stdout = await new Response(proc.stdout).text();
      const stderr = await new Response(proc.stderr).text();
      const exitCode = await proc.exited;
      return { stdout, stderr, exitCode };
    },
    catch: (e) => ({ stdout: '', stderr: String(e), exitCode: 1 }),
  }).pipe(Effect.catchAll(() => Effect.succeed({ stdout: '', stderr: '', exitCode: 1 })));

// ============================================================================
// Get Modified Files
// ============================================================================

const getModifiedFiles = (cwd: string): Effect.Effect<string[], never, never> =>
  Effect.gen(function* () {
    const staged = yield* runCommand(['git', 'diff', '--cached', '--name-only'], cwd);
    const unstaged = yield* runCommand(['git', 'diff', '--name-only'], cwd);
    const lastCommit = yield* runCommand(['git', 'diff', '--name-only', 'HEAD~1'], cwd);

    const allFiles = new Set<string>();
    for (const line of [...staged.stdout.split('\n'), ...unstaged.stdout.split('\n'), ...lastCommit.stdout.split('\n')]) {
      const file = line.trim();
      if (file && existsSync(join(cwd, file))) {
        allFiles.add(join(cwd, file));
      }
    }
    return [...allFiles];
  });

// ============================================================================
// AST-Grep Validation
// ============================================================================

interface Violation {
  rule: string;
  file: string;
  line: number;
  message: string;
}

const validateWithAstGrep = (files: string[], cwd: string): Effect.Effect<Violation[], never, never> =>
  Effect.gen(function* () {
    const violations: Violation[] = [];

    // Only validate TypeScript files
    const tsFiles = files.filter((f) => f.endsWith('.ts') || f.endsWith('.tsx'));
    if (tsFiles.length === 0) return violations;

    // Use combined rules file (single invocation instead of O(rules × files))
    if (!existsSync(COMBINED_RULES_FILE)) return violations;

    // Run ast-grep with combined rules on all TypeScript files at once
    const { stdout, exitCode } = yield* runCommand(
      ['sg', 'scan', '--rule', COMBINED_RULES_FILE, '--json', ...tsFiles],
      cwd
    );

    if (exitCode === 0 && stdout.trim()) {
      const parseResult = yield* Effect.try({
        try: () => {
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
          return violations;
        },
        catch: () => violations,
      });
    }

    return violations;
  });

// ============================================================================
// Read stdin
// ============================================================================

const readStdin = Effect.tryPromise({
  try: async () => {
    const text = await Bun.stdin.text();
    if (!text.trim()) return null;
    return JSON.parse(text);
  },
  catch: () => null,
});

// ============================================================================
// Main Program
// ============================================================================

const program = pipe(
  readStdin,
  Effect.flatMap((raw) => {
    if (raw === null) {
      emitContinue();
      return Effect.void;
    }
    return pipe(
      decodeStopInput(raw),
      Effect.flatMap((input: StopInput) => {
        const cwd = input.cwd || process.cwd();
        const sessionId = input.session_id;

        return Effect.gen(function* () {
          yield* log(`Session ${sessionId} ended - starting polish`);

          // 1. Get modified files
          const modifiedFiles = yield* getModifiedFiles(cwd);
          if (modifiedFiles.length === 0) {
            yield* log(`No modified files to polish`);
            emitContinue();
            return;
          }

          yield* log(`Found ${modifiedFiles.length} modified files`);

          // 2. Run AST-grep validation
          const violations = yield* validateWithAstGrep(modifiedFiles, cwd);
          if (violations.length > 0) {
            yield* log(`Found ${violations.length} PARAGON violations:`);
            for (const v of violations) {
              yield* log(`  - ${v.rule}: ${v.file}:${v.line} - ${v.message}`);
            }
          }

          // 3. Report summary
          emitContinue({
            additionalContext: `Session validated: ${modifiedFiles.length} files, ${violations.length} violations logged`,
          });
        });
      }),
    );
  }),
  Effect.catchAll((error) => {
    logError('session-polish', error);
    emitContinue();
    return Effect.void;
  }),
);

// ============================================================================
// Execute
// ============================================================================

Effect.runPromise(program);
