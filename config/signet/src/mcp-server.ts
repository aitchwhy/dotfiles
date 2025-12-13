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
import { sigGuardTool, sigMigrateTool, sigParagonTool, sigStackTool } from '@/tools';
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
// sig-stack Tool
// =============================================================================

server.tool(sigStackTool.name, sigStackTool.description, sigStackTool.params, sigStackTool.handler);

// =============================================================================
// sig-guard Tool
// =============================================================================

server.tool(sigGuardTool.name, sigGuardTool.description, sigGuardTool.params, sigGuardTool.handler);

// =============================================================================
// sig-migrate Tool
// =============================================================================

server.tool(
  sigMigrateTool.name,
  sigMigrateTool.description,
  sigMigrateTool.params,
  sigMigrateTool.handler
);

// =============================================================================
// sig-paragon Tool (PARAGON-branded alias for patterns tier)
// =============================================================================

server.tool(
  sigParagonTool.name,
  sigParagonTool.description,
  sigParagonTool.params,
  sigParagonTool.handler
);

// =============================================================================
// sig-evolve Tool (Evolution system health check)
// =============================================================================

server.tool(
  'sig-evolve',
  `Check evolution system health. Returns score, trends, and action items.

Use this proactively at session start to understand codebase health.

Returns:
- score: 0-1 overall health score
- recommendation: ok | warning | urgent
- trend: stable | improving | declining
- action_items: Array of areas needing attention

Example response:
{
  "score": 0.85,
  "score_percent": 85,
  "recommendation": "ok",
  "trend": "stable",
  "alert_count": 0,
  "action_items": []
}`,
  {},
  async () => {
    const { exec } = await import('node:child_process');
    const { promisify } = await import('node:util');
    const execAsync = promisify(exec);

    try {
      const { stdout } = await execAsync(
        'bash ~/dotfiles/config/agents/evolution/evolve.sh --json',
        { timeout: 30000 }
      );

      const result = JSON.parse(stdout.trim());

      // Build human-readable summary
      const lines: string[] = [
        `Health Score: ${result.score_percent}% (${result.recommendation})`,
        `Trend: ${result.trend}`,
      ];

      if (result.week) {
        lines.push(`This Week: ${result.week.sessions} sessions, ${result.week.lessons} lessons, ${result.week.avg_score}% avg`);
      }

      if (result.memory) {
        lines.push(`Memory: ${result.memory.active} active, ${result.memory.archived} archived`);
      }

      if (result.alert_count > 0) {
        lines.push(`Alerts: ${result.alert_count}`);
      }

      if (result.action_items && result.action_items.length > 0) {
        lines.push('');
        lines.push('Action Items:');
        for (const item of result.action_items) {
          lines.push(`  - ${item}`);
        }
      }

      if (result.lessons && result.lessons.length > 0) {
        lines.push('');
        lines.push('Recent Lessons:');
        for (const lesson of result.lessons.slice(0, 3)) {
          lines.push(`  [${lesson.category}] ${lesson.text.slice(0, 60)}...`);
        }
      }

      return {
        content: [
          {
            type: 'text' as const,
            text: lines.join('\n'),
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text' as const,
            text: `Evolution check failed: ${error instanceof Error ? error.message : String(error)}`,
          },
        ],
      };
    }
  }
);

// =============================================================================
// sig-gc Tool (Nix Garbage Collection)
// =============================================================================

server.tool(
  'sig-gc',
  `Trigger Nix garbage collection manually.

Cleans up old generations and optimizes the Nix store.

Actions:
- Deletes paths older than 7 days
- Optimizes store (hardlinks identical files)

Use when:
- Disk space is low
- After many darwin-rebuild cycles
- Before major updates

Returns: Space freed and generations removed.`,
  {
    dryRun: {
      type: 'boolean',
      description: 'Show what would be deleted without actually deleting (default: false)',
    },
  },
  async ({ dryRun }: { dryRun?: boolean }) => {
    const { exec } = await import('node:child_process');
    const { promisify } = await import('node:util');
    const execAsync = promisify(exec);

    try {
      const lines: string[] = [];

      // Get current generation count
      const { stdout: genBefore } = await execAsync(
        'darwin-rebuild --list-generations 2>/dev/null | wc -l',
        { timeout: 10000 }
      );
      const genCountBefore = parseInt(genBefore.trim(), 10) || 0;

      // Get store size before (approximate)
      const { stdout: sizeBefore } = await execAsync(
        'df -h /nix/store | tail -1 | awk \'{print $3}\'',
        { timeout: 10000 }
      );

      if (dryRun) {
        lines.push('Dry run mode - showing what would be deleted:');
        const { stdout: dryRunOutput } = await execAsync(
          'nix-collect-garbage --delete-older-than 7d --dry-run 2>&1 | tail -20',
          { timeout: 60000 }
        );
        lines.push(dryRunOutput.trim());
      } else {
        lines.push('Running garbage collection...');

        // Run GC
        const { stdout: gcOutput } = await execAsync(
          'sudo nix-collect-garbage --delete-older-than 7d 2>&1 | tail -10',
          { timeout: 120000 }
        );
        lines.push(gcOutput.trim());

        // Optimize store
        lines.push('');
        lines.push('Optimizing store...');
        await execAsync('nix store optimise 2>&1', { timeout: 120000 });
        lines.push('Store optimized.');

        // Get final stats
        const { stdout: genAfter } = await execAsync(
          'darwin-rebuild --list-generations 2>/dev/null | wc -l',
          { timeout: 10000 }
        );
        const genCountAfter = parseInt(genAfter.trim(), 10) || 0;

        const { stdout: sizeAfter } = await execAsync(
          'df -h /nix/store | tail -1 | awk \'{print $3}\'',
          { timeout: 10000 }
        );

        lines.push('');
        lines.push(`Generations: ${genCountBefore} → ${genCountAfter} (${genCountBefore - genCountAfter} removed)`);
        lines.push(`Store size: ${sizeBefore.trim()} → ${sizeAfter.trim()}`);
      }

      return {
        content: [{ type: 'text' as const, text: lines.join('\n') }],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text' as const,
            text: `GC failed: ${error instanceof Error ? error.message : String(error)}`,
          },
        ],
      };
    }
  }
);

