# Engineering Memories

Staff-to-Principal level craft knowledge.
Flat list of patterns, constraints, and gotchas.

**Total**: 22 memories
- Principles: 5
- Constraints: 4
- Patterns: 11
- Gotchas: 2

---
## Principles

*Guiding philosophies (highest priority)*

### Parse, Don't Validate

Transform untyped data into typed data at boundaries using Schema.decodeUnknown. Once parsed, trust the types throughout the codebase. Never re-validate internal data.

*Verified: 2024-12-24*

### Schema-First Development

Define Effect Schema first, derive types via `typeof Schema.Type`. Schemas are SSOT for validation, serialization, and documentation. Zod is banned.

*Verified: 2024-12-24*

### Enforcement Over Documentation

Constraints that can be enforced by code must be. Pre-commit hooks, TypeScript types, and Effect pipelines replace policy documents. Docs describe; code enforces.

*Verified: 2024-12-24*

### Single Source of Truth

Every piece of configuration lives in exactly one place. versions.ts for deps, ports.nix for ports, schema.ts for types. Derivation over duplication.

*Verified: 2024-12-24*

### Delete, Don't Deprecate

Remove unused code immediately. No @deprecated annotations, no TODO(remove) comments. Git preserves history. Dead code is debt that compounds.

*Verified: 2024-12-24*

---

## Constraints

*Hard rules that MUST be followed*

### Zero Try-Catch in Business Logic

Never use try/catch in business logic. All errors flow through Effect pipelines. EXCEPTIONS: (1) Server entrypoint for uncaught errors, (2) Adapters wrapping external SDKs, (3) Boundary functions like Schema.decodeUnknownSync. Use Effect.tryPromise for async calls.

*Verified: 2024-12-24*

### Result Types for Fallible Operations

Functions that can fail return Effect<A, E, R> or Either<A, E>. Exceptions are banned from business logic. Type signatures must reflect failure modes.

*Verified: 2024-12-24*

### Effect Platform for HTTP

@effect/platform HttpServer is the only HTTP layer. No Hono, Express, or Fastify. Effect Platform provides typed middleware, error handling, and OpenTelemetry integration.

*Verified: 2024-12-24*

### One Hook Per Event Type

Each Claude Code hook event (PreToolUse, PostToolUse, etc.) has exactly one handler. Multiple concerns go in one handler, not multiple handlers per event.

*Verified: 2024-12-24*

---

## Patterns

*Reusable solutions*

### Evidence-Based Timeouts

Timeouts derived from p99 latency + buffer, not guesses. Use Effect.timeout with Schedule.exponential for retries. Document timeout source in comments.

*Verified: 2024-12-24*

### Bootloader Pattern for Context

CLAUDE.md is a bootloader, not a manual. It provides protocol for dynamic context loading. Read skills on-demand, never dump entire codebase into context.

*Verified: 2024-12-24*

### Hexagonal Architecture with Effect

Ports are Context.Tag interfaces, adapters are Layer implementations. Business logic depends on ports, never concrete adapters. Test via Layer.succeed mocks.

*Verified: 2024-12-24*

### Dynamic Credentials via ESC + OIDC

No static secrets in CI/CD. GitHub Actions uses OIDC to assume AWS IAM roles. Credentials are short-lived (1 hour), scoped to repo/branch via JWT claims. Local dev uses Pulumi ESC. Production uses direct OIDC federation.

*Verified: 2024-12-24*

### Statsig for Feature Flags

@statsig/js-client for web, statsig-node for API. Gates control feature rollout, experiments run A/B tests. Never hardcode feature toggles.

*Verified: 2024-12-24*

### Nix Derivation Splitting

Split large Nix derivations for cache efficiency. deps derivation for node_modules, build derivation for app code. Changes to app code skip dependency rebuild.

*Verified: 2024-12-24*

### XState v5 Actor Model

Complex async state uses XState v5 machines with singleton actors. authMachine handles auth state transitions. Machines are typed with setup(). Use @xstate/react useSelector for reactive state access.

*Verified: 2024-12-24*

### BetterAuth Session Pattern

Authentication via BetterAuth with HttpOnly session cookies (browser) and Bearer tokens (API). Sessions stored server-side in PostgreSQL. Session middleware validates on every request. Phone OTP is primary auth method for mobile-first UX.

*Verified: 2024-12-24*

### Docker Compose for Development

Local development uses docker compose up with Caddy reverse proxy. Nix is for dotfiles only, not application dev shells. File watching via docker compose watch. ESC env vars loaded via direnv.

*Verified: 2024-12-24*

### E2E-First Testing Strategy

E2E tests are primary verification layer. Run before every deploy. packages/e2e is independent, imports only @ember/config and @ember/domain. No test bypass code in production. E2E generates valid JWTs using same contract as prod.

*Verified: 2024-12-24*

### Drizzle ORM with PostgreSQL

Database access via Drizzle ORM in drizzle.adapter.ts. Schema in packages/domain. Uses Effect Layer for connection pooling. All queries return Effect, never raw promises. Migrations via drizzle-kit. No Prisma, no raw pg driver.

*Verified: 2024-12-24*

---

## Gotchas

*Pitfalls to avoid*

### Nix Sandbox Isolation

Nix builds run in sandboxed environment without network access. All dependencies must be declared in inputs. Builds that fetch at build-time fail.

*Verified: 2024-12-24*

### ECS Task Definition Immutability

ECS task definitions are immutable. Updates create new revisions. Blue-green deploys via service update, not in-place modification. Old revisions retained for rollback.

*Verified: 2024-12-24*
