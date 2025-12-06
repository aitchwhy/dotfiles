/**
 * Nix Health Grader
 *
 * Checks flake validity, formatting, and deprecated patterns.
 * Weight: 30% of overall score
 */
import { BaseGrader, runShell } from './base';
import { type GraderOutput, type GraderIssue, DEFAULT_GRADER_CONFIGS } from './types';

const POINTS = {
  FLAKE_CHECK: 40,
  FLAKE_EVAL: 30,
  NIX_FMT: 15,
  DEPRECATED_PATTERNS: 15,
} as const;

const TOTAL_POINTS = POINTS.FLAKE_CHECK + POINTS.FLAKE_EVAL + POINTS.NIX_FMT + POINTS.DEPRECATED_PATTERNS;

export class NixHealthGrader extends BaseGrader {
  constructor(dotfilesPath?: string) {
    super(DEFAULT_GRADER_CONFIGS['nix-health']!, dotfilesPath);
  }

  protected async execute(): Promise<GraderOutput> {
    const issues: GraderIssue[] = [];
    let deductions = 0;

    // 1. Flake check (40 pts) - Does the flake evaluate without errors?
    const flakeCheck = await runShell(`nix flake check "${this.dotfilesPath}" --no-build 2>&1`);
    if (!flakeCheck.ok || flakeCheck.data.exitCode !== 0) {
      deductions += POINTS.FLAKE_CHECK;
      issues.push({
        message: 'nix flake check failed',
        severity: 'error',
      });
    }

    // 2. Flake eval (30 pts) - Can we evaluate the darwin configuration?
    const hostname = await this.getHostname();
    const flakeEval = await runShell(
      `nix eval "${this.dotfilesPath}#darwinConfigurations.${hostname}.system" --json 2>&1`
    );
    if (!flakeEval.ok || flakeEval.data.exitCode !== 0) {
      deductions += POINTS.FLAKE_EVAL;
      issues.push({
        message: `flake eval failed for ${hostname}`,
        severity: 'error',
      });
    }

    // 3. Nix fmt (15 pts) - Is the code formatted correctly?
    const fmtCheck = await runShell(
      `alejandra --check "${this.dotfilesPath}" 2>&1 | head -20`
    );
    if (!fmtCheck.ok || fmtCheck.data.exitCode !== 0) {
      deductions += POINTS.NIX_FMT;
      const unformattedFiles = fmtCheck.ok
        ? fmtCheck.data.stdout
            .split('\n')
            .filter((line) => line.includes('Requires formatting'))
            .map((line) => line.replace('Requires formatting: ', '').replace(this.dotfilesPath, ''))
            .slice(0, 5)
        : [];
      issues.push({
        message: `${unformattedFiles.length > 0 ? unformattedFiles.length : 'some'} files need formatting`,
        severity: 'warning',
      });
    }

    // 4. Deprecated patterns (15 pts) - Avoid 'with lib;' anti-pattern
    const deprecatedCheck = await runShell(
      `grep -r "with lib;" "${this.dotfilesPath}"/*.nix "${this.dotfilesPath}"/modules/ 2>/dev/null | wc -l`
    );
    const deprecatedCount = deprecatedCheck.ok
      ? parseInt(deprecatedCheck.data.stdout.trim()) || 0
      : 0;

    if (deprecatedCount > 5) {
      deductions += POINTS.DEPRECATED_PATTERNS;
      issues.push({
        message: `${deprecatedCount} deprecated 'with lib;' patterns found`,
        severity: 'warning',
      });
    } else if (deprecatedCount > 0) {
      // Partial deduction for 1-5 patterns
      const partialDeduction = Math.ceil((deprecatedCount / 5) * POINTS.DEPRECATED_PATTERNS);
      deductions += partialDeduction;
      issues.push({
        message: `${deprecatedCount} deprecated 'with lib;' patterns found`,
        severity: 'info',
      });
    }

    // Calculate final score
    const score = Math.max(0, (TOTAL_POINTS - deductions) / TOTAL_POINTS);

    return {
      score,
      passed: score >= this.config.passingScore,
      issues,
      metrics: {
        flake_check_passed: flakeCheck.ok && flakeCheck.data.exitCode === 0 ? 1 : 0,
        flake_eval_passed: flakeEval.ok && flakeEval.data.exitCode === 0 ? 1 : 0,
        fmt_passed: fmtCheck.ok && fmtCheck.data.exitCode === 0 ? 1 : 0,
        deprecated_patterns: deprecatedCount,
      },
    };
  }

  private async getHostname(): Promise<string> {
    const result = await runShell('hostname -s');
    return result.ok ? result.data.stdout.trim() : 'unknown';
  }
}
