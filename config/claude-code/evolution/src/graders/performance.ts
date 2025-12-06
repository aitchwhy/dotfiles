/**
 * Performance Grader
 *
 * Measures flake evaluation time and shell startup time.
 * Weight: 10% of overall score
 */
import { BaseGrader, runShell } from './base';
import { type GraderOutput, type GraderIssue, DEFAULT_GRADER_CONFIGS } from './types';

const THRESHOLDS = {
  // Flake eval time thresholds (seconds)
  FLAKE_EVAL_EXCELLENT: 5,
  FLAKE_EVAL_GOOD: 10,
  FLAKE_EVAL_ACCEPTABLE: 20,

  // Shell startup time thresholds (milliseconds)
  SHELL_STARTUP_EXCELLENT: 100,
  SHELL_STARTUP_GOOD: 300,
  SHELL_STARTUP_ACCEPTABLE: 500,
} as const;

export class PerformanceGrader extends BaseGrader {
  constructor(dotfilesPath?: string) {
    super(DEFAULT_GRADER_CONFIGS['performance']!, dotfilesPath);
  }

  protected async execute(): Promise<GraderOutput> {
    const issues: GraderIssue[] = [];
    const scores: number[] = [];

    // 1. Flake evaluation time (50% of this grader)
    const flakeEvalResult = await this.measureFlakeEvalTime();
    scores.push(flakeEvalResult.score);
    if (flakeEvalResult.issue) {
      issues.push(flakeEvalResult.issue);
    }

    // 2. Shell startup time (50% of this grader)
    const shellStartupResult = await this.measureShellStartupTime();
    scores.push(shellStartupResult.score);
    if (shellStartupResult.issue) {
      issues.push(shellStartupResult.issue);
    }

    // Calculate weighted average
    const score = scores.reduce((a, b) => a + b, 0) / scores.length;

    return {
      score,
      passed: score >= this.config.passingScore,
      issues,
      metrics: {
        flake_eval_time_seconds: flakeEvalResult.timeSeconds,
        shell_startup_time_ms: shellStartupResult.timeMs,
      },
    };
  }

  private async measureFlakeEvalTime(): Promise<{
    score: number;
    timeSeconds: number;
    issue: GraderIssue | undefined;
  }> {
    const hostname = await this.getHostname();

    // Use Bun's performance API for timing
    const startTime = performance.now();

    const result = await runShell(
      `nix eval "${this.dotfilesPath}#darwinConfigurations.${hostname}.system" --json 2>&1 >/dev/null`
    );

    const endTime = performance.now();
    const timeSeconds = (endTime - startTime) / 1000;

    // If eval failed, still record the time but give lower score
    if (!result.ok || result.data.exitCode !== 0) {
      return {
        score: 0,
        timeSeconds,
        issue: {
          message: `flake eval failed (${timeSeconds.toFixed(1)}s)`,
          severity: 'error',
        },
      };
    }

    // Score based on thresholds
    let score: number;
    let issue: GraderIssue | undefined;

    if (timeSeconds <= THRESHOLDS.FLAKE_EVAL_EXCELLENT) {
      score = 1.0;
    } else if (timeSeconds <= THRESHOLDS.FLAKE_EVAL_GOOD) {
      score = 0.85;
    } else if (timeSeconds <= THRESHOLDS.FLAKE_EVAL_ACCEPTABLE) {
      score = 0.7;
      issue = {
        message: `flake eval slow: ${timeSeconds.toFixed(1)}s (target: <${THRESHOLDS.FLAKE_EVAL_GOOD}s)`,
        severity: 'info',
      };
    } else {
      score = 0.5;
      issue = {
        message: `flake eval very slow: ${timeSeconds.toFixed(1)}s (target: <${THRESHOLDS.FLAKE_EVAL_ACCEPTABLE}s)`,
        severity: 'warning',
      };
    }

    return { score, timeSeconds, issue };
  }

  private async measureShellStartupTime(): Promise<{
    score: number;
    timeMs: number;
    issue: GraderIssue | undefined;
  }> {
    // Measure zsh startup time (average of 3 runs)
    const times: number[] = [];

    for (let i = 0; i < 3; i++) {
      const startTime = performance.now();
      const result = await runShell('zsh -i -c exit 2>/dev/null');
      const endTime = performance.now();

      if (result.ok && result.data.exitCode === 0) {
        times.push(endTime - startTime);
      }
    }

    if (times.length === 0) {
      return {
        score: 0,
        timeMs: 0,
        issue: {
          message: 'could not measure shell startup time',
          severity: 'error',
        },
      };
    }

    const avgTimeMs = times.reduce((a, b) => a + b, 0) / times.length;

    // Score based on thresholds
    let score: number;
    let issue: GraderIssue | undefined;

    if (avgTimeMs <= THRESHOLDS.SHELL_STARTUP_EXCELLENT) {
      score = 1.0;
    } else if (avgTimeMs <= THRESHOLDS.SHELL_STARTUP_GOOD) {
      score = 0.85;
    } else if (avgTimeMs <= THRESHOLDS.SHELL_STARTUP_ACCEPTABLE) {
      score = 0.7;
      issue = {
        message: `shell startup slow: ${avgTimeMs.toFixed(0)}ms (target: <${THRESHOLDS.SHELL_STARTUP_GOOD}ms)`,
        severity: 'info',
      };
    } else {
      score = 0.5;
      issue = {
        message: `shell startup very slow: ${avgTimeMs.toFixed(0)}ms (target: <${THRESHOLDS.SHELL_STARTUP_ACCEPTABLE}ms)`,
        severity: 'warning',
      };
    }

    return { score, timeMs: avgTimeMs, issue };
  }

  private async getHostname(): Promise<string> {
    const result = await runShell('hostname -s');
    return result.ok ? result.data.stdout.trim() : 'unknown';
  }
}
