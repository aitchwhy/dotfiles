/**
 * API Generator
 *
 * Generates hexagonal Hono API projects with:
 * - Ports (Context.Tag interfaces)
 * - Adapters (Layer implementations)
 * - Routes and middleware
 * - Cloudflare Workers deployment config
 */
import { Effect } from 'effect'
import type { FileTree } from '@/layers/file-system'
import { renderTemplates, TemplateEngine } from '@/layers/template-engine'
import type { ProjectSpec } from '@/schema/project-spec'

// =============================================================================
// Templates - Server & Entry
// =============================================================================

const SERVER_TS_TEMPLATE = `/**
 * {{name}} - Hono Server
 *
 * Composition root that wires routes and middleware.
 */
import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { logger } from 'hono/logger'
import { errorMiddleware } from './middleware/error'
import { healthRoutes } from './routes/health'

const app = new Hono()

// Global middleware
app.use('*', logger())
app.use('*', cors())
app.onError(errorMiddleware)

// Routes
app.route('/health', healthRoutes)

export { app }
`

const INDEX_TS_TEMPLATE = `/**
 * {{name}} - Worker Entry
 *
 * Cloudflare Workers entry point.
 */
import { app } from './server'

export default app
`

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
`

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
`

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
`

// =============================================================================
// Templates - Routes
// =============================================================================

const HEALTH_ROUTE_TEMPLATE = `/**
 * Health Routes
 *
 * Liveness and readiness probes.
 */
import { Hono } from 'hono'

export const healthRoutes = new Hono()

healthRoutes.get('/', (c) => {
  return c.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
  })
})

healthRoutes.get('/ready', (c) => {
  // TODO: Add database connectivity check
  return c.json({
    status: 'ready',
    timestamp: new Date().toISOString(),
  })
})
`

// =============================================================================
// Templates - Middleware
// =============================================================================

const ERROR_MIDDLEWARE_TEMPLATE = `/**
 * Error Middleware
 *
 * Global error handler for Hono.
 */
import type { ErrorHandler } from 'hono'

export const errorMiddleware: ErrorHandler = (err, c) => {
  console.error('Unhandled error:', err)

  const status = 'status' in err && typeof err.status === 'number' ? err.status : 500
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
`

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
`

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
`

// =============================================================================
// Generator
// =============================================================================

/**
 * Generate hexagonal API project files from ProjectSpec
 */
export const generateApi = (
  spec: ProjectSpec
): Effect.Effect<FileTree, Error, TemplateEngine> => {
  const data = {
    name: spec.name,
    description: spec.description,
    hasDatabase: Boolean(spec.infra.database),
    isTurso: spec.infra.database === 'turso',
    isD1: spec.infra.database === 'd1',
  }

  // Base templates (always generated)
  const templates: FileTree = {
    'src/server.ts': SERVER_TS_TEMPLATE,
    'src/index.ts': INDEX_TS_TEMPLATE,
    'src/routes/health.ts': HEALTH_ROUTE_TEMPLATE,
    'src/middleware/error.ts': ERROR_MIDDLEWARE_TEMPLATE,
    'src/lib/result.ts': RESULT_TS_TEMPLATE,
    'wrangler.toml': WRANGLER_TOML_TEMPLATE,
  }

  // Conditional: Database port and adapter
  if (spec.infra.database) {
    templates['src/ports/database.ts'] = DATABASE_PORT_TEMPLATE

    if (spec.infra.database === 'turso') {
      templates['src/adapters/turso.ts'] = TURSO_ADAPTER_TEMPLATE
    } else if (spec.infra.database === 'd1') {
      templates['src/adapters/d1.ts'] = D1_ADAPTER_TEMPLATE
    }
  }

  return renderTemplates(templates, data)
}
