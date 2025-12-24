/**
 * Effect-based Hook Utilities
 *
 * Provides typed hook infrastructure using Effect.
 *
 * SSOT Reference: Types should match config/agents/hooks/lib/types.ts
 * (Cannot import directly due to separate node_modules causing type mismatches)
 */

import { Console, Effect, Schema } from 'effect';

// =============================================================================
// Hook Protocol Types (must match SSOT at config/agents/hooks/lib/types.ts)
// =============================================================================

export type HookDecision =
  | { readonly decision: 'approve'; readonly reason?: string }
  | { readonly decision: 'block'; readonly reason: string }
  | { readonly decision: 'skip'; readonly reason?: string };

// Guard result types (used by procedural/content/structural guards)
export type GuardResultOk = { readonly ok: true; readonly warnings?: readonly string[] };
export type GuardResultError = { readonly ok: false; readonly error: string };
export type GuardResult = GuardResultOk | GuardResultError;

// =============================================================================
// Hook Input Schemas (must match SSOT at config/agents/hooks/lib/types.ts)
// =============================================================================

const ToolInputSchema = Schema.Struct({
  file_path: Schema.optional(Schema.String),
  content: Schema.optional(Schema.String),
  new_string: Schema.optional(Schema.String),
  command: Schema.optional(Schema.String),
  description: Schema.optional(Schema.String),
}).pipe(Schema.extend(Schema.Record({ key: Schema.String, value: Schema.Unknown })));

export const PreToolUseInputSchema = Schema.Struct({
  hook_event_name: Schema.Literal('PreToolUse'),
  session_id: Schema.String,
  tool_name: Schema.String,
  tool_input: ToolInputSchema,
});

export type PreToolUseInput = typeof PreToolUseInputSchema.Type;

export const StopInputSchema = Schema.Struct({
  hook_event_name: Schema.Literal('Stop'),
  session_id: Schema.String,
  cwd: Schema.optional(Schema.String),
});

export type StopInput = typeof StopInputSchema.Type;

// =============================================================================
// File Exclusion Patterns (must match SSOT at config/agents/hooks/lib/types.ts)
// =============================================================================

export const EXCLUDED_PATTERNS: readonly RegExp[] = [
  /\.test\.[jt]sx?$/,
  /\.spec\.[jt]sx?$/,
  /\.d\.ts$/,
  /\/api\/.*\.[jt]s$/, // API boundary files
  /-client\.[jt]s$/, // Client boundary files
  /\.schema\.[jt]s$/, // Schema files
  /\/schemas\//, // Schema directories
  /\/parsers\//, // Parser directories
  /-guard\.[jt]s$/, // Guard files themselves
  /\/node_modules\//,
  /\.stories\.[jt]sx?$/,
  /\/mocks?\//,
  /\/hooks\//, // Hook scripts are entry points that need env access
];

export const isExcludedPath = (filePath: string): boolean =>
  EXCLUDED_PATTERNS.some((pattern) => pattern.test(filePath));

export const isTypeScriptFile = (filePath: string): boolean =>
  /\.[jt]sx?$/.test(filePath) && !filePath.endsWith('.d.ts');

// =============================================================================
// Hook Execution
// =============================================================================

export const readStdin = Effect.gen(function* () {
  const chunks: Buffer[] = [];
  const stdin = process.stdin;

  yield* Effect.async<string, Error>((resume) => {
    stdin.on('data', (chunk: Buffer | string) => {
      if (typeof chunk === 'string') {
        chunks.push(Buffer.from(chunk));
      } else {
        chunks.push(chunk);
      }
    });
    stdin.on('end', () => resume(Effect.succeed(Buffer.concat(chunks).toString())));
    stdin.on('error', (err) => resume(Effect.fail(err)));
  });

  return Buffer.concat(chunks).toString();
});

export const parseInput = (raw: string) =>
  Effect.gen(function* () {
    const json = yield* Effect.try({
      try: () => JSON.parse(raw),
      catch: () => new Error('Invalid JSON input'),
    });
    return yield* Schema.decodeUnknown(PreToolUseInputSchema)(json);
  });

export const outputDecision = (decision: HookDecision) =>
  Effect.gen(function* () {
    yield* Console.log(JSON.stringify(decision));
  });

export const approve = (reason?: string): HookDecision =>
  reason !== undefined ? { decision: 'approve', reason } : { decision: 'approve' };

export const block = (reason: string): HookDecision => ({
  decision: 'block',
  reason,
});

export const skip = (reason?: string): HookDecision =>
  reason !== undefined ? { decision: 'skip', reason } : { decision: 'skip' };
