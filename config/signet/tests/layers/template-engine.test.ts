/**
 * TemplateEngine Layer Tests
 *
 * Tests for the Effect Layer that handles Handlebars template rendering.
 */

import { describe, expect, test } from 'bun:test';
import { Effect } from 'effect';
import type { FileTree } from '@/layers/file-system';
import { renderTemplate, renderTemplates, TemplateEngineLive } from '@/layers/template-engine';

describe('TemplateEngine Layer', () => {
  describe('renderTemplate', () => {
    test('renders simple template', async () => {
      const template = 'Hello, {{name}}!';
      const data = { name: 'World' };

      const program = renderTemplate(template, data).pipe(Effect.provide(TemplateEngineLive));
      const result = await Effect.runPromise(program);

      expect(result).toBe('Hello, World!');
    });

    test('renders template with nested data', async () => {
      const template = '{{project.name}} by {{project.author}}';
      const data = {
        project: { name: 'my-app', author: 'Hank' },
      };

      const program = renderTemplate(template, data).pipe(Effect.provide(TemplateEngineLive));
      const result = await Effect.runPromise(program);

      expect(result).toBe('my-app by Hank');
    });

    test('renders template with conditionals', async () => {
      const template = '{{#if enabled}}Enabled{{else}}Disabled{{/if}}';

      const enabledProgram = renderTemplate(template, { enabled: true }).pipe(
        Effect.provide(TemplateEngineLive)
      );
      const disabledProgram = renderTemplate(template, { enabled: false }).pipe(
        Effect.provide(TemplateEngineLive)
      );

      expect(await Effect.runPromise(enabledProgram)).toBe('Enabled');
      expect(await Effect.runPromise(disabledProgram)).toBe('Disabled');
    });

    test('renders template with loops', async () => {
      const template = '{{#each items}}{{this}} {{/each}}';
      const data = { items: ['a', 'b', 'c'] };

      const program = renderTemplate(template, data).pipe(Effect.provide(TemplateEngineLive));
      const result = await Effect.runPromise(program);

      expect(result).toBe('a b c ');
    });

    test('renders template with object loops', async () => {
      const template = '{{#each deps}}{{@key}}:{{this}},{{/each}}';
      const data = { deps: { react: '19.0.0', hono: '4.6.0' } };

      const program = renderTemplate(template, data).pipe(Effect.provide(TemplateEngineLive));
      const result = await Effect.runPromise(program);

      expect(result).toContain('react:19.0.0');
      expect(result).toContain('hono:4.6.0');
    });

    test('handles empty/missing variables', async () => {
      const template = 'Value: {{value}}';
      const data = {};

      const program = renderTemplate(template, data).pipe(Effect.provide(TemplateEngineLive));
      const result = await Effect.runPromise(program);

      expect(result).toBe('Value: ');
    });
  });

  describe('renderTemplates', () => {
    test('renders multiple templates', async () => {
      const templates: FileTree = {
        'package.json': '{"name": "{{name}}"}',
        'README.md': '# {{name}}',
      };
      const data = { name: 'my-project' };

      const program = renderTemplates(templates, data).pipe(Effect.provide(TemplateEngineLive));
      const result = await Effect.runPromise(program);

      expect(result['package.json']).toBe('{"name": "my-project"}');
      expect(result['README.md']).toBe('# my-project');
    });

    test('handles empty template tree', async () => {
      const templates: FileTree = {};
      const data = { name: 'test' };

      const program = renderTemplates(templates, data).pipe(Effect.provide(TemplateEngineLive));
      const result = await Effect.runPromise(program);

      expect(result).toEqual({});
    });

    test('preserves path structure', async () => {
      const templates: FileTree = {
        'src/index.ts': 'export const name = "{{name}}"',
        'src/lib/utils.ts': 'export const version = "{{version}}"',
      };
      const data = { name: 'app', version: '1.0.0' };

      const program = renderTemplates(templates, data).pipe(Effect.provide(TemplateEngineLive));
      const result = await Effect.runPromise(program);

      expect(result['src/index.ts']).toBe('export const name = "app"');
      expect(result['src/lib/utils.ts']).toBe('export const version = "1.0.0"');
    });
  });
});
