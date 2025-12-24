/**
 * Stack Definition Schema
 *
 * TypeScript types are the source of truth.
 * Effect Schema validates at runtime using `satisfies` pattern.
 *
 * This replaces lib/versions.nix as the single source of truth
 * for all version numbers and stack configuration.
 */
import { Schema } from 'effect';

// =============================================================================
// VERSION STRING VALIDATION
// =============================================================================

/** Version string with optional pre-release (e.g., "1.2.3-beta.1") */
const versionPattern = /^\d+\.\d+\.\d+(-[\w.]+)?$/;

const VersionString = Schema.String.pipe(
  Schema.pattern(versionPattern, {
    message: () => 'Must be valid semver',
  })
);

/** Nix flake URL (e.g., "github:owner/repo" or "github:owner/repo/branch") */
const flakeUrlPattern = /^github:[\w-]+\/[\w.-]+(\/[\w.-]+)?$/;

const FlakeUrl = Schema.String.pipe(
  Schema.pattern(flakeUrlPattern, {
    message: () => 'Must be valid flake URL',
  })
);

/** Nix branch name (e.g., "nixos-unstable") */
const NixBranch = Schema.String.pipe(Schema.minLength(1));

/** State version string (e.g., "26.05") */
const stateVersionPattern = /^\d{2}\.\d{2}$/;

const StateVersionString = Schema.String.pipe(
  Schema.pattern(stateVersionPattern, {
    message: () => 'Must be YY.MM format',
  })
);

/** Date string (e.g., "2024-12-21") */
const datePattern = /^\d{4}-\d{2}-\d{2}$/;

const DateString = Schema.String.pipe(
  Schema.pattern(datePattern, {
    message: () => 'Must be YYYY-MM-DD format',
  })
);

// =============================================================================
// MINIMUM VERSION ENFORCEMENT (December 2025 Policy)
// =============================================================================

/** Python must be 3.14.0 or higher */
const PythonMinVersion = Schema.String.pipe(
  Schema.pattern(versionPattern, {
    message: () => 'Must be valid semver',
  }),
  Schema.filter(
    (v) => {
      const parts = v.split('.').map(Number);
      const major = parts[0] ?? 0;
      const minor = parts[1] ?? 0;
      return major > 3 || (major === 3 && minor >= 14);
    },
    {
      message: () => 'Python must be 3.14.0 or higher (no 3.12/3.13)',
    }
  )
);

// =============================================================================
// TYPESCRIPT TYPES (Source of Truth)
// =============================================================================

/**
 * Runtime version definitions
 */
export type RuntimeVersions = {
  readonly pnpm: string;
  readonly node: string;
  readonly uv: string;
  readonly volta: string;
};

/**
 * Frontend framework versions
 */
export type FrontendVersions = {
  readonly react: string;
  readonly 'react-dom': string;
  readonly xstate: string;
  readonly 'tanstack-router': string;
  readonly tailwindcss: string;
};

/**
 * Backend framework versions (Effect Platform HTTP + Drizzle)
 */
export type BackendVersions = {
  readonly 'drizzle-orm': string;
};

/**
 * Infrastructure tool versions
 */
export type InfraVersions = {
  readonly pulumi: string;
  readonly 'pulumi-aws': string;
  readonly 'pulumi-awsx': string;
  readonly 'docker-compose': string;
  readonly tailscale: string;
};

/**
 * Testing framework versions
 */
export type TestingVersions = {
  readonly playwright: string;
  readonly vitest: string;
  readonly vite: string;
  readonly 'bruno-cli': string;
};

/**
 * Python ecosystem versions
 */
export type PythonVersions = {
  readonly python: string;
  readonly pydantic: string;
  readonly ruff: string;
};

/**
 * Database adapter versions
 */
export type DatabaseVersions = {
  readonly 'libsql-client': string;
  readonly postgres: string;
};

/**
 * Service versions (auth, realtime, etc.)
 */
export type ServiceVersions = {
  readonly 'better-auth': string;
  readonly livekit: string;
};

/**
 * Observability tool versions (Datadog + OTEL 2.x)
 */
export type ObservabilityVersions = {
  readonly 'opentelemetry-api': string;
  readonly 'opentelemetry-sdk-node': string;
  readonly 'opentelemetry-sdk-trace-node': string;
  readonly 'opentelemetry-sdk-metrics': string;
  readonly 'opentelemetry-resources': string;
  readonly 'opentelemetry-semantic-conventions': string;
  readonly 'opentelemetry-exporter-trace-otlp-proto': string;
  readonly 'opentelemetry-exporter-metrics-otlp-proto': string;
  readonly 'opentelemetry-auto-instrumentations-node': string;
  readonly 'posthog-js': string;
  readonly 'posthog-node': string;
  readonly 'statsig-js-client': string;
  readonly 'statsig-node': string;
  readonly 'datadog-agent': string;
};

