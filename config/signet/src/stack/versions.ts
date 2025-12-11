/**
 * Signet Stack - Frozen Version Registry
 *
 * SSOT (Single Source of Truth) for all version numbers.
 * Frozen: December 2025
 *
 * This file replaces lib/versions.nix.
 *
 * Consumed by:
 *   - Signet generators (package.json generation)
 *   - Pulumi components (version-aware provisioning)
 *   - Enforcement hooks (version drift detection)
 *   - Policy as Code (deploy-time validation)
 */
import type { StackDefinition } from './schema';
import { stackDefinitionSchema } from './schema';

/**
 * STACK - Frozen December 2025 Configuration
 *
 * All versions are exact (no semver ranges) for reproducibility.
 * Use `npm.xyz` for package.json generation.
 * Use category versions for documentation/reference.
 */
export const STACK = {
  meta: {
    frozen: '2025-12',
    updated: '2025-12-10',
    ssotVersion: '3.0.0',
  },

  // ===========================================================================
  // RUNTIME
  // ===========================================================================
  runtime: {
    bun: '1.3.4', // Anthropic-acquired, latest stable
    node: '25.2.1', // Current (NOT LTS - user preference)
    uv: '0.5.1', // Python manager (Rust)
    volta: '2.0.1', // Tool manager (Rust)
  },

  // ===========================================================================
  // FRONTEND
  // ===========================================================================
  frontend: {
    react: '19.2.1',
    'react-dom': '19.2.1',
    xstate: '5.24.0', // Actor model state machines (handles API state)
    'tanstack-router': '1.140.0',
    tailwindcss: '4.1.17',
  },

  // ===========================================================================
  // BACKEND
  // ===========================================================================
  backend: {
    hono: '4.10.7', // Standards-based server (latest Dec 8, 2025)
    'drizzle-orm': '0.45.0',
    temporal: '1.13.0', // Durable workflows (SDK version)
    restate: '1.9.1', // Alternative durable execution
  },

  // ===========================================================================
  // INFRASTRUCTURE
  // ===========================================================================
  infra: {
    pulumi: '3.210.0', // IaC (TypeScript) - Dec 2025
    'pulumi-gcp': '9.6.0', // GCP provider
    'process-compose': '1.5.0', // Unified observability
    tailscale: '1.78.0', // Mesh network
  },

  // ===========================================================================
  // TESTING & BUILD
  // ===========================================================================
  testing: {
    playwright: '1.57.0',
    vitest: '4.0.15',
    vite: '7.2.7',
    'bruno-cli': '1.30.0', // API testing
  },

  // ===========================================================================
  // PYTHON
  // ===========================================================================
  python: {
    python: '3.14.0', // Minimum enforced - no 3.12/3.13
    pydantic: '2.10.0',
    ruff: '0.8.0',
  },

  // ===========================================================================
  // DATABASE ADAPTERS (PostgreSQL 18+, SQLite/Turso 3.50+ - NO MySQL)
  // ===========================================================================
  databases: {
    'libsql-client': '0.15.15', // Turso (SQLite 3.50+)
    postgres: '3.4.7', // pg driver for PostgreSQL 18+
    // MySQL BANNED - use PostgreSQL or Turso instead
  },

  // ===========================================================================
  // AUTH & SERVICES
  // ===========================================================================
  services: {
    'better-auth': '1.4.6', // TypeScript-first auth (replaces Clerk)
    livekit: '2.9.0',
  },

  // ===========================================================================
  // OBSERVABILITY (December 2025 - Datadog + OTEL 2.x)
  // ===========================================================================
  observability: {
    'opentelemetry-api': '1.9.0',
    'opentelemetry-sdk-node': '0.200.0',
    'opentelemetry-sdk-trace-node': '2.0.0',
    'opentelemetry-sdk-metrics': '2.0.0',
    'opentelemetry-resources': '2.0.0',
    'opentelemetry-semantic-conventions': '1.30.0',
    'opentelemetry-exporter-trace-otlp-proto': '0.200.0',
    'opentelemetry-exporter-metrics-otlp-proto': '0.200.0',
    'opentelemetry-auto-instrumentations-node': '0.56.0',
    'posthog-js': '1.200.0',
    'posthog-node': '5.14.1',
    'devcycle-server-sdk': '2.0.0',
    'devcycle-client-sdk': '1.30.0',
    'datadog-agent': '7.60.0', // Reference only (not npm)
  },

  // ===========================================================================
  // NIX ECOSYSTEM (December 2025 - BLEEDING EDGE)
  // ===========================================================================
  nix: {
    // Core flake inputs - BLEEDING EDGE
    nixpkgs: 'nixos-unstable',
    'nix-darwin': 'github:LnL7/nix-darwin',
    'home-manager': 'github:nix-community/home-manager', // master for 26.05

    // State versions - December 2025 bleeding edge
    'home-manager-stateVersion': '26.05',
    'nixos-stateVersion': '26.05',

    // Flake architecture (December 2025 standard)
    'flake-parts': 'github:hercules-ci/flake-parts',
    'git-hooks-nix': 'github:cachix/git-hooks.nix',

    // Formatters & linters
    'nixfmt-rfc-style': '0.6.0',
    deadnix: '1.2.1',
    statix: '0.5.8',
    alejandra: '3.1.0',

    // Language server
    nixd: '2.6.1',

    // Build tooling
    'nix-output-monitor': '2.1.2',
    'nix-tree': '0.3.1',
    'nix-diff': '1.0.18',

    // Optional inputs
    disko: 'github:nix-community/disko',
    'sops-nix': 'github:Mic92/sops-nix',
    'nix-homebrew': 'github:zhaofengli-wip/nix-homebrew',
  },

  // ===========================================================================
  // FLAT NPM DEPENDENCIES (for package.json generation)
  // ===========================================================================
  npm: {
    // Core (Effect ecosystem - versions must be compatible)
    typescript: '5.9.3',
    effect: '3.19.9',
    '@effect/cli': '0.72.1',
    '@effect/platform': '0.93.6',
    '@effect/platform-node': '0.103.0',
    '@effect/platform-bun': '0.86.0',
    '@effect/printer': '0.47.0',
    '@effect/printer-ansi': '0.47.0',
    zod: '4.1.13',

    // Frontend
    react: '19.2.1',
    'react-dom': '19.2.1',
    xstate: '5.24.0',
    '@xstate/react': '5.0.0',
    '@tanstack/react-router': '1.140.0',
    tailwindcss: '4.1.17',

    // Backend
    hono: '4.10.7',
    '@hono/zod-openapi': '0.18.0',
    'drizzle-orm': '0.45.0',
    'drizzle-kit': '0.30.0',

    // Auth
    'better-auth': '1.4.6',

    // Durable Workflows
    '@temporalio/client': '1.13.0',
    '@temporalio/worker': '1.13.0',
    '@temporalio/workflow': '1.13.0',
    '@temporalio/activity': '1.13.0',
    '@restatedev/restate-sdk': '1.9.1',

    // Observability (Datadog + OTEL 2.x)
    '@opentelemetry/api': '1.9.0',
    '@opentelemetry/sdk-node': '0.200.0',
    '@opentelemetry/sdk-trace-node': '2.0.0',
    '@opentelemetry/sdk-metrics': '2.0.0',
    '@opentelemetry/resources': '2.0.0',
    '@opentelemetry/semantic-conventions': '1.30.0',
    '@opentelemetry/exporter-trace-otlp-proto': '0.200.0',
    '@opentelemetry/exporter-metrics-otlp-proto': '0.200.0',
    '@opentelemetry/auto-instrumentations-node': '0.56.0',
    'posthog-js': '1.200.0',
    'posthog-node': '5.14.1',
    '@devcycle/nodejs-server-sdk': '2.0.0',
    '@devcycle/js-client-sdk': '1.30.0',

    // Cache & Queue
    ioredis: '5.8.2',

    // Database
    '@libsql/client': '0.15.15',
    postgres: '3.4.7',

    // Testing
    '@playwright/test': '1.57.0',
    vitest: '4.0.15',
    '@vitest/ui': '4.0.15',

    // Build
    vite: '7.2.7',
    handlebars: '4.7.8',

    // Dev & Linting
    oxlint: '1.32.0',
    '@biomejs/biome': '2.3.8',
    '@types/bun': '1.2.10',
    '@ast-grep/napi': '0.33.1',

    // Pulumi (infrastructure) - Dec 2025
    '@pulumi/pulumi': '3.210.0',
    '@pulumi/gcp': '9.6.0',
    '@pulumi/random': '4.18.4',
    '@pulumi/policy': '1.20.0',
  },
} as const satisfies StackDefinition;

