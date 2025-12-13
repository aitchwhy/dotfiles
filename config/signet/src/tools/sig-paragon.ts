/**
 * sig-paragon MCP Tool
 *
 * PARAGON compliance verification - runs pattern checks with PARAGON branding.
 * This is an alias for sig-verify patterns tier with PARAGON-specific output.
 */

import { Effect } from 'effect';
import { runVerification, type VerificationResult } from '@/verification/index';

// =============================================================================
// PARAGON Guard Matrix (for reference in output)
// =============================================================================

const PARAGON_GUARDS = `
PARAGON Guard Matrix (14 guards):
┌─────┬──────────────────────┬─────────────┐
│ #   │ Guard                │ Severity    │
├─────┼──────────────────────┼─────────────┤
│  1  │ Bash Safety          │ BLOCKING    │
│  2  │ Conventional Commits │ BLOCKING    │
│  3  │ Forbidden Files      │ BLOCKING    │
│  4  │ Forbidden Imports    │ BLOCKING    │
│  5  │ No Any Type          │ BLOCKING    │
│  6  │ No z.infer           │ BLOCKING    │
│  7  │ No Mock Patterns     │ BLOCKING    │
│  8  │ TDD Enforcement      │ BLOCKING    │
│  9  │ No DevOps Files      │ BLOCKING    │
│ 10  │ No DevOps Commands   │ BLOCKING    │
│ 11  │ Flake Patterns       │ Advisory    │
│ 12  │ Port Registry        │ Advisory    │
│ 13  │ Assumption Language  │ BLOCKING    │
│ 14  │ Throw Detector       │ Advisory    │
└─────┴──────────────────────┴─────────────┘
`;

// =============================================================================
// Tool Definition
// =============================================================================

export const sigParagonTool = {
  name: 'sig-paragon',
  description: `PARAGON compliance verification. Runs AST-based pattern checks.

Checks for:
- Guard 5: Any type usage (: any, as any)
- Guard 6: z.infer<> patterns (use satisfies instead)
- Guard 7: Mock patterns (jest.mock, vi.mock)
- Guard 13: Assumption language ("should work", "probably")
- Guard 14: Throw statements (prefer Result/Effect)

Plus: ts-ignore, console.log, debugger, empty catch blocks.

Exit codes:
- 0: PARAGON COMPLIANT
- 1: Warnings only (continue)
- 2: Violations found (BLOCKING)`,

  params: {
    path: {
      type: 'string',
      description: 'Path to verify (default: current directory)',
    },
    verbose: {
      type: 'boolean',
      description: 'Show guard matrix and detailed output (default: false)',
    },
  },

  handler: async (args: {
    path?: string;
    verbose?: boolean;
  }): Promise<{ content: Array<{ type: 'text'; text: string }> }> => {
    const targetPath = args.path ?? '.';
    const verbose = args.verbose ?? false;

    // Run only patterns tier (PARAGON checks)
    const program = runVerification({
      path: targetPath,
      tiers: ['patterns'],
      fix: false,
      verbose: verbose,
    });

    const result = await Effect.runPromise(program).catch(
      (): VerificationResult => ({
        passed: false,
        totalErrors: 1,
        totalWarnings: 0,
        tierResults: [
          {
            tier: 'patterns',
            passed: false,
            errors: 1,
            warnings: 0,
            details: ['Verification failed unexpectedly'],
            duration: 0,
          },
        ],
        duration: 0,
      })
    );

    // Format PARAGON-branded output
    const tierResult = result.tierResults[0];
    const status = result.passed
      ? result.totalWarnings > 0
        ? '⚠️  PARAGON: WARNINGS'
        : '✅ PARAGON COMPLIANT'
      : '❌ PARAGON VIOLATION';

    const exitCode = result.passed ? (result.totalWarnings > 0 ? 1 : 0) : 2;

    const lines: string[] = [
      '═══════════════════════════════════════════════════════════',
      '  PARAGON Compliance Check',
      '═══════════════════════════════════════════════════════════',
      '',
      `Status: ${status}`,
      `Path: ${targetPath}`,
      `Duration: ${result.duration}ms`,
      '',
      `Errors: ${result.totalErrors}`,
      `Warnings: ${result.totalWarnings}`,
      '',
    ];

    // Add details if any
    if (tierResult && tierResult.details.length > 0) {
      lines.push('Details:');
      for (const detail of tierResult.details.slice(0, 15)) {
        lines.push(`  ${detail}`);
      }
      if (tierResult.details.length > 15) {
        lines.push(`  ... and ${tierResult.details.length - 15} more`);
      }
      lines.push('');
    }

    // Add guard matrix if verbose
    if (verbose) {
      lines.push(PARAGON_GUARDS);
    }

    lines.push('═══════════════════════════════════════════════════════════');
    lines.push(`Exit code: ${exitCode}${exitCode === 2 ? ' (BLOCKING)' : ''}`);
    lines.push('═══════════════════════════════════════════════════════════');

    return {
      content: [
        {
          type: 'text' as const,
          text: lines.join('\n'),
        },
      ],
    };
  },
};
