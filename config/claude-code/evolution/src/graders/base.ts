/**
 * Base Grader Class
 *
 * All graders extend this abstract class to ensure consistent interface.
 */
import { type Result, Ok, Err, tryCatchAsync } from '../lib/result';
import { type GraderConfig, type GraderOutput, type GraderIssue } from './types';

// ============================================================================
// Abstract Base Class
// ============================================================================

export abstract class BaseGrader {
  protected readonly config: GraderConfig;
  protected readonly dotfilesPath: string;

  constructor(config: GraderConfig, dotfilesPath?: string) {
    this.config = config;
    this.dotfilesPath = dotfilesPath ?? `${process.env['HOME']}/dotfiles`;
  }

  /**
   * Run the grader with timeout handling
   */
  async run(): Promise<Result<GraderOutput, Error>> {
    const startTime = Date.now();

    // Create timeout promise
    const timeoutPromise = new Promise<never>((_, reject) => {
      setTimeout(() => {
        reject(new Error(`Grader ${this.config.name} timed out after ${this.config.timeout}ms`));
      }, this.config.timeout);
    });

    // Race against timeout
    const result = await Promise.race([
      tryCatchAsync(() => this.execute()),
      timeoutPromise.then(() => Err(new Error('Timeout')) as Result<GraderOutput, Error>),
    ]);

    // Add execution time metric if successful
    if (result.ok && result.data.metrics) {
      result.data.metrics['execution_time_ms'] = Date.now() - startTime;
    }

    return result;
  }

  /**
   * Execute the grader logic - must be implemented by subclasses
   */
  protected abstract execute(): Promise<GraderOutput>;

  /**
   * Helper to create a passing output
   */
  protected pass(score: number = 1.0, issues: GraderIssue[] = []): GraderOutput {
    return {
      score: Math.max(0, Math.min(1, score)),
      passed: score >= this.config.passingScore,
      issues,
      metrics: {},
    };
  }

  /**
   * Helper to create a failing output
   */
  protected fail(issues: GraderIssue[], score: number = 0): GraderOutput {
    return {
      score: Math.max(0, Math.min(1, score)),
      passed: false,
      issues,
      metrics: {},
    };
  }

  /**
   * Calculate score based on issue counts
   */
  protected calculateScore(total: number, failures: number): number {
    if (total === 0) return 1.0;
    return Math.max(0, (total - failures) / total);
  }
}

// ============================================================================
// Shell Command Helper
// ============================================================================

export interface ShellResult {
  exitCode: number;
  stdout: string;
  stderr: string;
}

export async function runShell(
  command: string,
  cwd?: string
): Promise<Result<ShellResult, Error>> {
  return tryCatchAsync(async () => {
    const proc = Bun.spawn(['sh', '-c', command], {
      cwd: cwd ?? process.cwd(),
      stdout: 'pipe',
      stderr: 'pipe',
    });

    const [stdout, stderr] = await Promise.all([
      new Response(proc.stdout).text(),
      new Response(proc.stderr).text(),
    ]);

    const exitCode = await proc.exited;

    return { exitCode, stdout, stderr };
  });
}

/**
 * Run shell and expect success (exit code 0)
 */
export async function runShellExpectSuccess(
  command: string,
  cwd?: string
): Promise<Result<string, Error>> {
  const result = await runShell(command, cwd);
  if (!result.ok) return result;

  if (result.data.exitCode !== 0) {
    return Err(new Error(`Command failed with exit code ${result.data.exitCode}: ${result.data.stderr}`));
  }

  return Ok(result.data.stdout);
}
