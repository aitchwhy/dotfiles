/**
 * Shared types for PARAGON hooks
 *
 * TypeScript types are source of truth (never z.infer)
 */

import { z } from 'zod';

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
// Hook Input Types
// =============================================================================

export type HookInput = {
  readonly hook_event_name: 'PreToolUse';
  readonly session_id: string;
  readonly tool_name: string;
  readonly tool_input: {
    readonly file_path?: string;
    readonly content?: string;
    readonly new_string?: string;
    readonly command?: string;
    readonly [key: string]: unknown;
  };
};

export const HookInputSchema = z.object({
  hook_event_name: z.literal('PreToolUse'),
  session_id: z.string(),
  tool_name: z.string(),
  tool_input: z
    .object({
      file_path: z.string().optional(),
      content: z.string().optional(),
      new_string: z.string().optional(),
      command: z.string().optional(),
    })
    .passthrough(),
}) satisfies z.ZodType<HookInput>;

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
