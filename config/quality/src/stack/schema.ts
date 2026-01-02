/**
 * Stack Definition Schema
 *
 * Effect Schema is the single source of truth.
 * TypeScript types are DERIVED from schemas (no manual type definitions).
 *
 * This replaces lib/versions.nix as the single source of truth
 * for all version numbers and stack configuration.
 */
import { Schema } from 'effect'

// =============================================================================
// VERSION STRING VALIDATION
// =============================================================================

/** Version string with optional pre-release (e.g., "1.2.3-beta.1") */
const versionPattern = /^\d+\.\d+\.\d+(-[\w.]+)?$/

const VersionString = Schema.String.pipe(
  Schema.pattern(versionPattern, {
    message: () => 'Must be valid semver',
  }),
)

/** Nix flake URL (e.g., "github:owner/repo" or "github:owner/repo/branch") */
const flakeUrlPattern = /^github:[\w-]+\/[\w.-]+(\/[\w.-]+)?$/

const FlakeUrl = Schema.String.pipe(
  Schema.pattern(flakeUrlPattern, {
    message: () => 'Must be valid flake URL',
  }),
)

/** Nix branch name (e.g., "nixos-unstable") */
const NixBranch = Schema.String.pipe(Schema.minLength(1))

/** State version string (e.g., "26.05") */
const stateVersionPattern = /^\d{2}\.\d{2}$/

const StateVersionString = Schema.String.pipe(
  Schema.pattern(stateVersionPattern, {
    message: () => 'Must be YY.MM format',
  }),
)

/** Date string (e.g., "2024-12-21") */
const datePattern = /^\d{4}-\d{2}-\d{2}$/

const DateString = Schema.String.pipe(
  Schema.pattern(datePattern, {
    message: () => 'Must be YYYY-MM-DD format',
  }),
)

// =============================================================================
// MINIMUM VERSION ENFORCEMENT (January 2026 Policy)
// =============================================================================

/** Parse semver string into [major, minor, patch] */
function parseSemver(v: string): [number, number, number] {
  const [major = 0, minor = 0, patch = 0] = v.split('.').map(Number)
  return [major, minor, patch]
}

/** Python must be 3.14.0 or higher */
const PythonMinVersion = Schema.String.pipe(
  Schema.pattern(versionPattern, {
    message: () => 'Must be valid semver',
  }),
  Schema.filter(
    (v) => {
      const [major, minor] = parseSemver(v)
      return major > 3 || (major === 3 && minor >= 14)
    },
    {
      message: () => 'Python must be 3.14.0 or higher (no 3.12/3.13)',
    },
  ),
)

// =============================================================================
// EFFECT SCHEMAS (Single Source of Truth)
// Types are DERIVED from schemas - no manual type definitions needed
// =============================================================================

/** Runtime version definitions */
export const RuntimeVersionsSchema = Schema.Struct({
  pnpm: VersionString,
  node: VersionString,
  uv: VersionString,
  volta: VersionString,
})
export type RuntimeVersions = Schema.Schema.Type<typeof RuntimeVersionsSchema>

/** Frontend framework versions (Web) */
export const FrontendVersionsSchema = Schema.Struct({
  react: VersionString,
  'react-dom': VersionString,
  xstate: VersionString,
  'tanstack-router': VersionString,
  tailwindcss: VersionString,
})
export type FrontendVersions = Schema.Schema.Type<typeof FrontendVersionsSchema>

/** Mobile/Universal versions (Expo SDK 53 - January 2026) */
export const MobileVersionsSchema = Schema.Struct({
  // Core runtime
  expo: VersionString,
  'react-native': VersionString,
  'react-native-web': VersionString,

  // Routing
  'expo-router': VersionString,

  // Animation
  'react-native-reanimated': VersionString,
  moti: VersionString,
  'react-native-gesture-handler': VersionString,

  // Styling
  nativewind: VersionString,

  // Navigation primitives
  'react-native-screens': VersionString,
  'react-native-safe-area-context': VersionString,

  // Essential Expo packages
  'expo-splash-screen': VersionString,
  'expo-status-bar': VersionString,
  'expo-constants': VersionString,
  'expo-linking': VersionString,
  'expo-secure-store': VersionString,
  'expo-image': VersionString,
  'expo-video': VersionString,
  'expo-audio': VersionString,
  'expo-haptics': VersionString,
  'expo-notifications': VersionString,
  'expo-updates': VersionString,
  'expo-background-task': VersionString,

  // Performance
  '@shopify/flash-list': VersionString,

  // Storage
  '@react-native-async-storage/async-storage': VersionString,
  'expo-sqlite': VersionString,
})
export type MobileVersions = Schema.Schema.Type<typeof MobileVersionsSchema>

/** Backend framework versions (Effect Platform HTTP + Drizzle) */
export const BackendVersionsSchema = Schema.Struct({
  'drizzle-orm': VersionString,
})
export type BackendVersions = Schema.Schema.Type<typeof BackendVersionsSchema>

