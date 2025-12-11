/**
 * API Generator
 *
 * Generates hexagonal Hono API projects with:
 * - Ports (Context.Tag interfaces)
 * - Adapters (Layer implementations)
 * - Routes and middleware
 * - Cloudflare Workers deployment config
 */
import type { Effect } from 'effect';
import type { FileTree } from '@/layers/file-system';
import { renderTemplates, type TemplateEngine } from '@/layers/template-engine';
import type { ProjectSpec } from '@/schema/project-spec';
import versions from '../../versions.json';

// =============================================================================
// Templates - Package.json (API-specific dependencies)
// =============================================================================

const API_PACKAGE_JSON_TEMPLATE = `{
  "name": "{{name}}",
  "version": "0.1.0",
  "type": "module",
  "description": "{{#if description}}{{description}}{{else}}{{name}} API{{/if}}",
  "scripts": {
    "dev": "wrangler dev",
    "start": "wrangler dev",
    "deploy": "wrangler deploy",
    "test": "bun test",
    "typecheck": "tsc --noEmit",
    "lint": "bunx biome check .",
    "lint:fix": "bunx biome check --write .",
    "format": "bunx biome format --write .",
    "validate": "bun run typecheck && bun run lint && bun test"
  },
  "dependencies": {
    "hono": "^{{honoVersion}}",
    "effect": "^{{effectVersion}}",
    "zod": "^{{zodVersion}}"
  },
  "devDependencies": {
    "@biomejs/biome": "^{{biomeVersion}}",
    "@types/bun": "^{{bunTypesVersion}}",
    "typescript": "^{{typescriptVersion}}",
    "wrangler": "^3.99.0"
  },
  "engines": {
    "bun": ">={{bunVersion}}"
  }
}`;

// =============================================================================
// Templates - Server & Entry
// =============================================================================

const SERVER_TS_TEMPLATE = `/**
 * {{name}} - Hono Server (Composition Root)
 *
 * This is the ONLY file that should import Hono directly.
 * All route handlers are pure Effect functions wired here.
 *
 * Hexagonal Architecture:
 * - Routes (src/handlers/*) = Pure Effect handlers, framework-agnostic
 * - Server (this file) = Composition root, wires handlers to HTTP
 * - Ports (src/ports/*) = Abstract interfaces (Context.Tag)
 * - Adapters (src/adapters/*) = Concrete implementations (Layer)
 */
import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { logger } from 'hono/logger'
import { Effect, Runtime } from 'effect'
import { errorMiddleware } from './middleware/error'
import { healthRoutes, type HealthResponse } from './handlers/health'

const app = new Hono()

// Global middleware
app.use('*', logger())
app.use('*', cors())
app.onError(errorMiddleware)

// Create runtime for Effect execution
const runtime = Runtime.defaultRuntime

/**
 * Wire Effect handlers to Hono routes
 * This is where framework-specific code lives
 */
for (const route of healthRoutes) {
  app.on(route.method, route.path, async (c) => {
    const result = await Runtime.runPromise(runtime)(route.handler as Effect.Effect<HealthResponse>)
    return c.json(result)
  })
}

export { app }
`;

const INDEX_TS_TEMPLATE = `/**
 * {{name}} - Worker Entry
 *
 * Cloudflare Workers entry point.
 */
import { app } from './server'

export default app
`;

// =============================================================================
// Templates - Ports (Interfaces)
// =============================================================================

const DATABASE_PORT_TEMPLATE = `/**
 * Database Port
 *
 * Abstract interface for database operations.
 * Implement with Turso, D1, or Neon adapter.
 */
import { Context, Effect } from 'effect'

export interface DatabaseService {
  readonly query: <T>(sql: string, params?: unknown[]) => Effect.Effect<T[], Error>
  readonly execute: (sql: string, params?: unknown[]) => Effect.Effect<void, Error>
}

export class Database extends Context.Tag('Database')<Database, DatabaseService>() {}
`;

// =============================================================================
// Templates - Adapters (Implementations)
// =============================================================================

const TURSO_ADAPTER_TEMPLATE = `/**
 * Turso Adapter
 *
 * Database adapter using libsql client for Turso.
 */
import { Effect, Layer } from 'effect'
import { createClient } from '@libsql/client'
import { Database, type DatabaseService } from '../ports/database'

const makeTursoService = (url: string, authToken: string): DatabaseService => {
  const client = createClient({ url, authToken })

  return {
    query: <T>(sql: string, params?: unknown[]) =>
      Effect.tryPromise({
        try: async () => {
          const result = await client.execute({ sql, args: params ?? [] })
          return result.rows as T[]
        },
        catch: (e) => new Error(\`Query failed: \${e}\`),
      }),

    execute: (sql: string, params?: unknown[]) =>
      Effect.tryPromise({
        try: async () => {
          await client.execute({ sql, args: params ?? [] })
        },
        catch: (e) => new Error(\`Execute failed: \${e}\`),
      }),
  }
}

export const TursoLive = (url: string, authToken: string) =>
  Layer.succeed(Database, makeTursoService(url, authToken))
`;

const D1_ADAPTER_TEMPLATE = `/**
 * D1 Adapter
 *
 * Database adapter using Cloudflare D1.
 */
import { Effect, Layer } from 'effect'
import { Database, type DatabaseService } from '../ports/database'

type D1Database = {
  prepare: (sql: string) => {
    bind: (...params: unknown[]) => {
      all: <T>() => Promise<{ results: T[] }>
      run: () => Promise<void>
    }
  }
}

const makeD1Service = (db: D1Database): DatabaseService => ({
  query: <T>(sql: string, params?: unknown[]) =>
    Effect.tryPromise({
      try: async () => {
        const stmt = db.prepare(sql).bind(...(params ?? []))
        const result = await stmt.all<T>()
        return result.results
      },
      catch: (e) => new Error(\`Query failed: \${e}\`),
    }),

  execute: (sql: string, params?: unknown[]) =>
    Effect.tryPromise({
      try: async () => {
        const stmt = db.prepare(sql).bind(...(params ?? []))
        await stmt.run()
      },
      catch: (e) => new Error(\`Execute failed: \${e}\`),
    }),
})

export const D1Live = (db: D1Database) => Layer.succeed(Database, makeD1Service(db))
`;

