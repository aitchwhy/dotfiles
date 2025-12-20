#!/usr/bin/env bun
/**
 * Verification Gate Hook - BLOCKS completion with unverified claims
 *
 * Trigger: Stop event
 * Mode: Block Completion
 *
 * Queries the verification_claims table for pending claims and blocks
 * session completion if any exist. Claims must be verified via tests
 * or explicitly marked as UNVERIFIED.
 *
 * Full Effect pipeline - no try/catch.
 */

import { Effect, pipe } from "effect";
import { Database } from 'bun:sqlite';
import { existsSync } from 'node:fs';
import { emitContinue, logError, logWarning } from './lib/hook-logging';
import { decodeGenericHookInput, type GenericHookInput } from './lib/types';

const DB_PATH = `${process.env.HOME}/.claude-metrics/evolution.db`;

interface UnverifiedClaim {
  id: number;
  claim_text: string;
  claim_type: string;
}

// =============================================================================
// Database Query (Effect-wrapped)
// =============================================================================

const getUnverifiedClaims = (sessionId: string): Effect.Effect<UnverifiedClaim[], never, never> =>
  Effect.try({
    try: () => {
      if (!existsSync(DB_PATH)) {
        return [];
      }

      const db = new Database(DB_PATH, { readonly: true });

      const tableCheck = db
        .query("SELECT name FROM sqlite_master WHERE type='table' AND name='verification_claims'")
        .get();

      if (!tableCheck) {
        db.close();
        return [];
      }

      const claims = db
        .query(
          `
        SELECT id, claim_text, claim_type
        FROM verification_claims
        WHERE session_id = ? AND verification_status = 'pending'
      `
        )
        .all(sessionId) as UnverifiedClaim[];

      db.close();
      return claims;
    },
    catch: () => [] as UnverifiedClaim[], // Database error - return empty to avoid blocking
  }).pipe(Effect.catchAll(() => Effect.succeed([] as UnverifiedClaim[])));

// =============================================================================
// Read stdin
// =============================================================================

const readStdin = Effect.tryPromise({
  try: async () => {
    const text = await Bun.stdin.text();
    if (!text.trim()) return null;
    return JSON.parse(text);
  },
  catch: () => null,
});

// =============================================================================
// Main Program
// =============================================================================

const program = pipe(
  readStdin,
  Effect.flatMap((raw) => {
    if (raw === null) {
      emitContinue();
      return Effect.void;
    }
    return pipe(
      decodeGenericHookInput(raw),
      Effect.flatMap((input: GenericHookInput) => {
        // Only gate Stop events
        if (input.hook_event_name !== 'Stop') {
          emitContinue();
          return Effect.void;
        }

        return pipe(
          getUnverifiedClaims(input.session_id),
          Effect.tap((unverified) => {
            if (unverified.length > 0) {
              const claimsList = unverified.map((c) => `  - [${c.claim_type}] ${c.claim_text}`).join('\n');

              const errorMsg = `BLOCKED: ${unverified.length} unverified claim(s) require proof:

${claimsList}

To unblock, either:
  1. Use /verify "[claim]" to verify with test evidence
  2. Mark as UNVERIFIED with explanation

Verification format:
  ✅ VERIFIED: [claim]
     Test: [test_file]:[test_name]
     Output: [relevant test output]`;

              logWarning('verification-gate', errorMsg);
              process.exit(2);
            }

            emitContinue();
            return Effect.void;
          }),
        );
      }),
    );
  }),
  Effect.catchAll((error) => {
    logError('verification-gate', error);
    // On error, allow continuation to avoid blocking (fail-safe)
    emitContinue();
    return Effect.void;
  }),
);

// =============================================================================
// Execute
// =============================================================================

Effect.runPromise(program);
