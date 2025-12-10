/**
 * ProjectSpec Schema
 *
 * The formal specification language for Signet.
 * Every project is a parameter instantiation of this schema.
 *
 * Pattern: TypeScript types are source of truth, schemas satisfy types.
 * Uses Effect Schema for parse-don't-validate semantics.
 */
import { Schema } from 'effect';

// =============================================================================
// Effect Schema Branded Types
// =============================================================================

// For Effect Schema, the schema IS the source of truth for branded types
// because Effect's brand() creates a unique nominal type at the schema level.
// We derive types from these specific schemas (exception to TS-first rule).

export const projectNameSchema = Schema.String.pipe(
  Schema.pattern(/^[a-z][a-z0-9-]*$/),
  Schema.brand('ProjectName')
);
export type ProjectName = typeof projectNameSchema.Type;

export const portSchema = Schema.Number.pipe(
  Schema.int(),
  Schema.between(1024, 65535),
  Schema.brand('Port')
);
export type Port = typeof portSchema.Type;

// =============================================================================
// TypeScript Types (Source of Truth for Non-Branded Types)
// =============================================================================

/**
 * Project types supported by the factory
 */
export type ProjectType = 'monorepo' | 'api' | 'ui' | 'infra' | 'library';

/**
 * Database types
 */
export type DatabaseType = 'turso' | 'd1' | 'neon';

/**
 * Queue types
 */
export type QueueType = 'redis' | 'sqs' | 'none';

/**
 * Auth types
 */
export type AuthType = 'better-auth' | 'none';

/**
 * Workflow/Durable Execution types
 */
export type WorkflowType = 'temporal' | 'restate' | 'none';

/**
 * Telemetry provider types
 */
export type TelemetryProvider = 'opentelemetry' | 'posthog' | 'both' | 'none';

/**
 * Cache types
 */
export type CacheType = 'redis' | 'none';

/**
 * Runtime types
 */
export type RuntimeType = 'bun' | 'node';

/**
 * Debugger types
 */
export type DebuggerType = 'vscode' | 'nvim-dap';

/**
 * Port configuration for services
 */
export type PortConfig = {
  readonly http?: Port | undefined;
  readonly debug?: Port | undefined;
  readonly metrics?: Port | undefined;
};

/**
 * Infrastructure configuration
 */
export type InfraConfig = {
  readonly runtime: RuntimeType;
  readonly database?: DatabaseType | undefined;
  readonly queue?: QueueType | undefined;
  readonly cache?: CacheType | undefined;
  readonly auth?: AuthType | undefined;
  readonly workflow?: WorkflowType | undefined;
  readonly telemetry?: TelemetryProvider | undefined;
};

/**
 * Observability configuration (REQUIRED for all projects)
 */
export type ObservabilityConfig = {
  readonly processCompose: true;
  readonly metrics: boolean;
  readonly debugger: DebuggerType;
};

/**
 * Port definition for hexagonal architecture
 */
export type PortDefinition = {
  readonly method: string;
  readonly input: unknown;
  readonly output: unknown;
};

/**
 * Ports record - maps port names to definitions
 */
export type Ports = Record<string, PortDefinition>;

/**
 * Workspace definition
 */
export type Workspace = {
  readonly name: ProjectName;
  readonly type: ProjectType;
  readonly path: string;
};

/**
 * ProjectSpec - The complete project specification
 *
 * This is the DNA of every generated project.
 * All other schemas derive from or compose with this.
 */
export type ProjectSpec = {
  readonly name: ProjectName;
  readonly description?: string | undefined;
  readonly type: ProjectType;
  readonly ports?: PortConfig | undefined;
  readonly hexagonal?:
    | {
        readonly ports?: Ports | undefined;
      }
    | undefined;
  readonly infra: InfraConfig;
  readonly observability: ObservabilityConfig;
  readonly workspaces?: readonly Workspace[] | undefined;
};

// =============================================================================
// Effect Schemas (Satisfy TypeScript Types)
// =============================================================================

// Literal/Enum schemas
export const projectTypeSchema = Schema.Literal(
  'monorepo',
  'api',
  'ui',
  'infra',
  'library'
) satisfies Schema.Schema<ProjectType>;

