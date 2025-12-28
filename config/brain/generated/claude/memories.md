# Engineering Memories

Staff-to-Principal level craft knowledge.
Flat list of patterns, constraints, and gotchas.

**Total**: 31 memories
- Principles: 6
- Constraints: 9
- Patterns: 16
- Gotchas: 0

---
## Principles

*Guiding philosophies (highest priority)*

### Explicit Configuration

No default values in code. All config must be explicit, well-typed, and DI'd via Context/Layer. Zero magic numbers.

*Verified: 2025-12-28*

### Parse Don't Validate

Zero `as Type` except TS2589. Schema.decodeUnknown for runtime. $Infer vendor types only.

*Verified: 2025-12-28*

### Types As Documentation

No documentation/comments/ADRs - code is self-documenting. Enforcement via tooling, not docs.

*Verified: 2025-12-28*

### No One-Off Scripts

Verification is tests, config is declarative (biome/lefthook/Pulumi). No standalone scripts.

*Verified: 2025-12-28*

### Max IoC

Apps/packages/modules unaware of caller/env. Define only own configs, accept env vars at runtime. No getEnvironment().

*Verified: 2025-12-28*

### Domain is Truth

packages/domain is the Single Source of Truth. Contains: Branded types, Effect Schemas, HttpApi contracts, Context.Tag interfaces. Zero side effects, zero external adapter dependencies.

*Verified: 2025-12-28*

---

## Constraints

*Hard rules that MUST be followed*

### Effect-TS ONLY

@effect/platform HttpServer+HttpRouter. BetterAuth via auth.api.* direct calls. returnHeaders:true for Set-Cookie. Zero try/catch, zero Hono/Express.

*Verified: 2025-12-28*

### High-Performance Toolchain

tsgo (type-check), oxlint (lint), biome (format), AST-grep (custom rules), lefthook. Zero tsc, zero eslint.

*Verified: 2025-12-28*

### Dec 2025 Version Pinning

effect@3.19, react@19.2, vite@7.3, xstate@5.25, @tanstack/react-router@1.144, @playwright/test@1.57, vitest@4.0, typescript@5.9, tsgo, better-auth@1.4.9.

*Verified: 2025-12-28*

### Layer Import Rules

L0 (Domain) imports NOTHING. L1 imports L0. L2 imports L0, L1. Never import across same-level apps (e.g. api cannot import web). Use shared packages for code sharing.

*Verified: 2025-12-28*

### File Naming Conventions

kebab-case only. {name}-machine.ts, {name}.adapter.ts, {name}.test.ts. Route params: $param.tsx. Root: __root.tsx.

*Verified: 2025-12-28*

### Code Naming Conventions

PascalCase for Components, Types, Interfaces, Effect Tags (Database). camelCase for functions. SCREAMING_SNAKE for constants.

*Verified: 2025-12-28*

### Effect-TS Naming Rules

Name Context.Tag by Capability (e.g. Database), not implementation. Implementations use Technology prefix (e.g. DrizzleDatabase). BANNED SUFFIXES: *Live, *Port, *Service, *Adapter, *Impl.

*Verified: 2025-12-28*

### Strict Import Ordering

1. External (effect, react). 2. Workspace (@scope/domain). 3. Relative (../). Enforced by Biome. Always use barrel imports from packages (e.g. import { ... } from "@scope/ui").

*Verified: 2025-12-28*

### No .env Files

Use direnv + Pulumi ESC for secrets. Config package (@scope/config) is SSOT for EnvSchema. eval $(pulumi env open project/dev --format shell).

*Verified: 2025-12-28*

---

## Patterns

*Reusable solutions*

### Foundation Stack

pnpm + Docker Compose (OrbStack) + AWS (ECS Fargate + RDS + CloudFront). Node.js 24, Vite 7, TypeScript 7 (tsgo). All config from Pulumi ESC (4-layer: vendor→infra-shared→base→env).

*Verified: 2025-12-28*

### IaC via Pulumi Automation API

Pulumi Automation API (deploy.ts+Effect). ESC refs via template literal types. DeployStack=Schema.Literal. sha-$GITHUB_SHA. tsx usage. AWS+OIDC.

*Verified: 2025-12-28*

### Same-Origin Reverse Proxy

Single baseUrl, /api/*→backend. Local=Caddy (tls internal), Deployed=CloudFront→HTTP→ALB. Zero CORS, zero SSL bypass, 12-factor parity.

*Verified: 2025-12-28*

### Ember Staging Strategy

No custom domain. Uses CloudFront URL directly (*.cloudfront.net). No ember.app or staging.ember.app exists.

*Verified: 2025-12-28*

### Contract-First API

Backend (@ember/domain EmberApi) is source of truth. Frontend derives client via HttpApiClient.make(). Zero drift, auto-sync.

*Verified: 2025-12-28*

### XState with Effect

Use Effect primitives (retry, timeout, polling) via fromPromise wrapping Effect.runPromise. No custom retry code. setup() API with typed actors.

*Verified: 2025-12-28*

### Backend Routing Architecture

Server-level path prefix dispatch, single dispatcher. External URLs as named constants. Branded types for domain IDs.

*Verified: 2025-12-28*

### Cookie-Based Auth

HttpOnly cookies, credentials:"include". handleRaw+returnHeaders:true for Set-Cookie. CloudFront /api/*→ALB same-domain.

*Verified: 2025-12-28*

### BetterAuth Performance

experimental.joins:true for 2-3x latency improvement via DB joins instead of multiple queries.

*Verified: 2025-12-28*

### Conversational Prompts

Claude Code prompts: conversational markdown in chat. User copies. Include validation tests.

*Verified: 2025-12-28*

### Monorepo Layer Architecture

Strict unidirectional dependencies (L5 deps on L4 on L3...). L5=Infra, L4=Apps, L3=Auth, L2=Adapters(DB/Storage), L1=Config/UI, L0=Pure(Domain/Schemas). Higher layers depend on lower only.

*Verified: 2025-12-28*

### Directory Structure

apps/{api,web,agent}, packages/{domain,config,ui,db,auth}, infra/. apps/api/src: handlers (thin), middleware, runtime (AppLive). packages/domain/src: schemas, api, capabilities.

*Verified: 2025-12-28*

### Thin API Handlers

Handlers (HttpApiBuilder.group) are thin orchestration only. NEVER contain business logic. Pattern: parse request -> call capability -> format response. Delegate logic to Repository/Domain.

*Verified: 2025-12-28*

### Type-Safe Dependency Injection

Use Context.Tag for capabilities (interfaces). Use Layer for implementations. Compose in runtime/AppLive.ts using Layer.mergeAll. No manual DI containers.

*Verified: 2025-12-28*

### XState v5 Patterns

Use discriminated union contexts (phase: idle|loading|loaded|error). Use setup() factory pattern. Bridge Effect to XState via runPromise helpers. Explicit states over implicit boolean flags.

*Verified: 2025-12-28*

### 3-Tier Testing Strategy

1. E2E (Playwright) for critical user journeys/auth. 2. Integration (TestContainers) for API/Database. 3. Unit (Vitest+Effect) for Pure Domain logic. Auth Tier 2: Reuse storageState json for speed.

*Verified: 2025-12-28*

---

## Gotchas

*Pitfalls to avoid*


