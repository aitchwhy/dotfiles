/**
 * UI Generator Tests
 *
 * Tests for the React 19 + XState + TanStack Router generator.
 */
import { Effect } from 'effect'
import { describe, expect, test } from 'bun:test'
import { generateUi } from '@/generators/ui'
import { TemplateEngineLive } from '@/layers/template-engine'
import type { ProjectSpec } from '@/schema/project-spec'

// Minimal valid ProjectSpec for UI testing
const makeSpec = (overrides: Partial<ProjectSpec> = {}): ProjectSpec =>
  ({
    name: 'test-app',
    type: 'ui',
    infra: { runtime: 'bun' },
    observability: { processCompose: true, metrics: false, debugger: 'vscode' },
    ...overrides,
  }) as ProjectSpec

describe('UI Generator', () => {
  describe('generateUi', () => {
    test('generates App.tsx root component', async () => {
      const spec = makeSpec({ name: 'ember-web' })

      const program = generateUi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['src/App.tsx']).toBeDefined()
      expect(tree['src/App.tsx']).toContain('ember-web')
      expect(tree['src/App.tsx']).toContain('RouterProvider')
    })

    test('generates main.tsx entry point', async () => {
      const spec = makeSpec()

      const program = generateUi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['src/main.tsx']).toBeDefined()
      expect(tree['src/main.tsx']).toContain('createRoot')
      expect(tree['src/main.tsx']).toContain('StrictMode')
    })

    test('generates router configuration', async () => {
      const spec = makeSpec()

      const program = generateUi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['src/router.tsx']).toBeDefined()
      expect(tree['src/router.tsx']).toContain('createRouter')
      expect(tree['src/router.tsx']).toContain('routeTree')
    })

    test('generates root route', async () => {
      const spec = makeSpec()

      const program = generateUi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['src/routes/__root.tsx']).toBeDefined()
      expect(tree['src/routes/__root.tsx']).toContain('createRootRoute')
      expect(tree['src/routes/__root.tsx']).toContain('Outlet')
    })

    test('generates index route', async () => {
      const spec = makeSpec()

      const program = generateUi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['src/routes/index.tsx']).toBeDefined()
      expect(tree['src/routes/index.tsx']).toContain('createFileRoute')
    })

    test('generates example XState machine', async () => {
      const spec = makeSpec()

      const program = generateUi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['src/machines/counter.ts']).toBeDefined()
      expect(tree['src/machines/counter.ts']).toContain('createMachine')
      expect(tree['src/machines/counter.ts']).toContain('states')
    })

    test('generates vite.config.ts', async () => {
      const spec = makeSpec()

      const program = generateUi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['vite.config.ts']).toBeDefined()
      expect(tree['vite.config.ts']).toContain('defineConfig')
      expect(tree['vite.config.ts']).toContain('@vitejs/plugin-react')
    })

    test('generates index.html', async () => {
      const spec = makeSpec({ name: 'my-app' })

      const program = generateUi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['index.html']).toBeDefined()
      expect(tree['index.html']).toContain('my-app')
      expect(tree['index.html']).toContain('src/main.tsx')
    })

    test('generates tailwind.config.ts', async () => {
      const spec = makeSpec()

      const program = generateUi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['tailwind.config.ts']).toBeDefined()
      expect(tree['tailwind.config.ts']).toContain('content')
    })

    test('generates globals.css with Tailwind directives', async () => {
      const spec = makeSpec()

      const program = generateUi(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['src/globals.css']).toBeDefined()
      expect(tree['src/globals.css']).toContain('@tailwind')
    })
  })
})
