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
import { z } from 'zod';
import { existsSync } from 'fs';

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

  let input;
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
    // BLOCK: Unverified claims exist
    const claimsList = unverified.map((c) => `  - [${c.claim_type}] ${c.claim_text}`).join('\n');

    console.log(
      JSON.stringify({
        continue: false,
        reason: `BLOCKED: ${unverified.length} unverified claim(s) require proof:

${claimsList}

To unblock, either:
  1. Use /verify "[claim]" to verify with test evidence
  2. Mark as UNVERIFIED with explanation

Verification format:
  ✅ VERIFIED: [claim]
     Test: [test_file]:[test_name]
     Output: [relevant test output]`,
      })
    );
    return;
  }

  console.log(JSON.stringify({ continue: true }));
}

main().catch((e) => {
  console.error('Verification Gate error:', e);
  // On error, allow continuation to avoid blocking
  console.log(JSON.stringify({ continue: true }));
});
