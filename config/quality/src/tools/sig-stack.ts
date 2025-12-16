/**
 * sig-stack MCP Tool
 *
 * Check package.json files for stack compliance (versions, forbidden deps).
 * Use fix=true to auto-correct version drift.
 */

import { Effect } from 'effect';
import {
  checkAll,
  fixVersions,
  formatStackResult,
  type StackCheckResult,
  type StackFixResult,
} from '@/services/stack';

// =============================================================================
// Tool Definition
// =============================================================================

export const sigStackTool = {
  name: 'sig-stack',
  description: `Check stack compliance (versions, forbidden deps). Use fix=true to auto-correct.

Checks:
- Forbidden dependencies (lodash, express, prisma, etc.)
- Version drift from STACK.npm (zod, effect, hono, etc.)

Actions:
- Check: Reports violations without modifying files
- Fix: Auto-corrects version drift in package.json files

Exit behavior:
- Returns structured report with violations
- Forbidden deps cannot be auto-fixed (manual removal required)`,

  params: {
    path: {
      type: 'string',
      description: 'Directory to check (default: current directory)',
    },
    fix: {
      type: 'boolean',
      description: 'Auto-correct version drift in package.json files (default: false)',
    },
  },

  handler: async ({
    path,
    fix,
  }: {
    path?: string;
    fix?: boolean;
  }): Promise<{ content: Array<{ type: 'text'; text: string }> }> => {
    const targetPath = path ?? '.';

    let result: StackCheckResult | StackFixResult;

    if (fix) {
      result = await Effect.runPromise(fixVersions(targetPath)).catch(
        (): StackFixResult => ({
          fixed: [],
          skipped: [],
          result: { violations: [], filesChecked: 0, passed: true },
        })
      );
    } else {
      result = await Effect.runPromise(checkAll(targetPath)).catch(
        (): StackCheckResult => ({
          violations: [],
          filesChecked: 0,
          passed: true,
        })
      );
    }

    const summary = formatStackResult(result);

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
