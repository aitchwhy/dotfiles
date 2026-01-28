/**
 * Quality System Stack - Frozen Version Registry
 *
 * SSOT (Single Source of Truth) for all version numbers.
 * Frozen: January 2026
 *
 * This file replaces lib/versions.nix.
 *
 * Consumed by:
 *   - Quality System generators (package.json generation)
 *   - Enforcement hooks (version drift detection)
 */

import { type Either, type ParseResult, Schema } from 'effect'
import type { StackDefinition } from './schema'
import { StackDefinitionSchema } from './schema'

/**
 * STACK - Frozen January 2026 Configuration
 *
 * All versions are exact (no semver ranges) for reproducibility.
 * Use `npm.xyz` for package.json generation.
 * Use category versions for documentation/reference.
 */
export const STACK = {
  meta: {
    frozen: '2026-01',
    updated: '2026-01-28',
    ssotVersion: '5.3.1', // SOTA Jan 28, 2026: updated all packages
  },

  // ===========================================================================
  // RUNTIME
  // ===========================================================================
  runtime: {
    pnpm: '10.28.2', // Fast, disk-efficient package manager
    node: '25.5.0', // Current release (EOL June 2026)
    uv: '0.5.1', // Python manager (Rust)
    volta: '2.0.1', // Tool manager (Rust)
  },

  // ===========================================================================
  // FRONTEND (Web)
  // ===========================================================================
  frontend: {
    react: '19.2.4', // Latest stable with security fixes
    'react-dom': '19.2.4',
    xstate: '5.25.0', // Actor model state machines (handles API state)
    'tanstack-router': '1.151.6',
    tailwindcss: '4.1.17',
  },

  // ===========================================================================
  // MOBILE / UNIVERSAL (Expo SDK 54 - January 2026)
  // Universal = iOS + Android + Web from single codebase
  // Synced with Told project (apps/mobile)
  // ===========================================================================
  mobile: {
    // Core runtime (SDK 54)
    expo: '54.0.31',
    'react-native': '0.81.5',
    'react-native-web': '0.21.1',

    // Routing (file-based, universal)
    'expo-router': '6.0.21',

    // Animation (Moti for declarative, Reanimated for gestures)
    'react-native-reanimated': '4.1.1',
    moti: '0.30.0',
    'react-native-gesture-handler': '2.28.0',

    // Styling (NativeWind = Tailwind for RN, aligns with tailwindcss SSOT)
    nativewind: '4.1.23',
    // NOTE: tailwindcss version shared with frontend section

    // Navigation primitives
    'react-native-screens': '4.16.0',
    'react-native-safe-area-context': '5.6.2',

    // Essential Expo packages (SDK 54)
    'expo-splash-screen': '0.30.0',
    'expo-status-bar': '2.0.0',
    'expo-constants': '17.0.0',
    'expo-linking': '7.0.0',
    'expo-secure-store': '14.0.0',
    'expo-image': '2.0.0',
    'expo-video': '2.0.0', // Replaces expo-av Video
    'expo-audio': '1.0.0', // Replaces expo-av Audio
    'expo-haptics': '14.0.0',
    'expo-notifications': '0.30.0',
    'expo-updates': '0.28.0',
    'expo-background-task': '0.2.0', // Replaces expo-background-fetch

    // Performance
    '@shopify/flash-list': '2.0.0',

    // Storage
    '@react-native-async-storage/async-storage': '2.1.0',
    'expo-sqlite': '15.0.0',

    // LiveKit for voice (Told uses @livekit/react-native)
    '@livekit/react-native': '2.9.6',
    '@livekit/react-native-webrtc': '137.0.2',
  },

  // ===========================================================================
  // BACKEND (Effect Platform HTTP - NO Hono)
  // @effect/platform provides HttpServer via platform-node/platform-bun
  // ===========================================================================
  backend: {
    'drizzle-orm': '0.45.1',
  },

  // ===========================================================================
  // INFRASTRUCTURE
  // ===========================================================================
  infra: {
    pulumi: '3.217.1', // IaC (TypeScript) - Jan 2026
    'pulumi-aws': '7.15.0', // AWS provider
    'pulumi-awsx': '3.1.0', // AWS Crosswalk (higher-level constructs)
    'docker-compose': '2.32.0', // Container orchestration
    tailscale: '1.76.6', // Mesh network (nixpkgs-unstable, Dec 2025)
  },

  // ===========================================================================
  // TESTING & BUILD
  // ===========================================================================
  testing: {
    playwright: '1.57.0',
    vitest: '4.0.17',
    vite: '7.3.1',
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
    'better-auth': '1.4.15', // TypeScript-first auth (replaces Clerk)
    'livekit-client': '2.16.1', // Client SDK
    'livekit-server-sdk': '2.15.0', // Server SDK
  },

  // ===========================================================================
  // OBSERVABILITY (January 2026 - Datadog + OTEL 2.x)
  // ===========================================================================
  observability: {
    'opentelemetry-api': '1.9.0',
    'opentelemetry-sdk-node': '0.208.0',
    'opentelemetry-sdk-trace-node': '2.2.0',
    'opentelemetry-sdk-metrics': '2.2.0',
    'opentelemetry-resources': '2.2.0',
    'opentelemetry-semantic-conventions': '1.38.0',
    'opentelemetry-exporter-trace-otlp-proto': '0.208.0',
    'opentelemetry-exporter-metrics-otlp-proto': '0.208.0',
    'opentelemetry-auto-instrumentations-node': '0.56.0',
    'posthog-js': '1.200.0',
    'posthog-node': '5.14.1',
    'statsig-js-client': '3.31.0', // Web feature flags
    'statsig-node': '5.20.0', // Server feature flags
    'datadog-agent': '7.60.0', // Reference only (not npm)
  },

  // ===========================================================================
  // NIX ECOSYSTEM (January 2026 - BLEEDING EDGE)
  // ===========================================================================
  nix: {
    // Core flake inputs - BLEEDING EDGE
    nixpkgs: 'nixos-unstable',
    'nix-darwin': 'github:LnL7/nix-darwin',
    'home-manager': 'github:nix-community/home-manager', // master for 26.05

    // State versions - January 2026 bleeding edge
    'home-manager-stateVersion': '26.05',
    'nixos-stateVersion': '26.05',

    // Flake architecture (January 2026 standard)
    'flake-parts': 'github:hercules-ci/flake-parts',
    'git-hooks-nix': 'github:cachix/git-hooks.nix',

    // Formatters & linters
    nixfmt: '0.6.0',
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
    // NOTE: tsgo (@typescript/native-preview) used for compilation via scripts
    typescript: '5.9.3', // Kept for types - tsgo handles compilation
    effect: '3.19.14',
    '@effect/cli': '0.72.1',
    '@effect/platform': '0.94.1',
    '@effect/platform-node': '0.104.0',
    '@effect/platform-bun': '0.87.0',
    '@effect/printer': '0.47.0',
    '@effect/printer-ansi': '0.47.0',
    // NOTE: zod removed - it's in FORBIDDEN_PACKAGES (use Effect Schema)

    // Frontend
    react: '19.2.4',
    'react-dom': '19.2.4',
    xstate: '5.25.0',
    '@xstate/react': '6.0.0',
    '@tanstack/react-router': '1.151.6',
    tailwindcss: '4.1.17',

    // Backend (Effect Platform HTTP - no Hono)
    'drizzle-orm': '0.45.1',
    'drizzle-kit': '0.31.8',

    // Auth
    'better-auth': '1.4.15',
    '@better-auth/expo': '1.4.15',

    // Observability (Datadog + OTEL 2.x)
    '@opentelemetry/api': '1.9.0',
    '@opentelemetry/sdk-node': '0.208.0',
    '@opentelemetry/sdk-trace-node': '2.2.0',
    '@opentelemetry/sdk-metrics': '2.2.0',
    '@opentelemetry/resources': '2.2.0',
    '@opentelemetry/semantic-conventions': '1.38.0',
    '@opentelemetry/exporter-trace-otlp-proto': '0.208.0',
    '@opentelemetry/exporter-metrics-otlp-proto': '0.208.0',
    '@opentelemetry/auto-instrumentations-node': '0.56.0',
    'posthog-js': '1.200.0',
    'posthog-node': '5.14.1',
    '@statsig/js-client': '3.31.0',
    '@statsig/react-bindings': '3.31.0',
    'statsig-node': '2.6.0',

    // Cache & Queue
    ioredis: '5.8.2',

    // Database
    '@libsql/client': '0.15.15',
    postgres: '3.4.7',

    // Testing
    '@playwright/test': '1.57.0',
    vitest: '4.0.17',
    '@vitest/ui': '4.0.17',

    // Build
    vite: '7.3.1',
    handlebars: '4.7.8',

    // Dev & Linting (Jan 2026 - SOTA: oxlint for linting, biome for formatting)
    oxlint: '1.39.0', // Type-aware linter (Oxlint 1.0 stable, 655+ rules)
    '@biomejs/biome': '2.3.11', // Formatter ONLY (linting disabled)
    '@types/node': '25.0.3', // Node 25 Current types
    tsx: '4.19.2', // TS runner
    '@ast-grep/napi': '0.40.3',
    '@ast-grep/cli': '0.40.3', // CLI for ast-grep scan
    lefthook: '2.0.13', // Git hooks manager

    // Pulumi (infrastructure) - Jan 2026
    '@pulumi/pulumi': '3.217.1',
    '@pulumi/aws': '7.15.0',
    '@pulumi/awsx': '3.1.0',
    '@pulumi/random': '4.18.4',
    '@pulumi/policy': '1.20.0',

    // Effect ecosystem - OpenTelemetry integration
    '@effect/opentelemetry': '0.44.0',

    // Effect SQL (evolution system)
    '@effect/sql': '0.49.0',
    '@effect/sql-sqlite-bun': '0.50.0',

    // Effect testing
    '@effect/vitest': '0.27.0',

    // Utilities
    tinyglobby: '0.2.15',

    // Voice AI
    hume: '0.15.7',

    // Auth (JWT)
    jose: '6.1.3',

    // React ecosystem - additional utilities
    'react-hook-form': '7.56.4',
    clsx: '2.1.1',
    'tailwind-merge': '3.2.0',

    // WebGL
    ogl: '1.0.11',

    // ===========================================================================
    // MOBILE / UNIVERSAL (for package.json generation - SDK 54)
    // ===========================================================================
    expo: '54.0.31',
    'react-native': '0.81.5',
    'react-native-web': '0.21.1',
    'expo-router': '6.0.21',
    'react-native-reanimated': '4.1.1',
    moti: '0.30.0',
    'react-native-gesture-handler': '2.28.0',
    nativewind: '4.1.23',
    'react-native-screens': '4.16.0',
    'react-native-safe-area-context': '5.6.2',
    'expo-splash-screen': '0.30.0',
    'expo-status-bar': '2.0.0',
    'expo-constants': '17.0.0',
    'expo-linking': '7.0.0',
    'expo-secure-store': '14.0.0',
    'expo-image': '2.0.0',
    'expo-video': '2.0.0',
    'expo-audio': '1.0.0',
    'expo-haptics': '14.0.0',
    'expo-notifications': '0.30.0',
    'expo-updates': '0.28.0',
    'expo-background-task': '0.2.0',
    '@shopify/flash-list': '2.0.0',
    '@react-native-async-storage/async-storage': '2.1.0',
    'expo-sqlite': '15.0.0',

    // ===========================================================================
    // LIVEKIT (Voice AI - Told apps/agent)
    // ===========================================================================
    'livekit-client': '2.16.1',
    'livekit-server-sdk': '2.15.0',
    '@livekit/agents': '1.0.31',
    '@livekit/agents-plugin-cartesia': '1.0.31',
    '@livekit/agents-plugin-deepgram': '1.0.31',
    '@livekit/agents-plugin-silero': '1.0.31',
    '@livekit/react-native': '2.9.6',
    '@livekit/react-native-webrtc': '137.0.2',

    // ===========================================================================
    // DATABASE (PostgreSQL + PGLite)
    // ===========================================================================
    '@electric-sql/pglite': '0.3.14',
  },
} as const satisfies StackDefinition

