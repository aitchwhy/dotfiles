/**
 * Shared types for PARAGON hooks
 *
 * TypeScript types are source of truth - using Effect Schema (not Zod)
 * All decoders return Effect, never throw.
 */

import { Schema } from "effect";

// =============================================================================
// Hook Protocol Types
// =============================================================================

export type HookDecision =
  | { readonly decision: 'approve'; readonly reason?: string }
  | { readonly decision: 'block'; readonly reason: string }
  | { readonly decision: 'skip'; readonly reason?: string };

export type GuardResultOk = { readonly ok: true; readonly warnings?: readonly string[] };
export type GuardResultError = { readonly ok: false; readonly error: string };
export type GuardResult = GuardResultOk | GuardResultError;

// =============================================================================
// Hook Input Schema (Effect Schema)
// =============================================================================

const ToolInputSchema = Schema.Struct({
  file_path: Schema.optional(Schema.String),
  content: Schema.optional(Schema.String),
  new_string: Schema.optional(Schema.String),
  command: Schema.optional(Schema.String),
  description: Schema.optional(Schema.String),
}).pipe(Schema.extend(Schema.Record({ key: Schema.String, value: Schema.Unknown })));

export const PreToolUseInputSchema = Schema.Struct({
  hook_event_name: Schema.Literal("PreToolUse"),
  session_id: Schema.String,
  tool_name: Schema.String,
  tool_input: ToolInputSchema,
});

export type PreToolUseInput = typeof PreToolUseInputSchema.Type;

export const StopInputSchema = Schema.Struct({
  hook_event_name: Schema.Literal("Stop"),
  session_id: Schema.String,
  cwd: Schema.optional(Schema.String),
});

export type StopInput = typeof StopInputSchema.Type;

export const GenericHookInputSchema = Schema.Struct({
  hook_event_name: Schema.String,
  session_id: Schema.String,
});

export type GenericHookInput = typeof GenericHookInputSchema.Type;

// =============================================================================
// Decoders (return Effect, never throw)
// =============================================================================

export const decodePreToolUseInput = Schema.decodeUnknown(PreToolUseInputSchema);
export const decodeStopInput = Schema.decodeUnknown(StopInputSchema);
export const decodeGenericHookInput = Schema.decodeUnknown(GenericHookInputSchema);

// Legacy alias for backward compatibility during migration
export const HookInputSchema = PreToolUseInputSchema;
export type HookInput = PreToolUseInput;

// =============================================================================
// Guard Context
// =============================================================================

export type GuardContext = {
  readonly toolName: string;
  readonly filePath: string | undefined;
  readonly content: string | undefined;
  readonly command: string | undefined;
};

// =============================================================================
// File Exclusion Patterns
// =============================================================================

export const EXCLUDED_PATTERNS: readonly RegExp[] = [
  /\.test\.tsx?$/,
  /\.spec\.tsx?$/,
  /\.d\.ts$/,
  /\/api\/.*\.ts$/, // API boundary files
  /-client\.ts$/, // Client boundary files
  /\.schema\.ts$/, // Schema files
  /\/schemas\//, // Schema directories
  /\/parsers\//, // Parser directories
  /-guard\.ts$/, // Guard files themselves
  /\/sig-.*\.ts$/, // Signet tools
  /\/node_modules\//,
  /\.stories\.tsx?$/,
  /\/mocks?\//,
];

export function isExcludedPath(filePath: string): boolean {
  return EXCLUDED_PATTERNS.some((pattern) => pattern.test(filePath));
}

export function isTypeScriptFile(filePath: string): boolean {
  return /\.[jt]sx?$/.test(filePath) && !filePath.endsWith('.d.ts');
}

export function isNixFile(filePath: string): boolean {
  return filePath.endsWith('.nix');
}
