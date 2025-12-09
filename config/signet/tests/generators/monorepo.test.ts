/**
 * Monorepo Generator Tests
 *
 * Tests for the Bun workspaces monorepo generator.
 */
import { Effect } from 'effect'
import { describe, expect, test } from 'vitest'
import { generateMonorepo } from '@/generators/monorepo'
import { TemplateEngineLive } from '@/layers/template-engine'
import { makeSpec } from '@tests/helpers/test-spec'

describe('Monorepo Generator', () => {
  describe('generateMonorepo', () => {
    test('generates root package.json with workspaces', async () => {
      const spec = makeSpec({ name: 'ember-platform' })

      const program = generateMonorepo(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['package.json']).toBeDefined()
      const pkg = JSON.parse(tree['package.json']!)
      expect(pkg.name).toBe('ember-platform')
      expect(pkg.workspaces).toBeDefined()
      expect(pkg.workspaces).toContain('packages/*')
      expect(pkg.workspaces).toContain('apps/*')
    })

    test('generates root tsconfig.json', async () => {
      const spec = makeSpec()

      const program = generateMonorepo(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['tsconfig.json']).toBeDefined()
      const tsconfig = JSON.parse(tree['tsconfig.json']!)
      expect(tsconfig.compilerOptions).toBeDefined()
    })

    test('generates tsconfig.base.json for shared settings', async () => {
      const spec = makeSpec()

      const program = generateMonorepo(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['tsconfig.base.json']).toBeDefined()
      const base = JSON.parse(tree['tsconfig.base.json']!)
      expect(base.compilerOptions.strict).toBe(true)
    })

    test('generates biome.json at root', async () => {
      const spec = makeSpec()

      const program = generateMonorepo(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['biome.json']).toBeDefined()
      const biome = JSON.parse(tree['biome.json']!)
      expect(biome.linter.enabled).toBe(true)
    })

    test('generates shared package placeholder', async () => {
      const spec = makeSpec({ name: 'my-mono' })

      const program = generateMonorepo(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['packages/shared/package.json']).toBeDefined()
      const pkg = JSON.parse(tree['packages/shared/package.json']!)
      expect(pkg.name).toBe('@my-mono/shared')
    })

    test('generates shared package index.ts', async () => {
      const spec = makeSpec()

      const program = generateMonorepo(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['packages/shared/src/index.ts']).toBeDefined()
      expect(tree['packages/shared/src/index.ts']).toContain('export')
    })

    test('generates .gitignore', async () => {
      const spec = makeSpec()

      const program = generateMonorepo(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['.gitignore']).toBeDefined()
      expect(tree['.gitignore']).toContain('node_modules')
    })

    test('generates flake.nix for dev shell', async () => {
      const spec = makeSpec({ name: 'platform' })

      const program = generateMonorepo(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['flake.nix']).toBeDefined()
      expect(tree['flake.nix']).toContain('platform')
      expect(tree['flake.nix']).toContain('bun')
    })

    test('generates .envrc for direnv', async () => {
      const spec = makeSpec()

      const program = generateMonorepo(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['.envrc']).toBeDefined()
      expect(tree['.envrc']).toContain('use flake')
    })

    test('generates README with project structure', async () => {
      const spec = makeSpec({ name: 'ember-platform' })

      const program = generateMonorepo(spec).pipe(Effect.provide(TemplateEngineLive))
      const tree = await Effect.runPromise(program)

      expect(tree['README.md']).toBeDefined()
      expect(tree['README.md']).toContain('ember-platform')
      expect(tree['README.md']).toContain('packages/')
      expect(tree['README.md']).toContain('apps/')
    })
  })
})