export const databaseTypeSchema = Schema.Literal(
  'turso',
  'd1',
  'neon'
) satisfies Schema.Schema<DatabaseType>;

export const queueTypeSchema = Schema.Literal(
  'redis',
  'sqs',
  'none'
) satisfies Schema.Schema<QueueType>;

export const authTypeSchema = Schema.Literal(
  'better-auth',
  'none'
) satisfies Schema.Schema<AuthType>;

export const workflowTypeSchema = Schema.Literal(
  'temporal',
  'restate',
  'none'
) satisfies Schema.Schema<WorkflowType>;

export const telemetryProviderSchema = Schema.Literal(
  'opentelemetry',
  'posthog',
  'both',
  'none'
) satisfies Schema.Schema<TelemetryProvider>;

export const cacheTypeSchema = Schema.Literal('redis', 'none') satisfies Schema.Schema<CacheType>;

export const runtimeTypeSchema = Schema.Literal('bun', 'node') satisfies Schema.Schema<RuntimeType>;

export const debuggerTypeSchema = Schema.Literal(
  'vscode',
  'nvim-dap'
) satisfies Schema.Schema<DebuggerType>;

// Config object schemas
export const portConfigSchema = Schema.Struct({
  http: Schema.optional(portSchema),
  debug: Schema.optional(portSchema),
  metrics: Schema.optional(portSchema),
});

export const infraConfigSchema = Schema.Struct({
  runtime: runtimeTypeSchema,
  database: Schema.optional(databaseTypeSchema),
  queue: Schema.optional(queueTypeSchema),
  cache: Schema.optional(cacheTypeSchema),
  auth: Schema.optional(authTypeSchema),
  workflow: Schema.optional(workflowTypeSchema),
  telemetry: Schema.optional(telemetryProviderSchema),
});

export const observabilityConfigSchema = Schema.Struct({
  processCompose: Schema.Literal(true),
  metrics: Schema.Boolean,
  debugger: debuggerTypeSchema,
});

export const portDefinitionSchema = Schema.Struct({
  method: Schema.String,
  input: Schema.Unknown,
  output: Schema.Unknown,
}) satisfies Schema.Schema<PortDefinition>;

export const portsSchema = Schema.Record({
  key: Schema.String,
  value: portDefinitionSchema,
});

export const workspaceSchema = Schema.Struct({
  name: projectNameSchema,
  type: projectTypeSchema,
  path: Schema.String,
});

// Main ProjectSpec schema
export const projectSpecSchema = Schema.Struct({
  name: projectNameSchema,
  description: Schema.optional(Schema.String),
  type: projectTypeSchema,
  ports: Schema.optional(portConfigSchema),
  hexagonal: Schema.optional(
    Schema.Struct({
      ports: Schema.optional(portsSchema),
    })
  ),
  infra: infraConfigSchema,
  observability: observabilityConfigSchema,
  workspaces: Schema.optional(Schema.Array(workspaceSchema)),
});

// =============================================================================
// Helpers
// =============================================================================

/**
 * Decode unknown input to ProjectSpec
 */
export const decodeProjectSpec = Schema.decodeUnknown(projectSpecSchema);

/**
 * Encode ProjectSpec to unknown (for serialization)
 */
export const encodeProjectSpec = Schema.encode(projectSpecSchema);

/**
 * Validate that input is a valid ProjectSpec
 */
export const isProjectSpec = Schema.is(projectSpecSchema);

// =============================================================================
// Legacy Exports (for backwards compatibility during migration)
// =============================================================================

// These match the old PascalCase export names
export const ProjectName = projectNameSchema;
export const Port = portSchema;
export const ProjectType = projectTypeSchema;
export const DatabaseType = databaseTypeSchema;
export const QueueType = queueTypeSchema;
export const AuthType = authTypeSchema;
export const WorkflowType = workflowTypeSchema;
export const TelemetryProvider = telemetryProviderSchema;
export const CacheType = cacheTypeSchema;
export const RuntimeType = runtimeTypeSchema;
export const DebuggerType = debuggerTypeSchema;
export const PortConfig = portConfigSchema;
export const InfraConfig = infraConfigSchema;
export const ObservabilityConfig = observabilityConfigSchema;
export const PortDefinition = portDefinitionSchema;
export const Ports = portsSchema;
export const ProjectSpec = projectSpecSchema;
