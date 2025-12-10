/**
 * Signet MCP Server
 *
 * Exposes the `sig-verify` tool for automatic Claude Code invocation.
 * Hard gate: failures block generation (exit code 2).
 *
 * Run: bun run src/mcp-server.ts
 */
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { Effect } from 'effect';
import {
  ALL_TIERS,
  formatVerificationResult,
  runVerification,
  type TierName,
  type VerificationResult,
} from '@/verification/index';

// =============================================================================
// MCP Server Setup
// =============================================================================

const server = new McpServer({
  name: 'signet',
  version: '2.0.0',
});

// =============================================================================
// sig-verify Tool (using JSON Schema instead of Zod due to version conflict)
// =============================================================================

server.tool(
  'sig-verify',
  `Run 5-tier verification on a codebase. Hard gate - failures block generation.

Tiers:
1. patterns  - AST drift detection, code smells (any, ts-ignore, etc.)
2. formal    - Branded types, satisfies patterns, property tests (info only)
3. execution - TypeScript check, Biome lint, test suite
4. review    - Multi-agent code review (future: Claude API)
5. context   - Hexagonal architecture, circular deps, layer violations

Exit codes:
- 0: All pass
- 1: Warnings (continue)
- 2: Errors (BLOCK generation)`,
  {
    path: {
      type: 'string',
      description: 'Path to verify (default: current directory)',
    },
    tiers: {
      type: 'string',
      description:
        'Comma-separated tiers to run (default: all). Options: patterns,formal,execution,review,context',
    },
    fix: {
      type: 'boolean',
      description: 'Auto-fix fixable issues (default: false)',
    },
    verbose: {
      type: 'boolean',
      description: 'Show detailed output (default: false)',
    },
  },
  async ({
    path,
    tiers,
    fix,
    verbose,
  }: {
    path?: string;
    tiers?: string;
    fix?: boolean;
    verbose?: boolean;
  }) => {
    const targetPath = path ?? '.';

    // Parse tiers
    const selectedTiers: TierName[] = tiers
      ? (tiers.split(',').map((s: string) => s.trim()) as TierName[]).filter((t) =>
          ALL_TIERS.includes(t)
        )
      : [...ALL_TIERS];

    // Run verification via Effect
    const program = runVerification({
      path: targetPath,
      tiers: selectedTiers,
      fix: fix ?? false,
      verbose: verbose ?? false,
    });

    const result = await Effect.runPromise(program).catch(
      (error): VerificationResult => ({
        passed: false,
        totalErrors: 1,
        totalWarnings: 0,
        tierResults: [
          {
            tier: 'execution',
            passed: false,
            errors: 1,
            warnings: 0,
            details: [
              `Verification failed: ${error instanceof Error ? error.message : String(error)}`,
            ],
            duration: 0,
          },
        ],
        duration: 0,
      })
    );

    // Format summary
    const summary = formatVerificationResult(result);

    // Determine exit code
    const exitCode = result.passed ? (result.totalWarnings > 0 ? 1 : 0) : 2;

    // Return text content for Claude
    return {
      content: [
        {
          type: 'text' as const,
          text: `${summary}\n\nExit code: ${exitCode}${exitCode === 2 ? ' (BLOCKING)' : ''}`,
        },
      ],
    };
  }
);

// =============================================================================
// Start Server
// =============================================================================

const transport = new StdioServerTransport();
await server.connect(transport);
