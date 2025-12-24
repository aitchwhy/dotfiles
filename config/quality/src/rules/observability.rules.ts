/**
 * Observability Rules
 *
 * Enforce structured logging and tracing.
 */

import type { QualityRule } from '../schemas';
import { RuleId } from '../schemas';

export const OBSERVABILITY_RULES: readonly QualityRule[] = [
  {
    id: RuleId('no-console'),
    name: 'No console logging',
    category: 'observability',
    severity: 'error',
    message: 'console.* bypasses structured logging and tracing',
    patterns: ['console.log(', 'console.error(', 'console.warn('],
    fix: 'Use Effect.log, Effect.logError, or Effect.logWarning for structured output',
  },
] as const;
