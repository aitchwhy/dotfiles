#!/usr/bin/env bun
import { closeDB, getDB } from './db/client';
import type { EvolutionCycleInsert, GraderRunInsert, LessonInsert } from './db/schema';
import { LessonSource } from './db/schema';
/**
 * Evolution System CLI
 *
 * Commands:
 *   grade   - Run all graders and report score
 *   reflect - Analyze session and generate lessons
 *   audit   - Comprehensive security audit
 *   metrics - Display DORA metrics dashboard
 *   lesson  - Manage lessons (add, list, recent)
 */
import { printGradeResult, runAllGraders } from './graders';

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
      console.log(
        `${category.padEnd(20)} ${row.lesson_count} lessons, ${row.avg_applications.toFixed(1)} avg uses`
      );
    }
  }

  console.log(`\n${'='.repeat(60)}\n`);

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
// Lesson Commands
// ============================================================================

async function lessonCommand(subcommand: string, lessonArgs: string[]): Promise<number> {
  const dbResult = getDB();
  if (!dbResult.ok) {
    console.error(`❌ Database error: ${dbResult.error.message}`);
    return 1;
  }

  const db = dbResult.data;

  try {
    switch (subcommand) {
      case 'add': {
        // Parse: lesson add "text" --source reflection
        const sourceIdx = lessonArgs.indexOf('--source');
        const source = sourceIdx !== -1 ? lessonArgs[sourceIdx + 1] : 'manual';
        const text = lessonArgs.filter((_, i) => i !== sourceIdx && i !== sourceIdx + 1).join(' ');

        if (!text) {
          console.error('Usage: lesson add "text" --source <reflection|session|manual|grader>');
          return 1;
        }

        // Validate source
        const sourceResult = LessonSource.safeParse(source);
        if (!sourceResult.success) {
          console.error(
            `Invalid source: ${source}. Must be one of: reflection, session, manual, grader`
          );
          return 1;
        }

        const lesson: LessonInsert = {
          created_at: new Date().toISOString(),
          lesson: text,
          source: sourceResult.data,
          category: null,
          confidence: 1.0,
        };

        const result = db.insertLesson(lesson);
        if (!result.ok) {
          console.error(`❌ Failed to add lesson: ${result.error.message}`);
          return 1;
        }

        console.log(`✅ Lesson added (id: ${result.data.id})`);
        return 0;
      }

      case 'list': {
        // Parse: lesson list [--limit N]
        const limitIdx = lessonArgs.indexOf('--limit');
        const limit = limitIdx !== -1 ? Number.parseInt(lessonArgs[limitIdx + 1] ?? '20', 10) : 20;

        const result = db.getAllLessons();
        if (!result.ok) {
          console.error(`❌ Failed to list lessons: ${result.error.message}`);
          return 1;
        }

        const lessons = result.data.slice(0, limit);
        console.log(`\n📚 Lessons (${lessons.length} of ${result.data.length})\n`);
        console.log('-'.repeat(60));

        for (const lesson of lessons) {
          const date = new Date(lesson.created_at).toLocaleDateString();
          const preview =
            lesson.lesson.length > 60 ? `${lesson.lesson.slice(0, 60)}...` : lesson.lesson;
          console.log(`[${lesson.id}] ${date} (${lesson.source}): ${preview}`);
        }

        console.log('');
        return 0;
      }

      case 'recent': {
        // Parse: lesson recent [--count N]
        // Output: semicolon-separated lessons for session-start.sh
        const countIdx = lessonArgs.indexOf('--count');
        const count = countIdx !== -1 ? Number.parseInt(lessonArgs[countIdx + 1] ?? '5', 10) : 5;

        const result = db.getAllLessons();
        if (!result.ok) {
          console.error(`❌ Failed to get lessons: ${result.error.message}`);
          return 1;
        }

        const lessons = result.data.slice(0, count);
        const output = lessons.map((l) => l.lesson).join('; ');
        console.log(output);
        return 0;
      }

      default:
        console.log(`
Lesson Commands

Usage:
  bun run src/index.ts lesson <command> [options]

Commands:
  add <text> --source <type>   Add a new lesson
                               Sources: reflection, session, manual, grader

  list [--limit N]             List lessons (default: 20)

  recent [--count N]           Get recent lessons as semicolon-separated text
                               For use by session-start.sh hook

Examples:
  bun run src/index.ts lesson add "Always use Result types" --source manual
  bun run src/index.ts lesson list --limit 10
  bun run src/index.ts lesson recent --count 5
`);
        return subcommand ? 1 : 0;
    }
  } finally {
    closeDB();
  }
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

    case 'lesson':
      return lessonCommand(args[0] ?? '', args.slice(1));

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

  lesson   Manage lessons (add, list, recent)
           Run 'lesson' without args for subcommand help

Examples:
  bun run src/index.ts grade
  bun run src/index.ts grade --ci --save
  bun run src/index.ts metrics
  bun run src/index.ts lesson add "Use Result types" --source manual
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
