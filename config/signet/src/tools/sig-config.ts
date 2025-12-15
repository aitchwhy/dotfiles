/**
 * sig-config MCP Tool
 *
 * Configuration centralization verification for Nix files.
 * Detects hardcoded ports, split-brain config, and hardcoded URLs.
 *
 * Guards:
 * - 28: No hardcoded ports outside lib/config/
 * - 29: No split-brain config (same value in 2+ files)
 * - 30: No hardcoded localhost URLs outside lib/config/
 */

import { readFile, readdir, stat } from 'node:fs/promises';
import { join, relative } from 'node:path';

// =============================================================================
// Types
// =============================================================================

type ConfigViolation = {
  readonly guard: 28 | 29 | 30;
  readonly file: string;
  readonly line: number;
  readonly match: string;
  readonly message: string;
  readonly severity: 'error' | 'warning';
};

type ConfigCheckResult = {
  readonly violations: readonly ConfigViolation[];
  readonly passed: boolean;
  readonly errors: number;
  readonly warnings: number;
  readonly filesChecked: number;
};

// =============================================================================
// File Discovery
// =============================================================================

async function findNixFiles(basePath: string): Promise<string[]> {
  const nixFiles: string[] = [];

  async function walkDir(dir: string): Promise<void> {
    try {
      const entries = await readdir(dir, { withFileTypes: true });

      for (const entry of entries) {
        const fullPath = join(dir, entry.name);

        // Skip hidden directories and common non-source dirs
        if (entry.name.startsWith('.') || entry.name === 'node_modules' || entry.name === 'result') {
          continue;
        }

        if (entry.isDirectory()) {
          await walkDir(fullPath);
        } else if (entry.isFile() && entry.name.endsWith('.nix')) {
          nixFiles.push(fullPath);
        }
      }
    } catch {
      // Ignore permission errors
    }
  }

  await walkDir(basePath);
  return nixFiles;
}

// =============================================================================
// Checks
// =============================================================================

function isAllowedPath(filePath: string): boolean {
  // Files in lib/config/ are the SSOT - they can have hardcoded values
  return filePath.includes('lib/config/') || filePath.includes('lib/ports.nix');
}

async function checkFile(filePath: string, basePath: string): Promise<ConfigViolation[]> {
  const violations: ConfigViolation[] = [];

  if (isAllowedPath(filePath)) {
    return violations;
  }

  try {
    const content = await readFile(filePath, 'utf-8');
    const lines = content.split('\n');
    const relPath = relative(basePath, filePath);

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const lineNum = i + 1;

      // Guard 28: Hardcoded ports (4-5 digit numbers in port context)
      // Match: port = 3000; or ports = [ 22 ]; but not ports.infrastructure.ssh
      const portPattern = /(?<!ports\.[\w.]*)\b(port|ports)\s*=\s*\[?\s*(\d{2,5})\b/gi;
      let portMatch;
      while ((portMatch = portPattern.exec(line)) !== null) {
        const portNum = parseInt(portMatch[2], 10);
        // Filter to likely port numbers (>= 22 and <= 65535)
        if (portNum >= 22 && portNum <= 65535) {
          violations.push({
            guard: 28,
            file: relPath,
            line: lineNum,
            match: portMatch[0],
            message: `Hardcoded port ${portNum}. Use cfg.ports.* from lib/config/`,
            severity: 'error',
          });
        }
      }

      // Guard 30: Hardcoded localhost URLs
      const localhostPattern = /(?:localhost|127\.0\.0\.1):\d{2,5}/g;
      let urlMatch;
      while ((urlMatch = localhostPattern.exec(line)) !== null) {
        violations.push({
          guard: 30,
          file: relPath,
          line: lineNum,
          match: urlMatch[0],
          message: `Hardcoded localhost URL. Use cfg.services.*.url from lib/config/`,
          severity: 'error',
        });
      }
    }
  } catch {
    // Ignore read errors
  }

  return violations;
}

async function checkSplitBrain(
  files: string[],
  basePath: string
): Promise<ConfigViolation[]> {
  const violations: ConfigViolation[] = [];
  const portOccurrences = new Map<number, Array<{ file: string; line: number }>>();

  for (const filePath of files) {
    if (isAllowedPath(filePath)) continue;

    try {
      const content = await readFile(filePath, 'utf-8');
      const lines = content.split('\n');
      const relPath = relative(basePath, filePath);

      for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        // Look for numeric assignments that could be ports
        const numPattern = /=\s*(\d{4,5})\s*;/g;
        let match;
        while ((match = numPattern.exec(line)) !== null) {
          const num = parseInt(match[1], 10);
          // Filter to likely port range
          if (num >= 1024 && num <= 65535) {
            const existing = portOccurrences.get(num) ?? [];
            existing.push({ file: relPath, line: i + 1 });
            portOccurrences.set(num, existing);
          }
        }
      }
    } catch {
      // Ignore read errors
    }
  }

  // Find values appearing in multiple files
  for (const [port, locations] of portOccurrences) {
    const uniqueFiles = new Set(locations.map((l) => l.file));
    if (uniqueFiles.size > 1) {
      // Report one violation per port, listing all files
      const fileList = Array.from(uniqueFiles).join(', ');
      violations.push({
        guard: 29,
        file: Array.from(uniqueFiles)[0],
        line: locations[0].line,
        match: String(port),
        message: `Split-brain: port ${port} defined in ${uniqueFiles.size} files: ${fileList}`,
        severity: 'warning',
      });
    }
  }

  return violations;
}

