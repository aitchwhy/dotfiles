#!/usr/bin/env bun
/**
 * Assumption Detector Hook - BLOCKS completion with "should" language
 *
 * Trigger: Stop event
 * Mode: Block Completion - User chose hard enforcement
 *
 * Scans session transcript for banned assumption language and blocks
 * completion if high-severity patterns are found.
 *
 * Banned patterns (high severity = block):
 * - "should now" / "should work" / "should be"
 * - "this should/will fix"
 * - "will now have/work/be"
 */

import { Database } from 'bun:sqlite';
import { existsSync, readFileSync } from 'node:fs';
import { z } from 'zod';

// Hook input schema matching Claude Code's Stop event
const HookInputSchema = z.object({
  hook_event_name: z.literal('Stop'),
  session_id: z.string(),
  transcript_path: z.string().optional(),
});

const DB_PATH = `${process.env.HOME}/.claude-metrics/evolution.db`;

// Assumption patterns with severity levels
// High severity = BLOCK completion
// Medium/Low = Log warning only
const PATTERNS = [
  // High severity - BLOCK these
  { pattern: /should now (?:have|work|be|fix)/gi, severity: 'high' as const },
  { pattern: /should work/gi, severity: 'high' as const },
  { pattern: /this (?:should|will) fix/gi, severity: 'high' as const },
  { pattern: /will now (?:have|work|be)/gi, severity: 'high' as const },
  { pattern: /this fixes/gi, severity: 'high' as const },

  // Medium severity - Log but don't block
  { pattern: /probably (?:works?|fixed|correct)/gi, severity: 'medium' as const },
  { pattern: /likely (?:works?|fixed|correct|resolved)/gi, severity: 'medium' as const },
  { pattern: /should be (?:fine|good|correct|ok)/gi, severity: 'medium' as const },

  // Low severity - Just log for analysis
  { pattern: /i (?:believe|think) (?:this|it) (?:will|should)/gi, severity: 'low' as const },
  { pattern: /assuming (?:this|it|that)/gi, severity: 'low' as const },
];

interface Assumption {
  text: string;
  severity: 'high' | 'medium' | 'low';
  context: string;
}

/**
 * Strip content that shouldn't be scanned for assumptions:
 * - Fenced code blocks (```...```)
 * - Inline code (`...`)
 * - Quoted strings ("..." or '...')
 * - JSON content (tool outputs, file contents)
 * - Meta-discussion about the patterns themselves
 * - Test file content and documentation
 *
 * This prevents false positives from:
 * - Documentation examples showing banned patterns
 * - Test file contents with "should work" assertions
 * - Code samples and configuration
 * - Discussion about what patterns are banned
 */
function stripExcludedContent(text: string): string {
  let result = text;

  // Remove fenced code blocks (```...```)
  result = result.replace(/```[\s\S]*?```/g, ' ');

  // Remove inline code (`...`)
  result = result.replace(/`[^`]+`/g, ' ');

  // Remove JSON objects/arrays (tool outputs)
  result = result.replace(/\{[\s\S]*?\}/g, ' ');
  result = result.replace(/\[[\s\S]*?\]/g, ' ');

  // Remove double-quoted strings (but keep surrounding context)
  result = result.replace(/"[^"]*"/g, ' ');

  // Remove single-quoted strings
  result = result.replace(/'[^']*'/g, ' ');

  // Remove lines that are meta-discussion about patterns (test descriptions, docs)
  // These patterns indicate we're DISCUSSING the rules, not violating them
  const metaPatterns = [
    /.*(?:blocks? on|detects?|bann(?:ed|ing)|pattern|severity|❌|✅|BLOCKED|VERIFIED|UNVERIFIED).*/gi,
    /.*(?:test|expect|assert|describe|it\(|test\().*/gi,
    /.*\.test\.ts.*/gi,
    /.*assumption-detector.*/gi,
  ];

  for (const pattern of metaPatterns) {
    result = result.replace(pattern, ' ');
  }

  return result;
}

function extractAssumptions(transcript: string): Assumption[] {
  const assumptions: Assumption[] = [];

  // Strip excluded content before scanning
  const cleanTranscript = stripExcludedContent(transcript);

  for (const { pattern, severity } of PATTERNS) {
    // Reset regex state for global patterns
    pattern.lastIndex = 0;
    for (const match of cleanTranscript.matchAll(pattern)) {
      const start = Math.max(0, match.index - 50);
      const end = Math.min(cleanTranscript.length, match.index + match[0].length + 50);
      const context = cleanTranscript.slice(start, end).replace(/\n/g, ' ').trim();

      assumptions.push({
        text: match[0],
        severity,
        context,
      });
    }
  }

  return assumptions;
}

async function logAssumptions(sessionId: string, assumptions: Assumption[]): Promise<void> {
  // Ensure database directory exists
  const dbDir = DB_PATH.replace(/\/[^/]+$/, '');
  if (!existsSync(dbDir)) {
    return; // Can't log if DB doesn't exist yet
  }

  if (!existsSync(DB_PATH)) {
    return; // Can't log if DB doesn't exist
  }

  try {
    const db = new Database(DB_PATH);
    const stmt = db.prepare(`
      INSERT INTO assumption_log (session_id, assumption_text, context, severity)
      VALUES (?, ?, ?, ?)
    `);

    for (const a of assumptions) {
      stmt.run(sessionId, a.text, a.context, a.severity);
    }
    db.close();
  } catch {
    // Silently fail if table doesn't exist yet
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

  // No transcript path provided
  if (!input.transcript_path) {
    console.log(JSON.stringify({ continue: true }));
    return;
  }

  // Read transcript
  let transcript: string;
  try {
    transcript = readFileSync(input.transcript_path, 'utf-8');
  } catch {
    // Can't read transcript - allow continuation
    console.log(JSON.stringify({ continue: true }));
    return;
  }

  // Extract assumptions from transcript
  const assumptions = extractAssumptions(transcript);

  if (assumptions.length > 0) {
    // Log all assumptions to database
    await logAssumptions(input.session_id, assumptions);

    // Check for high-severity assumptions
    const highSeverity = assumptions.filter((a) => a.severity === 'high');

    if (highSeverity.length > 0) {
      // BLOCK: Use exit code 2 (blocking error) with stderr
      // Exit code 2 is Claude Code's signal for "blocking error"
      const errorMsg = `BLOCKED: ${highSeverity.length} unverified assumption(s) detected:

${highSeverity.map((a) => `  ❌ "${a.text}"`).join('\n')}

Replace "should" with verified evidence:
  ✅ VERIFIED via [test]: [assertion passed]
  ⚠️ UNVERIFIED: [claim] - requires [test]

The phrase "should work" is banned. Only "verified" or "UNVERIFIED" are allowed.`;

      console.error(errorMsg);
      process.exit(2);
    }

    // Medium severity - warn but allow
    const mediumSeverity = assumptions.filter((a) => a.severity === 'medium');
    if (mediumSeverity.length > 0) {
      console.log(
        JSON.stringify({
          continue: true,
          warning: `⚠️  ${mediumSeverity.length} assumption(s) logged:
${mediumSeverity.map((a) => `  - "${a.text}"`).join('\n')}

Consider replacing with verified evidence next time.`,
        })
      );
      return;
    }
  }

  console.log(JSON.stringify({ continue: true }));
}

main().catch((e) => {
  console.error('Assumption Detector error:', e);
  // On error, allow continuation to avoid blocking (fail-safe)
  console.log(JSON.stringify({ continue: true }));
  process.exit(0);
});
