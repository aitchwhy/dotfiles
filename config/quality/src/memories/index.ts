/**
 * Memory Registry - Flat Memory List
 *
 * 18 consolidated engineering patterns for Dec 2025 Stack.
 * SSOT for code quality, architecture, and tech stack.
 *
 * Categories:
 *   - principle: Guiding philosophies
 *   - constraint: Hard rules
 *   - pattern: Reusable solutions
 *   - gotcha: Pitfalls to avoid
 */

import { ARCHITECTURE_MEMORIES } from './architecture'
import { NAMING_MEMORIES } from './naming'
import { PATTERN_MEMORIES } from './patterns'
import type { Memory } from './schemas'
import { STANDARDS_MEMORIES } from './standards'

// 1. Stack
const INFRA_MEMORIES: Memory[] = [
  {
    id: 'infra-stack',
    category: 'pattern',
    title: 'Foundation Stack',
    content:
      'pnpm + Docker Compose (OrbStack) + AWS (ECS Fargate + RDS + CloudFront). Node.js 24, Vite 7, TypeScript 7 (tsgo). ' +
      'All config from Pulumi ESC (4-layer: vendor→infra-shared→base→env).',
    verified: '2025-12-28',
  },
  {
    id: 'infra-iac',
    category: 'pattern',
    title: 'IaC via Pulumi Automation API',
    content:
      'Pulumi Automation API (deploy.ts+Effect). ESC refs via template literal types. DeployStack=Schema.Literal. ' +
      'sha-$GITHUB_SHA. tsx usage. AWS+OIDC.',
    verified: '2025-12-28',
  },
  {
    id: 'transport-unification',
    category: 'pattern',
    title: 'Same-Origin Reverse Proxy',
    content:
      'Single baseUrl, /api/*→backend. Local=Caddy (tls internal), Deployed=CloudFront→HTTP→ALB. ' +
      'Zero CORS, zero SSL bypass, 12-factor parity.',
    verified: '2025-12-28',
  },
  {
    id: 'ember-staging',
    category: 'pattern',
    title: 'Ember Staging Strategy',
    content:
      'No custom domain. Uses CloudFront URL directly (*.cloudfront.net). No ember.app or staging.ember.app exists.',
    verified: '2025-12-28',
  },
]

// 2. Runtime
const RUNTIME_MEMORIES: Memory[] = [
  {
    id: 'effect-platform-only',
    category: 'constraint',
    title: 'Effect-TS ONLY',
    content:
      '@effect/platform HttpServer+HttpRouter. BetterAuth via auth.api.* direct calls. ' +
      'returnHeaders:true for Set-Cookie. Zero try/catch, zero Hono/Express.',
    verified: '2025-12-28',
  },
  {
    id: 'api-contract',
    category: 'pattern',
    title: 'Contract-First API',
    content:
      'Backend (@ember/domain EmberApi) is source of truth. Frontend derives client via HttpApiClient.make(). ' +
      'Zero drift, auto-sync.',
    verified: '2025-12-28',
  },
  {
    id: 'xstate-machines',
    category: 'pattern',
    title: 'XState with Effect',
    content:
      'Use Effect primitives (retry, timeout, polling) via fromPromise wrapping Effect.runPromise. ' +
      'No custom retry code. setup() API with typed actors.',
    verified: '2025-12-28',
  },
  {
    id: 'backend-routing',
    category: 'pattern',
    title: 'Backend Routing Architecture',
    content:
      'Server-level path prefix dispatch, single dispatcher. External URLs as named constants. ' +
      'Branded types for domain IDs.',
    verified: '2025-12-28',
  },
  {
    id: 'explicit-config',
    category: 'principle',
    title: 'Explicit Configuration',
    content:
      "No default values in code. All config must be explicit, well-typed, and DI'd via Context/Layer. " +
      'Zero magic numbers.',
    verified: '2025-12-28',
  },
  {
    id: 'parse-dont-validate',
    category: 'principle',
    title: "Parse Don't Validate",
    content:
      'Zero `as Type` except TS2589. Schema.decodeUnknown for runtime. $Infer vendor types only.',
    verified: '2025-12-28',
  },
]

// 3. Auth
const AUTH_MEMORIES: Memory[] = [
  {
    id: 'auth-cookies',
    category: 'pattern',
    title: 'Cookie-Based Auth',
    content:
      'HttpOnly cookies, credentials:"include". handleRaw+returnHeaders:true for Set-Cookie. ' +
      'CloudFront /api/*→ALB same-domain.',
    verified: '2025-12-28',
  },
  {
    id: 'betterauth-performance',
    category: 'pattern',
    title: 'BetterAuth Performance',
    content:
      'experimental.joins:true for 2-3x latency improvement via DB joins instead of multiple queries.',
    verified: '2025-12-28',
  },
]

// 4. Tooling
const TOOLING_MEMORIES: Memory[] = [
  {
    id: 'no-docs',
    category: 'principle',
    title: 'Types As Documentation',
    content:
      'No documentation/comments/ADRs - code is self-documenting. Enforcement via tooling, not docs.',
    verified: '2025-12-28',
  },
  {
    id: 'no-scripts',
    category: 'principle',
    title: 'No One-Off Scripts',
    content:
      'Verification is tests, config is declarative (biome/lefthook/Pulumi). No standalone scripts.',
    verified: '2025-12-28',
  },
  {
    id: 'programmatic-toolchain',
    category: 'constraint',
    title: 'High-Performance Toolchain',
    content:
      'tsgo (type-check), oxlint (lint), biome (format), AST-grep (custom rules), lefthook. ' +
      'Zero tsc, zero eslint.',
    verified: '2025-12-28',
  },
]

// 5. Deps
const DEPS_MEMORIES: Memory[] = [
  {
    id: 'dec-2025-deps',
    category: 'constraint',
    title: 'Dec 2025 Version Pinning',
    content:
      'effect@3.19, react@19.2, vite@7.3, xstate@5.25, @tanstack/react-router@1.144, ' +
      '@playwright/test@1.57, vitest@4.0, typescript@5.9, tsgo, better-auth@1.4.9.',
    verified: '2025-12-28',
  },
]

// 6. Principles
const ARCH_MEMORIES: Memory[] = [
  {
    id: 'ai-prompts',
    category: 'pattern',
    title: 'Conversational Prompts',
    content:
      'Claude Code prompts: conversational markdown in chat. User copies. Include validation tests.',
    verified: '2025-12-28',
  },
  {
    id: 'inversion-of-control',
    category: 'principle',
    title: 'Max IoC',
    content:
      'Apps/packages/modules unaware of caller/env. Define only own configs, accept env vars at runtime. ' +
      'No getEnvironment().',
    verified: '2025-12-28',
  },
]

// Flatten and Export
const ALL_NEW_MEMORIES = [
  ...INFRA_MEMORIES,
  ...RUNTIME_MEMORIES,
  ...AUTH_MEMORIES,
  ...TOOLING_MEMORIES,
  ...DEPS_MEMORIES,
  ...ARCH_MEMORIES,
  ...ARCHITECTURE_MEMORIES,
  ...NAMING_MEMORIES,
  ...PATTERN_MEMORIES,
  ...STANDARDS_MEMORIES,
]

export const MEMORIES: readonly Memory[] = ALL_NEW_MEMORIES as unknown as readonly Memory[]

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
  standard: MEMORIES.filter((m) => m.category === 'standard').length,
  total: MEMORIES.length,
} as const
