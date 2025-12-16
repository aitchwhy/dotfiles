/**
 * Core Generator Tests
 *
 * Tests for the base generator that all other generators extend.
 */

import { describe, expect, test } from 'bun:test';
import { makeSpec } from '@tests/helpers/test-spec';
import { Effect } from 'effect';
import { generateCore } from '@/generators/core';
import { TemplateEngineLive } from '@/layers/template-engine';

describe('Core Generator', () => {
  describe('generateCore', () => {
    test('generates package.json', async () => {
      const spec = makeSpec({ name: 'my-app', description: 'My awesome app' });

      const program = generateCore(spec).pipe(Effect.provide(TemplateEngineLive));
      const tree = await Effect.runPromise(program);

      expect(tree['package.json']).toBeDefined();
      const pkg = JSON.parse(tree['package.json']!);
      expect(pkg.name).toBe('my-app');
      expect(pkg.description).toBe('My awesome app');
    });

    test('generates tsconfig.json', async () => {
      const spec = makeSpec();

      const program = generateCore(spec).pipe(Effect.provide(TemplateEngineLive));
      const tree = await Effect.runPromise(program);

      expect(tree['tsconfig.json']).toBeDefined();
      const tsconfig = JSON.parse(tree['tsconfig.json']!);
      expect(tsconfig.compilerOptions.strict).toBe(true);
    });

    test('generates biome.json', async () => {
      const spec = makeSpec();

      const program = generateCore(spec).pipe(Effect.provide(TemplateEngineLive));
      const tree = await Effect.runPromise(program);

      expect(tree['biome.json']).toBeDefined();
      const biome = JSON.parse(tree['biome.json']!);
      expect(biome.linter.enabled).toBe(true);
    });

    test('generates flake.nix', async () => {
      const spec = makeSpec({ name: 'ember-api' });

      const program = generateCore(spec).pipe(Effect.provide(TemplateEngineLive));
      const tree = await Effect.runPromise(program);

      expect(tree['flake.nix']).toBeDefined();
      expect(tree['flake.nix']).toContain('ember-api');
      expect(tree['flake.nix']).toContain('bun');
    });

    test('generates .gitignore', async () => {
      const spec = makeSpec();

      const program = generateCore(spec).pipe(Effect.provide(TemplateEngineLive));
      const tree = await Effect.runPromise(program);

      expect(tree['.gitignore']).toBeDefined();
      expect(tree['.gitignore']).toContain('node_modules');
      expect(tree['.gitignore']).toContain('.env');
    });

    test('generates .envrc', async () => {
      const spec = makeSpec();

      const program = generateCore(spec).pipe(Effect.provide(TemplateEngineLive));
      const tree = await Effect.runPromise(program);

      expect(tree['.envrc']).toBeDefined();
      expect(tree['.envrc']).toContain('use flake');
    });

    test('generates src/index.ts', async () => {
      const spec = makeSpec({ name: 'test-lib' });

      const program = generateCore(spec).pipe(Effect.provide(TemplateEngineLive));
      const tree = await Effect.runPromise(program);

      expect(tree['src/index.ts']).toBeDefined();
    });

    test('generates src/lib/result.ts', async () => {
      const spec = makeSpec();

      const program = generateCore(spec).pipe(Effect.provide(TemplateEngineLive));
      const tree = await Effect.runPromise(program);

      expect(tree['src/lib/result.ts']).toBeDefined();
      expect(tree['src/lib/result.ts']).toContain('Result');
      expect(tree['src/lib/result.ts']).toContain('Ok');
      expect(tree['src/lib/result.ts']).toContain('Err');
    });

    test('includes runtime-specific packages', async () => {
      const bunSpec = makeSpec({ infra: { runtime: 'bun' } });
      const nodeSpec = makeSpec({ infra: { runtime: 'node' } });

      const bunProgram = generateCore(bunSpec).pipe(Effect.provide(TemplateEngineLive));
      const nodeProgram = generateCore(nodeSpec).pipe(Effect.provide(TemplateEngineLive));

      const bunTree = await Effect.runPromise(bunProgram);
      // Run nodeProgram to ensure it generates successfully (validates both runtimes work)
      await Effect.runPromise(nodeProgram);

      const bunPkg = JSON.parse(bunTree['package.json']!);

      // Bun should have @types/bun
      expect(bunPkg.devDependencies['@types/bun']).toBeDefined();
    });
  });
});