/**
 * Validate STACK at runtime (development check)
 * Returns Either with validation result.
 *
 * Note: This is redundant with `as const satisfies StackDefinition` compile-time check,
 * but kept for backward compatibility and explicit runtime assertion.
 */
export function validateStack(): Either.Either<StackDefinition, ParseResult.ParseError> {
  return Schema.decodeUnknownEither(StackDefinitionSchema)(STACK)
}

/**
 * Export as JSON for backward compatibility
 * This allows existing code that reads versions.json to continue working
 */
export const versionsJson = JSON.stringify(STACK, null, 2)

/**
 * Get a specific npm package version
 * Type-safe access to npm versions
 */
export function getNpmVersion<K extends keyof typeof STACK.npm>(pkg: K): string {
  return STACK.npm[pkg]
}

/**
 * Get all npm versions as a Record
 * Useful for generating package.json dependencies
 */
export function getNpmVersions(): Record<string, string> {
  return { ...STACK.npm }
}

/**
 * Check if a package version matches the SSOT
 */
export function isVersionMatch(pkg: string, version: string): boolean {
  const npmVersions: Readonly<Record<string, string>> = STACK.npm
  const expected = npmVersions[pkg]
  if (!expected) return true // Unknown packages are allowed
  return expected === version
}

/**
 * Get drift report for a set of dependencies
 */
export function getDrift(
  dependencies: Record<string, string>,
): Array<{ pkg: string; expected: string; actual: string }> {
  const drift: Array<{ pkg: string; expected: string; actual: string }> = []
  const npmVersions: Readonly<Record<string, string>> = STACK.npm

  for (const [pkg, version] of Object.entries(dependencies)) {
    const expected = npmVersions[pkg]
    if (expected && expected !== version) {
      drift.push({ pkg, expected, actual: version })
    }
  }

  return drift
}
