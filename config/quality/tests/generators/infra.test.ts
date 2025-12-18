/**
 * Infrastructure Generator Tests
 *
 * Tests for the Docker Compose + Pulumi infrastructure generator.
 */

import { describe, expect, test } from 'bun:test';
import { makeSpec } from '@tests/helpers/test-spec';
import { Effect } from 'effect';
import { generateInfra } from '@/generators/infra';
import { TemplateEngineLive } from '@/layers/template-engine';

describe('Infrastructure Generator', () => {
  describe('generateInfra', () => {
    test('generates docker-compose.yml', async () => {
      const spec = makeSpec({ name: 'my-infra' });

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive));
      const tree = await Effect.runPromise(program);

      expect(tree['docker-compose.yml']).toBeDefined();
      expect(tree['docker-compose.yml']).toContain('services:');
      expect(tree['docker-compose.yml']).toContain('my-infra');
    });

    test('generates Dockerfile with pnpm', async () => {
      const spec = makeSpec({ name: 'my-project' });

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive));
      const tree = await Effect.runPromise(program);

      expect(tree['Dockerfile']).toBeDefined();
      expect(tree['Dockerfile']).toContain('pnpm');
      expect(tree['Dockerfile']).toContain('node:22');
    });

    test('generates VSCode launch.json for debugging', async () => {
      const spec = makeSpec({
        observability: { processCompose: true, metrics: false, debugger: 'vscode' },
      });

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive));
      const tree = await Effect.runPromise(program);

      expect(tree['.vscode/launch.json']).toBeDefined();
      expect(tree['.vscode/launch.json']).toContain('configurations');
      expect(tree['.vscode/launch.json']).toContain('pnpm');
    });

    test('generates nvim-dap config when debugger is nvim-dap', async () => {
      const spec = makeSpec({
        observability: { processCompose: true, metrics: false, debugger: 'nvim-dap' },
      });

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive));
      const tree = await Effect.runPromise(program);

      expect(tree['.nvim/dap.lua']).toBeDefined();
      expect(tree['.nvim/dap.lua']).toContain('dap');
    });

    test('generates Pulumi.yaml project config', async () => {
      const spec = makeSpec({ name: 'cloud-infra' });

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive));
      const tree = await Effect.runPromise(program);

      expect(tree['infra/Pulumi.yaml']).toBeDefined();
      expect(tree['infra/Pulumi.yaml']).toContain('cloud-infra');
      expect(tree['infra/Pulumi.yaml']).toContain('runtime:');
    });

    test('generates Pulumi index.ts entry point', async () => {
      const spec = makeSpec();

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive));
      const tree = await Effect.runPromise(program);

      expect(tree['infra/index.ts']).toBeDefined();
      expect(tree['infra/index.ts']).toContain('pulumi');
      expect(tree['infra/index.ts']).toContain('export');
    });

    test('generates Pulumi stack config', async () => {
      const spec = makeSpec({ name: 'my-project' });

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive));
      const tree = await Effect.runPromise(program);

      expect(tree['infra/Pulumi.dev.yaml']).toBeDefined();
      expect(tree['infra/Pulumi.dev.yaml']).toContain('config:');
    });

    test('generates package.json for Pulumi deps', async () => {
      const spec = makeSpec();

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive));
      const tree = await Effect.runPromise(program);

      expect(tree['infra/package.json']).toBeDefined();
      const pkg = JSON.parse(tree['infra/package.json']!);
      expect(pkg.dependencies['@pulumi/pulumi']).toBeDefined();
    });

    test('generates tsconfig.json for Pulumi', async () => {
      const spec = makeSpec();

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive));
      const tree = await Effect.runPromise(program);

      expect(tree['infra/tsconfig.json']).toBeDefined();
      const tsconfig = JSON.parse(tree['infra/tsconfig.json']!);
      expect(tsconfig.compilerOptions.strict).toBe(true);
    });

    test('skips vscode config when debugger is not vscode', async () => {
      const spec = makeSpec({
        observability: { processCompose: true, metrics: false, debugger: 'nvim-dap' },
      });

      const program = generateInfra(spec).pipe(Effect.provide(TemplateEngineLive));
      const tree = await Effect.runPromise(program);

      expect(tree['.vscode/launch.json']).toBeUndefined();
    });
  });
});
