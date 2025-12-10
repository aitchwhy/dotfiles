/**
 * Stack Definition Schema
 *
 * TypeScript types are the source of truth.
 * Zod schemas validate at runtime using `satisfies` pattern.
 *
 * This replaces lib/versions.nix as the single source of truth
 * for all version numbers and stack configuration.
 */
import { z } from 'zod';

// =============================================================================
// VERSION STRING VALIDATION
// =============================================================================

/** Version string with optional pre-release (e.g., "1.2.3-beta.1") */
const versionPattern = /^\d+\.\d+\.\d+(-[\w.]+)?$/;

const versionString = z.string().regex(versionPattern, 'Must be valid semver');

/** Nix flake URL (e.g., "github:owner/repo" or "github:owner/repo/branch") */
const flakeUrlPattern = /^github:[\w-]+\/[\w.-]+(\/[\w.-]+)?$/;

const flakeUrl = z.string().regex(flakeUrlPattern, 'Must be valid flake URL');

/** Nix branch name (e.g., "nixos-unstable") */
const nixBranch = z.string().min(1);

// =============================================================================
// MINIMUM VERSION ENFORCEMENT (December 2025 Policy)
// =============================================================================

/** Python must be 3.14.0 or higher */
const pythonMinVersion = z
  .string()
  .regex(versionPattern, 'Must be valid semver')
  .refine(
    (v) => {
      const parts = v.split('.').map(Number);
      const major = parts[0] ?? 0;
      const minor = parts[1] ?? 0;
      return major > 3 || (major === 3 && minor >= 14);
    },
    'Python must be 3.14.0 or higher (no 3.12/3.13)'
  );

// =============================================================================
// TYPESCRIPT TYPES (Source of Truth)
// =============================================================================

/**
 * Runtime version definitions
 */
