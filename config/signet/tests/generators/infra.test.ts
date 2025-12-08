/**
 * Infrastructure Generator Tests
 *
 * Tests for the Pulumi + process-compose infrastructure generator.
 */
import { Effect } from 'effect'
import { describe, expect, test } from 'bun:test'
import { generateInfra } from '@/generators/infra'
import { TemplateEngineLive } from '@/layers/template-engine'
import type { ProjectSpec } from '@/schema/project-spec'

// Minimal valid ProjectSpec for infra testing
const makeSpec = (overrides: Partial<ProjectSpec> = {}): ProjectSpec =>
  ({
    name: 'test-infra',
    type: 'infra',
    infra: { runtime: 'bun' },
    observability: { processCompose: true, metrics: false, debugger: 'vscode' },
    ...overrides,
  }) as ProjectSpec

describe('Infrastructure Generator', () => {
  describe('generateInfra', () => {
    test('generates process-compose.yaml', async () => {
      const spec = makeSpec({ name: 'ember-infra' })

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['process-compose.yaml']).toBeDefined()
      expect(tree['process-compose.yaml']).toContain('version:')
      expect(tree['process-compose.yaml']).toContain('processes:')
    })

    test('generates VSCode launch.json for debugging', async () => {
      const spec = makeSpec({ observability: { processCompose: true, metrics: false, debugger: 'vscode' } })

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['.vscode/launch.json']).toBeDefined()
      expect(tree['.vscode/launch.json']).toContain('configurations')
      expect(tree['.vscode/launch.json']).toContain('bun')
    })

    test('generates nvim-dap config when debugger is nvim-dap', async () => {
      const spec = makeSpec({ observability: { processCompose: true, metrics: false, debugger: 'nvim-dap' } })

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['.nvim/dap.lua']).toBeDefined()
      expect(tree['.nvim/dap.lua']).toContain('dap')
    })

    test('generates Pulumi.yaml project config', async () => {
      const spec = makeSpec({ name: 'cloud-infra' })

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['Pulumi.yaml']).toBeDefined()
      expect(tree['Pulumi.yaml']).toContain('cloud-infra')
      expect(tree['Pulumi.yaml']).toContain('runtime:')
    })

    test('generates Pulumi index.ts entry point', async () => {
      const spec = makeSpec()

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['index.ts']).toBeDefined()
      expect(tree['index.ts']).toContain('pulumi')
      expect(tree['index.ts']).toContain('export')
    })

    test('generates Pulumi stack config', async () => {
      const spec = makeSpec({ name: 'my-project' })

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['Pulumi.dev.yaml']).toBeDefined()
      expect(tree['Pulumi.dev.yaml']).toContain('config:')
    })

    test('generates package.json for Pulumi deps', async () => {
      const spec = makeSpec()

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['package.json']).toBeDefined()
      const pkg = JSON.parse(tree['package.json']!)
      expect(pkg.dependencies['@pulumi/pulumi']).toBeDefined()
    })

    test('generates tsconfig.json for Pulumi', async () => {
      const spec = makeSpec()

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['tsconfig.json']).toBeDefined()
      const tsconfig = JSON.parse(tree['tsconfig.json']!)
      expect(tsconfig.compilerOptions.strict).toBe(true)
    })

    test('skips vscode config when debugger is not vscode', async () => {
      const spec = makeSpec({ observability: { processCompose: true, metrics: false, debugger: 'nvim-dap' } })

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['.vscode/launch.json']).toBeUndefined()
    })
  })
})
