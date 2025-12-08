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
 */

import { Database } from 'bun:sqlite';
import { existsSync } from 'node:fs';
import { z } from 'zod';

// Hook input schema matching Claude Code's Stop event
const HookInputSchema = z.object({
  hook_event_name: z.string(),
  session_id: z.string(),
});

const DB_PATH = `${process.env.HOME}/.claude-metrics/evolution.db`;

interface UnverifiedClaim {
  id: number;
  claim_text: string;
  claim_type: string;
}

async function getUnverifiedClaims(sessionId: string): Promise<UnverifiedClaim[]> {
  // Check if database exists
  if (!existsSync(DB_PATH)) {
    return [];
  }

  try {
    const db = new Database(DB_PATH, { readonly: true });

    // Check if table exists
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
  } catch {
    // Database error - return empty to avoid blocking
    return [];
  }
}

async function main() {
  let rawInput: string;
  try {
    rawInput = await Bun.stdin.text();
  } catch {
    console.log(JSON.stringify({ continue: true }));
    return;
  }

  let input: z.infer<typeof HookInputSchema>;
  try {
    input = HookInputSchema.parse(JSON.parse(rawInput));
  } catch {
    // Invalid input - allow continuation
    console.log(JSON.stringify({ continue: true }));
    return;
  }

  // Only gate Stop events
  if (input.hook_event_name !== 'Stop') {
    console.log(JSON.stringify({ continue: true }));
    return;
  }

  // Query for unverified claims
  const unverified = await getUnverifiedClaims(input.session_id);

  if (unverified.length > 0) {
    // BLOCK: Use exit code 2 (blocking error) with stderr
    // Exit code 2 is Claude Code's signal for "blocking error"
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

    console.error(errorMsg);
    process.exit(2);
  }

  console.log(JSON.stringify({ continue: true }));
}

main().catch((e) => {
  console.error('Verification Gate error:', e);
  // On error, allow continuation to avoid blocking (fail-safe)
  console.log(JSON.stringify({ continue: true }));
  process.exit(0);
});
