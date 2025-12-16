#!/usr/bin/env bun
/**
 * PARAGON Guard v4.0 - Modular Enforcement System
 *
 * Consolidates 39 guards into modular architecture:
 * - Procedural guards (1-3, 8-12, 28-31): TypeScript validation
 * - Content guards (4-7, 13-14, 26, 32-39): AST-grep rules
 * - Structural guards (15-25): Clean code analysis
 *
 * Key improvements:
 * - Single AST parse for all pattern rules
 * - No infinite loop workarounds (proper file exclusions instead)
 * - ~200 lines orchestrator (down from 2921)
 */

import { approve, block, logError } from './lib/hook-logging';
import { HookInputSchema, type GuardResult } from './lib/types';
import { runProceduralGuards } from './lib/guards/procedural';
import { runStructuralGuards } from './lib/guards/structural';
import { runContentGuards } from './lib/guards/content';

// =============================================================================
// Main Entry Point
// =============================================================================

async function main(): Promise<void> {
  const startTime = Date.now();
  let guardsChecked = 0;

  try {
    // Parse stdin input
    const rawInput = await Bun.stdin.text();
    if (!rawInput.trim()) {
      approve();
      return;
    }

    const parseResult = HookInputSchema.safeParse(JSON.parse(rawInput));
    if (!parseResult.success) {
      approve('Invalid hook input format');
      return;
    }

    const { tool_name, tool_input } = parseResult.data;
    const { file_path: filePath, content, new_string, command } = tool_input;

    // Use new_string for Edit operations if content is not provided
    const effectiveContent = content ?? new_string;

    // Collect all warnings for advisory guards
    const warnings: string[] = [];

    // ==========================================================================
    // Run Guard Categories
    // ==========================================================================

    // 1. Procedural Guards (1-3, 8-12, 28-31)
    guardsChecked += 12;
    const proceduralResult = await runProceduralGuards(tool_name, {
      file_path: filePath,
      content: effectiveContent,
      command,
    });

    if (!proceduralResult.ok) {
      logPerf(tool_name, filePath ?? '', Date.now() - startTime, 'block', guardsChecked);
      block(proceduralResult.error);
      return;
    }
    if (proceduralResult.warnings) {
      warnings.push(...proceduralResult.warnings);
    }

    // 2. Content Guards (AST-based: 4-7, 13-14, 26, 32-39)
    if (effectiveContent && filePath) {
      guardsChecked += 14;
      const contentResult = await runContentGuards(effectiveContent, filePath);

      if (!contentResult.ok) {
        logPerf(tool_name, filePath, Date.now() - startTime, 'block', guardsChecked);
        block(contentResult.error);
        return;
      }
      if (contentResult.warnings) {
        warnings.push(...contentResult.warnings);
      }
    }

    // 3. Structural Guards (Clean Code: 15-25)
    if (effectiveContent && filePath) {
      guardsChecked += 11;
      const structuralResult = runStructuralGuards(effectiveContent, filePath);

      if (!structuralResult.ok) {
        logPerf(tool_name, filePath, Date.now() - startTime, 'block', guardsChecked);
        block(structuralResult.error);
        return;
      }
      if (structuralResult.warnings) {
        warnings.push(...structuralResult.warnings);
      }
    }

    // ==========================================================================
    // All Guards Passed
    // ==========================================================================
    logPerf(tool_name, filePath ?? '', Date.now() - startTime, 'approve', guardsChecked);

    if (warnings.length > 0) {
      approve(`Advisory: ${warnings.slice(0, 3).join(' | ')}`);
    } else {
      approve();
    }
  } catch (e) {
    logError('paragon-guard', e);
    // Fail-closed: only approve on known-safe parse errors
    if (e instanceof SyntaxError && rawInput.trim() === '') {
      approve('Empty input');
      return;
    }
    block(`Guard system error: ${e instanceof Error ? e.message : 'Unknown error'}`);
    return;
  }
}

// =============================================================================
// Performance Logging
// =============================================================================

import { appendFileSync, mkdirSync, existsSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

const METRICS_DIR = join(homedir(), '.claude-metrics');
const PERF_LOG = join(METRICS_DIR, 'perf.jsonl');

function logPerf(tool: string, file: string, durationMs: number, result: 'approve' | 'block', guards: number): void {
  try {
    if (!existsSync(METRICS_DIR)) {
      mkdirSync(METRICS_DIR, { recursive: true });
    }
    const metric = {
      timestamp: new Date().toISOString(),
      hook: 'paragon-guard',
      tool,
      file: file.split('/').pop() ?? '',
      duration_ms: durationMs,
      result,
      guards_checked: guards,
    };
    appendFileSync(PERF_LOG, JSON.stringify(metric) + '\n');
  } catch {
    // Fail silently
  }
}

// =============================================================================
// Execute
// =============================================================================

main();
