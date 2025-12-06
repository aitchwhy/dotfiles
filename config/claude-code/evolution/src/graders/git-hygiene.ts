/**
 * Git Hygiene Grader
 *
 * Checks conventional commits, secrets, and .gitignore coverage.
 * Weight: 20% of overall score
 */
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { BaseGrader, runShell } from './base';
import { type GraderOutput, type GraderIssue, DEFAULT_GRADER_CONFIGS } from './types';

const POINTS = {
  UNSTAGED_CHANGES: 30,
  CONVENTIONAL_COMMITS: 25,
  SECRETS: 35,
  GITIGNORE_COVERAGE: 10,
} as const;

const TOTAL_POINTS =
  POINTS.UNSTAGED_CHANGES +
  POINTS.CONVENTIONAL_COMMITS +
  POINTS.SECRETS +
  POINTS.GITIGNORE_COVERAGE;

// Conventional commit regex
const CONVENTIONAL_REGEX =
  /^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?:/;

// Required .gitignore patterns
const REQUIRED_GITIGNORE = ['.env', '.envrc', '*.gpg', '.dev.vars'];

// Dangerous patterns that indicate actual secrets (not just env var references)
const SECRET_PATTERNS = [
  /sk-[a-zA-Z0-9]{20,}/,                    // OpenAI keys
  /ghp_[a-zA-Z0-9]{36}/,                    // GitHub personal access tokens
  /gho_[a-zA-Z0-9]{36}/,                    // GitHub OAuth tokens
  /-----BEGIN.*PRIVATE KEY-----/,           // Private keys
  /AKIA[0-9A-Z]{16}/,                       // AWS access keys
  /xox[baprs]-[0-9a-zA-Z-]{10,}/,          // Slack tokens
];

export class GitHygieneGrader extends BaseGrader {
  constructor(dotfilesPath?: string) {
    super(DEFAULT_GRADER_CONFIGS['git-hygiene']!, dotfilesPath);
  }

  protected async execute(): Promise<GraderOutput> {
    const issues: GraderIssue[] = [];
    let deductions = 0;

    // 1. Unstaged changes (30 pts if > 10 files)
    const unstagedResult = await this.checkUnstagedChanges();
    if (unstagedResult.count > 10) {
      deductions += POINTS.UNSTAGED_CHANGES;
      issues.push({
        message: `${unstagedResult.count} unstaged changes`,
        severity: 'warning',
      });
    } else if (unstagedResult.count > 5) {
      // Partial deduction
      deductions += Math.ceil(POINTS.UNSTAGED_CHANGES * 0.5);
      issues.push({
        message: `${unstagedResult.count} unstaged changes`,
        severity: 'info',
      });
    }

    // 2. Conventional commits (25 pts)
    const commitsResult = await this.checkConventionalCommits();
    if (commitsResult.nonConventional > 3) {
      deductions += POINTS.CONVENTIONAL_COMMITS;
      issues.push({
        message: `${commitsResult.nonConventional} of last ${commitsResult.total} commits are non-conventional`,
        severity: 'warning',
      });
    } else if (commitsResult.nonConventional > 0) {
      // Partial deduction
      const partialDeduction = Math.ceil(
        (commitsResult.nonConventional / 3) * POINTS.CONVENTIONAL_COMMITS
      );
      deductions += partialDeduction;
      issues.push({
        message: `${commitsResult.nonConventional} of last ${commitsResult.total} commits are non-conventional`,
        severity: 'info',
      });
    }

    // 3. Secrets scan (35 pts - critical security issue)
    const secretsResult = await this.scanForSecrets();
    if (secretsResult.found) {
      deductions += POINTS.SECRETS;
      for (const secret of secretsResult.patterns) {
        issues.push({
          message: `potential secret pattern: ${secret}`,
          severity: 'error',
        });
      }
    }

    // 4. .gitignore coverage (10 pts)
    const gitignoreResult = this.checkGitignore();
    const missingCount = gitignoreResult.missing.length;
    if (missingCount > 0) {
      const deduction = Math.min(POINTS.GITIGNORE_COVERAGE, missingCount * 3);
      deductions += deduction;
      for (const pattern of gitignoreResult.missing) {
        issues.push({
          file: '.gitignore',
          message: `missing gitignore pattern: ${pattern}`,
          severity: 'warning',
        });
      }
    }

    // Calculate final score
    const score = Math.max(0, (TOTAL_POINTS - deductions) / TOTAL_POINTS);

    return {
      score,
      passed: score >= this.config.passingScore,
      issues,
      metrics: {
        unstaged_count: unstagedResult.count,
        non_conventional_commits: commitsResult.nonConventional,
        conventional_commits: commitsResult.conventional,
        secrets_found: secretsResult.found ? 1 : 0,
        gitignore_missing: missingCount,
      },
    };
  }

  private async checkUnstagedChanges(): Promise<{ count: number }> {
    const result = await runShell('git diff --name-only | wc -l', this.dotfilesPath);
    const count = result.ok ? parseInt(result.data.stdout.trim()) || 0 : 0;
    return { count };
  }

  private async checkConventionalCommits(): Promise<{
    total: number;
    conventional: number;
    nonConventional: number;
  }> {
    const result = await runShell(
      "git log --oneline -10 --format='%s'",
      this.dotfilesPath
    );

    if (!result.ok) {
      return { total: 0, conventional: 0, nonConventional: 0 };
    }

    const messages = result.data.stdout.trim().split('\n').filter(Boolean);
    let conventional = 0;
    let nonConventional = 0;

    for (const msg of messages) {
      // Skip merge commits
      if (msg.startsWith('Merge ')) {
        continue;
      }

      if (CONVENTIONAL_REGEX.test(msg)) {
        conventional++;
      } else {
        nonConventional++;
      }
    }

    return {
      total: messages.length,
      conventional,
      nonConventional,
    };
  }

  private async scanForSecrets(): Promise<{
    found: boolean;
    patterns: string[];
  }> {
    const foundPatterns: string[] = [];

    // Use git grep to search tracked files
    for (const pattern of SECRET_PATTERNS) {
      const result = await runShell(
        `git grep -E '${pattern.source}' -- ':!*.gpg' ':!*.example' ':!*graders*' ':!*.sh' 2>/dev/null | head -1`,
        this.dotfilesPath
      );

      if (result.ok && result.data.stdout.trim()) {
        foundPatterns.push(pattern.source.slice(0, 30) + '...');
      }
    }

    return {
      found: foundPatterns.length > 0,
      patterns: foundPatterns,
    };
  }

  private checkGitignore(): { missing: string[] } {
    const missing: string[] = [];
    const gitignorePath = join(this.dotfilesPath, '.gitignore');

    try {
      const content = readFileSync(gitignorePath, 'utf-8');
      for (const pattern of REQUIRED_GITIGNORE) {
        if (!content.includes(pattern)) {
          missing.push(pattern);
        }
      }
    } catch {
      // .gitignore doesn't exist
      missing.push(...REQUIRED_GITIGNORE);
    }

    return { missing };
  }
}
