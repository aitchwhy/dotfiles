/**
 * Critic Mode Registry - Self-Review Behaviors
 *
 * 5 metacognitive protocols:
 *   - planning (3): Before writing code
 *   - execution (2): During implementation
 */
import type { CriticBehavior, CriticModeConfig } from './schemas';

export const CRITIC_BEHAVIORS: readonly CriticBehavior[] = [
  // ===========================================================================
  // PLANNING PHASE (3) - Before writing code
  // ===========================================================================
  {
    id: 'assumption-detection',
    phase: 'planning',
    title: 'Assumption Detection',
    trigger: 'When proposing a solution without explicit user confirmation',
    action:
      'Pause and enumerate assumptions. Mark each as "confirmed" or "needs verification". ' +
      'Ask user to confirm unverified assumptions before proceeding.',
  },
  {
    id: 'scope-boundary-check',
    phase: 'planning',
    title: 'Scope Boundary Check',
    trigger: 'When task touches multiple files or introduces new patterns',
    action:
      'Define explicit boundaries: what IS in scope vs what is NOT. ' +
      'Resist scope creep. Refactoring adjacent code is out of scope unless requested.',
  },
  {
    id: 'failure-mode-enumeration',
    phase: 'planning',
    title: 'Failure Mode Enumeration',
    trigger: 'When implementing error handling or fallback logic',
    action:
      'List all failure modes: network, parsing, auth, rate limits, timeouts. ' +
      'Each mode needs an explicit Effect.fail or Recovery strategy.',
  },

  // ===========================================================================
  // EXECUTION PHASE (2) - During implementation
  // ===========================================================================
  {
    id: 'side-effect-audit',
    phase: 'execution',
    title: 'Side Effect Audit',
    trigger: 'Before writing file, making API call, or running command',
    action:
      'Verify the side effect is necessary and reversible. ' +
      'Prefer read-only exploration before mutation. Use --dry-run flags when available.',
  },
  {
    id: 'incremental-verification',
    phase: 'execution',
    title: 'Incremental Verification',
    trigger: 'After completing a logical unit of work',
    action:
      'Run typecheck and tests before moving on. Fix errors immediately. ' +
      'Never accumulate multiple changes before verification.',
  },
] as const satisfies readonly CriticBehavior[];

/**
 * Full critic mode configuration
 */
export const CRITIC_MODE_CONFIG: CriticModeConfig = {
  enabled: true,
  behaviors: [...CRITIC_BEHAVIORS],
} as const satisfies CriticModeConfig;

/**
 * Get behaviors by phase
 */
export function getBehaviorsByPhase(phase: CriticBehavior['phase']): readonly CriticBehavior[] {
  return CRITIC_BEHAVIORS.filter((b) => b.phase === phase);
}

/**
 * Behavior counts by phase
 */
export const BEHAVIOR_COUNTS = {
  planning: CRITIC_BEHAVIORS.filter((b) => b.phase === 'planning').length,
  execution: CRITIC_BEHAVIORS.filter((b) => b.phase === 'execution').length,
  total: CRITIC_BEHAVIORS.length,
} as const;
