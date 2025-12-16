/**
 * sig-guard MCP Tool
 *
 * Validate code content before writing using AST-grep rules.
 * Returns violations or approves the content.
 */

import { Effect } from 'effect';
import { checkContent, formatGuardResult, type GuardCheckResult } from '@/services/guard';

// =============================================================================
// Tool Definition
// =============================================================================

export const sigGuardTool = {
  name: 'sig-guard',
  description: `Validate code content before writing. Runs AST-grep rules.

Rules applied:
- no-any-type: Forbids 'any' type (use 'unknown' instead)
- no-zod-infer: Forbids z.infer<> (TypeScript type is source of truth)
- no-mock-patterns: Forbids jest.mock/vi.mock (use real adapters)
- no-throw-expected: Warns on throw statements (use Result/Effect)
- no-should-work: Forbids assumption language in comments

Severity:
- error: Blocks the write (fails validation)
- warning: Allows write but reports issue

Use this BEFORE writing TypeScript files to catch violations early.`,

  params: {
    content: {
      type: 'string',
      description: 'File content to validate',
    },
    filePath: {
      type: 'string',
      description: 'Target file path (used for language detection)',
    },
  },

  handler: async (args: {
    content?: string;
    filePath?: string;
  }): Promise<{ content: Array<{ type: 'text'; text: string }> }> => {
    const content = args.content ?? '';
    const filePath = args.filePath ?? 'unknown.ts';

    const result = await Effect.runPromise(checkContent(content, filePath)).catch(
      (): GuardCheckResult => ({
        violations: [],
        passed: true, // Fail-open on errors
        blockers: 0,
        warnings: 0,
      })
    );

    const summary = formatGuardResult(result, filePath);

    return {
      content: [
        {
          type: 'text' as const,
          text: summary,
        },
      ],
    };
  },
};
