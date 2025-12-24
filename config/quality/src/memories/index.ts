/**
 * Memory Registry - Flat Memory List
 *
 * 17 consolidated engineering patterns.
 * Staff-to-Principal level craft knowledge.
 *
 * Categories:
 *   - principle (5): Guiding philosophies
 *   - constraint (4): Hard rules
 *   - pattern (6): Reusable solutions
 *   - gotcha (2): Pitfalls to avoid
 */
import type { Memory } from './schemas';

export const MEMORIES: readonly Memory[] = [
  // ===========================================================================
  // PRINCIPLES (5) - Guiding philosophies
  // ===========================================================================
  {
    id: 'parse-dont-validate',
    category: 'principle',
    title: "Parse, Don't Validate",
    content:
      'Transform untyped data into typed data at boundaries using Schema.decodeUnknown. ' +
      'Once parsed, trust the types throughout the codebase. Never re-validate internal data.',
    verified: '2024-12-18',
  },
  {
    id: 'schema-first',
    category: 'principle',
    title: 'Schema-First Development',
    content:
      'Define Effect Schema first, derive types via `typeof Schema.Type`. ' +
      'Schemas are SSOT for validation, serialization, and documentation. Zod is banned.',
    verified: '2024-12-18',
  },
  {
    id: 'enforcement-over-docs',
    category: 'principle',
    title: 'Enforcement Over Documentation',
    content:
      'Constraints that can be enforced by code must be. Pre-commit hooks, TypeScript types, ' +
      'and Effect pipelines replace policy documents. Docs describe; code enforces.',
    verified: '2024-12-18',
  },
  {
    id: 'single-source-of-truth',
    category: 'principle',
    title: 'Single Source of Truth',
    content:
      'Every piece of configuration lives in exactly one place. versions.ts for deps, ' +
      'ports.nix for ports, schema.ts for types. Derivation over duplication.',
    verified: '2024-12-18',
  },
  {
    id: 'delete-dont-deprecate',
    category: 'principle',
    title: "Delete, Don't Deprecate",
    content:
      'Remove unused code immediately. No @deprecated annotations, no TODO(remove) comments. ' +
      'Git preserves history. Dead code is debt that compounds.',
    verified: '2024-12-18',
  },

  // ===========================================================================
  // CONSTRAINTS (4) - Hard rules that MUST be followed
  // ===========================================================================
  {
    id: 'zero-try-catch',
    category: 'constraint',
    title: 'Zero Try-Catch',
    content:
      'Never use try/catch blocks. All errors flow through Effect pipelines. ' +
      'Effect.tryPromise for external calls, Effect.fail for domain errors. ' +
      'PARAGON pre-commit hook enforces this.',
    verified: '2024-12-18',
  },
  {
    id: 'result-types-only',
    category: 'constraint',
    title: 'Result Types for Fallible Operations',
    content:
      'Functions that can fail return Effect<A, E, R> or Either<A, E>. ' +
      'Exceptions are banned from business logic. Type signatures must reflect failure modes.',
    verified: '2024-12-18',
  },
  {
    id: 'effect-platform-http',
    category: 'constraint',
    title: 'Effect Platform for HTTP',
    content:
      '@effect/platform HttpServer is the only HTTP layer. No Hono, Express, or Fastify. ' +
      'Effect Platform provides typed middleware, error handling, and OpenTelemetry integration.',
    verified: '2024-12-18',
  },
  {
    id: 'one-hook-per-event',
    category: 'constraint',
    title: 'One Hook Per Event Type',
    content:
      'Each Claude Code hook event (PreToolUse, PostToolUse, etc.) has exactly one handler. ' +
      'Multiple concerns go in one handler, not multiple handlers per event.',
    verified: '2024-12-18',
  },

  // ===========================================================================
  // PATTERNS (6) - Reusable solutions
  // ===========================================================================
  {
    id: 'evidence-based-timeouts',
    category: 'pattern',
    title: 'Evidence-Based Timeouts',
    content:
      'Timeouts derived from p99 latency + buffer, not guesses. ' +
      'Use Effect.timeout with Schedule.exponential for retries. ' +
      'Document timeout source in comments.',
    verified: '2024-12-18',
  },
  {
    id: 'bootloader-pattern',
    category: 'pattern',
    title: 'Bootloader Pattern for Context',
    content:
      'CLAUDE.md is a bootloader, not a manual. It provides protocol for dynamic context loading. ' +
      'Read skills on-demand, never dump entire codebase into context.',
    verified: '2024-12-18',
  },
  {
    id: 'hexagonal-architecture',
    category: 'pattern',
    title: 'Hexagonal Architecture with Effect',
    content:
      'Ports are Context.Tag interfaces, adapters are Layer implementations. ' +
      'Business logic depends on ports, never concrete adapters. Test via Layer.succeed mocks.',
    verified: '2024-12-18',
  },
  {
    id: 'pulumi-esc-only',
    category: 'pattern',
    title: 'Pulumi ESC for Secrets',
    content:
      'All environment variables come from Pulumi ESC, never .env files. ' +
      'ESC provides versioning, audit trails, and rotation. `esc env open` in CI/CD.',
    verified: '2024-12-18',
  },
  {
    id: 'statsig-feature-flags',
    category: 'pattern',
    title: 'Statsig for Feature Flags',
    content:
      '@statsig/js-client for web, statsig-node for API. ' +
      'Gates control feature rollout, experiments run A/B tests. ' +
      'Never hardcode feature toggles.',
    verified: '2024-12-18',
  },
  {
    id: 'derivation-splitting',
    category: 'pattern',
    title: 'Nix Derivation Splitting',
    content:
      'Split large Nix derivations for cache efficiency. deps derivation for node_modules, ' +
      'build derivation for app code. Changes to app code skip dependency rebuild.',
    verified: '2024-12-18',
  },

  // ===========================================================================
  // GOTCHAS (2) - Pitfalls to avoid
  // ===========================================================================
  {
    id: 'nix-sandbox-isolation',
    category: 'gotcha',
    title: 'Nix Sandbox Isolation',
    content:
      'Nix builds run in sandboxed environment without network access. ' +
      'All dependencies must be declared in inputs. Builds that fetch at build-time fail.',
    verified: '2024-12-18',
  },
  {
    id: 'task-definition-immutability',
    category: 'gotcha',
    title: 'ECS Task Definition Immutability',
    content:
      'ECS task definitions are immutable. Updates create new revisions. ' +
      'Blue-green deploys via service update, not in-place modification. ' +
      'Old revisions retained for rollback.',
    verified: '2024-12-18',
  },
] as const satisfies readonly Memory[];

/**
 * Get memories by category
 */
export function getMemoriesByCategory(category: Memory['category']): readonly Memory[] {
  return MEMORIES.filter((m) => m.category === category);
}

/**
 * Get a single memory by ID
 */
export function getMemory(id: string): Memory | undefined {
  return MEMORIES.find((m) => m.id === id);
}

/**
 * Memory counts by category
 */
export const MEMORY_COUNTS = {
  principle: MEMORIES.filter((m) => m.category === 'principle').length,
  constraint: MEMORIES.filter((m) => m.category === 'constraint').length,
  pattern: MEMORIES.filter((m) => m.category === 'pattern').length,
  gotcha: MEMORIES.filter((m) => m.category === 'gotcha').length,
  total: MEMORIES.length,
} as const;
