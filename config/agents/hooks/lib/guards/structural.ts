/**
 * Structural Guards - Clean Code enforcement
 *
 * Guards 15-25: Comments, naming, function size, complexity, nesting
 * These require parsing but not full AST - line-based analysis suffices.
 */

import { isExcludedPath, isTypeScriptFile, type GuardResult } from '../types';

// =============================================================================
// Shared Utilities
// =============================================================================

function stripStringsAndComments(code: string): string {
  return code
    .replace(/\/\/.*$/gm, '')
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/'(?:[^'\\]|\\.)*'/g, "''")
    .replace(/"(?:[^"\\]|\\.)*"/g, '""')
    .replace(/`(?:[^`\\]|\\.)*`/g, '``');
}

// =============================================================================
// Guard 15: No Comments (blocks unnecessary inline comments)
// =============================================================================

const UNNECESSARY_COMMENT_PATTERNS = [
  /\/\/\s*(TODO|FIXME|HACK|XXX|BUG)/i,
  /\/\/\s*eslint-disable/,
  /\/\/\s*@ts-ignore/,
  /\/\/\s*@ts-expect-error/,
  /\/\/\s*prettier-ignore/,
  /\/\/\s*biome-ignore/,
];

export function checkNoComments(content: string, filePath: string): GuardResult {
  if (!isTypeScriptFile(filePath)) return { ok: true };
  if (isExcludedPath(filePath)) return { ok: true };

  const lines = content.split('\n');
  const violations: string[] = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] ?? '';
    for (const pattern of UNNECESSARY_COMMENT_PATTERNS) {
      if (pattern.test(line)) {
        violations.push(`Line ${i + 1}: ${pattern.source.replace(/\\/g, '')}`);
        break;
      }
    }
  }

  if (violations.length > 0) {
    return {
      ok: false,
      error: `Guard 15: Unnecessary comments detected\n\n${violations.slice(0, 5).join('\n')}\n\nRemove or address these comments.`,
    };
  }

  return { ok: true };
}

// =============================================================================
// Guard 16: Meaningful Names
// =============================================================================

const BAD_NAME_PATTERNS = [
  /\b(tmp|temp|foo|bar|baz|qux|test|data|info|item|thing|stuff)\s*[=:]/,
  /\b[a-z]\s*[=:]/, // single letter variables (except i, j, k in loops)
  /\b(str|num|obj|arr|func|cb|val)\s*[=:]/i, // type prefixes
];

const NAME_EXCLUSIONS = [
  /for\s*\(\s*(let|const|var)\s+[ijk]\s/,
  /\.(map|filter|reduce|forEach)\(\s*\(?\s*[a-z]\s*\)?\s*=>/,
];

export function checkMeaningfulNames(content: string, filePath: string): GuardResult {
  if (!isTypeScriptFile(filePath)) return { ok: true };
  if (isExcludedPath(filePath)) return { ok: true };

  const stripped = stripStringsAndComments(content);
  const lines = stripped.split('\n');
  const violations: string[] = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] ?? '';

    // Skip if it's an excluded pattern
    if (NAME_EXCLUSIONS.some((p) => p.test(line))) continue;

    for (const pattern of BAD_NAME_PATTERNS) {
      if (pattern.test(line)) {
        violations.push(`Line ${i + 1}: Poor variable naming`);
        break;
      }
    }
  }

  if (violations.length > 3) {
    return {
      ok: false,
      error: `Guard 16: ${violations.length} poorly named variables\n\n${violations.slice(0, 5).join('\n')}\n\nUse meaningful, descriptive names.`,
    };
  }

  return { ok: true };
}

// =============================================================================
// Guard 17: No Commented-Out Code
// =============================================================================

const COMMENTED_CODE_PATTERNS = [
  /\/\/\s*(const|let|var|function|class|import|export|if|for|while|return)\s/,
  /\/\/\s*[a-zA-Z]+\s*\([^)]*\)\s*[{;]/,
  /\/\*[\s\S]*?(const|let|var|function|class)\s/,
];

export function checkCommentedOutCode(content: string, filePath: string): GuardResult {
  if (!isTypeScriptFile(filePath)) return { ok: true };
  if (isExcludedPath(filePath)) return { ok: true };

  const lines = content.split('\n');
  const violations: string[] = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] ?? '';
    for (const pattern of COMMENTED_CODE_PATTERNS) {
      if (pattern.test(line)) {
        violations.push(`Line ${i + 1}: Commented-out code`);
        break;
      }
    }
  }

  if (violations.length > 0) {
    return {
      ok: false,
      error: `Guard 17: Commented-out code detected\n\n${violations.slice(0, 5).join('\n')}\n\nDelete dead code, don't comment it out.`,
    };
  }

  return { ok: true };
}

// =============================================================================
// Guard 18: Function Arguments (max 3 positional)
// =============================================================================