// =============================================================================
// sig-metrics Tool (Hook Performance Metrics)
// =============================================================================

server.tool(
  'sig-metrics',
  `Show PARAGON hook performance metrics.

Displays:
- Total checks performed
- Average latency by tool type
- Block rate (blocked vs approved)
- Slowest checks (>50ms)

Use to:
- Identify slow guards
- Monitor enforcement effectiveness
- Debug performance issues`,
  {},
  async () => {
    const { readFile } = await import('node:fs/promises');
    const { homedir } = await import('node:os');

    try {
      const metricsPath = `${homedir()}/.claude-metrics/perf.jsonl`;
      const content = await readFile(metricsPath, 'utf-8').catch(() => '');

      if (!content.trim()) {
        return {
          content: [
            { type: 'text' as const, text: 'No metrics recorded yet. Run some Claude Code sessions first.' },
          ],
        };
      }

      const lines = content.trim().split('\n');
      const metrics = lines.map((line) => {
        try {
          return JSON.parse(line);
        } catch {
          return null;
        }
      }).filter(Boolean);

      if (metrics.length === 0) {
        return {
          content: [{ type: 'text' as const, text: 'No valid metrics found.' }],
        };
      }

      // Analyze metrics
      const totalChecks = metrics.length;
      const blocked = metrics.filter((m) => m.result === 'block').length;
      const approved = metrics.filter((m) => m.result === 'approve').length;

      // Group by tool
      const byTool: Record<string, { count: number; totalMs: number }> = {};
      for (const m of metrics) {
        const tool = m.tool || 'unknown';
        if (!byTool[tool]) byTool[tool] = { count: 0, totalMs: 0 };
        byTool[tool].count++;
        byTool[tool].totalMs += m.duration_ms || 0;
      }

      // Find slow checks
      const slowChecks = metrics
        .filter((m) => (m.duration_ms || 0) > 50)
        .sort((a, b) => (b.duration_ms || 0) - (a.duration_ms || 0))
        .slice(0, 5);

      // Build report
      const report: string[] = [
        'PARAGON Guard Performance Report',
        '═════════════════════════════════',
        '',
        `Total checks: ${totalChecks}`,
        '',
        'Block rate:',
        `  Blocked: ${blocked} (${((blocked / totalChecks) * 100).toFixed(1)}%)`,
        `  Approved: ${approved} (${((approved / totalChecks) * 100).toFixed(1)}%)`,
        '',
        'Average latency by tool:',
      ];

      const sortedTools = Object.entries(byTool).sort((a, b) => b[1].count - a[1].count);
      for (const [tool, stats] of sortedTools) {
        const avgMs = (stats.totalMs / stats.count).toFixed(1);
        report.push(`  ${tool}: ${avgMs}ms avg (${stats.count} checks)`);
      }

      if (slowChecks.length > 0) {
        report.push('');
        report.push('Slowest checks (>50ms):');
        for (const check of slowChecks) {
          const file = (check.file || '').slice(-40);
          report.push(`  ${check.duration_ms}ms - ${check.tool} - ${file}`);
        }
      }

      return {
        content: [{ type: 'text' as const, text: report.join('\n') }],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text' as const,
            text: `Metrics retrieval failed: ${error instanceof Error ? error.message : String(error)}`,
          },
        ],
      };
    }
  }
);

// =============================================================================
// Start Server
// =============================================================================

const transport = new StdioServerTransport();
await server.connect(transport);
