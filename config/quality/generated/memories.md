# Engineering Memories

Staff-to-Principal level craft knowledge.
Flat list of patterns, constraints, and gotchas.

**Total**: 17 memories
- Principles: 5
- Constraints: 4
- Patterns: 6
- Gotchas: 2

---
## Principles

*Guiding philosophies (highest priority)*

### Parse, Don't Validate

Transform untyped data into typed data at boundaries using Schema.decodeUnknown. Once parsed, trust the types throughout the codebase. Never re-validate internal data.

*Verified: 2024-12-18*

### Schema-First Development

Define Effect Schema first, derive types via `typeof Schema.Type`. Schemas are SSOT for validation, serialization, and documentation. Zod is banned.

*Verified: 2024-12-18*

### Enforcement Over Documentation

Constraints that can be enforced by code must be. Pre-commit hooks, TypeScript types, and Effect pipelines replace policy documents. Docs describe; code enforces.

*Verified: 2024-12-18*

### Single Source of Truth

Every piece of configuration lives in exactly one place. versions.ts for deps, ports.nix for ports, schema.ts for types. Derivation over duplication.

*Verified: 2024-12-18*

### Delete, Don't Deprecate

Remove unused code immediately. No @deprecated annotations, no TODO(remove) comments. Git preserves history. Dead code is debt that compounds.

*Verified: 2024-12-18*

---

## Constraints

*Hard rules that MUST be followed*

### Zero Try-Catch

Never use try/catch blocks. All errors flow through Effect pipelines. Effect.tryPromise for external calls, Effect.fail for domain errors. PARAGON pre-commit hook enforces this.

*Verified: 2024-12-18*

### Result Types for Fallible Operations

Functions that can fail return Effect<A, E, R> or Either<A, E>. Exceptions are banned from business logic. Type signatures must reflect failure modes.

*Verified: 2024-12-18*

### Effect Platform for HTTP

@effect/platform HttpServer is the only HTTP layer. No Hono, Express, or Fastify. Effect Platform provides typed middleware, error handling, and OpenTelemetry integration.

*Verified: 2024-12-18*

### One Hook Per Event Type

Each Claude Code hook event (PreToolUse, PostToolUse, etc.) has exactly one handler. Multiple concerns go in one handler, not multiple handlers per event.

*Verified: 2024-12-18*

---

## Patterns

*Reusable solutions*

### Evidence-Based Timeouts

Timeouts derived from p99 latency + buffer, not guesses. Use Effect.timeout with Schedule.exponential for retries. Document timeout source in comments.

*Verified: 2024-12-18*

### Bootloader Pattern for Context

CLAUDE.md is a bootloader, not a manual. It provides protocol for dynamic context loading. Read skills on-demand, never dump entire codebase into context.

*Verified: 2024-12-18*

### Hexagonal Architecture with Effect

Ports are Context.Tag interfaces, adapters are Layer implementations. Business logic depends on ports, never concrete adapters. Test via Layer.succeed mocks.

*Verified: 2024-12-18*

### Pulumi ESC for Secrets

All environment variables come from Pulumi ESC, never .env files. ESC provides versioning, audit trails, and rotation. `esc env open` in CI/CD.

*Verified: 2024-12-18*

### Statsig for Feature Flags

@statsig/js-client for web, statsig-node for API. Gates control feature rollout, experiments run A/B tests. Never hardcode feature toggles.

*Verified: 2024-12-18*

### Nix Derivation Splitting

Split large Nix derivations for cache efficiency. deps derivation for node_modules, build derivation for app code. Changes to app code skip dependency rebuild.

*Verified: 2024-12-18*

---

## Gotchas

*Pitfalls to avoid*

### Nix Sandbox Isolation

Nix builds run in sandboxed environment without network access. All dependencies must be declared in inputs. Builds that fetch at build-time fail.

*Verified: 2024-12-18*

### ECS Task Definition Immutability

ECS task definitions are immutable. Updates create new revisions. Blue-green deploys via service update, not in-place modification. Old revisions retained for rollback.

*Verified: 2024-12-18*