/** Infrastructure tool versions */
export const InfraVersionsSchema = Schema.Struct({
  pulumi: VersionString,
  'pulumi-aws': VersionString,
  'pulumi-awsx': VersionString,
  'docker-compose': VersionString,
  tailscale: VersionString,
})
export type InfraVersions = Schema.Schema.Type<typeof InfraVersionsSchema>

/** Testing framework versions */
export const TestingVersionsSchema = Schema.Struct({
  playwright: VersionString,
  vitest: VersionString,
  vite: VersionString,
  'bruno-cli': VersionString,
})
export type TestingVersions = Schema.Schema.Type<typeof TestingVersionsSchema>

/** Python ecosystem versions */
export const PythonVersionsSchema = Schema.Struct({
  python: PythonMinVersion, // Enforced minimum: 3.14.0+
  pydantic: VersionString,
  ruff: VersionString,
})
export type PythonVersions = Schema.Schema.Type<typeof PythonVersionsSchema>

/** Database adapter versions */
export const DatabaseVersionsSchema = Schema.Struct({
  'libsql-client': VersionString,
  postgres: VersionString,
})
export type DatabaseVersions = Schema.Schema.Type<typeof DatabaseVersionsSchema>

/** Service versions (auth, realtime, etc.) */
export const ServiceVersionsSchema = Schema.Struct({
  'better-auth': VersionString,
  livekit: VersionString,
})
export type ServiceVersions = Schema.Schema.Type<typeof ServiceVersionsSchema>

/** Observability tool versions (Datadog + OTEL 2.x) */
export const ObservabilityVersionsSchema = Schema.Struct({
  'opentelemetry-api': VersionString,
  'opentelemetry-sdk-node': VersionString,
  'opentelemetry-sdk-trace-node': VersionString,
  'opentelemetry-sdk-metrics': VersionString,
  'opentelemetry-resources': VersionString,
  'opentelemetry-semantic-conventions': VersionString,
  'opentelemetry-exporter-trace-otlp-proto': VersionString,
  'opentelemetry-exporter-metrics-otlp-proto': VersionString,
  'opentelemetry-auto-instrumentations-node': VersionString,
  'posthog-js': VersionString,
  'posthog-node': VersionString,
  'statsig-js-client': VersionString,
  'statsig-node': VersionString,
  'datadog-agent': VersionString,
})
export type ObservabilityVersions = Schema.Schema.Type<typeof ObservabilityVersionsSchema>

/** Stack metadata */
export const StackMetaSchema = Schema.Struct({
  frozen: Schema.String,
  updated: DateString,
  ssotVersion: VersionString,
})
export type StackMeta = Schema.Schema.Type<typeof StackMetaSchema>

/** Nix ecosystem versions (flake URLs and tool versions) */
export const NixVersionsSchema = Schema.Struct({
  // Core flake inputs
  nixpkgs: NixBranch,
  'nix-darwin': FlakeUrl,
  'home-manager': FlakeUrl,

  // State versions - January 2026 bleeding edge
  'home-manager-stateVersion': StateVersionString,
  'nixos-stateVersion': StateVersionString,

  // Flake architecture
  'flake-parts': FlakeUrl,
  'git-hooks-nix': FlakeUrl,

  // Formatters & linters (semver)
  'nixfmt-rfc-style': VersionString,
  deadnix: VersionString,
  statix: VersionString,
  alejandra: VersionString,

  // Language server
  nixd: VersionString,

  // Build tooling
  'nix-output-monitor': VersionString,
  'nix-tree': VersionString,
  'nix-diff': VersionString,

  // Optional inputs
  disko: FlakeUrl,
  'sops-nix': FlakeUrl,
  'nix-homebrew': FlakeUrl,
})
export type NixVersions = Schema.Schema.Type<typeof NixVersionsSchema>

/**
 * Flat npm dependencies for package.json generation
 * Key is the exact npm package name, value is the exact version
 */