/**
 * Nix ecosystem versions (flake URLs and tool versions)
 */
export type NixVersions = {
  // Core flake inputs
  readonly nixpkgs: string;
  readonly 'nix-darwin': string;
  readonly 'home-manager': string;

  // State versions - December 2025 bleeding edge
  readonly 'home-manager-stateVersion': string;
  readonly 'nixos-stateVersion': string;

  // Flake architecture (December 2025 standard)
  readonly 'flake-parts': string;
  readonly 'git-hooks-nix': string;

  // Formatters & linters
  readonly 'nixfmt-rfc-style': string;
  readonly deadnix: string;
  readonly statix: string;
  readonly alejandra: string;

  // Language server
  readonly nixd: string;

  // Build tooling
  readonly 'nix-output-monitor': string;
  readonly 'nix-tree': string;
  readonly 'nix-diff': string;

  // Optional inputs
  readonly disko: string;
  readonly 'sops-nix': string;
  readonly 'nix-homebrew': string;
};

/**
 * Stack metadata
 */
export type StackMeta = {
  readonly frozen: string;
  readonly updated: string;
  readonly ssotVersion: string;
};

/**
 * Flat npm dependencies for package.json generation
 * Key is the exact npm package name, value is the exact version
 */
export type NpmVersions = {
  // Core (Effect ecosystem)
  readonly typescript: string;
  readonly effect: string;
  readonly '@effect/cli': string;
  readonly '@effect/platform': string;
  readonly '@effect/platform-node': string;
  readonly '@effect/platform-bun': string;
  readonly '@effect/printer': string;
  readonly '@effect/printer-ansi': string;
  readonly zod: string;

  // Frontend
  readonly react: string;
  readonly 'react-dom': string;
  readonly xstate: string;
  readonly '@xstate/react': string;
  readonly '@tanstack/react-router': string;
  readonly tailwindcss: string;

  // Backend (Effect Platform HTTP - no Hono)
  readonly 'drizzle-orm': string;
  readonly 'drizzle-kit': string;

  // Auth
  readonly 'better-auth': string;

  // Observability (Datadog + OTEL 2.x)
  readonly '@opentelemetry/api': string;
  readonly '@opentelemetry/sdk-node': string;
  readonly '@opentelemetry/sdk-trace-node': string;
  readonly '@opentelemetry/sdk-metrics': string;
  readonly '@opentelemetry/resources': string;
  readonly '@opentelemetry/semantic-conventions': string;
  readonly '@opentelemetry/exporter-trace-otlp-proto': string;
  readonly '@opentelemetry/exporter-metrics-otlp-proto': string;
  readonly '@opentelemetry/auto-instrumentations-node': string;
  readonly 'posthog-js': string;
  readonly 'posthog-node': string;
  readonly '@statsig/js-client': string;
  readonly '@statsig/react-bindings': string;
  readonly 'statsig-node': string;

  // Cache & Queue
  readonly ioredis: string;

  // Database
  readonly '@libsql/client': string;
  readonly postgres: string;

  // Testing
  readonly '@playwright/test': string;
  readonly vitest: string;
  readonly '@vitest/ui': string;

  // Build
  readonly vite: string;
  readonly handlebars: string;

  // Dev & Linting
  readonly oxlint: string;
  readonly '@biomejs/biome': string;
  readonly '@types/node': string;
  readonly tsx: string;
  readonly '@ast-grep/napi': string;

  // Pulumi (infrastructure)
  readonly '@pulumi/pulumi': string;
  readonly '@pulumi/aws': string;
  readonly '@pulumi/awsx': string;
  readonly '@pulumi/random': string;
  readonly '@pulumi/policy': string;

  // Effect ecosystem - OpenTelemetry integration
  readonly '@effect/opentelemetry': string;

  // Effect SQL (evolution system)
  readonly '@effect/sql': string;
  readonly '@effect/sql-sqlite-bun': string;

  // Effect testing
  readonly '@effect/vitest': string;

  // Utilities
  readonly tinyglobby: string;

  // Voice AI
  readonly hume: string;

  // Auth (JWT)
  readonly jose: string;

  // React ecosystem - additional utilities
  readonly 'react-hook-form': string;
  readonly clsx: string;
  readonly 'tailwind-merge': string;

  // WebGL
  readonly ogl: string;
};

/**
 * Complete stack definition - single source of truth
 * Replaces lib/versions.nix
 */
export type StackDefinition = {
  readonly meta: StackMeta;
  readonly runtime: RuntimeVersions;
  readonly frontend: FrontendVersions;
  readonly backend: BackendVersions;
  readonly infra: InfraVersions;
  readonly testing: TestingVersions;
  readonly python: PythonVersions;
  readonly databases: DatabaseVersions;
  readonly services: ServiceVersions;
  readonly observability: ObservabilityVersions;
  readonly nix: NixVersions;
  readonly npm: NpmVersions;
};

