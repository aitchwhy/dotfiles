#!/usr/bin/env bun
/**
 * DevOps Enforcer - Enforces Nix-first DevOps philosophy
 *
 * Guards:
 * 1. Forbidden files - blocks docker-compose.yml, Dockerfile, .dockerignore
 * 2. Forbidden commands - blocks docker-compose, docker build, npm/bun run dev
 *
 * Allows:
 * - process-compose commands
 * - nix build/run/develop
 * - npm/bun run build|test|lint|typecheck
 *
 * Philosophy: localhost === CI === production
 * - Local dev: process-compose
 * - Builds: nix build
 * - Containers: nix2container
 * - CI/CD: GHA + nix
 */

import { z } from 'zod';

// ============================================================================
// Input Types (TypeScript first, schema satisfies type)
// ============================================================================

type HookInput = {
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

const HookInputSchema = z.object({
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

// ============================================================================
// Output Helpers
// ============================================================================

function allow(): void {
  console.log(JSON.stringify({ decision: 'approve' }));
}

function block(reason: string): void {
  console.log(JSON.stringify({ decision: 'block', reason }));
}

// ============================================================================
// 1. FORBIDDEN FILES
// ============================================================================

interface ForbiddenFile {
  pattern: string | RegExp;
  reason: string;
  alternative: string;
}

const FORBIDDEN_FILES: ForbiddenFile[] = [
  {
    pattern: /^docker-compose\.(ya?ml)$/,
    reason: 'Use process-compose for local orchestration',
    alternative: 'process-compose.yaml',
  },
  {
    pattern: /^Dockerfile(\..*)?$/,
    reason: 'Use nix2container for OCI images',
    alternative: 'nix build .#container-<name>',
  },
  {
    pattern: '.dockerignore',
    reason: 'Not needed with nix2container',
    alternative: 'Nix handles build context automatically',
  },
];

function checkForbiddenFiles(filePath: string): string | null {
  const fileName = filePath.split('/').pop() || '';

  for (const forbidden of FORBIDDEN_FILES) {
    const matches =
      typeof forbidden.pattern === 'string'
        ? fileName === forbidden.pattern || filePath.endsWith(`/${forbidden.pattern}`)
        : forbidden.pattern.test(fileName);

    if (matches) {
      return `DEVOPS VIOLATION: ${fileName}

Reason: ${forbidden.reason}
Alternative: ${forbidden.alternative}

Philosophy: localhost === CI === production
- Local dev: process-compose (NOT docker-compose)
- Containers: nix2container (NOT Dockerfile)

See: devops-patterns skill for correct approach.`;
    }
  }
  return null;
}

// ============================================================================
// 2. FORBIDDEN COMMANDS
// ============================================================================

interface ForbiddenCommand {
  pattern: RegExp;
  description: string;
  alternative: string;
}

const FORBIDDEN_COMMANDS: ForbiddenCommand[] = [
  // Docker Compose commands
  {
    pattern: /\bdocker-compose\s+(up|start|run|exec|build)\b/,
    description: 'docker-compose',
    alternative: 'process-compose up',
  },
  {
    pattern: /\bdocker\s+compose\s+(up|start|run|exec|build)\b/,
    description: 'docker compose',
    alternative: 'process-compose up',
  },
  // Docker build
  {
    pattern: /\bdocker\s+build\b/,
    description: 'docker build',
    alternative: 'nix build .#container-<name>',
  },
  // npm/bun/yarn/pnpm run dev|start|serve
  {
    pattern: /\b(npm|bun|yarn|pnpm)\s+run\s+(dev|start|serve)\b/,
    description: 'npm/bun/yarn/pnpm run dev|start|serve',
    alternative: 'process-compose up',
  },
  // Direct invocations (npm start, bun dev, etc.)
  {
    pattern: /\bnpm\s+start\b/,
    description: 'npm start',
    alternative: 'process-compose up',
  },
];

function checkForbiddenCommands(command: string): string | null {
  for (const forbidden of FORBIDDEN_COMMANDS) {
    if (forbidden.pattern.test(command)) {
      return `DEVOPS VIOLATION: ${forbidden.description} detected

Alternative: ${forbidden.alternative}

Philosophy: localhost === CI === production
- Use process-compose for local development orchestration
- All services defined in process-compose.yaml
- Run: process-compose up (all) or process-compose up <service>

See: devops-patterns skill for correct approach.`;
    }
  }
  return null;
}

// ============================================================================
// Main Hook Logic
// ============================================================================

async function main(): Promise<void> {
  let rawInput: string;
  try {
    rawInput = await Bun.stdin.text();
  } catch {
    allow(); // Fail-safe
    return;
  }

  // Empty input = allow
  if (!rawInput.trim()) {
    allow();
    return;
  }

  let input: HookInput;
  try {
    input = HookInputSchema.parse(JSON.parse(rawInput));
  } catch {
    allow(); // Fail-safe: invalid JSON = allow
    return;
  }

  const { tool_name, tool_input } = input;
  const filePath = tool_input.file_path || '';
  const command = tool_input.command || '';

  // ─────────────────────────────────────────────────────────────────────────
  // 1. FORBIDDEN FILES (for Write/Edit commands)
  // ─────────────────────────────────────────────────────────────────────────
  if ((tool_name === 'Write' || tool_name === 'Edit') && filePath) {
    const fileError = checkForbiddenFiles(filePath);
    if (fileError) {
      block(fileError);
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. FORBIDDEN COMMANDS (for Bash commands)
  // ─────────────────────────────────────────────────────────────────────────
  if (tool_name === 'Bash' && command) {
    const commandError = checkForbiddenCommands(command);
    if (commandError) {
      block(commandError);
      return;
    }
  }

  // All checks passed
  allow();
}

main().catch((e) => {
  console.error('DevOps Enforcer error:', e);
  allow(); // Fail-open on error
});