export function checkFunctionArguments(content: string, filePath: string): GuardResult {
  if (!isTypeScriptFile(filePath)) return { ok: true };
  if (isExcludedPath(filePath)) return { ok: true };

  const stripped = stripStringsAndComments(content);
  const funcPattern = /(?:function\s+\w+|const\s+\w+\s*=\s*(?:async\s*)?\(|(?:async\s+)?function\s*\()\s*([^)]*)\)/g;

  let match: RegExpExecArray | null;
  const violations: string[] = [];

  while ((match = funcPattern.exec(stripped)) !== null) {
    const params = match[1] ?? '';
    // Count params (split by comma, exclude destructured)
    const paramCount = params
      .split(',')
      .filter((p) => p.trim() && !p.includes('{') && !p.includes('['))
      .length;

    if (paramCount > 3) {
      violations.push(`Too many parameters: ${paramCount}`);
    }
  }

  if (violations.length > 0) {
    return {
      ok: false,
      error: `Guard 18: Functions with >3 parameters\n\n${violations.slice(0, 3).join('\n')}\n\nUse an options object instead.`,
    };
  }

  return { ok: true };
}

// =============================================================================
// Guard 19: Law of Demeter (method chain violations)
// =============================================================================

export function checkLawOfDemeter(content: string, filePath: string): GuardResult {
  if (!isTypeScriptFile(filePath)) return { ok: true };
  if (isExcludedPath(filePath)) return { ok: true };

  // Skip fluent APIs and common chaining patterns
  if (content.includes('Effect.') || content.includes('.pipe(')) return { ok: true };

  const stripped = stripStringsAndComments(content);
  // Look for x.a.b.c.d patterns (4+ levels)
  const chainPattern = /\w+(?:\.\w+){4,}/g;

  const matches = stripped.match(chainPattern) ?? [];
  // Filter out common allowed patterns
  const violations = matches.filter(
    (m) =>
      !m.startsWith('process.') &&
      !m.startsWith('console.') &&
      !m.includes('.prototype.') &&
      !m.includes('.then.') &&
      !m.includes('.catch.')
  );

  if (violations.length > 2) {
    return {
      ok: false,
      error: `Guard 19: Law of Demeter violations\n\n${violations.slice(0, 3).join('\n')}\n\nAvoid deep method chains.`,
    };
  }

  return { ok: true };
}

// =============================================================================
// Guard 20: Function Size (max 30 lines)
// =============================================================================

const MAX_FUNCTION_LINES = 30;

export function checkFunctionSize(content: string, filePath: string): GuardResult {
  if (!isTypeScriptFile(filePath)) return { ok: true };
  if (isExcludedPath(filePath)) return { ok: true };

  const lines = content.split('\n');
  const violations: string[] = [];

  let inFunction = false;
  let functionStart = 0;
  let braceCount = 0;
  let functionName = '';

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] ?? '';

    // Detect function start
    const funcMatch = line.match(/(?:function\s+(\w+)|const\s+(\w+)\s*=.*=>|(\w+)\s*\([^)]*\)\s*(?::\s*\w+)?\s*{)/);
    if (funcMatch && !inFunction) {
      inFunction = true;
      functionStart = i;
      functionName = funcMatch[1] ?? funcMatch[2] ?? funcMatch[3] ?? 'anonymous';
      braceCount = (line.match(/{/g) ?? []).length - (line.match(/}/g) ?? []).length;
      continue;
    }

    if (inFunction) {
      braceCount += (line.match(/{/g) ?? []).length;
      braceCount -= (line.match(/}/g) ?? []).length;

      if (braceCount <= 0) {
        const functionLines = i - functionStart + 1;
        if (functionLines > MAX_FUNCTION_LINES) {
          violations.push(`${functionName}: ${functionLines} lines (max ${MAX_FUNCTION_LINES})`);
        }
        inFunction = false;
        functionName = '';
      }
    }
  }

  if (violations.length > 0) {
    return {
      ok: false,
      error: `Guard 20: Functions too large\n\n${violations.slice(0, 3).join('\n')}\n\nExtract smaller functions.`,
    };
  }

  return { ok: true };
}

// =============================================================================
// Guard 21: Cyclomatic Complexity (max 10 branches)
// =============================================================================

