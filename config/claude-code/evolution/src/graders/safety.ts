/**
 * Safety Grader
 *
 * Checks for secrets, API keys, and dangerous file permissions.
 * Weight: 15% of overall score
 *
 * This is a CRITICAL grader - must score 100% to pass.
 */
import { readFileSync, statSync } from 'node:fs';
import { extname, join } from 'node:path';
import { BaseGrader, runShell } from './base';
import { DEFAULT_GRADER_CONFIGS, type GraderIssue, type GraderOutput } from './types';

// High-entropy patterns that indicate actual secrets
const SECRET_PATTERNS = [
  { name: 'OpenAI API Key', pattern: /sk-[a-zA-Z0-9]{20,}/ },
  { name: 'Anthropic API Key', pattern: /sk-ant-[a-zA-Z0-9-]{40,}/ },
  { name: 'GitHub PAT', pattern: /ghp_[a-zA-Z0-9]{36}/ },
  { name: 'GitHub OAuth', pattern: /gho_[a-zA-Z0-9]{36}/ },
  { name: 'AWS Access Key', pattern: /AKIA[0-9A-Z]{16}/ },
  { name: 'AWS Secret Key', pattern: /[a-zA-Z0-9/+=]{40}(?![a-zA-Z0-9/+=])/ },
  { name: 'Slack Token', pattern: /xox[baprs]-[0-9a-zA-Z-]{10,}/ },
  { name: 'Private Key', pattern: /-----BEGIN\s+(RSA|EC|DSA|OPENSSH)?\s*PRIVATE KEY-----/ },
  { name: 'Generic API Key', pattern: /api[_-]?key["']?\s*[:=]\s*["'][a-zA-Z0-9]{20,}["']/ },
];

// Files that should never be tracked
const FORBIDDEN_FILES = ['.env', '.env.local', 'credentials.json', 'secrets.yaml'];

// Extensions to scan for secrets
const SCANNABLE_EXTENSIONS = [
  '.nix',
  '.sh',
  '.bash',
  '.zsh',
  '.ts',
  '.tsx',
  '.js',
  '.jsx',
  '.json',
  '.yaml',
  '.yml',
  '.toml',
  '.md',
  '.txt',
];

export class SafetyGrader extends BaseGrader {
  constructor(dotfilesPath?: string) {
    super(DEFAULT_GRADER_CONFIGS['safety']!, dotfilesPath);
  }

  protected async execute(): Promise<GraderOutput> {
    const issues: GraderIssue[] = [];

    // 1. Check for secrets in tracked files
    const secretsResult = await this.scanForSecrets();
    issues.push(...secretsResult.issues);

    // 2. Check for forbidden files in git
    const forbiddenResult = await this.checkForbiddenFiles();
    issues.push(...forbiddenResult.issues);

    // 3. Check file permissions (sensitive files should not be world-readable)
    const permissionsResult = this.checkFilePermissions();
    issues.push(...permissionsResult.issues);

    // Safety grader is binary - any issue fails it
    const hasErrors = issues.some((issue) => issue.severity === 'error');
    const score = hasErrors ? 0 : 1.0;

    return {
      score,
      passed: !hasErrors,
      issues,
      metrics: {
        secrets_found: secretsResult.count,
        forbidden_files: forbiddenResult.count,
        permission_issues: permissionsResult.count,
      },
    };
  }

  private async scanForSecrets(): Promise<{
    count: number;
    issues: GraderIssue[];
  }> {
    const issues: GraderIssue[] = [];
    let count = 0;

    // Get list of tracked files
    const trackedResult = await runShell('git ls-files', this.dotfilesPath);
    if (!trackedResult.ok) {
      return { count: 0, issues: [] };
    }

    const trackedFiles = trackedResult.data.stdout.trim().split('\n').filter(Boolean);

    for (const relativePath of trackedFiles) {
      const ext = extname(relativePath).toLowerCase();

      // Skip non-scannable files
      if (!SCANNABLE_EXTENSIONS.includes(ext)) continue;

      // Skip grader files, examples, and encrypted files
      if (
        relativePath.includes('graders/') ||
        relativePath.includes('.example') ||
        relativePath.endsWith('.gpg')
      ) {
        continue;
      }

      const fullPath = join(this.dotfilesPath, relativePath);

      try {
        const content = readFileSync(fullPath, 'utf-8');

        for (const { name, pattern } of SECRET_PATTERNS) {
          if (pattern.test(content)) {
            count++;
            issues.push({
              file: relativePath,
              message: `potential ${name} found`,
              severity: 'error',
            });
            break; // Only report one secret per file
          }
        }
      } catch {
        // File might not exist or be unreadable - skip
      }
    }

    return { count, issues };
  }

  private async checkForbiddenFiles(): Promise<{
    count: number;
    issues: GraderIssue[];
  }> {
    const issues: GraderIssue[] = [];
    let count = 0;

    for (const forbidden of FORBIDDEN_FILES) {
      const result = await runShell(
        `git ls-files --error-unmatch "${forbidden}" 2>/dev/null`,
        this.dotfilesPath
      );

      if (result.ok && result.data.exitCode === 0) {
        count++;
        issues.push({
          file: forbidden,
          message: `forbidden file tracked: ${forbidden}`,
          severity: 'error',
        });
      }
    }

    return { count, issues };
  }

  private checkFilePermissions(): {
    count: number;
    issues: GraderIssue[];
  } {
    const issues: GraderIssue[] = [];
    let count = 0;

    // Check specific sensitive directories/files
    const sensitiveLocations = [
      { path: '.ssh', maxMode: 0o700 },
      { path: '.gnupg', maxMode: 0o700 },
      { path: '.config/gh', maxMode: 0o700 },
    ];

    const home = process.env['HOME'] ?? '';

    for (const { path, maxMode } of sensitiveLocations) {
      const fullPath = join(home, path);

      try {
        const stats = statSync(fullPath);
        const mode = stats.mode & 0o777;

        if (mode > maxMode) {
          count++;
          issues.push({
            file: path,
            message: `${path} has overly permissive permissions: ${mode.toString(8)} (should be ${maxMode.toString(8)} or stricter)`,
            severity: 'warning',
          });
        }
      } catch {
        // Directory doesn't exist - not an issue
      }
    }

    return { count, issues };
  }
}
