#!/usr/bin/env bun
/**
 * Evolution System CLI
 *
 * Commands:
 *   grade   - Run all graders and report score
 *   reflect - Analyze session and generate lessons
 *   audit   - Comprehensive security audit
 *   metrics - Display DORA metrics dashboard
 */
import { runAllGraders, printGradeResult } from './graders';
import { getDB, closeDB } from './db/client';
import { type EvolutionCycleInsert, type GraderRunInsert } from './db/schema';

// ============================================================================
// CLI Argument Parsing
// ============================================================================

const command = process.argv[2];
const args = process.argv.slice(3);

const DOTFILES_PATH = process.env['DOTFILES'] ?? `${process.env['HOME']}/dotfiles`;

// ============================================================================
// Commands
// ============================================================================

async function gradeCommand(options: { ci?: boolean; save?: boolean }): Promise<number> {
  console.log('🔍 Running evolution graders...\n');

  const result = await runAllGraders(DOTFILES_PATH);

  if (!result.ok) {
    console.error(`❌ Grading failed: ${result.error.message}`);
    return 1;
  }

  printGradeResult(result.data);

  // Save to database if requested
  if (options.save) {
    const dbResult = getDB();
    if (dbResult.ok) {
      const db = dbResult.data;
      const now = new Date().toISOString();

      // Insert evolution cycle
      const cycleInsert: EvolutionCycleInsert = {
        started_at: now,
        ended_at: now,
        overall_score: result.data.overallScore,
        recommendation: result.data.recommendation,
        trigger: options.ci ? 'ci' : 'manual',
        session_id: null,
        proposals: null,
        applied_proposals: null,
      };

      const cycleResult = db.insertEvolutionCycle(cycleInsert);
      if (cycleResult.ok) {
        // Insert grader runs
        for (const [name, { output }] of Object.entries(result.data.results)) {
          const runInsert: GraderRunInsert = {
            evolution_cycle_id: cycleResult.data.id,
            grader_name: name,
            started_at: now,
            ended_at: now,
            score: output.score,
            passed: output.passed,
            issues: JSON.stringify(output.issues),
            raw_output: output.rawOutput ?? null,
            execution_time_ms: output.metrics?.['execution_time_ms'] ?? null,
          };
          db.insertGraderRun(runInsert);
        }
        console.log('📊 Results saved to database\n');
      }

      closeDB();
    }
  }

  // Exit code for CI
  if (options.ci) {
    return result.data.overallScore >= 0.8 ? 0 : 1;
  }

  return 0;
}

async function metricsCommand(): Promise<number> {
  const dbResult = getDB();
  if (!dbResult.ok) {
    console.error(`❌ Database error: ${dbResult.error.message}`);
    return 1;
  }

  const db = dbResult.data;

  console.log('\n📈 EVOLUTION METRICS DASHBOARD\n');
  console.log('='.repeat(60));

  // Score Trend
  const trendResult = db.getScoreTrend(30);
  if (trendResult.ok && trendResult.data.length > 0) {
    console.log('\n📊 Score Trend (Last 30 Days)');
    console.log('-'.repeat(40));
    for (const row of trendResult.data.slice(0, 7)) {
      const bar = '█'.repeat(Math.round(row.avg_score * 20));
      console.log(`${row.date}: ${bar} ${(row.avg_score * 100).toFixed(1)}%`);
    }
  }

  // Grader Trends
  const graderResult = db.getGraderTrends(30);
  if (graderResult.ok && graderResult.data.length > 0) {
    console.log('\n🎯 Grader Performance');
    console.log('-'.repeat(40));

    // Group by grader
    const byGrader = new Map<string, { totalScore: number; count: number }>();
    for (const row of graderResult.data) {
      const current = byGrader.get(row.grader_name) ?? { totalScore: 0, count: 0 };
      current.totalScore += row.avg_score * row.total_runs;
      current.count += row.total_runs;
      byGrader.set(row.grader_name, current);
    }

    for (const [name, { totalScore, count }] of byGrader) {
      const avgScore = totalScore / count;
      console.log(`${name.padEnd(20)} ${(avgScore * 100).toFixed(1)}% (${count} runs)`);
    }
  }

  // Lesson Effectiveness
  const lessonResult = db.getLessonEffectiveness();
  if (lessonResult.ok && lessonResult.data.length > 0) {
    console.log('\n📚 Lessons by Category');
    console.log('-'.repeat(40));
    for (const row of lessonResult.data) {
      const category = row.category ?? 'uncategorized';
      console.log(`${category.padEnd(20)} ${row.lesson_count} lessons, ${row.avg_applications.toFixed(1)} avg uses`);
    }
  }

  console.log('\n' + '='.repeat(60) + '\n');

  closeDB();
  return 0;
}

async function auditCommand(): Promise<number> {
  console.log('🔒 Running security audit...\n');

  // For now, just run the safety grader
  const result = await runAllGraders(DOTFILES_PATH);

  if (!result.ok) {
    console.error(`❌ Audit failed: ${result.error.message}`);
    return 1;
  }

  // Focus on safety results
  const safetyResult = result.data.results['safety'];
  if (safetyResult) {
    console.log('\n🔒 SECURITY AUDIT RESULTS');
    console.log('='.repeat(60));

    if (safetyResult.output.passed) {
      console.log('\n✅ No security issues found\n');
    } else {
      console.log('\n❌ Security issues detected:\n');
      for (const issue of safetyResult.output.issues) {
        const icon = issue.severity === 'error' ? '🚨' : '⚠️';
        console.log(`${icon} ${issue.message}`);
        if (issue.file) {
          console.log(`   File: ${issue.file}`);
        }
      }
      console.log('');
    }
  }

  return safetyResult?.output.passed ? 0 : 1;
}

// ============================================================================
// Main
// ============================================================================

async function main(): Promise<number> {
  switch (command) {
    case 'grade':
      return gradeCommand({
        ci: args.includes('--ci'),
        save: args.includes('--save') || args.includes('-s'),
      });

    case 'metrics':
      return metricsCommand();

    case 'audit':
      return auditCommand();

    case 'reflect':
      console.log('📝 Reflection not yet implemented in TypeScript');
      return 0;

    default:
      console.log(`
Evolution System CLI

Usage:
  bun run src/index.ts <command> [options]

Commands:
  grade    Run all graders and report score
           --ci     Exit with code 1 if score < 80%
           --save   Save results to database

  reflect  Analyze session and generate lessons (WIP)

  audit    Run security-focused audit

  metrics  Display DORA metrics dashboard

Examples:
  bun run src/index.ts grade
  bun run src/index.ts grade --ci --save
  bun run src/index.ts metrics
  bun run src/index.ts audit
`);
      return command ? 1 : 0;
  }
}

main()
  .then((code) => process.exit(code))
  .catch((err) => {
    console.error('Fatal error:', err);
    process.exit(1);
  });
