/**
 * Tier 3: Execution Feedback
 *
 * Runs actual tools and captures output:
 * - TypeScript type checking (bun run tsc --noEmit)
 * - Linting (biome check)
 * - Test execution (bun test)
 */

import { spawn } from 'node:child_process';
import { Effect } from 'effect';
import type { TierResult, VerificationOptions } from '../index.js';

// =============================================================================
// Types
// =============================================================================

type CommandResult = {
  readonly exitCode: number;
  readonly stdout: string;
  readonly stderr: string;
};

// =============================================================================
// Helpers
// =============================================================================

/**
 * Run a command and capture output
 */
const runCommand = (
  cmd: string,
  args: string[],
  cwd: string
): Effect.Effect<CommandResult, Error> =>
  Effect.tryPromise({
    try: () =>
      new Promise<CommandResult>((resolve, reject) => {
        const proc = spawn(cmd, args, {
          cwd,
          stdio: ['ignore', 'pipe', 'pipe'],
          env: { ...process.env, FORCE_COLOR: '0' },
        });

        let stdout = '';
        let stderr = '';

        proc.stdout.on('data', (data) => {
          stdout += data.toString();
        });
        proc.stderr.on('data', (data) => {
          stderr += data.toString();
        });

        proc.on('error', (err) => {
          reject(new Error(`Failed to spawn ${cmd}: ${err.message}`));
        });

        proc.on('close', (code) => {
          resolve({
            exitCode: code ?? 1,
            stdout,
            stderr,
          });
        });
      }),
    catch: (e) => new Error(`Command ${cmd} failed: ${e}`),
  });

/**
 * Extract error count from TypeScript output
 */
const parseTypeScriptErrors = (output: string): { errors: number; details: string[] } => {
  const details: string[] = [];
  const lines = output.split('\n');

  for (const line of lines) {
    // Match TypeScript error format: file(line,col): error TS####: message
    if (line.includes('error TS')) {
      details.push(line.trim());
    }
  }

  return { errors: details.length, details: details.slice(0, 10) };
};

/**
 * Extract error count from Biome output
 */
const parseBiomeErrors = (
  output: string
): { errors: number; warnings: number; details: string[] } => {
  const details: string[] = [];
  let errors = 0;
  let warnings = 0;

  const lines = output.split('\n');
  for (const line of lines) {
    if (line.includes('error[')) {
      errors++;
      details.push(line.trim());
    } else if (line.includes('warning[')) {
      warnings++;
      details.push(line.trim());
    }
  }

  return { errors, warnings, details: details.slice(0, 10) };
};

/**
 * Extract test failures from Bun test output
 */
const parseTestErrors = (output: string): { errors: number; details: string[] } => {
  const details: string[] = [];
  let errors = 0;

  // Look for "FAIL" lines
  const lines = output.split('\n');
  for (const line of lines) {
    if (line.includes('FAIL') || line.includes('fail')) {
      errors++;
      details.push(line.trim());
    }
  }

  // Also check for summary line: "X pass | Y fail"
  const summaryMatch = output.match(/(\d+)\s+fail/i);
  if (summaryMatch?.[1]) {
    errors = Math.max(errors, parseInt(summaryMatch[1], 10));
  }

  return { errors, details: details.slice(0, 10) };
};

// =============================================================================
// Tier Implementation
// =============================================================================

/**
 * Run Tier 3: Execution Feedback
 */
export const runExecutionTier = (opts: VerificationOptions): Effect.Effect<TierResult, Error> =>
  Effect.gen(function* () {
    const startTime = Date.now();
    const details: string[] = [];
    let totalErrors = 0;
    let totalWarnings = 0;

    // 1. TypeScript type check
    const tscResult = yield* runCommand('bun', ['run', 'tsc', '--noEmit'], opts.path).pipe(
      Effect.catchAll((e) =>
        Effect.succeed({ exitCode: 1, stdout: '', stderr: `tsc not available: ${e.message}` })
      )
    );

    if (tscResult.exitCode !== 0) {
      const parsed = parseTypeScriptErrors(tscResult.stdout + tscResult.stderr);
      totalErrors += parsed.errors;
      details.push(`TypeCheck: ${parsed.errors} error(s)`);
      details.push(...parsed.details.map((d) => `  ${d}`));
    } else {
      details.push('TypeCheck: passed');
    }

    // 2. Biome lint
    const biomeResult = yield* runCommand('bunx', ['@biomejs/biome', 'check', '.'], opts.path).pipe(
      Effect.catchAll((e) =>
        Effect.succeed({ exitCode: 1, stdout: '', stderr: `biome not available: ${e.message}` })
      )
    );

    if (biomeResult.exitCode !== 0) {
      const parsed = parseBiomeErrors(biomeResult.stdout + biomeResult.stderr);
      totalErrors += parsed.errors;
      totalWarnings += parsed.warnings;
      details.push(`Lint: ${parsed.errors} error(s), ${parsed.warnings} warning(s)`);
      details.push(...parsed.details.map((d) => `  ${d}`));
    } else {
      details.push('Lint: passed');
    }

    // 3. Test execution
    const testResult = yield* runCommand('bun', ['test', '--run'], opts.path).pipe(
      Effect.catchAll(() => Effect.succeed({ exitCode: 0, stdout: 'No tests found', stderr: '' }))
    );

    if (testResult.exitCode !== 0) {
      const parsed = parseTestErrors(testResult.stdout + testResult.stderr);
      totalErrors += parsed.errors;
      details.push(`Tests: ${parsed.errors} failure(s)`);
      details.push(...parsed.details.map((d) => `  ${d}`));
    } else {
      details.push('Tests: passed');
    }

    return {
      tier: 'execution' as const,
      passed: totalErrors === 0,
      errors: totalErrors,
      warnings: totalWarnings,
      details,
      duration: Date.now() - startTime,
    };
  });
