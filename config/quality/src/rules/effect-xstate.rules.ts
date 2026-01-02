/**
 * Effect-XState Integration Rules
 *
 * Enforce correct patterns for Effect-TS + XState v5 integration.
 * Guards 52-55: Effect-XState bridge patterns.
 */

import type { QualityRule } from '../schemas'
import { RuleId } from '../schemas'

export const EFFECT_XSTATE_RULES: readonly QualityRule[] = [
  {
    id: RuleId('no-runpromise-then-catch'),
    name: 'No Effect.runPromise().then/.catch',
    category: 'effect-xstate',
    severity: 'error',
    message: 'Effect.runPromise().then/.catch loses typed errors',
    patterns: ['Effect.runPromise(', '.then(', '.catch('],
    fix: 'Use Effect.runPromiseExit() + Exit.isFailure()/isSuccess()',
    note: 'Guard 52: Typed errors must be preserved',
  },
  {
    id: RuleId('no-ref-for-machine-state'),
    name: 'No useRef for XState-owned state',
    category: 'effect-xstate',
    severity: 'warning',
    message: 'useRef near XState creates split-brain state',
    patterns: ['useRef<', 'useMachine(', 'useActor('],
    fix: 'Store API responses, tokens, URLs in machine context via assign()',
    note: 'Guard 53: Refs for DOM ok, refs for state data banned',
  },
  {
    id: RuleId('no-useeffect-runpromise'),
    name: 'No useEffect + Effect.runPromise',
    category: 'effect-xstate',
    severity: 'error',
    message: 'useEffect + Effect.runPromise bypasses XState invoke system',
    patterns: ['useEffect(', 'Effect.runPromise('],
    fix: 'Use XState invoke with fromPromise actor instead',
    note: 'Guard 54: All async goes through machine actors',
  },
  {
    id: RuleId('no-string-error-conversion'),
    name: 'No String(err) error conversion',
    category: 'effect-xstate',
    severity: 'warning',
    message: 'String(err) or err.message loses typed error information',
    patterns: ['String(err)', '.message'],
    fix: 'Preserve Effect Cause types or use Schema.TaggedError',
    note: 'Guard 55: Error types must be preserved',
  },
] as const
