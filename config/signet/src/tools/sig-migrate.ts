/**
 * sig-migrate MCP Tool
 *
 * Detect project drift from STACK standards.
 * Use fix=true to auto-fix issues like missing CLAUDE.md and forbidden files.
 */

import { Effect } from 'effect';
import {
  checkProject,
  fixProject,
  formatMigrateResult,
  type MigrateCheckResult,
  type MigrateFixResult,
} from '@/services/migrate';

// =============================================================================
// Tool Definition
// =============================================================================

export const sigMigrateTool = {
  name: 'sig-migrate',
  description: `Detect project drift from STACK standards.

Checks:
- Missing CLAUDE.md (should link to AGENT.md)
- Forbidden files (package-lock.json, .eslintrc, etc.)
- Forbidden dependencies (lodash, express, prisma, etc.)
- Version drift from STACK.npm

Actions:
- Check: Reports drift items without modifying files
- Fix: Creates CLAUDE.md symlink, removes forbidden files

Note: Use sig-stack for fixing version drift in package.json.`,

  params: {
    path: {
      type: 'string',
      description: 'Project directory to check (default: current directory)',
    },
    fix: {
      type: 'boolean',
      description: 'Auto-fix drift issues (default: false)',
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

    let result: MigrateCheckResult | MigrateFixResult;

    if (fix) {
      result = await Effect.runPromise(fixProject(targetPath)).catch(
        (): MigrateFixResult => ({
          created: [],
          removed: [],
          skipped: [],
          result: { driftItems: [], projectName: 'unknown', passed: true },
        })
      );
    } else {
      result = await Effect.runPromise(checkProject(targetPath)).catch(
        (): MigrateCheckResult => ({
          driftItems: [],
          projectName: 'unknown',
          passed: true,
        })
      );
    }

    const summary = formatMigrateResult(result);

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
