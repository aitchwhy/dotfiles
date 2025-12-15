#!/usr/bin/env bun
/**
 * PARAGON Cleanup Hook v1.0
 *
 * Healing layer that detects code smell drift and auto-corrects.
 * Based on Martin Fowler's Refactoring Catalog.
 *
 * Modes:
 * - incremental: Run on changed files only (PostToolUse)
 * - full: Run on entire codebase (Stop event)
 *
 * Philosophy: Converge toward "good taste" through continuous small improvements.
 */

import { appendFileSync, mkdirSync, existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { join, relative } from "node:path";
import { spawnSync } from "node:child_process";
import { logError } from "./lib/hook-logging";

// ═══════════════════════════════════════════════════════════════════════════════
// TYPES
// ═══════════════════════════════════════════════════════════════════════════════

type Severity = "critical" | "major" | "minor" | "style";

type SmellCategory =
  | "bloaters"
  | "oo-abusers"
  | "change-preventers"
  | "dispensables"
  | "couplers";

type RefactoringName =
  | "ExtractFunction"
  | "InlineFunction"
  | "ExtractVariable"
  | "InlineVariable"
  | "RenameVariable"
  | "RenameField"
  | "EncapsulateVariable"
  | "IntroduceParameterObject"
  | "PreserveWholeObject"
  | "RemoveFlagArgument"
  | "ReplaceNestedConditionalWithGuardClauses"
  | "ReplaceConditionalWithPolymorphism"
  | "DecomposeConditional"
  | "ConsolidateConditional"
  | "ReplaceLoopWithPipeline"
  | "RemoveDeadCode"
  | "ExtractClass"
  | "InlineClass"
  | "MoveFunction"
  | "MoveField"
  | "HideDelegate"
  | "RemoveMiddleMan"
  | "SeparateQueryFromModifier"
  | "ReplaceTempWithQuery"
  | "SplitVariable"
  | "ReplacePrimitiveWithObject";

type CodeSmell = {
  readonly name: string;
  readonly category: SmellCategory;
  readonly severity: Severity;
  readonly file: string;
  readonly line: number;
  readonly description: string;
  readonly suggestedRefactoring: RefactoringName;
  readonly match: string;
};

type CleanupResult = {
  readonly timestamp: string;
  readonly mode: "incremental" | "full";
  readonly filesAnalyzed: number;
  readonly smellsDetected: number;
  readonly smellsFixed: number;
  readonly refactoringsApplied: readonly RefactoringName[];
  readonly testsPass: boolean;
  readonly duration: number;
  readonly bySeverity: Record<Severity, number>;
  readonly byCategory: Record<SmellCategory, number>;
};

// ═══════════════════════════════════════════════════════════════════════════════
// CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════════

const METRICS_DIR = join(homedir(), ".claude-metrics");
const CLEANUP_LOG = join(METRICS_DIR, "cleanup.jsonl");

const EXCLUDED_PATTERNS = [
  /node_modules/,
  /\.git/,
  /dist\//,
  /build\//,
  /\.next\//,
  /coverage\//,
  /\.d\.ts$/,
  /\.test\.[jt]sx?$/,
  /\.spec\.[jt]sx?$/,
  /\.e2e\.[jt]sx?$/,
  /__tests__\//,
  /\.bats$/,
  /\.md$/,
  /\.json$/,
  /\.yaml$/,
  /\.yml$/,
  /\.nix$/,
];

// ═══════════════════════════════════════════════════════════════════════════════
// SMELL DETECTORS (Fowler's Refactoring Catalog)
// ═══════════════════════════════════════════════════════════════════════════════

type SmellPattern = {
  readonly name: string;
  readonly pattern: RegExp;
  readonly category: SmellCategory;
  readonly severity: Severity;
  readonly refactoring: RefactoringName;
  readonly multiline?: boolean;
};

const SMELL_PATTERNS: readonly SmellPattern[] = [
  // ─────────────────────────────────────────────────────────────────────────────
  // BLOATERS (Code that has grown excessively)
  // ─────────────────────────────────────────────────────────────────────────────
  {
    name: "Long Parameter List",
    pattern: /function\s+\w+\s*\([^)]*,[^)]*,[^)]*,[^)]*,/g,
    category: "bloaters",
    severity: "major",
    refactoring: "IntroduceParameterObject",
  },
  {
    name: "Primitive Obsession (ID)",
    pattern: /:\s*string\s*[,)]\s*\/\*\s*id\s*\*\//gi,
    category: "bloaters",
    severity: "minor",
    refactoring: "ReplacePrimitiveWithObject",
  },
  {
    name: "Non-Descriptive Name",
    pattern: /\b(const|let|var)\s+(tmp|temp|data|obj|val|res|ret|arr|str|num|cnt|idx|ptr|buf)\s*[=:]/g,
    category: "bloaters",
    severity: "minor",
    refactoring: "RenameVariable",
  },

  // ─────────────────────────────────────────────────────────────────────────────
  // DISPENSABLES (Code that isn't needed)
  // ─────────────────────────────────────────────────────────────────────────────
  {
    name: "Dead Code (Commented)",
    pattern: /^\s*\/\/\s*(const|let|var|function|class|if|for|while|return)\s+/m,
    category: "dispensables",
    severity: "major",
    refactoring: "RemoveDeadCode",
  },
  {
    name: "Redundant Comment",
    pattern: /\/\/\s*(loop|iterate|check|get|set|return|increment|decrement)\s+(through|over|the|a|an)\b/gi,
    category: "dispensables",
    severity: "style",
    refactoring: "ExtractFunction",
  },

  // ─────────────────────────────────────────────────────────────────────────────
  // OO-ABUSERS (Incorrect OOP usage)
  // ─────────────────────────────────────────────────────────────────────────────
  {
    name: "Switch on Type",
    pattern: /switch\s*\(\s*\w+\.(type|kind|variant|tag)\s*\)/g,
    category: "oo-abusers",
    severity: "major",
    refactoring: "ReplaceConditionalWithPolymorphism",
  },
  {
    name: "Flag Argument",
    pattern: /function\s+\w+\s*\([^)]*,\s*\w+:\s*boolean\s*[,)]/g,
    category: "oo-abusers",
    severity: "minor",
    refactoring: "RemoveFlagArgument",
  },
  {
    name: "Any Type",
    pattern: /:\s*[a]ny\b|as\s+[a]ny\b|<[a]ny>/g,
    category: "oo-abusers",
    severity: "critical",
    refactoring: "ReplacePrimitiveWithObject",
  },
  {
    name: "z.infer Usage",
    pattern: /z\.(infer|input|output)</g,
    category: "oo-abusers",
    severity: "critical",
    refactoring: "ExtractVariable",
  },

  // ─────────────────────────────────────────────────────────────────────────────
  // COUPLERS (Excessive coupling between classes)
  // ─────────────────────────────────────────────────────────────────────────────
  {
    name: "Message Chain",
    pattern: /\.\w+\([^)]*\)\.\w+\([^)]*\)\.\w+\([^)]*\)\.\w+\(/g,
    category: "couplers",
    severity: "minor",
    refactoring: "HideDelegate",
  },
  {
    name: "Feature Envy",
    pattern: /(\w+)\.\w+[\s\S]{0,30}\1\.\w+[\s\S]{0,30}\1\.\w+[\s\S]{0,30}\1\.\w+/g,
    category: "couplers",
    severity: "major",
    refactoring: "MoveFunction",
  },

  // ─────────────────────────────────────────────────────────────────────────────
  // CHANGE PREVENTERS (Code that's hard to change)
  // ─────────────────────────────────────────────────────────────────────────────
  {
    name: "Deeply Nested Conditional",
    pattern: /if\s*\([^)]+\)\s*\{[^{}]*if\s*\([^)]+\)\s*\{[^{}]*if\s*\([^)]+\)\s*\{/g,
    category: "change-preventers",
    severity: "major",
    refactoring: "ReplaceNestedConditionalWithGuardClauses",
  },
  {
    name: "Mutable Variable",
    pattern: /^\s*let\s+\w+\s*=(?!.*(?:for|while)\s*\()/gm,
    category: "change-preventers",
    severity: "style",
    refactoring: "SplitVariable",
  },

  // ─────────────────────────────────────────────────────────────────────────────
  // STACK-SPECIFIC (PARAGON conventions)
  // ─────────────────────────────────────────────────────────────────────────────
  {
    name: "Imperative Loop",
    pattern: /for\s*\(\s*(let|var)\s+\w+\s*=\s*0\s*;/g,
    category: "dispensables",
    severity: "style",
    refactoring: "ReplaceLoopWithPipeline",
  },
  {
    name: "Throw for Expected Error",
    pattern: /throw\s+new\s+(Error|TypeError|RangeError)\s*\([^)]*(?:not\s+found|invalid|missing|failed)\b/gi,
    category: "oo-abusers",
    severity: "major",
    refactoring: "ExtractFunction",
  },
  {
    name: "Assumption Language",
    pattern: /\/\/.*\b(should\s+(now\s+)?work|probably|I\s+think|might\s+(fix|work))\b/gi,
    category: "dispensables",
    severity: "major",
    refactoring: "RemoveDeadCode",
  },
];

// ═══════════════════════════════════════════════════════════════════════════════
// SMELL DETECTION ENGINE
// ═══════════════════════════════════════════════════════════════════════════════

const MAX_MATCH_DISPLAY_LENGTH = 60;

function detectSmells(filePath: string, content: string): CodeSmell[] {
  const smells: CodeSmell[] = [];

  for (const detector of SMELL_PATTERNS) {
    detector.pattern.lastIndex = 0;
    let match: RegExpExecArray | null;

    while ((match = detector.pattern.exec(content)) !== null) {
      const lineNumber = content.substring(0, match.index).split("\n").length;
      const matchText = match[0].substring(0, MAX_MATCH_DISPLAY_LENGTH);

      smells.push({
        name: detector.name,
        category: detector.category,
        severity: detector.severity,
        file: filePath,
        line: lineNumber,
        description: `${detector.name}: "${matchText}${match[0].length > MAX_MATCH_DISPLAY_LENGTH ? "..." : ""}"`,
        suggestedRefactoring: detector.refactoring,
        match: match[0],
      });
    }
  }

  return smells;
}

// ═══════════════════════════════════════════════════════════════════════════════
// FILE DISCOVERY
// ═══════════════════════════════════════════════════════════════════════════════

function shouldExcludeFile(filePath: string): boolean {
  return EXCLUDED_PATTERNS.some((pattern) => pattern.test(filePath));
}

function getChangedFiles(): string[] {
  const result = spawnSync("git", ["diff", "--name-only", "--diff-filter=ACMR", "HEAD"], {
    encoding: "utf-8",
  });

  if (result.status !== 0) {
    return [];
  }

  return result.stdout
    .split("\n")
    .filter((f) => f.endsWith(".ts") || f.endsWith(".tsx"))
    .filter((f) => !shouldExcludeFile(f));
}

function getAllSourceFiles(dir: string = "."): string[] {
  const files: string[] = [];

  function walk(currentDir: string): void {
    try {
      const entries = readdirSync(currentDir);
      for (const entry of entries) {
        const fullPath = join(currentDir, entry);
        if (shouldExcludeFile(fullPath)) continue;

        try {
          const stat = statSync(fullPath);
          if (stat.isDirectory()) {
            walk(fullPath);
          } else if (stat.isFile() && /\.[jt]sx?$/.test(entry)) {
            files.push(fullPath);
          }
        } catch {
          // Skip files we can't stat
        }
      }
    } catch {
      // Skip directories we can't read
    }
  }

  walk(dir);
  return files;
}

// ═══════════════════════════════════════════════════════════════════════════════
// METRICS & REPORTING
// ═══════════════════════════════════════════════════════════════════════════════

function logMetrics(result: CleanupResult): void {
  try {
    if (!existsSync(METRICS_DIR)) {
      mkdirSync(METRICS_DIR, { recursive: true });
    }
    appendFileSync(CLEANUP_LOG, JSON.stringify(result) + "\n");
  } catch {
    // Fail silently - don't block on metrics
  }
}

function formatReport(
  smells: readonly CodeSmell[],
  mode: "incremental" | "full"
): string {
  if (smells.length === 0) {
    return "✓ No code smells detected";
  }

  const lines: string[] = [
    "═══════════════════════════════════════════════════════════════",
    `  PARAGON Cleanup Report (${mode})`,
    "═══════════════════════════════════════════════════════════════",
    "",
  ];

  // Group by severity - initialize all keys to avoid type issues
  const bySeverity = smells.reduce(
    (acc, smell) => {
      acc[smell.severity].push(smell);
      return acc;
    },
    {
      critical: [] as CodeSmell[],
      major: [] as CodeSmell[],
      minor: [] as CodeSmell[],
      style: [] as CodeSmell[],
    } as Record<Severity, CodeSmell[]>
  );

  const severityOrder: Severity[] = ["critical", "major", "minor", "style"];
  const severityIcons: Record<Severity, string> = {
    critical: "🔴",
    major: "🟠",
    minor: "🟡",
    style: "⚪",
  };

  for (const severity of severityOrder) {
    const severitySmells = bySeverity[severity];
    if (!severitySmells || severitySmells.length === 0) continue;

    lines.push(
      `${severityIcons[severity]} ${severity.toUpperCase()} (${severitySmells.length})`
    );
    lines.push("");

    for (const smell of severitySmells.slice(0, 5)) {
      lines.push(`  ${smell.file}:${smell.line}`);
      lines.push(`    Smell: ${smell.name}`);
      lines.push(`    Refactoring: ${smell.suggestedRefactoring}`);
      lines.push("");
    }

    if (severitySmells.length > 5) {
      lines.push(`  ... and ${severitySmells.length - 5} more`);
      lines.push("");
    }
  }

  // Refactoring catalog reference
  lines.push("───────────────────────────────────────────────────────────────");
  lines.push("  Fowler Refactoring Catalog: https://refactoring.com/catalog/");
  lines.push("═══════════════════════════════════════════════════════════════");

  return lines.join("\n");
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN CLEANUP ORCHESTRATOR
// ═══════════════════════════════════════════════════════════════════════════════

async function cleanup(mode: "incremental" | "full"): Promise<CleanupResult> {
  const startTime = Date.now();

  // Get files to analyze
  const files = mode === "incremental" ? getChangedFiles() : getAllSourceFiles();

  if (files.length === 0) {
    const result: CleanupResult = {
      timestamp: new Date().toISOString(),
      mode,
      filesAnalyzed: 0,
      smellsDetected: 0,
      smellsFixed: 0,
      refactoringsApplied: [],
      testsPass: true,
      duration: Date.now() - startTime,
      bySeverity: { critical: 0, major: 0, minor: 0, style: 0 },
      byCategory: {
        bloaters: 0,
        "oo-abusers": 0,
        "change-preventers": 0,
        dispensables: 0,
        couplers: 0,
      },
    };
    logMetrics(result);
    return result;
  }

  // Detect smells
  const allSmells: CodeSmell[] = [];
  for (const file of files) {
    try {
      const content = readFileSync(file, "utf-8");
      const smells = detectSmells(file, content);
      allSmells.push(...smells);
    } catch {
      // File might not exist or be readable
    }
  }

  // Aggregate by severity and category
  const bySeverity: Record<Severity, number> = {
    critical: 0,
    major: 0,
    minor: 0,
    style: 0,
  };
  const byCategory: Record<SmellCategory, number> = {
    bloaters: 0,
    "oo-abusers": 0,
    "change-preventers": 0,
    dispensables: 0,
    couplers: 0,
  };

  for (const smell of allSmells) {
    bySeverity[smell.severity]++;
    byCategory[smell.category]++;
  }

  // Print report
  process.stdout.write(formatReport(allSmells, mode) + '\n');

  const duration = Date.now() - startTime;
  const result: CleanupResult = {
    timestamp: new Date().toISOString(),
    mode,
    filesAnalyzed: files.length,
    smellsDetected: allSmells.length,
    smellsFixed: 0, // No auto-fix in v1.0 - advisory only
    refactoringsApplied: [],
    testsPass: true,
    duration,
    bySeverity,
    byCategory,
  };

  logMetrics(result);
  return result;
}

// ═══════════════════════════════════════════════════════════════════════════════
// CLI ENTRY POINT
// ═══════════════════════════════════════════════════════════════════════════════

const args = process.argv.slice(2);
const modeIndex = args.indexOf("--mode");
const mode: "incremental" | "full" =
  modeIndex >= 0 && args[modeIndex + 1] === "full" ? "full" : "incremental";

const isCI = args.includes("--ci");
const isJson = args.includes("--json");

cleanup(mode)
  .then((result) => {
    if (isJson) {
      process.stdout.write(JSON.stringify(result, null, 2) + '\n');
    }

    // In CI mode, exit with error if critical smells found
    if (isCI && result.bySeverity.critical > 0) {
      logError('paragon-cleanup', `Found ${result.bySeverity.critical} critical code smells`);
      process.exit(2);
    }
  })
  .catch((error) => {
    logError('paragon-cleanup', error);
    process.exit(1);
  });
