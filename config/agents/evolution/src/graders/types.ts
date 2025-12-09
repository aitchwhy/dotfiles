/**
 * Grader Type Definitions
 */
import { z } from 'zod';

// ============================================================================
// Grader Configuration
// ============================================================================

export const GraderConfigSchema = z.object({
  name: z.string().min(1),
  weight: z.number().min(0).max(100),
  passingScore: z.number().min(0).max(1),
  timeout: z.number().int().positive().default(30000), // ms
  enabled: z.boolean().default(true),
});

export type GraderConfig = z.infer<typeof GraderConfigSchema>;

// ============================================================================
// Grader Issue
// ============================================================================

export const GraderIssueSeverity = z.enum(['error', 'warning', 'info']);
export type GraderIssueSeverity = z.infer<typeof GraderIssueSeverity>;

export const GraderIssueSchema = z.object({
  file: z.string().optional(),
  line: z.number().int().positive().optional(),
  message: z.string(),
  severity: GraderIssueSeverity.default('warning'),
});

export type GraderIssue = z.infer<typeof GraderIssueSchema>;

// ============================================================================
// Grader Output
// ============================================================================

export const GraderOutputSchema = z.object({
  score: z.number().min(0).max(1),
  passed: z.boolean(),
  issues: z.array(GraderIssueSchema),
  metrics: z.record(z.string(), z.number()).optional(),
  rawOutput: z.string().optional(),
});

export type GraderOutput = z.infer<typeof GraderOutputSchema>;

// ============================================================================
// Default Grader Configurations (sum weights = 100)
// ============================================================================

// Individual configs exported for type-safe access (weights sum to 100)
export const NIX_HEALTH_CONFIG: GraderConfig = {
  name: 'nix-health',
  weight: 40,
  passingScore: 0.8,
  timeout: 60000,
  enabled: true,
};

export const CONFIG_VALIDITY_CONFIG: GraderConfig = {
  name: 'config-validity',
  weight: 35,
  passingScore: 0.9,
  timeout: 30000,
  enabled: true,
};

export const GIT_HYGIENE_CONFIG: GraderConfig = {
  name: 'git-hygiene',
  weight: 25,
  passingScore: 0.85,
  timeout: 30000,
  enabled: true,
};

// Aggregate for iteration (used by index.ts)
export const DEFAULT_GRADER_CONFIGS: Record<string, GraderConfig> = {
  'nix-health': NIX_HEALTH_CONFIG,
  'config-validity': CONFIG_VALIDITY_CONFIG,
  'git-hygiene': GIT_HYGIENE_CONFIG,
};
