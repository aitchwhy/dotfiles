/**
 * Test Helpers for ProjectSpec - Tests
 */
import { describe, expect, test } from 'vitest'
import { Schema } from 'effect'
import { ProjectName } from '@/schema/project-spec'
import { makeSpec, makeProjectName } from './test-spec'

describe('Test Helpers', () => {
  describe('makeSpec', () => {
    test('creates valid ProjectSpec with defaults', () => {
      const spec = makeSpec()
      expect(spec.name).toBeDefined()
      expect(spec.type).toBe('api')
      expect(spec.infra.runtime).toBe('bun')
    })

    test('allows overriding name', () => {
      const spec = makeSpec({ name: 'my-project' })
      // Verify it's a branded type by checking schema validation
      expect(Schema.is(ProjectName)(spec.name)).toBe(true)
    })

    test('allows overriding type', () => {
      const spec = makeSpec({ type: 'monorepo' })
      expect(spec.type).toBe('monorepo')
    })

    test('allows overriding infra', () => {
      const spec = makeSpec({ infra: { runtime: 'node', database: 'd1' } })
      expect(spec.infra.runtime).toBe('node')
      expect(spec.infra.database).toBe('d1')
    })
  })

  describe('makeProjectName', () => {
    test('creates branded ProjectName from string', () => {
      const name = makeProjectName('test-project')
      expect(Schema.is(ProjectName)(name)).toBe(true)
    })

    test('validates project name format', () => {
      // Valid kebab-case names work
      expect(() => makeProjectName('valid-name')).not.toThrow()
      expect(() => makeProjectName('my-project')).not.toThrow()
      // Underscores are rejected (must be kebab-case)
      expect(() => makeProjectName('my_project')).toThrow()
    })
  })
})
