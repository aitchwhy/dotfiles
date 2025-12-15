/**
 * Tier 4: Multi-Agent Review
 *
 * Provides automated code review with multiple perspectives:
 * - Critic: Finds edge cases, security issues, performance problems
 * - Architect: Checks architectural consistency and patterns
 * - Pragmatist: Balances complexity vs. simplicity
 *
 * Implementation Modes:
 * - Local: Heuristic-based review (always available)
 * - Claude API: Enhanced review when ANTHROPIC_API_KEY is set (future)
 *
 * The local mode provides actionable feedback without external dependencies.
 */
import { readdir, readFile } from 'node:fs/promises';
import { extname, join } from 'node:path';
import { Effect } from 'effect';
import type { TierResult, VerificationOptions } from '../index.js';

// =============================================================================
// Types
// =============================================================================

type ReviewFinding = {
  readonly category: 'security' | 'performance' | 'complexity' | 'architecture' | 'maintainability';
  readonly severity: 'error' | 'warning' | 'suggestion';
  readonly file: string;
  readonly line?: number;
  readonly message: string;
  readonly recommendation: string;
};

type ReviewConfig = {
  readonly maxFilesPerReview: number;
  readonly maxFileSize: number;
  readonly enabledReviewers: readonly string[];
};

// =============================================================================
// Configuration
// =============================================================================

const DEFAULT_CONFIG: ReviewConfig = {
  maxFilesPerReview: 30,
  maxFileSize: 50_000, // 50KB
  enabledReviewers: ['critic', 'architect', 'pragmatist'],
};

/**
 * Check if Claude API review is available
 */
const isClaudeApiAvailable = (): boolean => {
  return (
    typeof process.env['ANTHROPIC_API_KEY'] === 'string' &&
    process.env['ANTHROPIC_API_KEY'].length > 0
  );
};

// =============================================================================
// Local Review Patterns (Heuristic-based)
// =============================================================================

/**
 * Critic Agent: Security and edge case detection
 */