/**
 * Validate STACK at runtime (development check)
 * Throws if STACK doesn't match schema
 */
export function validateStack(): void {
  stackDefinitionSchema.parse(STACK);
}

/**
 * Export as JSON for backward compatibility
 * This allows existing code that reads versions.json to continue working
 */
export const versionsJson = JSON.stringify(STACK, null, 2);

/**
 * Get a specific npm package version
 * Type-safe access to npm versions
 */
export function getNpmVersion<K extends keyof typeof STACK.npm>(pkg: K): string {
  return STACK.npm[pkg];
}

/**
 * Get all npm versions as a Record
 * Useful for generating package.json dependencies
 */
export function getNpmVersions(): Record<string, string> {
  return { ...STACK.npm };
}

/**
 * Check if a package version matches the SSOT
 */
export function isVersionMatch(pkg: string, version: string): boolean {
  const npmVersions: Readonly<Record<string, string>> = STACK.npm;
  const expected = npmVersions[pkg];
  if (!expected) return true; // Unknown packages are allowed
  return expected === version;
}

/**
 * Get drift report for a set of dependencies
 */
export function getDrift(
  dependencies: Record<string, string>
): Array<{ pkg: string; expected: string; actual: string }> {
  const drift: Array<{ pkg: string; expected: string; actual: string }> = [];
  const npmVersions: Readonly<Record<string, string>> = STACK.npm;

  for (const [pkg, version] of Object.entries(dependencies)) {
    const expected = npmVersions[pkg];
    if (expected && expected !== version) {
      drift.push({ pkg, expected, actual: version });
    }
  }

  return drift;
}
