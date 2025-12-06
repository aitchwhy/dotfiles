/**
 * Grader Registry
 *
 * Central export for all graders and utilities.
 */

export * from './base';
export { ConfigValidityGrader } from './config-validity';
export { GitHygieneGrader } from './git-hygiene';
export { NixHealthGrader } from './nix-health';
export { PerformanceGrader } from './performance';
export { SafetyGrader } from './safety';
export * from './types';

import { Err, Ok, type Result } from '../lib/result';
import type { BaseGrader } from './base';
import { ConfigValidityGrader } from './config-validity';
import { GitHygieneGrader } from './git-hygiene';
import { NixHealthGrader } from './nix-health';
import { PerformanceGrader } from './performance';
import { SafetyGrader } from './safety';
import { DEFAULT_GRADER_CONFIGS, type GraderConfig, type GraderOutput } from './types';

// ============================================================================
// Grader Factory
// ============================================================================

export function createGrader(name: string, dotfilesPath?: string): BaseGrader | null {
  switch (name) {
    case 'nix-health':
      return new NixHealthGrader(dotfilesPath);
    case 'config-validity':
      return new ConfigValidityGrader(dotfilesPath);
    case 'git-hygiene':
      return new GitHygieneGrader(dotfilesPath);
    case 'performance':
      return new PerformanceGrader(dotfilesPath);
    case 'safety':
      return new SafetyGrader(dotfilesPath);
    default:
      return null;
  }
}

// ============================================================================
// Run All Graders
// ============================================================================

export interface GradeResult {
  overallScore: number;
  recommendation: 'stable' | 'improve' | 'urgent';
  results: Record<string, { output: GraderOutput; config: GraderConfig }>;
  executionTimeMs: number;
}

export async function runAllGraders(dotfilesPath?: string): Promise<Result<GradeResult, Error>> {
  const startTime = performance.now();
  const results: Record<string, { output: GraderOutput; config: GraderConfig }> = {};

  // Run all enabled graders
  const graderNames = Object.keys(DEFAULT_GRADER_CONFIGS);

  for (const name of graderNames) {
    const config = DEFAULT_GRADER_CONFIGS[name];
    if (!config?.enabled) continue;

    const grader = createGrader(name, dotfilesPath);
    if (!grader) continue;

    console.log(`Running ${name}...`);
    const result = await grader.run();

    if (!result.ok) {
      return Err(new Error(`Grader ${name} failed: ${result.error.message}`));
    }

    results[name] = { output: result.data, config };
  }

  // Calculate weighted overall score
  let totalWeight = 0;
  let weightedScore = 0;

  for (const [_name, { output, config }] of Object.entries(results)) {
    totalWeight += config.weight;
    weightedScore += output.score * config.weight;
  }

  const overallScore = totalWeight > 0 ? weightedScore / totalWeight : 0;

  // Determine recommendation
  let recommendation: 'stable' | 'improve' | 'urgent';
  const allPassed = Object.values(results).every(({ output }) => output.passed);

  if (allPassed && overallScore >= 0.9) {
    recommendation = 'stable';
  } else if (overallScore >= 0.7) {
    recommendation = 'improve';
  } else {
    recommendation = 'urgent';
  }

  const executionTimeMs = performance.now() - startTime;

  return Ok({
    overallScore,
    recommendation,
    results,
    executionTimeMs,
  });
}

// ============================================================================
// Print Results
// ============================================================================

export function printGradeResult(result: GradeResult): void {
  const { overallScore, recommendation, results, executionTimeMs } = result;

  console.log(`\n${'='.repeat(60)}`);
  console.log('EVOLUTION GRADE REPORT');
  console.log('='.repeat(60));

  // Print individual grader results
  for (const [name, { output, config }] of Object.entries(results)) {
    const status = output.passed ? '✓' : '✗';
    const scorePercent = (output.score * 100).toFixed(1);
    console.log(
      `\n${status} ${name.padEnd(20)} ${scorePercent.padStart(6)}% (weight: ${config.weight}%)`
    );

    if (output.issues.length > 0) {
      for (const issue of output.issues) {
        const icon =
          issue.severity === 'error' ? '  ❌' : issue.severity === 'warning' ? '  ⚠️' : '  ℹ️';
        console.log(`${icon} ${issue.message}`);
      }
    }
  }

  // Print summary
  console.log(`\n${'-'.repeat(60)}`);
  const overallPercent = (overallScore * 100).toFixed(1);
  const recEmoji = recommendation === 'stable' ? '🟢' : recommendation === 'improve' ? '🟡' : '🔴';

  console.log(`Overall Score: ${overallPercent}%`);
  console.log(`Recommendation: ${recEmoji} ${recommendation.toUpperCase()}`);
  console.log(`Execution Time: ${(executionTimeMs / 1000).toFixed(2)}s`);
  console.log(`${'='.repeat(60)}\n`);
}