// =============================================================================
// EFFECT SCHEMAS (Runtime Validation)
// =============================================================================

export const RuntimeVersionsSchema = Schema.Struct({
  pnpm: VersionString,
  node: VersionString,
  uv: VersionString,
  volta: VersionString,
}) satisfies Schema.Schema<RuntimeVersions, RuntimeVersions>;

export const FrontendVersionsSchema = Schema.Struct({
  react: VersionString,
  'react-dom': VersionString,
  xstate: VersionString,
  'tanstack-router': VersionString,
  tailwindcss: VersionString,
}) satisfies Schema.Schema<FrontendVersions, FrontendVersions>;

export const BackendVersionsSchema = Schema.Struct({
  'drizzle-orm': VersionString,
}) satisfies Schema.Schema<BackendVersions, BackendVersions>;

export const InfraVersionsSchema = Schema.Struct({
  pulumi: VersionString,
  'pulumi-aws': VersionString,
  'pulumi-awsx': VersionString,
  'docker-compose': VersionString,
  tailscale: VersionString,
}) satisfies Schema.Schema<InfraVersions, InfraVersions>;

export const TestingVersionsSchema = Schema.Struct({
  playwright: VersionString,
  vitest: VersionString,
  vite: VersionString,
  'bruno-cli': VersionString,
}) satisfies Schema.Schema<TestingVersions, TestingVersions>;

export const PythonVersionsSchema = Schema.Struct({
  python: PythonMinVersion, // Enforced minimum: 3.14.0+
  pydantic: VersionString,
  ruff: VersionString,
}) satisfies Schema.Schema<PythonVersions, PythonVersions>;

export const DatabaseVersionsSchema = Schema.Struct({
  'libsql-client': VersionString,
  postgres: VersionString,
}) satisfies Schema.Schema<DatabaseVersions, DatabaseVersions>;

export const ServiceVersionsSchema = Schema.Struct({
  'better-auth': VersionString,
  livekit: VersionString,
}) satisfies Schema.Schema<ServiceVersions, ServiceVersions>;

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
}) satisfies Schema.Schema<ObservabilityVersions, ObservabilityVersions>;

export const StackMetaSchema = Schema.Struct({
  frozen: Schema.String,
  updated: DateString,
  ssotVersion: VersionString,
}) satisfies Schema.Schema<StackMeta, StackMeta>;

export const NixVersionsSchema = Schema.Struct({
  // Core flake inputs
  nixpkgs: NixBranch,
  'nix-darwin': FlakeUrl,
  'home-manager': FlakeUrl,

  // State versions - December 2025 bleeding edge
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
}) satisfies Schema.Schema<NixVersions, NixVersions>;

export const NpmVersionsSchema = Schema.Struct({
  // Core
  typescript: VersionString,
  effect: VersionString,
  '@effect/cli': VersionString,
  '@effect/platform': VersionString,
  '@effect/platform-node': VersionString,
  '@effect/platform-bun': VersionString,
  '@effect/printer': VersionString,
  '@effect/printer-ansi': VersionString,
  zod: VersionString,

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

  // Dev & Linting
  oxlint: VersionString,
  '@biomejs/biome': VersionString,
  '@types/node': VersionString,
  tsx: VersionString,
  '@ast-grep/napi': VersionString,

  // Pulumi
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
}) satisfies Schema.Schema<NpmVersions, NpmVersions>;

export const StackDefinitionSchema = Schema.Struct({
  meta: StackMetaSchema,
  runtime: RuntimeVersionsSchema,
  frontend: FrontendVersionsSchema,
  backend: BackendVersionsSchema,
  infra: InfraVersionsSchema,
  testing: TestingVersionsSchema,
  python: PythonVersionsSchema,
  databases: DatabaseVersionsSchema,
  services: ServiceVersionsSchema,
  observability: ObservabilityVersionsSchema,
  nix: NixVersionsSchema,
  npm: NpmVersionsSchema,
}) satisfies Schema.Schema<StackDefinition, StackDefinition>;

// =============================================================================
// HELPER TYPES FOR PULUMI COMPONENTS
// =============================================================================

/** Environment type for infrastructure */
export type Environment = 'dev' | 'staging' | 'prod';

/** AWS regions we support */
export type AwsRegion =
  | 'us-east-1'
  | 'us-east-2'
  | 'us-west-1'
  | 'us-west-2'
  | 'eu-west-1'
  | 'ap-northeast-1';

/** RDS instance classes */
export type RdsInstanceClass =
  | 'db.t4g.micro'
  | 'db.t4g.small'
  | 'db.t4g.medium'
  | 'db.r6g.large'
  | 'db.r6g.xlarge';

/** App Runner memory options (MB) */
export type AppRunnerMemory = '512' | '1024' | '2048' | '3072' | '4096';

/** App Runner CPU options (vCPU units) */
export type AppRunnerCpu = '256' | '512' | '1024' | '2048' | '4096';