// =============================================================================
// Templates - Routes (Pure Effect Handlers - NO Hono imports)
// =============================================================================

const HEALTH_HANDLER_TEMPLATE = `/**
 * Health Handlers
 *
 * Pure Effect handlers for liveness and readiness probes.
 * Framework-agnostic: NO Hono imports allowed here.
 * The composition root (server.ts) wires these to HTTP routes.
 */
import { Effect } from 'effect'

/** Response type for health endpoints */
export interface HealthResponse {
  readonly status: 'ok' | 'ready' | 'degraded'
  readonly timestamp: string
}

/**
 * Liveness probe - returns ok if service is running
 */
export const livenessHandler = Effect.succeed<HealthResponse>({
  status: 'ok',
  timestamp: new Date().toISOString(),
})

/**
 * Readiness probe - returns ready if service can handle requests
 * TODO: Add dependency checks (database, external services)
 */
export const readinessHandler = Effect.succeed<HealthResponse>({
  status: 'ready',
  timestamp: new Date().toISOString(),
})

/** Route definitions for the composition root */
export const healthRoutes = [
  { method: 'GET' as const, path: '/health', handler: livenessHandler },
  { method: 'GET' as const, path: '/health/ready', handler: readinessHandler },
] as const
`;

// =============================================================================
// Templates - Middleware
// =============================================================================

const ERROR_MIDDLEWARE_TEMPLATE = `/**
 * Error Middleware
 *
 * Global error handler for Hono.
 */
import type { ErrorHandler } from 'hono'
import type { ContentfulStatusCode } from 'hono/utils/http-status'

export const errorMiddleware: ErrorHandler = (err, c) => {
  console.error('Unhandled error:', err)

  const status = ('status' in err && typeof err.status === 'number' ? err.status : 500) as ContentfulStatusCode
  const message = err.message || 'Internal Server Error'

  return c.json(
    {
      error: {
        message,
        status,
      },
    },
    status
  )
}
`;

// =============================================================================
// Templates - Utilities
// =============================================================================

const RESULT_TS_TEMPLATE = `/**
 * Result Type Utilities
 *
 * Standard Result type for fallible operations.
 */

export type Result<T, E = Error> =
  | { readonly ok: true; readonly data: T }
  | { readonly ok: false; readonly error: E }

export const Ok = <T>(data: T): Result<T, never> => ({ ok: true, data })

export const Err = <E>(error: E): Result<never, E> => ({ ok: false, error })

export const isOk = <T, E>(result: Result<T, E>): result is { ok: true; data: T } => result.ok

export const isErr = <T, E>(result: Result<T, E>): result is { ok: false; error: E } => !result.ok
`;

// =============================================================================
// Templates - Deployment
// =============================================================================

const WRANGLER_TOML_TEMPLATE = `# {{name}} - Cloudflare Workers Configuration
name = "{{name}}"
main = "src/index.ts"
compatibility_date = "2024-12-01"
compatibility_flags = ["nodejs_compat"]

[observability]
enabled = true

# Uncomment to enable D1
# [[d1_databases]]
# binding = "DB"
# database_name = "{{name}}-db"
# database_id = "YOUR_DATABASE_ID"
`;

// =============================================================================
// Generator
// =============================================================================

/**
 * Generate hexagonal API project files from ProjectSpec
 */
export const generateApi = (spec: ProjectSpec): Effect.Effect<FileTree, Error, TemplateEngine> => {
  const npmVersions = versions.npm as Record<string, string>;
  const runtimeVersions = versions.runtime as Record<string, string>;

  const data = {
    name: spec.name,
    description: spec.description,
    hasDatabase: Boolean(spec.infra.database),
    isTurso: spec.infra.database === 'turso',
    isD1: spec.infra.database === 'd1',
    honoVersion: npmVersions['hono'],
    effectVersion: npmVersions['effect'],
    zodVersion: npmVersions['zod'],
    typescriptVersion: npmVersions['typescript'],
    biomeVersion: npmVersions['@biomejs/biome'],
    bunTypesVersion: npmVersions['@types/bun'],
    bunVersion: runtimeVersions['bun'],
  };

  // Base templates (always generated)
  const templates: FileTree = {
    'package.json': API_PACKAGE_JSON_TEMPLATE,
    'src/server.ts': SERVER_TS_TEMPLATE,
    'src/index.ts': INDEX_TS_TEMPLATE,
    'src/handlers/health.ts': HEALTH_HANDLER_TEMPLATE,
    'src/middleware/error.ts': ERROR_MIDDLEWARE_TEMPLATE,
    'src/lib/result.ts': RESULT_TS_TEMPLATE,
    'wrangler.toml': WRANGLER_TOML_TEMPLATE,
  };

  // Conditional: Database port and adapter
  if (spec.infra.database) {
    templates['src/ports/database.ts'] = DATABASE_PORT_TEMPLATE;

    if (spec.infra.database === 'turso') {
      templates['src/adapters/turso.ts'] = TURSO_ADAPTER_TEMPLATE;
    } else if (spec.infra.database === 'd1') {
      templates['src/adapters/d1.ts'] = D1_ADAPTER_TEMPLATE;
    }
  }

  return renderTemplates(templates, data);
};
