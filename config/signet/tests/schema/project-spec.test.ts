/**
 * ProjectSpec Schema Tests
 *
 * Tests for the core ProjectSpec Effect Schema that defines
 * the formal specification for generated projects.
 */

import { describe, expect, test } from 'bun:test';
import { Schema } from 'effect';
import {
  InfraConfig,
  ObservabilityConfig,
  PortConfig,
  ProjectName,
  ProjectSpec,
  ProjectType,
} from '@/schema/project-spec';

describe('ProjectSpec Schema', () => {
  describe('ProjectName', () => {
    test('accepts valid kebab-case names', () => {
      const result = Schema.decodeUnknownSync(ProjectName)('my-project');
      expect(result as string).toBe('my-project');
    });

    test('accepts names starting with letter', () => {
      const result = Schema.decodeUnknownSync(ProjectName)('ember-api');
      expect(result as string).toBe('ember-api');
    });

    test('accepts names with numbers', () => {
      const result = Schema.decodeUnknownSync(ProjectName)('project123');
      expect(result as string).toBe('project123');
    });

    test('rejects names starting with number', () => {
      expect(() => Schema.decodeUnknownSync(ProjectName)('123project')).toThrow();
    });

    test('rejects names with uppercase', () => {
      expect(() => Schema.decodeUnknownSync(ProjectName)('MyProject')).toThrow();
    });

    test('rejects names with underscores', () => {
      expect(() => Schema.decodeUnknownSync(ProjectName)('my_project')).toThrow();
    });
  });

  describe('ProjectType', () => {
    test('accepts monorepo', () => {
      const result = Schema.decodeUnknownSync(ProjectType)('monorepo');
      expect(result).toBe('monorepo');
    });

    test('accepts api', () => {
      const result = Schema.decodeUnknownSync(ProjectType)('api');
      expect(result).toBe('api');
    });

    test('accepts ui', () => {
      const result = Schema.decodeUnknownSync(ProjectType)('ui');
      expect(result).toBe('ui');
    });

    test('accepts infra', () => {
      const result = Schema.decodeUnknownSync(ProjectType)('infra');
      expect(result).toBe('infra');
    });

    test('accepts library', () => {
      const result = Schema.decodeUnknownSync(ProjectType)('library');
      expect(result).toBe('library');
    });

    test('rejects invalid types', () => {
      expect(() => Schema.decodeUnknownSync(ProjectType)('invalid')).toThrow();
    });
  });

  describe('PortConfig', () => {
    test('accepts valid port numbers', () => {
      const result = Schema.decodeUnknownSync(PortConfig)({
        http: 3000,
        debug: 9229,
      });
      expect((result as { http: number; debug: number }).http).toBe(3000);
      expect((result as { http: number; debug: number }).debug).toBe(9229);
    });

    test('accepts optional metrics port', () => {
      const result = Schema.decodeUnknownSync(PortConfig)({
        http: 3000,
        metrics: 9090,
      });
      expect(result.metrics as number).toBe(9090);
    });

    test('rejects ports below 1024', () => {
      expect(() =>
        Schema.decodeUnknownSync(PortConfig)({
          http: 80,
        })
      ).toThrow();
    });

    test('rejects ports above 65535', () => {
      expect(() =>
        Schema.decodeUnknownSync(PortConfig)({
          http: 70000,
        })
      ).toThrow();
    });
  });

  describe('InfraConfig', () => {
    test('accepts valid infra config', () => {
      const result = Schema.decodeUnknownSync(InfraConfig)({
        runtime: 'bun',
        database: 'turso',
      });
      expect(result).toEqual({ runtime: 'bun', database: 'turso' });
    });

    test('accepts config without optional database', () => {
      const result = Schema.decodeUnknownSync(InfraConfig)({
        runtime: 'node',
      });
      expect(result.runtime).toBe('node');
      expect(result.database).toBeUndefined();
    });

    test('accepts all database types', () => {
      for (const db of ['turso', 'd1', 'neon'] as const) {
        const result = Schema.decodeUnknownSync(InfraConfig)({
          runtime: 'bun',
          database: db,
        });
        expect(result.database).toBe(db);
      }
    });
  });

  describe('ObservabilityConfig', () => {
    test('accepts valid observability config', () => {
      const result = Schema.decodeUnknownSync(ObservabilityConfig)({
        processCompose: true,
        metrics: true,
        debugger: 'vscode',
      });
      expect(result).toEqual({
        processCompose: true,
        metrics: true,
        debugger: 'vscode',
      });
    });

    test('requires processCompose to be true', () => {
      // processCompose is required per user's specification
      const result = Schema.decodeUnknownSync(ObservabilityConfig)({
        processCompose: true,
        metrics: false,
        debugger: 'nvim-dap',
      });
      expect(result.processCompose).toBe(true);
    });
  });

  describe('ProjectSpec (full)', () => {
    test('accepts minimal valid spec', () => {
      const spec = {
        name: 'my-project',
        type: 'api',
        infra: {
          runtime: 'bun',
        },
        observability: {
          processCompose: true,
          metrics: false,
          debugger: 'vscode',
        },
      };
      const result = Schema.decodeUnknownSync(ProjectSpec)(spec);
      expect(result.name as string).toBe('my-project');
      expect(result.type).toBe('api');
    });

    test('accepts full spec with all optional fields', () => {
      const spec = {
        name: 'ember-platform',
        description: 'Voice memory platform for families',
        type: 'monorepo',
        ports: {
          http: 3000,
          debug: 9229,
          metrics: 9090,
        },
        infra: {
          runtime: 'bun',
          database: 'turso',
          workflow: 'temporal',
        },
        observability: {
          processCompose: true,
          metrics: true,
          debugger: 'vscode',
        },
      };
      const result = Schema.decodeUnknownSync(ProjectSpec)(spec);
      expect(result.name as string).toBe('ember-platform');
      expect(result.description).toBe('Voice memory platform for families');
      expect(result.ports?.http as number).toBe(3000);
      expect(result.infra.database).toBe('turso');
    });

    test('rejects spec with invalid name', () => {
      const spec = {
        name: 'Invalid-Name',
        type: 'api',
        infra: { runtime: 'bun' },
        observability: { processCompose: true, metrics: false, debugger: 'vscode' },
      };
      expect(() => Schema.decodeUnknownSync(ProjectSpec)(spec)).toThrow();
    });

    test('rejects spec missing required fields', () => {
      const spec = {
        name: 'my-project',
        // missing type, infra, observability
      };
      expect(() => Schema.decodeUnknownSync(ProjectSpec)(spec)).toThrow();
    });
  });
});
