/**
 * ProjectSpec Schema
 *
 * The formal specification language for the Universal Project Factory.
 * Every project is a parameter instantiation of this schema.
 *
 * Uses Effect Schema for parse-don't-validate semantics.
 */
import { Schema } from 'effect'

// =============================================================================
// Branded Types
// =============================================================================

/**
 * Project name - must be lowercase kebab-case starting with letter
 */
export const ProjectName = Schema.String.pipe(
  Schema.pattern(/^[a-z][a-z0-9-]*$/),
  Schema.brand('ProjectName')
)
export type ProjectName = typeof ProjectName.Type

/**
 * Port number - must be in valid range (1024-65535)
 */
export const Port = Schema.Number.pipe(
  Schema.int(),
  Schema.between(1024, 65535),
  Schema.brand('Port')
)
export type Port = typeof Port.Type

// =============================================================================
// Enums / Literals
// =============================================================================

/**
 * Project types supported by the factory
 */
export const ProjectType = Schema.Literal('monorepo', 'api', 'ui', 'infra', 'library')
export type ProjectType = typeof ProjectType.Type

/**
 * Database types
 */
export const DatabaseType = Schema.Literal('turso', 'd1', 'neon')
export type DatabaseType = typeof DatabaseType.Type

/**
 * Queue types
 */
export const QueueType = Schema.Literal('temporal', 'sqs')
export type QueueType = typeof QueueType.Type

/**
 * Runtime types
 */
export const RuntimeType = Schema.Literal('bun', 'node')
export type RuntimeType = typeof RuntimeType.Type

/**
 * Debugger types
 */
export const DebuggerType = Schema.Literal('vscode', 'nvim-dap')
export type DebuggerType = typeof DebuggerType.Type

// =============================================================================
// Config Objects
// =============================================================================

/**
 * Port configuration for services
 */
export const PortConfig = Schema.Struct({
  http: Schema.optional(Port),
  debug: Schema.optional(Port),
  metrics: Schema.optional(Port),
})
export type PortConfig = typeof PortConfig.Type

/**
 * Infrastructure configuration
 */
export const InfraConfig = Schema.Struct({
  runtime: RuntimeType,
  database: Schema.optional(DatabaseType),
  queue: Schema.optional(QueueType),
})
export type InfraConfig = typeof InfraConfig.Type

/**
 * Observability configuration (REQUIRED for all projects)
 */
export const ObservabilityConfig = Schema.Struct({
  processCompose: Schema.Literal(true), // Always required
  metrics: Schema.Boolean,
  debugger: DebuggerType,
})
export type ObservabilityConfig = typeof ObservabilityConfig.Type

// =============================================================================
// Hexagonal Architecture
// =============================================================================

/**
 * Port definition for hexagonal architecture
 */
export const PortDefinition = Schema.Struct({
  method: Schema.String,
  input: Schema.Unknown,
  output: Schema.Unknown,
})
export type PortDefinition = typeof PortDefinition.Type

/**
 * Ports record - maps port names to definitions
 */
export const Ports = Schema.Record({ key: Schema.String, value: PortDefinition })
export type Ports = typeof Ports.Type

// =============================================================================
// Main Schema
// =============================================================================

/**
 * ProjectSpec - The complete project specification
 *
 * This is the DNA of every generated project.
 * All other schemas derive from or compose with this.
 */
export const ProjectSpec = Schema.Struct({
  // Metadata
  name: ProjectName,
  description: Schema.optional(Schema.String),

  // Project type
  type: ProjectType,

  // Network configuration
  ports: Schema.optional(PortConfig),

  // Hexagonal architecture (optional - mainly for API projects)
  hexagonal: Schema.optional(
    Schema.Struct({
      ports: Schema.optional(Ports),
    })
  ),

  // Infrastructure (REQUIRED)
  infra: InfraConfig,

  // Observability (REQUIRED - process-compose is always on)
  observability: ObservabilityConfig,

  // Workspaces (for monorepos)
  workspaces: Schema.optional(
    Schema.Array(
      Schema.Struct({
        name: ProjectName,
        type: ProjectType,
        path: Schema.String,
      })
    )
  ),
})
export type ProjectSpec = typeof ProjectSpec.Type

// =============================================================================
// Helpers
// =============================================================================

/**
 * Decode unknown input to ProjectSpec
 */
export const decodeProjectSpec = Schema.decodeUnknown(ProjectSpec)

/**
 * Encode ProjectSpec to unknown (for serialization)
 */
export const encodeProjectSpec = Schema.encode(ProjectSpec)

/**
 * Validate that input is a valid ProjectSpec
 */
export const isProjectSpec = Schema.is(ProjectSpec)