const criticReview = (content: string, filePath: string): readonly ReviewFinding[] => {
  const findings: ReviewFinding[] = [];
  const lines = content.split('\n');

  // Security patterns
  const securityPatterns = [
    {
      pattern: /eval\s*\(/g,
      message: 'Use of eval() is a security risk',
      recommendation: 'Replace with safer alternatives like JSON.parse() or Function()',
    },
    {
      pattern: /innerHTML\s*=/g,
      message: 'Direct innerHTML assignment can lead to XSS',
      recommendation: 'Use textContent or sanitize HTML with DOMPurify',
    },
    {
      pattern: /dangerouslySetInnerHTML/g,
      message: 'React dangerouslySetInnerHTML bypasses XSS protection',
      recommendation: 'Ensure content is sanitized or use safe alternatives',
    },
    {
      pattern: /new\s+Function\s*\(/g,
      message: 'Dynamic Function creation can be exploited',
      recommendation: 'Use static function definitions or validated templates',
    },
    {
      pattern: /process\.env\[/g,
      message: 'Dynamic environment variable access may leak secrets',
      recommendation: 'Use explicit env var names with validation',
    },
    {
      pattern: /password|secret|token|api_key|apikey/gi,
      message: 'Potential hardcoded secret or sensitive field exposure',
      recommendation: 'Ensure secrets are from environment variables, not hardcoded',
    },
  ];

  for (const { pattern, message, recommendation } of securityPatterns) {
    for (let i = 0; i < lines.length; i++) {
      if (pattern.test(lines[i])) {
        findings.push({
          category: 'security',
          severity: 'warning',
          file: filePath,
          line: i + 1,
          message,
          recommendation,
        });
      }
      // Reset lastIndex for global patterns
      pattern.lastIndex = 0;
    }
  }

  // Edge case patterns
  const edgeCasePatterns = [
    {
      pattern: /\.length\s*[><=]+\s*0(?!\s*\))/g,
      message: 'Array length check may miss edge cases',
      recommendation: 'Consider using Array.isArray() for type safety',
    },
    {
      pattern: /===?\s*undefined|===?\s*null(?!\s*\|\||\s*\?\?)/g,
      message: 'Isolated null/undefined check may be incomplete',
      recommendation: 'Consider ?? or || with default values for full coverage',
    },
    {
      pattern: /parseInt\([^,)]+\)(?!\s*,\s*10)/g,
      message: 'parseInt without radix can cause unexpected behavior',
      recommendation: 'Always specify radix: parseInt(value, 10)',
    },
  ];

  for (const { pattern, message, recommendation } of edgeCasePatterns) {
    for (let i = 0; i < lines.length; i++) {
      if (pattern.test(lines[i])) {
        findings.push({
          category: 'maintainability',
          severity: 'suggestion',
          file: filePath,
          line: i + 1,
          message,
          recommendation,
        });
      }
      pattern.lastIndex = 0;
    }
  }

  return findings;
};

/**
 * Architect Agent: Architectural consistency checks
 */
const architectReview = (content: string, filePath: string): readonly ReviewFinding[] => {
  const findings: ReviewFinding[] = [];
  const lines = content.split('\n');

  // Import patterns
  const importIssues = [
    {
      pattern: /import\s+.*\s+from\s+['"]\.\.\/\.\.\/\.\.\/\.\.\//g,
      message: 'Deep relative imports indicate architectural coupling',
      recommendation: 'Use path aliases (@/...) or restructure module boundaries',
    },
    {
      pattern: /require\s*\(/g,
      message: 'CommonJS require() in ESM project',
      recommendation: 'Use ES6 import syntax for consistency',
    },
  ];

  for (const { pattern, message, recommendation } of importIssues) {
    for (let i = 0; i < lines.length; i++) {
      if (pattern.test(lines[i])) {
        findings.push({
          category: 'architecture',
          severity: 'warning',
          file: filePath,
          line: i + 1,
          message,
          recommendation,
        });
      }
      pattern.lastIndex = 0;
    }
  }

  // File-level patterns
  const fileContent = content;

  // Check for god objects (too many methods/exports)
  const exportCount = (fileContent.match(/^export\s+(const|function|class|type|interface)/gm) || [])
    .length;
  if (exportCount > 15) {
    findings.push({
      category: 'architecture',
      severity: 'warning',
      file: filePath,
      message: `File exports ${exportCount} items - may be doing too much`,
      recommendation: 'Consider splitting into focused modules with single responsibility',
    });
  }

  // Check for mixed concerns (UI + business logic)
  const hasReactImport = /import.*from\s+['"]react['"]/g.test(fileContent);
  const hasEffectImport = /import.*from\s+['"]effect['"]/g.test(fileContent);
  const hasDbPattern = /drizzle|sql|query|db\./gi.test(fileContent);

  if (hasReactImport && hasDbPattern) {
    findings.push({
      category: 'architecture',
      severity: 'error',
      file: filePath,
      message: 'React component contains database operations',
      recommendation: 'Move data access to services layer, use hooks for data fetching',
    });
  }

  if (hasReactImport && hasEffectImport) {
    // This is actually fine for Effect-React integration
    // Only flag if there are Effect.gen with DB operations
    if (/Effect\.gen.*db\./gs.test(fileContent)) {
      findings.push({
        category: 'architecture',
        severity: 'warning',
        file: filePath,
        message: 'Effect service logic in React component',
        recommendation: 'Extract Effect pipelines to service layer, use useEffect for integration',
      });
    }
  }

  return findings;
};

/**
 * Pragmatist Agent: Complexity and simplicity balance
 */
const pragmatistReview = (content: string, filePath: string): readonly ReviewFinding[] => {
  const findings: ReviewFinding[] = [];
  const lines = content.split('\n');

  // Detect overly complex functions
  let braceDepth = 0;
  let maxDepth = 0;
  let functionStart = 0;
  let inFunction = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // Track function boundaries
    if (/^(export\s+)?(async\s+)?function|=>\s*\{|=\s*(async\s+)?function/.test(line)) {
      inFunction = true;
      functionStart = i;
      braceDepth = 0;
      maxDepth = 0;
    }

    // Count nesting
    const opens = (line.match(/\{/g) || []).length;
    const closes = (line.match(/\}/g) || []).length;
    braceDepth += opens - closes;

    if (braceDepth > maxDepth) {
      maxDepth = braceDepth;
    }

    // End of function
    if (inFunction && braceDepth <= 0) {
      const functionLength = i - functionStart;

      if (maxDepth > 5) {
        findings.push({
          category: 'complexity',
          severity: 'warning',
          file: filePath,
          line: functionStart + 1,
          message: `Function has nesting depth of ${maxDepth} (max recommended: 4)`,
          recommendation: 'Extract nested logic into helper functions or use early returns',
        });
      }

      if (functionLength > 50) {
        findings.push({
          category: 'complexity',
          severity: 'suggestion',
          file: filePath,
          line: functionStart + 1,
          message: `Function is ${functionLength} lines (recommended: <30)`,
          recommendation: 'Break down into smaller, focused functions',
        });
      }

      inFunction = false;
      maxDepth = 0;
    }
  }

  // Detect over-abstraction
  const abstractionPatterns = [
    {
      pattern: /Factory\w*Factory|Builder\w*Builder|Manager\w*Manager/g,
      message: 'Nested design pattern names suggest over-abstraction',
      recommendation: 'Simplify - a single Factory or Builder is usually sufficient',
    },
    {
      pattern: /Abstract\w+Abstract|Base\w+Base/g,
      message: 'Multiple abstraction layers may add unnecessary complexity',
      recommendation: 'Prefer composition over deep inheritance hierarchies',
    },
  ];

  for (const { pattern, message, recommendation } of abstractionPatterns) {
    if (pattern.test(content)) {
      findings.push({
        category: 'complexity',
        severity: 'suggestion',
        file: filePath,
        message,
        recommendation,
      });
    }
    pattern.lastIndex = 0;
  }

  // Check for unnecessary type complexity
  const complexTypePatterns = [
    {
      pattern: /type\s+\w+\s*=\s*[^;]+&[^;]+&[^;]+&[^;]+&/g,
      message: 'Type intersection with 4+ types may be overly complex',
      recommendation: 'Consider defining a single cohesive interface',
    },
    {
      pattern: /\?\s*:\s*[^;]+\|\s*[^;]+\|\s*[^;]+\|\s*[^;]+\|\s*[^;]+\|/g,
      message: 'Union type with 5+ members may indicate design issue',
      recommendation: 'Use discriminated union with explicit tags',
    },
  ];

  for (const { pattern, message, recommendation } of complexTypePatterns) {
    if (pattern.test(content)) {
      findings.push({
        category: 'complexity',
        severity: 'suggestion',
        file: filePath,
        message,
        recommendation,
      });
    }
    pattern.lastIndex = 0;
  }

  return findings;
};

// =============================================================================
// Performance Review
// =============================================================================

/**
 * Performance-focused review patterns
 */
const performanceReview = (content: string, filePath: string): readonly ReviewFinding[] => {
  const findings: ReviewFinding[] = [];
  const lines = content.split('\n');

  const perfPatterns = [
    {
      pattern: /\.map\([^)]+\)\.filter\(|\.filter\([^)]+\)\.map\(/g,
      message: 'Chained map/filter iterates array twice',
      recommendation: 'Use reduce() or flatMap() for single-pass processing',
    },
    {
      pattern: /JSON\.parse\(JSON\.stringify\(/g,
      message: 'JSON deep clone is slow for large objects',
      recommendation: 'Use structuredClone() or a library like immer',
    },
    {
      pattern: /new RegExp\([^)]+\)/g,
      message: 'RegExp in hot path creates object each call',
      recommendation: 'Move RegExp to module-level constant',
    },
    {
      pattern: /await.*in\s+(for|while)/g,
      message: 'Sequential await in loop may cause performance issues',
      recommendation: 'Use Promise.all() for parallel execution when possible',
    },
    {
      pattern: /useEffect\(\s*\(\)\s*=>\s*\{[^}]*fetch/g,
      message: 'Fetch in useEffect without dependencies',
      recommendation: 'Use TanStack Query or add proper dependency array',
    },
  ];

  for (const { pattern, message, recommendation } of perfPatterns) {
    for (let i = 0; i < lines.length; i++) {
      if (pattern.test(lines[i])) {
        findings.push({
          category: 'performance',
          severity: 'suggestion',
          file: filePath,
          line: i + 1,
          message,
          recommendation,
        });
      }
      pattern.lastIndex = 0;
    }
  }

  return findings;
};

// =============================================================================
// File Discovery
// =============================================================================

/**
 * Find files to review
 */
const findFilesToReview = async (
  dir: string,
  config: ReviewConfig
): Promise<{ files: string[]; skipped: number }> => {
  const files: string[] = [];
  let skipped = 0;

  const walk = async (currentDir: string): Promise<void> => {
    try {
      const entries = await readdir(currentDir, { withFileTypes: true });

      for (const entry of entries) {
        const name = entry.name;
        const fullPath = join(currentDir, name);

        // Skip patterns
        if (
          name.startsWith('.') ||
          name === 'node_modules' ||
          name === 'dist' ||
          name === 'build' ||
          name.endsWith('.test.ts') ||
          name.endsWith('.spec.ts')
        ) {
          continue;
        }

        if (entry.isDirectory()) {
          await walk(fullPath);
        } else {
          const ext = extname(name);
          if (['.ts', '.tsx'].includes(ext)) {
            if (files.length < config.maxFilesPerReview) {
              files.push(fullPath);
            } else {
              skipped++;
            }
          }
        }
      }
    } catch {
      // Directory not accessible
    }
  };

  await walk(dir);
  return { files, skipped };
};

// =============================================================================
// Main Review Logic
// =============================================================================

/**
 * Run all local reviewers on a file
 */
const runLocalReview = (
  content: string,
  filePath: string,
  enabledReviewers: readonly string[]
): readonly ReviewFinding[] => {
  const findings: ReviewFinding[] = [];

  if (enabledReviewers.includes('critic')) {
    findings.push(...criticReview(content, filePath));
  }

  if (enabledReviewers.includes('architect')) {
    findings.push(...architectReview(content, filePath));
  }

  if (enabledReviewers.includes('pragmatist')) {
    findings.push(...pragmatistReview(content, filePath));
  }

  // Always run performance review
  findings.push(...performanceReview(content, filePath));

  return findings;
};

// =============================================================================
// Tier Implementation
// =============================================================================

/**
 * Run Tier 4: Multi-Agent Review
 *
 * Provides heuristic-based code review with multiple perspectives.
 * Future: Claude API integration when ANTHROPIC_API_KEY is available.
 */
export const runReviewTier = (opts: VerificationOptions): Effect.Effect<TierResult, Error> =>
  Effect.gen(function* () {
    const startTime = Date.now();
    const details: string[] = [];
    const config = DEFAULT_CONFIG;

    // Check for Claude API availability
    const claudeAvailable = isClaudeApiAvailable();
    if (claudeAvailable) {
      details.push('Claude API: available (not yet implemented)');
    } else {
      details.push('Claude API: not configured (using local heuristics)');
    }

    // Find files to review
    const srcPath = join(opts.path, 'src');
    const { files, skipped } = yield* Effect.tryPromise({
      try: () => findFilesToReview(srcPath, config),
      catch: () => new Error('Failed to find files'),
    }).pipe(Effect.catchAll(() => Effect.succeed({ files: [] as string[], skipped: 0 })));

    if (files.length === 0) {
      details.push('No source files found for review');
      return {
        tier: 'review' as const,
        passed: true,
        errors: 0,
        warnings: 0,
        details,
        duration: Date.now() - startTime,
      };
    }

    details.push(`Reviewing ${files.length} files${skipped > 0 ? ` (${skipped} skipped)` : ''}...`);

    // Collect all findings
    const allFindings: ReviewFinding[] = [];

    for (const file of files) {
      const content = yield* Effect.tryPromise({
        try: () => readFile(file, 'utf-8'),
        catch: () => new Error('Failed to read file'),
      }).pipe(Effect.catchAll(() => Effect.succeed('')));

      // Skip large files
      if (content.length > config.maxFileSize) {
        details.push(`Skipped ${file.replace(`${opts.path}/`, '')}: exceeds size limit`);
        continue;
      }

      if (content) {
        const relativePath = file.replace(`${opts.path}/`, '');
        const findings = runLocalReview(content, relativePath, config.enabledReviewers);
        allFindings.push(...findings);
      }
    }

    // Categorize findings
    const errors = allFindings.filter((f) => f.severity === 'error');
    const warnings = allFindings.filter((f) => f.severity === 'warning');
    const suggestions = allFindings.filter((f) => f.severity === 'suggestion');

    // Add summary
    if (allFindings.length === 0) {
      details.push('No issues found by reviewers');
    } else {
      details.push('');
      details.push(
        `Found: ${errors.length} errors, ${warnings.length} warnings, ${suggestions.length} suggestions`
      );
      details.push('');

      // Group by category
      const byCategory = new Map<string, ReviewFinding[]>();
      for (const finding of allFindings) {
        const existing = byCategory.get(finding.category) || [];
        existing.push(finding);
        byCategory.set(finding.category, existing);
      }

      // Output by category (limited)
      for (const [category, findings] of byCategory) {
        details.push(`[${category.toUpperCase()}]`);
        for (const finding of findings.slice(0, 3)) {
          const loc = finding.line ? `:${finding.line}` : '';
          const icon =
            finding.severity === 'error' ? '✗' : finding.severity === 'warning' ? '⚠' : '💡';
          details.push(`  ${icon} ${finding.file}${loc}`);
          details.push(`    ${finding.message}`);
          if (opts.verbose) {
            details.push(`    → ${finding.recommendation}`);
          }
        }
        if (findings.length > 3) {
          details.push(`  ... and ${findings.length - 3} more in this category`);
        }
        details.push('');
      }
    }

    // Review tier is advisory by default - warnings don't fail the build
    // Only security errors should fail
    const securityErrors = errors.filter((e) => e.category === 'security');
    const passed = securityErrors.length === 0;

    return {
      tier: 'review' as const,
      passed,
      errors: errors.length,
      warnings: warnings.length + suggestions.length,
      details: details.slice(0, 40), // Limit output
      duration: Date.now() - startTime,
    };
  });
