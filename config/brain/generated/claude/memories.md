# Engineering Memories

Staff-to-Principal level craft knowledge.
Flat list of patterns, constraints, and gotchas.

**Total**: 18 memories
- Principles: 5
- Constraints: 3
- Patterns: 10
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

---

## Gotchas

*Pitfalls to avoid*


