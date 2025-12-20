#!/usr/bin/env bun
/**
 * PARAGON Guard v5.0 - Effect-based Modular Enforcement System
 *
 * Consolidates 39 guards into modular architecture:
 * - Procedural guards (1-3, 8-12, 28-31): TypeScript validation
 * - Content guards (4-7, 13-14, 26, 32-39): AST-grep rules
 * - Structural guards (15-25): Clean code analysis
 *
 * Full Effect pipeline - no try/catch.
 */

import { Effect, pipe } from "effect";
import { approve, block, logError } from './lib/hook-logging';
import { decodePreToolUseInput, type PreToolUseInput } from './lib/types';
import { runProceduralGuards } from './lib/guards/procedural';
import { runStructuralGuards } from './lib/guards/structural';
import { runContentGuards } from './lib/guards/content';

// =============================================================================
// Performance Logging
// =============================================================================

import { appendFileSync, mkdirSync, existsSync, statSync, renameSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

const METRICS_DIR = join(homedir(), '.claude-metrics');
const PERF_LOG = join(METRICS_DIR, 'perf.jsonl');

function logPerf(tool: string, file: string, durationMs: number, result: 'approve' | 'block', guards: number): void {
  Effect.runSync(
    Effect.try(() => {
      if (!existsSync(METRICS_DIR)) {
        mkdirSync(METRICS_DIR, { recursive: true });
      }

      // Rotate if > 10MB
      const stats = existsSync(PERF_LOG) ? statSync(PERF_LOG) : null;
      if (stats && stats.size > 10 * 1024 * 1024) {
        const archive = `${PERF_LOG}.${Date.now()}.archive`;
        renameSync(PERF_LOG, archive);
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
    }).pipe(Effect.catchAll(() => Effect.void))
  );
}

// =============================================================================
// Guard Runner
// =============================================================================

const runGuards = (input: PreToolUseInput): Effect.Effect<{ result: 'approve' | 'block'; reason?: string; warnings: string[] }, never, never> => {
  const startTime = Date.now();
  let guardsChecked = 0;

  const { tool_name, tool_input } = input;
  const { file_path: filePath, content, new_string, command } = tool_input;
  const effectiveContent = content ?? new_string;
  const warnings: string[] = [];

  return Effect.gen(function* () {
    // 1. Procedural Guards (sync - use Effect.try)
    guardsChecked += 12;
    const proceduralResult = yield* Effect.try({
      try: () => runProceduralGuards(tool_name, {
        file_path: filePath,
        content: effectiveContent,
        command,
      }),
      catch: (e) => new Error(`Procedural guard error: ${e}`),
    });

    if (!proceduralResult.ok) {
      logPerf(tool_name, filePath ?? '', Date.now() - startTime, 'block', guardsChecked);
      return { result: 'block' as const, reason: proceduralResult.error, warnings };
    }
    if (proceduralResult.warnings) {
      warnings.push(...proceduralResult.warnings);
    }

    // 2. Content Guards (async - use Effect.tryPromise)
    if (effectiveContent && filePath) {
      guardsChecked += 14;
      const contentResult = yield* Effect.tryPromise({
        try: () => runContentGuards(effectiveContent, filePath),
        catch: (e) => new Error(`Content guard error: ${e}`),
      });

      if (!contentResult.ok) {
        logPerf(tool_name, filePath, Date.now() - startTime, 'block', guardsChecked);
        return { result: 'block' as const, reason: contentResult.error, warnings };
      }
      if (contentResult.warnings) {
        warnings.push(...contentResult.warnings);
      }
    }

    // 3. Structural Guards (sync - use Effect.try)
    if (effectiveContent && filePath) {
      guardsChecked += 11;
      const structuralResult = yield* Effect.try({
        try: () => runStructuralGuards(effectiveContent, filePath),
        catch: (e) => new Error(`Structural guard error: ${e}`),
      });

      if (!structuralResult.ok) {
        logPerf(tool_name, filePath, Date.now() - startTime, 'block', guardsChecked);
        return { result: 'block' as const, reason: structuralResult.error, warnings };
      }
      if (structuralResult.warnings) {
        warnings.push(...structuralResult.warnings);
      }
    }

    // All guards passed
    logPerf(tool_name, filePath ?? '', Date.now() - startTime, 'approve', guardsChecked);
    return { result: 'approve' as const, warnings };
  });
};

// =============================================================================
// Read stdin
// =============================================================================

const readStdin = Effect.tryPromise({
  try: async () => {
    const text = await Bun.stdin.text();
    if (!text.trim()) return null;
    return JSON.parse(text);
  },
  catch: () => new Error("Failed to read stdin"),
});

// =============================================================================
// Main Program
// =============================================================================

const program = pipe(
  readStdin,
  Effect.flatMap((raw) => {
    if (raw === null) {
      approve();
      return Effect.void;
    }
    return pipe(
      decodePreToolUseInput(raw),
      Effect.flatMap(runGuards),
      Effect.tap((result) => {
        if (result.result === 'block') {
          block(result.reason ?? 'Unknown guard violation');
        } else if (result.warnings.length > 0) {
          approve(`Advisory: ${result.warnings.slice(0, 3).join(' | ')}`);
        } else {
          approve();
        }
        return Effect.void;
      }),
    );
  }),
  Effect.catchAll((error) => {
    // Parse errors -> approve (fail-open for invalid input format)
    const message = error instanceof Error ? error.message : String(error);
    if (message.includes('Expected') || message.includes('missing')) {
      approve('Invalid hook input format');
    } else {
      logError('paragon-guard', error);
      block(`Guard system error: ${message}`);
    }
    return Effect.void;
  }),
);

// =============================================================================
// Execute
// =============================================================================

Effect.runPromise(program);
