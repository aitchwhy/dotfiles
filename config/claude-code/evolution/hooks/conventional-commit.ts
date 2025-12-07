#!/usr/bin/env bun
/**
 * Conventional Commit Hook - Validates commit message format
 *
 * Trigger: PreToolUse on Bash (git commit commands)
 * Mode: Strict (Block)
 *
 * Validates commit messages match: type(scope): description
 * Valid types: feat, fix, refactor, test, docs, chore, perf, ci
 */

import { z } from 'zod';

// Hook input schema
const HookInputSchema = z.object({
  hook_event_name: z.literal('PreToolUse'),
  session_id: z.string(),
  tool_name: z.string(),
  tool_input: z
    .object({
      command: z.string().optional(),
    })
    .passthrough(),
});

// ============================================================================
// Conventional Commit Patterns
// ============================================================================

const VALID_TYPES = ['feat', 'fix', 'refactor', 'test', 'docs', 'chore', 'perf', 'ci'];

// Matches: type(scope): description or type: description
// Allows optional ! for breaking changes
const CONVENTIONAL_COMMIT_REGEX =
  /^(feat|fix|refactor|test|docs|chore|perf|ci)(\([a-z0-9-]+\))?!?:\s+\S/;

// ============================================================================
// Command Parsing
// ============================================================================

function isGitCommitWithMessage(command: string): boolean {
  // Match git commit with -m flag
  return /git\s+commit\s+.*-m\s+/.test(command);
}

function extractCommitMessage(command: string): string | null {
  // Try to match -m "message" or -m 'message'
  const doubleQuoteMatch = command.match(/git\s+commit\s+.*-m\s+"([^"]+)"/);
  if (doubleQuoteMatch) return doubleQuoteMatch[1] || null;

  const singleQuoteMatch = command.match(/git\s+commit\s+.*-m\s+'([^']+)'/);
  if (singleQuoteMatch) return singleQuoteMatch[1] || null;

  // Try heredoc pattern: git commit -m "$(cat <<'EOF'\nmessage\nEOF\n)"
  const heredocMatch = command.match(
    /git\s+commit\s+.*-m\s+"\$\(cat\s+<<['"]?(\w+)['"]?\n([\s\S]*?)\n\1/
  );
  if (heredocMatch) {
    // Get first line of heredoc (the actual commit message)
    const heredocContent = heredocMatch[2];
    if (heredocContent) {
      const firstLine = heredocContent.trim().split('\n')[0];
      return firstLine || null;
    }
  }

  return null;
}

function isValidConventionalCommit(message: string): boolean {
  return CONVENTIONAL_COMMIT_REGEX.test(message);
}

// ============================================================================
// Main Hook Logic
// ============================================================================

async function main() {
  let rawInput: string;
  try {
    rawInput = await Bun.stdin.text();
  } catch {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  let input: z.infer<typeof HookInputSchema>;
  try {
    input = HookInputSchema.parse(JSON.parse(rawInput));
  } catch {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // Only check Bash tool
  if (input.tool_name !== 'Bash') {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  const command = input.tool_input.command;
  if (!command) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // Only check git commit commands with -m flag
  if (!isGitCommitWithMessage(command)) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  const message = extractCommitMessage(command);
  if (!message) {
    // Could not extract message, might be using editor - allow
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  if (isValidConventionalCommit(message)) {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  // BLOCK: Invalid commit message
  console.log(
    JSON.stringify({
      decision: 'block',
      reason: `CONVENTIONAL COMMIT VIOLATION

Invalid: '${message.substring(0, 50)}${message.length > 50 ? '...' : ''}'

Expected format: type(scope): description

Valid types: ${VALID_TYPES.join(', ')}

Examples:
  feat(auth): add OAuth2 login
  fix(api): handle null response
  refactor(db): extract query builder
  docs: update README
  chore: update dependencies

Breaking changes: add ! before colon
  feat!: breaking change
  fix(auth)!: breaking fix`,
    })
  );
}

main().catch((e) => {
  console.error('Conventional Commit error:', e);
  console.log(JSON.stringify({ decision: 'allow' }));
});