export const NpmVersionsSchema = Schema.Struct({
  // Core (Effect ecosystem)
  typescript: VersionString,
  effect: VersionString,
  '@effect/cli': VersionString,
  '@effect/platform': VersionString,
  '@effect/platform-node': VersionString,
  '@effect/platform-bun': VersionString,
  '@effect/printer': VersionString,
  '@effect/printer-ansi': VersionString,

  // Frontend
  react: VersionString,
  'react-dom': VersionString,
  xstate: VersionString,
  '@xstate/react': VersionString,
  '@tanstack/react-router': VersionString,
  tailwindcss: VersionString,

  // Backend (Effect Platform HTTP - no Hono)
  'drizzle-orm': VersionString,
  'drizzle-kit': VersionString,

  // Auth
  'better-auth': VersionString,

  // Observability (Datadog + OTEL 2.x)
  '@opentelemetry/api': VersionString,
  '@opentelemetry/sdk-node': VersionString,
  '@opentelemetry/sdk-trace-node': VersionString,
  '@opentelemetry/sdk-metrics': VersionString,
  '@opentelemetry/resources': VersionString,
  '@opentelemetry/semantic-conventions': VersionString,
  '@opentelemetry/exporter-trace-otlp-proto': VersionString,
  '@opentelemetry/exporter-metrics-otlp-proto': VersionString,
  '@opentelemetry/auto-instrumentations-node': VersionString,
  'posthog-js': VersionString,
  'posthog-node': VersionString,
  '@statsig/js-client': VersionString,
  '@statsig/react-bindings': VersionString,
  'statsig-node': VersionString,

  // Cache & Queue
  ioredis: VersionString,

  // Database
  '@libsql/client': VersionString,
  postgres: VersionString,

  // Testing
  '@playwright/test': VersionString,
  vitest: VersionString,
  '@vitest/ui': VersionString,

  // Build
  vite: VersionString,
  handlebars: VersionString,

  // Dev & Linting (oxlint for linting, biome for formatting)
  oxlint: VersionString,
  '@biomejs/biome': VersionString,
  '@types/node': VersionString,
  tsx: VersionString,
  '@ast-grep/napi': VersionString,
  '@ast-grep/cli': VersionString,
  lefthook: VersionString,

  // Pulumi (infrastructure)
  '@pulumi/pulumi': VersionString,
  '@pulumi/aws': VersionString,
  '@pulumi/awsx': VersionString,
  '@pulumi/random': VersionString,
  '@pulumi/policy': VersionString,

  // Effect ecosystem - OpenTelemetry integration
  '@effect/opentelemetry': VersionString,

  // Effect SQL (evolution system)
  '@effect/sql': VersionString,
  '@effect/sql-sqlite-bun': VersionString,

  // Effect testing
  '@effect/vitest': VersionString,

  // Utilities
  tinyglobby: VersionString,

  // Voice AI
  hume: VersionString,

  // Auth (JWT)
  jose: VersionString,

  // React ecosystem - additional utilities
  'react-hook-form': VersionString,
  clsx: VersionString,
  'tailwind-merge': VersionString,

  // WebGL
  ogl: VersionString,

  // Mobile / Universal
  expo: VersionString,
  'react-native': VersionString,
  'react-native-web': VersionString,
  'expo-router': VersionString,
  'react-native-reanimated': VersionString,
  moti: VersionString,
  'react-native-gesture-handler': VersionString,
  nativewind: VersionString,
  'react-native-screens': VersionString,
  'react-native-safe-area-context': VersionString,
  'expo-splash-screen': VersionString,
  'expo-status-bar': VersionString,
  'expo-constants': VersionString,
  'expo-linking': VersionString,
  'expo-secure-store': VersionString,
  'expo-image': VersionString,
  'expo-video': VersionString,
  'expo-audio': VersionString,
  'expo-haptics': VersionString,
  'expo-notifications': VersionString,
  'expo-updates': VersionString,
  'expo-background-task': VersionString,
  '@shopify/flash-list': VersionString,
  '@react-native-async-storage/async-storage': VersionString,
  'expo-sqlite': VersionString,
})
export type NpmVersions = Schema.Schema.Type<typeof NpmVersionsSchema>

/** Complete stack definition - single source of truth */
export const StackDefinitionSchema = Schema.Struct({
  meta: StackMetaSchema,
  runtime: RuntimeVersionsSchema,
  frontend: FrontendVersionsSchema,
  mobile: MobileVersionsSchema,
  backend: BackendVersionsSchema,
  infra: InfraVersionsSchema,
  testing: TestingVersionsSchema,
  python: PythonVersionsSchema,
  databases: DatabaseVersionsSchema,
  services: ServiceVersionsSchema,
  observability: ObservabilityVersionsSchema,
  nix: NixVersionsSchema,
  npm: NpmVersionsSchema,
})
export type StackDefinition = Schema.Schema.Type<typeof StackDefinitionSchema>

// =============================================================================
// HELPER TYPES FOR PULUMI COMPONENTS
// =============================================================================

/** Environment type for infrastructure */
export type Environment = 'dev' | 'staging' | 'prod'

/** AWS regions we support */
export type AwsRegion =
  | 'us-east-1'
  | 'us-east-2'
  | 'us-west-1'
  | 'us-west-2'
  | 'eu-west-1'
  | 'ap-northeast-1'

/** RDS instance classes */
export type RdsInstanceClass =
  | 'db.t4g.micro'
  | 'db.t4g.small'
  | 'db.t4g.medium'
  | 'db.r6g.large'
  | 'db.r6g.xlarge'

/** App Runner memory options (MB) */
export type AppRunnerMemory = '512' | '1024' | '2048' | '3072' | '4096'

/** App Runner CPU options (vCPU units) */
export type AppRunnerCpu = '256' | '512' | '1024' | '2048' | '4096'
