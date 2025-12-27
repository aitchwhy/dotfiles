/**
 * Memory Registry - Flat Memory List
 *
 * 22 consolidated engineering patterns.
 * Staff-to-Principal level craft knowledge.
 *
 * Categories:
 *   - principle (5): Guiding philosophies
 *   - constraint (4): Hard rules
 *   - pattern (11): Reusable solutions
 *   - gotcha (2): Pitfalls to avoid
 */
import type { Memory } from './schemas'

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
    verified: '2024-12-24',
  },
  {
    id: 'schema-first',
    category: 'principle',
    title: 'Schema-First Development',
    content:
      'Define Effect Schema first, derive types via `typeof Schema.Type`. ' +
      'Schemas are SSOT for validation, serialization, and documentation. Zod is banned.',
    verified: '2024-12-24',
  },
  {
    id: 'enforcement-over-docs',
    category: 'principle',
    title: 'Enforcement Over Documentation',
    content:
      'Constraints that can be enforced by code must be. Pre-commit hooks, TypeScript types, ' +
      'and Effect pipelines replace policy documents. Docs describe; code enforces.',
    verified: '2024-12-24',
  },
  {
    id: 'single-source-of-truth',
    category: 'principle',
    title: 'Single Source of Truth',
    content:
      'Every piece of configuration lives in exactly one place. versions.ts for deps, ' +
      'ports.nix for ports, schema.ts for types. Derivation over duplication.',
    verified: '2024-12-24',
  },
  {
    id: 'delete-dont-deprecate',
    category: 'principle',
    title: "Delete, Don't Deprecate",
    content:
      'Remove unused code immediately. No @deprecated annotations, no TODO(remove) comments. ' +
      'Git preserves history. Dead code is debt that compounds.',
    verified: '2024-12-24',
  },

  // ===========================================================================
  // CONSTRAINTS (4) - Hard rules that MUST be followed
  // ===========================================================================
  {
    id: 'zero-try-catch',
    category: 'constraint',
    title: 'Zero Try-Catch in Business Logic',
    content:
      'Never use try/catch in business logic. All errors flow through Effect pipelines. ' +
      'EXCEPTIONS: (1) Server entrypoint for uncaught errors, (2) Adapters wrapping external SDKs, ' +
      '(3) Boundary functions like Schema.decodeUnknownSync. Use Effect.tryPromise for async calls.',
    verified: '2024-12-24',
  },
  {
    id: 'result-types-only',
    category: 'constraint',
    title: 'Result Types for Fallible Operations',
    content:
      'Functions that can fail return Effect<A, E, R> or Either<A, E>. ' +
      'Exceptions are banned from business logic. Type signatures must reflect failure modes.',
    verified: '2024-12-24',
  },
  {
    id: 'effect-platform-http',
    category: 'constraint',
    title: 'Effect Platform for HTTP',
    content:
      '@effect/platform HttpServer is the only HTTP layer. No Hono, Express, or Fastify. ' +
      'Effect Platform provides typed middleware, error handling, and OpenTelemetry integration.',
    verified: '2024-12-24',
  },
  {
    id: 'one-hook-per-event',
    category: 'constraint',
    title: 'One Hook Per Event Type',
    content:
      'Each Claude Code hook event (PreToolUse, PostToolUse, etc.) has exactly one handler. ' +
      'Multiple concerns go in one handler, not multiple handlers per event.',
    verified: '2024-12-24',
  },

  // ===========================================================================
  // PATTERNS (11) - Reusable solutions (Nx removed - using pnpm + Docker Compose)
  // ===========================================================================
  {
    id: 'evidence-based-timeouts',
    category: 'pattern',
    title: 'Evidence-Based Timeouts',
    content:
      'Timeouts derived from p99 latency + buffer, not guesses. ' +
      'Use Effect.timeout with Schedule.exponential for retries. ' +
      'Document timeout source in comments.',
    verified: '2024-12-24',
  },
  {
    id: 'bootloader-pattern',
    category: 'pattern',
    title: 'Bootloader Pattern for Context',
    content:
      'CLAUDE.md is a bootloader, not a manual. It provides protocol for dynamic context loading. ' +
      'Read skills on-demand, never dump entire codebase into context.',
    verified: '2024-12-24',
  },
  {
    id: 'hexagonal-architecture',
    category: 'pattern',
    title: 'Hexagonal Architecture with Effect',
    content:
      'Ports are Context.Tag interfaces, adapters are Layer implementations. ' +
      'Business logic depends on ports, never concrete adapters. Test via Layer.succeed mocks.',
    verified: '2024-12-24',
  },
  {
    id: 'dynamic-credentials',
    category: 'pattern',
    title: 'Dynamic Credentials via ESC + OIDC',
    content:
      'No static secrets in CI/CD. GitHub Actions uses OIDC to assume AWS IAM roles. ' +
      'Credentials are short-lived (1 hour), scoped to repo/branch via JWT claims. ' +
      'Local dev uses Pulumi ESC. Production uses direct OIDC federation.',
    verified: '2024-12-24',
  },
  {
    id: 'statsig-feature-flags',
    category: 'pattern',
    title: 'Statsig for Feature Flags',
    content:
      '@statsig/js-client for web, statsig-node for API. ' +
      'Gates control feature rollout, experiments run A/B tests. ' +
      'Never hardcode feature toggles.',
    verified: '2024-12-24',
  },
  {
    id: 'derivation-splitting',
    category: 'pattern',
    title: 'Nix Derivation Splitting',
    content:
      'Split large Nix derivations for cache efficiency. deps derivation for node_modules, ' +
      'build derivation for app code. Changes to app code skip dependency rebuild.',
    verified: '2024-12-24',
  },
  {
    id: 'xstate-actor-model',
    category: 'pattern',
    title: 'XState v5 Actor Model',
    content:
      'Complex async state uses XState v5 machines with singleton actors. ' +
      'authMachine handles auth state transitions. Machines are typed with setup(). ' +
      'Use @xstate/react useSelector for reactive state access.',
    verified: '2024-12-24',
  },
  {
    id: 'betterauth-sessions',
    category: 'pattern',
    title: 'BetterAuth Session Pattern',
    content:
      'Authentication via BetterAuth with HttpOnly session cookies (browser) and Bearer tokens (API). ' +
      'Sessions stored server-side in PostgreSQL. Session middleware validates on every request. ' +
      'Phone OTP is primary auth method for mobile-first UX.',
    verified: '2024-12-24',
  },
  {
    id: 'docker-compose-dev',
    category: 'pattern',
    title: 'Docker Compose for Development',
    content:
      'Local development uses docker compose up with Caddy reverse proxy. ' +
      'Nix is for dotfiles only, not application dev shells. ' +
      'File watching via docker compose watch. ESC env vars loaded via direnv.',
    verified: '2024-12-24',
  },
  {
    id: 'e2e-first-testing',
    category: 'pattern',
    title: 'E2E-First Testing Strategy',
    content:
      'E2E tests are primary verification layer. Run before every deploy. ' +
      'packages/e2e is independent, imports only @ember/config and @ember/domain. ' +
      'No test bypass code in production. E2E generates valid JWTs using same contract as prod.',
    verified: '2024-12-24',
  },
  {
    id: 'drizzle-postgres',
    category: 'pattern',
    title: 'Drizzle ORM with PostgreSQL',
    content:
      'Database access via Drizzle ORM in drizzle.adapter.ts. Schema in packages/domain. ' +
      'Uses Effect Layer for connection pooling. All queries return Effect, never raw promises. ' +
      'Migrations via drizzle-kit. No Prisma, no raw pg driver.',
    verified: '2024-12-24',
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
    verified: '2024-12-24',
  },
  {
    id: 'task-definition-immutability',
    category: 'gotcha',
    title: 'ECS Task Definition Immutability',
    content:
      'ECS task definitions are immutable. Updates create new revisions. ' +
      'Blue-green deploys via service update, not in-place modification. ' +
      'Old revisions retained for rollback.',
    verified: '2024-12-24',
  },
] as const satisfies readonly Memory[]

/**
 * Get memories by category
 */
export function getMemoriesByCategory(category: Memory['category']): readonly Memory[] {
  return MEMORIES.filter((m) => m.category === category)
}

/**
 * Get a single memory by ID
 */
export function getMemory(id: string): Memory | undefined {
  return MEMORIES.find((m) => m.id === id)
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
} as const
