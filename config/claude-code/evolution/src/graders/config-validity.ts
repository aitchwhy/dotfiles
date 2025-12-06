/**
 * Config Validity Grader
 *
 * Checks JSON/YAML parsing and critical symlinks.
 * Weight: 25% of overall score
 *
 * NOTE: Handles JSONC (JSON with Comments) for VSCode/Cursor config files.
 */
import { existsSync, lstatSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { BaseGrader, runShell } from './base';
import { DEFAULT_GRADER_CONFIGS, type GraderIssue, type GraderOutput } from './types';

const POINTS = {
  JSON_FILE: 5,
  YAML_FILE: 5,
  CRITICAL_SYMLINK: 10,
} as const;

// Directories that may contain JSONC (JSON with Comments)
const JSONC_DIRECTORIES = ['cursor', 'vscode', 'code'];

// Critical symlinks that must exist and be valid
const CRITICAL_SYMLINKS = [
  { path: '.config/nvim', name: 'neovim config' },
  { path: '.zshrc', name: 'zsh config' },
  { path: '.config/starship.toml', name: 'starship prompt' },
  { path: '.config/ghostty', name: 'ghostty terminal' },
];

export class ConfigValidityGrader extends BaseGrader {
  constructor(dotfilesPath?: string) {
    super(DEFAULT_GRADER_CONFIGS['config-validity']!, dotfilesPath);
  }

  protected async execute(): Promise<GraderOutput> {
    const issues: GraderIssue[] = [];
    let totalPoints = 0;
    let earnedPoints = 0;

    // 1. JSON validation
    const jsonResult = await this.validateJsonFiles();
    totalPoints += jsonResult.total;
    earnedPoints += jsonResult.earned;
    issues.push(...jsonResult.issues);

    // 2. YAML validation
    const yamlResult = await this.validateYamlFiles();
    totalPoints += yamlResult.total;
    earnedPoints += yamlResult.earned;
    issues.push(...yamlResult.issues);

    // 3. Critical symlinks validation
    const symlinkResult = this.validateSymlinks();
    totalPoints += symlinkResult.total;
    earnedPoints += symlinkResult.earned;
    issues.push(...symlinkResult.issues);

    // Calculate final score
    const score = totalPoints > 0 ? earnedPoints / totalPoints : 1.0;

    return {
      score,
      passed: score >= this.config.passingScore,
      issues,
      metrics: {
        json_files_checked: jsonResult.fileCount,
        json_files_valid: jsonResult.validCount,
        yaml_files_checked: yamlResult.fileCount,
        yaml_files_valid: yamlResult.validCount,
        symlinks_valid: symlinkResult.validCount,
        symlinks_total: CRITICAL_SYMLINKS.length,
      },
    };
  }

  private async validateJsonFiles(): Promise<{
    total: number;
    earned: number;
    issues: GraderIssue[];
    fileCount: number;
    validCount: number;
  }> {
    const issues: GraderIssue[] = [];
    const configDir = join(this.dotfilesPath, 'config');

    // Find all JSON files
    const findResult = await runShell(`fd -e json . "${configDir}" 2>/dev/null`);
    if (!findResult.ok) {
      return { total: 0, earned: 0, issues: [], fileCount: 0, validCount: 0 };
    }

    const jsonFiles = findResult.data.stdout.trim().split('\n').filter(Boolean);
    let validCount = 0;

    for (const file of jsonFiles) {
      const isJsonc = JSONC_DIRECTORIES.some((dir) => file.includes(`/${dir}/`));

      try {
        const content = readFileSync(file, 'utf-8');

        if (isJsonc) {
          // Strip comments for JSONC files
          const stripped = this.stripJsonComments(content);
          JSON.parse(stripped);
        } else {
          JSON.parse(content);
        }
        validCount++;
      } catch {
        const relativePath = file.replace(this.dotfilesPath, '');
        issues.push({
          file: relativePath,
          message: `invalid JSON${isJsonc ? 'C' : ''}: ${relativePath.split('/').pop()}`,
          severity: 'error',
        });
      }
    }

    const total = jsonFiles.length * POINTS.JSON_FILE;
    const earned = validCount * POINTS.JSON_FILE;

    return { total, earned, issues, fileCount: jsonFiles.length, validCount };
  }

  private async validateYamlFiles(): Promise<{
    total: number;
    earned: number;
    issues: GraderIssue[];
    fileCount: number;
    validCount: number;
  }> {
    const issues: GraderIssue[] = [];
    const configDir = join(this.dotfilesPath, 'config');

    // Find all YAML files
    const findResult = await runShell(`fd -e yaml -e yml . "${configDir}" 2>/dev/null`);
    if (!findResult.ok) {
      return { total: 0, earned: 0, issues: [], fileCount: 0, validCount: 0 };
    }

    const yamlFiles = findResult.data.stdout.trim().split('\n').filter(Boolean);
    let validCount = 0;

    for (const file of yamlFiles) {
      const checkResult = await runShell(`yq '.' "${file}" 2>&1`);
      if (checkResult.ok && checkResult.data.exitCode === 0) {
        validCount++;
      } else {
        const relativePath = file.replace(this.dotfilesPath, '');
        issues.push({
          file: relativePath,
          message: `invalid YAML: ${relativePath.split('/').pop()}`,
          severity: 'error',
        });
      }
    }

    const total = yamlFiles.length * POINTS.YAML_FILE;
    const earned = validCount * POINTS.YAML_FILE;

    return { total, earned, issues, fileCount: yamlFiles.length, validCount };
  }

  private validateSymlinks(): {
    total: number;
    earned: number;
    issues: GraderIssue[];
    validCount: number;
  } {
    const issues: GraderIssue[] = [];
    const home = process.env.HOME ?? '';
    let validCount = 0;

    for (const link of CRITICAL_SYMLINKS) {
      const fullPath = join(home, link.path);

      try {
        const stats = lstatSync(fullPath);
        if (stats.isSymbolicLink() && existsSync(fullPath)) {
          validCount++;
        } else if (!stats.isSymbolicLink()) {
          // Exists but not a symlink - might be ok for some configs
          validCount++;
        } else {
          issues.push({
            file: link.path,
            message: `broken symlink: ${link.name}`,
            severity: 'error',
          });
        }
      } catch {
        issues.push({
          file: link.path,
          message: `missing: ${link.name}`,
          severity: 'warning',
        });
      }
    }

    const total = CRITICAL_SYMLINKS.length * POINTS.CRITICAL_SYMLINK;
    const earned = validCount * POINTS.CRITICAL_SYMLINK;

    return { total, earned, issues, validCount };
  }

  /**
   * Strip single-line and multi-line comments from JSONC
   */
  private stripJsonComments(content: string): string {
    let result = '';
    let inString = false;
    let inSingleLineComment = false;
    let inMultiLineComment = false;

    for (let i = 0; i < content.length; i++) {
      const char = content[i]!;
      const nextChar = content[i + 1];

      if (inSingleLineComment) {
        if (char === '\n') {
          inSingleLineComment = false;
          result += char;
        }
        continue;
      }

      if (inMultiLineComment) {
        if (char === '*' && nextChar === '/') {
          inMultiLineComment = false;
          i++; // Skip the /
        }
        continue;
      }

      if (inString) {
        result += char;
        if (char === '"' && content[i - 1] !== '\\') {
          inString = false;
        }
        continue;
      }

      // Not in any special state
      if (char === '"') {
        inString = true;
        result += char;
      } else if (char === '/' && nextChar === '/') {
        inSingleLineComment = true;
        i++; // Skip the second /
      } else if (char === '/' && nextChar === '*') {
        inMultiLineComment = true;
        i++; // Skip the *
      } else {
        result += char;
      }
    }

    return result;
  }
}