export type RuntimeVersions = {
  readonly bun: string;
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
 * Backend framework versions
 */
export type BackendVersions = {
  readonly hono: string;
  readonly 'drizzle-orm': string;
  readonly temporal: string;
  readonly restate: string;
};

/**
 * Infrastructure tool versions
 */
export type InfraVersions = {
  readonly pulumi: string;
  readonly 'pulumi-gcp': string;
  readonly 'process-compose': string;
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
 * Observability tool versions
 */
export type ObservabilityVersions = {
  readonly 'opentelemetry-api': string;
  readonly 'opentelemetry-sdk': string;
  readonly 'posthog-js': string;
  readonly 'posthog-node': string;
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

  // Backend
  readonly hono: string;
  readonly '@hono/zod-openapi': string;
  readonly 'drizzle-orm': string;
  readonly 'drizzle-kit': string;

  // Auth
  readonly 'better-auth': string;

  // Durable Workflows
  readonly '@temporalio/client': string;
  readonly '@temporalio/worker': string;
  readonly '@temporalio/workflow': string;
  readonly '@temporalio/activity': string;
  readonly '@restatedev/restate-sdk': string;

  // Observability
  readonly '@opentelemetry/api': string;
  readonly '@opentelemetry/sdk-trace-node': string;
  readonly '@opentelemetry/exporter-trace-otlp-http': string;
  readonly 'posthog-js': string;
  readonly 'posthog-node': string;

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
  readonly '@types/bun': string;
  readonly '@ast-grep/napi': string;

  // Pulumi (infrastructure)
  readonly '@pulumi/pulumi': string;
  readonly '@pulumi/gcp': string;
  readonly '@pulumi/random': string;
  readonly '@pulumi/policy': string;
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
// ZOD SCHEMAS (Runtime Validation)
// =============================================================================

export const runtimeVersionsSchema = z.object({
  bun: versionString,
  node: versionString,
  uv: versionString,
  volta: versionString,
}) satisfies z.ZodType<RuntimeVersions>;

export const frontendVersionsSchema = z.object({
  react: versionString,
  'react-dom': versionString,
  xstate: versionString,
  'tanstack-router': versionString,
  tailwindcss: versionString,
}) satisfies z.ZodType<FrontendVersions>;

export const backendVersionsSchema = z.object({
  hono: versionString,
  'drizzle-orm': versionString,
  temporal: versionString,
  restate: versionString,
}) satisfies z.ZodType<BackendVersions>;

export const infraVersionsSchema = z.object({
  pulumi: versionString,
  'pulumi-gcp': versionString,
  'process-compose': versionString,
  tailscale: versionString,
}) satisfies z.ZodType<InfraVersions>;

export const testingVersionsSchema = z.object({
  playwright: versionString,
  vitest: versionString,
  vite: versionString,
  'bruno-cli': versionString,
}) satisfies z.ZodType<TestingVersions>;

export const pythonVersionsSchema = z.object({
  python: pythonMinVersion, // Enforced minimum: 3.14.0+
  pydantic: versionString,
  ruff: versionString,
}) satisfies z.ZodType<PythonVersions>;

export const databaseVersionsSchema = z.object({
  'libsql-client': versionString,
  postgres: versionString,
}) satisfies z.ZodType<DatabaseVersions>;

export const serviceVersionsSchema = z.object({
  'better-auth': versionString,
  livekit: versionString,
}) satisfies z.ZodType<ServiceVersions>;

export const observabilityVersionsSchema = z.object({
  'opentelemetry-api': versionString,
  'opentelemetry-sdk': versionString,
  'posthog-js': versionString,
  'posthog-node': versionString,
  'datadog-agent': versionString,
}) satisfies z.ZodType<ObservabilityVersions>;

export const stackMetaSchema = z.object({
  frozen: z.string(),
  updated: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  ssotVersion: versionString,
}) satisfies z.ZodType<StackMeta>;

/** State version string (e.g., "26.05") */
const stateVersionString = z.string().regex(/^\d{2}\.\d{2}$/, 'Must be YY.MM format');

export const nixVersionsSchema = z.object({
  // Core flake inputs
  nixpkgs: nixBranch,
  'nix-darwin': flakeUrl,
  'home-manager': flakeUrl,

  // State versions - December 2025 bleeding edge
  'home-manager-stateVersion': stateVersionString,
  'nixos-stateVersion': stateVersionString,

  // Flake architecture
  'flake-parts': flakeUrl,
  'git-hooks-nix': flakeUrl,

  // Formatters & linters (semver)
  'nixfmt-rfc-style': versionString,
  deadnix: versionString,
  statix: versionString,
  alejandra: versionString,

  // Language server
  nixd: versionString,

  // Build tooling
  'nix-output-monitor': versionString,
  'nix-tree': versionString,
  'nix-diff': versionString,

  // Optional inputs
  disko: flakeUrl,
  'sops-nix': flakeUrl,
  'nix-homebrew': flakeUrl,
}) satisfies z.ZodType<NixVersions>;

export const npmVersionsSchema = z.object({
  // Core
  typescript: versionString,
  effect: versionString,
  '@effect/cli': versionString,
  '@effect/platform': versionString,
  '@effect/platform-node': versionString,
  '@effect/platform-bun': versionString,
  '@effect/printer': versionString,
  '@effect/printer-ansi': versionString,
  zod: versionString,

  // Frontend
  react: versionString,
  'react-dom': versionString,
  xstate: versionString,
  '@xstate/react': versionString,
  '@tanstack/react-router': versionString,
  tailwindcss: versionString,

  // Backend
  hono: versionString,
  '@hono/zod-openapi': versionString,
  'drizzle-orm': versionString,
  'drizzle-kit': versionString,

  // Auth
  'better-auth': versionString,

  // Durable Workflows
  '@temporalio/client': versionString,
  '@temporalio/worker': versionString,
  '@temporalio/workflow': versionString,
  '@temporalio/activity': versionString,
  '@restatedev/restate-sdk': versionString,

  // Observability
  '@opentelemetry/api': versionString,
  '@opentelemetry/sdk-trace-node': versionString,
  '@opentelemetry/exporter-trace-otlp-http': versionString,
  'posthog-js': versionString,
  'posthog-node': versionString,

  // Cache & Queue
  ioredis: versionString,

  // Database
  '@libsql/client': versionString,
  postgres: versionString,

  // Testing
  '@playwright/test': versionString,
  vitest: versionString,
  '@vitest/ui': versionString,

  // Build
  vite: versionString,
  handlebars: versionString,

  // Dev & Linting
  oxlint: versionString,
  '@biomejs/biome': versionString,
  '@types/bun': versionString,
  '@ast-grep/napi': versionString,

  // Pulumi
  '@pulumi/pulumi': versionString,
  '@pulumi/gcp': versionString,
  '@pulumi/random': versionString,
  '@pulumi/policy': versionString,
}) satisfies z.ZodType<NpmVersions>;

export const stackDefinitionSchema = z.object({
  meta: stackMetaSchema,
  runtime: runtimeVersionsSchema,
  frontend: frontendVersionsSchema,
  backend: backendVersionsSchema,
  infra: infraVersionsSchema,
  testing: testingVersionsSchema,
  python: pythonVersionsSchema,
  databases: databaseVersionsSchema,
  services: serviceVersionsSchema,
  observability: observabilityVersionsSchema,
  nix: nixVersionsSchema,
  npm: npmVersionsSchema,
}) satisfies z.ZodType<StackDefinition>;

// =============================================================================
// HELPER TYPES FOR PULUMI COMPONENTS
// =============================================================================

/** Environment type for infrastructure */
export type Environment = 'dev' | 'staging' | 'prod';

/** GCP regions we support */
export type GcpRegion =
  | 'us-central1'
  | 'us-east1'
  | 'us-west1'
  | 'europe-west1'
  | 'asia-east1';

/** Database tiers for Cloud SQL */
export type DatabaseTier =
  | 'db-f1-micro'
  | 'db-g1-small'
  | 'db-custom-1-3840'
  | 'db-custom-2-7680'
  | 'db-custom-4-15360';

/** Cloud Run memory options */
export type CloudRunMemory =
  | '256Mi'
  | '512Mi'
  | '1Gi'
  | '2Gi'
  | '4Gi'
  | '8Gi';

/** Cloud Run CPU options */
export type CloudRunCpu = '1' | '2' | '4' | '8';
