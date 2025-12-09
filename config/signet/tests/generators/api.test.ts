/**
 * API Generator Tests
 *
 * Tests for the hexagonal Hono API generator.
 */
import { Effect } from 'effect'
import { describe, expect, test } from 'vitest'
import { generateApi } from '@/generators/api'
import { TemplateEngineLive } from '@/layers/template-engine'
import { makeSpec } from '@tests/helpers/test-spec'

describe('API Generator', () => {
  describe('generateApi', () => {
    test('generates server.ts with Hono app', async () => {
      const spec = makeSpec({ name: 'voice-api' })

      const program = generateApi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['src/server.ts']).toBeDefined()
      expect(tree['src/server.ts']).toContain('Hono')
      expect(tree['src/server.ts']).toContain('voice-api')
    })

    test('generates index.ts worker entry', async () => {
      const spec = makeSpec()

      const program = generateApi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['src/index.ts']).toBeDefined()
      expect(tree['src/index.ts']).toContain('export default')
    })

    test('generates database port', async () => {
      const spec = makeSpec({ infra: { runtime: 'bun', database: 'turso' } })

      const program = generateApi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['src/ports/database.ts']).toBeDefined()
      expect(tree['src/ports/database.ts']).toContain('Context.Tag')
      expect(tree['src/ports/database.ts']).toContain('DatabaseService')
    })

    test('generates turso adapter when database is turso', async () => {
      const spec = makeSpec({ infra: { runtime: 'bun', database: 'turso' } })

      const program = generateApi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['src/adapters/turso.ts']).toBeDefined()
      expect(tree['src/adapters/turso.ts']).toContain('Layer')
      expect(tree['src/adapters/turso.ts']).toContain('libsql')
    })

    test('generates d1 adapter when database is d1', async () => {
      const spec = makeSpec({ infra: { runtime: 'bun', database: 'd1' } })

      const program = generateApi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['src/adapters/d1.ts']).toBeDefined()
      expect(tree['src/adapters/d1.ts']).toContain('Layer')
      expect(tree['src/adapters/d1.ts']).toContain('D1Database')
    })

    test('generates health handlers', async () => {
      const spec = makeSpec()

      const program = generateApi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['src/handlers/health.ts']).toBeDefined()
      expect(tree['src/handlers/health.ts']).toContain('healthRoutes')
      expect(tree['src/handlers/health.ts']).toContain('/health/ready')
    })

    test('generates error middleware', async () => {
      const spec = makeSpec()

      const program = generateApi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['src/middleware/error.ts']).toBeDefined()
      expect(tree['src/middleware/error.ts']).toContain('errorMiddleware')
      expect(tree['src/middleware/error.ts']).toContain('ErrorHandler')
    })

    test('generates result utilities', async () => {
      const spec = makeSpec()

      const program = generateApi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['src/lib/result.ts']).toBeDefined()
      expect(tree['src/lib/result.ts']).toContain('Result')
    })

    test('generates wrangler.toml for Workers deployment', async () => {
      const spec = makeSpec({ name: 'ember-api' })

      const program = generateApi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['wrangler.toml']).toBeDefined()
      expect(tree['wrangler.toml']).toContain('ember-api')
      expect(tree['wrangler.toml']).toContain('compatibility_date')
    })

    test('skips database files when no database specified', async () => {
      const spec = makeSpec({ infra: { runtime: 'bun' } })

      const program = generateApi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['src/ports/database.ts']).toBeUndefined()
      expect(tree['src/adapters/turso.ts']).toBeUndefined()
      expect(tree['src/adapters/d1.ts']).toBeUndefined()
    })
  })
})