const BRANCH_PATTERNS = [/\bif\s*\(/, /\belse\s+if\b/, /\bswitch\s*\(/, /\bcase\s+/, /\bfor\s*\(/, /\bwhile\s*\(/, /\bcatch\s*\(/, /\?\s*:/];

export function checkCyclomaticComplexity(content: string, filePath: string): GuardResult {
  if (!isTypeScriptFile(filePath)) return { ok: true };
  if (isExcludedPath(filePath)) return { ok: true };

  const stripped = stripStringsAndComments(content);
  let complexity = 1; // Base complexity

  for (const pattern of BRANCH_PATTERNS) {
    const matches = stripped.match(new RegExp(pattern.source, 'g')) ?? [];
    complexity += matches.length;
  }

  if (complexity > 15) {
    return {
      ok: false,
      error: `Guard 21: High cyclomatic complexity (${complexity})\n\nMax: 15. Extract helper functions to reduce branches.`,
    };
  }

  return { ok: true };
}

// =============================================================================
// Guard 22: Switch on Type
// =============================================================================

export function checkSwitchOnType(content: string, filePath: string): GuardResult {
  if (!isTypeScriptFile(filePath)) return { ok: true };
  if (isExcludedPath(filePath)) return { ok: true };

  const stripped = stripStringsAndComments(content);
  const pattern = /switch\s*\(\s*\w+\.type\s*\)/;

  if (pattern.test(stripped)) {
    return {
      ok: false,
      error: `Guard 22: switch(x.type) detected\n\nUse discriminated unions with type guards or visitor pattern.`,
    };
  }

  return { ok: true };
}

// =============================================================================
// Guard 23: Null Returns
// =============================================================================

export function checkNullReturns(content: string, filePath: string): GuardResult {
  if (!isTypeScriptFile(filePath)) return { ok: true };
  if (isExcludedPath(filePath)) return { ok: true };

  const stripped = stripStringsAndComments(content);
  const pattern = /return\s+null\s*;/g;

  const matches = stripped.match(pattern) ?? [];
  if (matches.length > 2) {
    return {
      ok: false,
      error: `Guard 23: ${matches.length} return null statements\n\nUse Option<T> or Result<T, E> instead.`,
    };
  }

  return { ok: true };
}

// =============================================================================
// Guard 24: Interface Segregation (max 7 members)
// =============================================================================

export function checkInterfaceSegregation(content: string, filePath: string): GuardResult {
  if (!isTypeScriptFile(filePath)) return { ok: true };
  if (isExcludedPath(filePath)) return { ok: true };

  const interfacePattern = /interface\s+(\w+)\s*{([^}]*)}/g;
  const violations: string[] = [];

  let match: RegExpExecArray | null;
  while ((match = interfacePattern.exec(content)) !== null) {
    const name = match[1] ?? '';
    const body = match[2] ?? '';
    const memberCount = body.split(';').filter((m) => m.trim()).length;

    if (memberCount > 7) {
      violations.push(`${name}: ${memberCount} members (max 7)`);
    }
  }

  if (violations.length > 0) {
    return {
      ok: false,
      error: `Guard 24: Large interfaces\n\n${violations.slice(0, 3).join('\n')}\n\nSplit into smaller, focused interfaces.`,
    };
  }

  return { ok: true };
}

// =============================================================================
// Guard 25: Deep Nesting (max 3 levels)
// =============================================================================

export function checkDeepNesting(content: string, filePath: string): GuardResult {
  if (!isTypeScriptFile(filePath)) return { ok: true };
  if (isExcludedPath(filePath)) return { ok: true };

  const lines = content.split('\n');
  let maxIndent = 0;

  for (const line of lines) {
    const trimmed = line.replace(/^\s*/, '');
    if (!trimmed || trimmed.startsWith('//') || trimmed.startsWith('*')) continue;

    const indent = line.length - trimmed.length;
    const indentLevel = Math.floor(indent / 2); // Assuming 2-space indent
    maxIndent = Math.max(maxIndent, indentLevel);
  }

  if (maxIndent > 6) {
    // ~3 nested blocks
    return {
      ok: false,
      error: `Guard 25: Deep nesting detected (${Math.floor(maxIndent / 2)} levels)\n\nMax: 3. Use early returns or extract functions.`,
    };
  }

  return { ok: true };
}

// =============================================================================
// Main Entry Point
// =============================================================================

export function runStructuralGuards(content: string | undefined, filePath: string | undefined): GuardResult {
  if (!content || !filePath) return { ok: true };
  if (!isTypeScriptFile(filePath)) return { ok: true };
  if (isExcludedPath(filePath)) return { ok: true };

  // Run all structural guards
  const guards = [
    () => checkNoComments(content, filePath),
    () => checkMeaningfulNames(content, filePath),
    () => checkCommentedOutCode(content, filePath),
    () => checkFunctionArguments(content, filePath),
    () => checkLawOfDemeter(content, filePath),
    () => checkFunctionSize(content, filePath),
    () => checkCyclomaticComplexity(content, filePath),
    () => checkSwitchOnType(content, filePath),
    () => checkNullReturns(content, filePath),
    () => checkInterfaceSegregation(content, filePath),
    () => checkDeepNesting(content, filePath),
  ];

  for (const guard of guards) {
    const result = guard();
    if (!result.ok) return result;
  }

  return { ok: true };
}
