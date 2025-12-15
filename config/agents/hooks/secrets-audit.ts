#!/usr/bin/env bun
/**
 * Secrets Audit Hook - SessionStart
 *
 * Scans Claude settings files for hardcoded credentials.
 * Blocks session start if secrets are detected.
 *
 * Patterns detected:
 * - API keys (API_KEY, SECRET_KEY, AUTH_TOKEN)
 * - Database URLs with credentials
 * - AWS/GCP/Azure credentials
 * - JWT secrets, encryption keys
 */

import { readdir, readFile, stat } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join, relative } from 'node:path';
import { block as hookBlock, logError as hookLogError } from './lib/hook-logging';

// =============================================================================
// Types
// =============================================================================

type SecretViolation = {
  readonly file: string;
  readonly line: number;
  readonly pattern: string;
  readonly match: string;
};

// =============================================================================
// Secret Patterns
// =============================================================================

const SECRET_PATTERNS: ReadonlyArray<{ name: string; regex: RegExp }> = [
  // API Keys
  { name: 'API_KEY', regex: /[A-Z_]*API[_-]?KEY["\s]*[:=]["\s]*["'][^"']{16,}["']/gi },
  { name: 'SECRET_KEY', regex: /[A-Z_]*SECRET[_-]?KEY["\s]*[:=]["\s]*["'][^"']{16,}["']/gi },
  { name: 'AUTH_TOKEN', regex: /[A-Z_]*AUTH[_-]?TOKEN["\s]*[:=]["\s]*["'][^"']{16,}["']/gi },
  { name: 'ACCESS_KEY', regex: /[A-Z_]*ACCESS[_-]?KEY["\s]*[:=]["\s]*["'][^"']{16,}["']/gi },

  // Database URLs with credentials
  {
    name: 'DATABASE_URL',
    regex: /DATABASE[_-]?URL["\s]*[:=]["\s]*["'](?:postgres|mysql|mongodb):\/\/[^:]+:[^@]+@[^"']+["']/gi,
  },

  // AWS
  { name: 'AWS_SECRET', regex: /AWS[_-]?SECRET[_-]?ACCESS[_-]?KEY["\s]*[:=]["\s]*["'][A-Za-z0-9+/=]{32,}["']/gi },

  // Specific services (from ember-platform incident)
  { name: 'HUME_KEY', regex: /HUME[_-]?(?:API|SECRET)[_-]?KEY["\s]*[:=]["\s]*["'][^"']{20,}["']/gi },
  { name: 'TWILIO_TOKEN', regex: /TWILIO[_-]?(?:AUTH[_-]?TOKEN|ACCOUNT[_-]?SID)["\s]*[:=]["\s]*["'][^"']{20,}["']/gi },
  { name: 'BETTER_AUTH_SECRET', regex: /BETTER[_-]?AUTH[_-]?SECRET["\s]*[:=]["\s]*["'][^"']{20,}["']/gi },
  { name: 'R2_SECRET', regex: /R2[_-]?(?:SECRET[_-]?)?ACCESS[_-]?KEY["\s]*[:=]["\s]*["'][^"']{32,}["']/gi },

  // Generic patterns
  { name: 'PRIVATE_KEY', regex: /PRIVATE[_-]?KEY["\s]*[:=]["\s]*["'][^"']{32,}["']/gi },
  { name: 'JWT_SECRET', regex: /JWT[_-]?SECRET["\s]*[:=]["\s]*["'][^"']{16,}["']/gi },
  { name: 'ENCRYPTION_KEY', regex: /ENCRYPTION[_-]?KEY["\s]*[:=]["\s]*["'][^"']{16,}["']/gi },
];

// =============================================================================
// File Discovery
// =============================================================================

async function findClaudeSettingsFiles(): Promise<string[]> {
  const files: string[] = [];
  const home = homedir();

  // Search patterns
  const searchDirs = [
    join(home, '.claude'),
    join(home, 'src'),
    join(home, 'dotfiles'),
  ];

  for (const baseDir of searchDirs) {
    try {
      await walkForClaudeSettings(baseDir, files, 0);
    } catch {
      // Directory may not exist
    }
  }

  return files;
}

async function walkForClaudeSettings(dir: string, files: string[], depth: number): Promise<void> {
  if (depth > 5) return; // Limit recursion

  try {
    const entries = await readdir(dir, { withFileTypes: true });

    for (const entry of entries) {
      // Skip hidden dirs except .claude
      if (entry.name.startsWith('.') && entry.name !== '.claude') continue;
      // Skip node_modules, result, etc.
      if (['node_modules', 'result', '.git', 'vendor'].includes(entry.name)) continue;

      const fullPath = join(dir, entry.name);

      if (entry.isDirectory()) {
        // Only recurse into .claude directories or known project dirs
        if (entry.name === '.claude' || depth < 3) {
          await walkForClaudeSettings(fullPath, files, depth + 1);
        }
      } else if (entry.isFile()) {
        // Match Claude settings files
        if (
          entry.name === 'settings.json' ||
          entry.name === 'settings.local.json' ||
          entry.name.endsWith('.claude.json')
        ) {
          files.push(fullPath);
        }
      }
    }
  } catch {
    // Ignore permission errors
  }
}

// =============================================================================
// Scanning
// =============================================================================

async function scanFile(filePath: string): Promise<SecretViolation[]> {
  const violations: SecretViolation[] = [];

  try {
    const content = await readFile(filePath, 'utf-8');
    const lines = content.split('\n');

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const lineNum = i + 1;

      for (const pattern of SECRET_PATTERNS) {
        // Reset regex state
        pattern.regex.lastIndex = 0;

        let match;
        while ((match = pattern.regex.exec(line)) !== null) {
          // Mask the actual secret value
          const maskedMatch = match[0].replace(/["'][^"']{8,}["']/g, '"***REDACTED***"');

          violations.push({
            file: filePath,
            line: lineNum,
            pattern: pattern.name,
            match: maskedMatch,
          });
        }
      }
    }
  } catch {
    // Ignore read errors
  }

  return violations;
}

// =============================================================================
// Main
// =============================================================================

async function main(): Promise<void> {
  const settingsFiles = await findClaudeSettingsFiles();

  if (settingsFiles.length === 0) {
    process.exit(0); // No files to check
  }

  const allViolations: SecretViolation[] = [];

  for (const file of settingsFiles) {
    const violations = await scanFile(file);
    allViolations.push(...violations);
  }

  if (allViolations.length > 0) {
    const home = homedir();
    const message = [
      '🔐 SECRETS DETECTED IN CLAUDE SETTINGS',
      '',
      `Found ${allViolations.length} hardcoded credential(s):`,
      '',
      ...allViolations.map(
        (v) => `  ${relative(home, v.file)}:${v.line} [${v.pattern}]`
      ),
      '',
      'Action required:',
      '  1. Remove secrets from settings files',
      '  2. Use environment variables or sops-nix instead',
      '  3. Rotate any exposed credentials immediately',
      '',
      'Blocking session start until secrets are removed.',
    ].join('\n');

    hookBlock(message);
    process.exit(2);
  }

  // All clear
  process.exit(0);
}

main().catch((error) => {
  hookLogError(`Secrets audit failed: ${error}`);
  process.exit(1);
});