// =============================================================================
// Main Check Function
// =============================================================================

async function runConfigCheck(basePath: string): Promise<ConfigCheckResult> {
  const nixFiles = await findNixFiles(basePath);
  const allViolations: ConfigViolation[] = [];

  // Run single-file checks in parallel
  const fileCheckResults = await Promise.all(
    nixFiles.map((f) => checkFile(f, basePath))
  );
  for (const violations of fileCheckResults) {
    allViolations.push(...violations);
  }

  // Run cross-file split-brain check
  const splitBrainViolations = await checkSplitBrain(nixFiles, basePath);
  allViolations.push(...splitBrainViolations);

  const errors = allViolations.filter((v) => v.severity === 'error').length;
  const warnings = allViolations.filter((v) => v.severity === 'warning').length;

  return {
    violations: allViolations,
    passed: errors === 0,
    errors,
    warnings,
    filesChecked: nixFiles.length,
  };
}

// =============================================================================
// Formatting
// =============================================================================

function formatConfigResult(result: ConfigCheckResult): string {
  const lines: string[] = [
    '━'.repeat(50),
    '  SIGNET CONFIG CENTRALIZATION CHECK',
    '━'.repeat(50),
    '',
    `Status: ${result.passed ? '✅ PASS' : '❌ VIOLATIONS FOUND'}`,
    `Files checked: ${result.filesChecked}`,
    `Errors: ${result.errors}, Warnings: ${result.warnings}`,
    '',
  ];

  if (result.violations.length > 0) {
    // Group by guard
    const byGuard = new Map<number, ConfigViolation[]>();
    for (const v of result.violations) {
      const existing = byGuard.get(v.guard) ?? [];
      existing.push(v);
      byGuard.set(v.guard, existing);
    }

    for (const [guard, violations] of byGuard) {
      const guardName =
        guard === 28 ? 'No Hardcoded Ports' : guard === 29 ? 'No Split-Brain' : 'Config Reference';
      lines.push(`Guard ${guard}: ${guardName}`);
      lines.push('─'.repeat(40));

      for (const v of violations) {
        const icon = v.severity === 'error' ? '❌' : '⚠️';
        lines.push(`${icon} ${v.file}:${v.line}`);
        lines.push(`   ${v.message}`);
        lines.push(`   Match: ${v.match}`);
        lines.push('');
      }
    }
  } else {
    lines.push('No configuration violations found.');
    lines.push('All Nix files properly reference lib/config/');
  }

  return lines.join('\n');
}

// =============================================================================
// Tool Definition
// =============================================================================

export const sigConfigTool = {
  name: 'sig-config',
  description: `Verify configuration centralization (Nix files).

Guards checked:
- Guard 28: No hardcoded ports outside lib/config/
- Guard 29: No split-brain config (same value in 2+ files)
- Guard 30: No hardcoded localhost URLs outside lib/config/

Use this to ensure all ports and service URLs reference lib/config/ports.nix.

Exit codes:
- 0: All config centralized
- 1: Warnings (advisory)
- 2: Violations (blocking)`,

  params: {
    path: {
      type: 'string',
      description: 'Path to verify (default: current directory)',
    },
  },

  handler: async (args: {
    path?: string;
  }): Promise<{ content: Array<{ type: 'text'; text: string }> }> => {
    const targetPath = args.path ?? process.cwd();

    // Verify path exists
    try {
      await stat(targetPath);
    } catch {
      return {
        content: [
          {
            type: 'text' as const,
            text: `Error: Path does not exist: ${targetPath}`,
          },
        ],
      };
    }

    const result = await runConfigCheck(targetPath);
    const summary = formatConfigResult(result);
    const exitCode = result.passed ? (result.warnings > 0 ? 1 : 0) : 2;

    return {
      content: [
        {
          type: 'text' as const,
          text: `${summary}\n\nExit code: ${exitCode}${exitCode === 2 ? ' (BLOCKING)' : ''}`,
        },
      ],
    };
  },
};
