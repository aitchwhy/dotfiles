/**
 * Architect Enforcer Tests
 *
 * Tests for hexagonal boundary and architecture validation.
 */
import { Effect } from 'effect'
import { describe, expect, test } from 'bun:test'
import {
  checkHexagonalBoundaries,
  checkCircularDependencies,
  checkLayerViolations,
  type ArchitectViolation,
} from '@/enforcers/architect'

describe('Architect Enforcer', () => {
  describe('checkHexagonalBoundaries', () => {
    test('allows adapters to import from ports', async () => {
      const imports = [
        { from: 'src/adapters/turso.ts', to: 'src/ports/database.ts' },
      ]

      const program = checkHexagonalBoundaries(imports)
      const violations = await Effect.runPromise(program)

      expect(violations).toEqual([])
    })

    test('disallows ports to import from adapters', async () => {
      const imports = [
        { from: 'src/ports/database.ts', to: 'src/adapters/turso.ts' },
      ]

      const program = checkHexagonalBoundaries(imports)
      const violations = await Effect.runPromise(program)

      expect(violations.length).toBe(1)
      expect(violations[0]?.rule).toBe('port-imports-adapter')
    })

    test('allows app to import from ports', async () => {
      const imports = [
        { from: 'src/app/service.ts', to: 'src/ports/database.ts' },
      ]

      const program = checkHexagonalBoundaries(imports)
      const violations = await Effect.runPromise(program)

      expect(violations).toEqual([])
    })
  })

  describe('checkCircularDependencies', () => {
    test('returns no violations for acyclic graph', async () => {
      const imports = [
        { from: 'a.ts', to: 'b.ts' },
        { from: 'b.ts', to: 'c.ts' },
      ]

      const program = checkCircularDependencies(imports)
      const violations = await Effect.runPromise(program)

      expect(violations).toEqual([])
    })

    test('detects simple circular dependency', async () => {
      const imports = [
        { from: 'a.ts', to: 'b.ts' },
        { from: 'b.ts', to: 'a.ts' },
      ]

      const program = checkCircularDependencies(imports)
      const violations = await Effect.runPromise(program)

      expect(violations.length).toBe(1)
      expect(violations[0]?.rule).toBe('circular-dependency')
    })

    test('detects longer circular dependency chain', async () => {
      const imports = [
        { from: 'a.ts', to: 'b.ts' },
        { from: 'b.ts', to: 'c.ts' },
        { from: 'c.ts', to: 'a.ts' },
      ]

      const program = checkCircularDependencies(imports)
      const violations = await Effect.runPromise(program)

      expect(violations.length).toBe(1)
      expect(violations[0]?.rule).toBe('circular-dependency')
    })
  })

  describe('checkLayerViolations', () => {
    test('allows lower layers to not import upper layers', async () => {
      const imports = [
        { from: 'src/routes/api.ts', to: 'src/app/service.ts' },
        { from: 'src/app/service.ts', to: 'src/ports/database.ts' },
      ]

      const program = checkLayerViolations(imports)
      const violations = await Effect.runPromise(program)

      expect(violations).toEqual([])
    })

    test('detects routes being imported by app layer', async () => {
      const imports = [
        { from: 'src/app/service.ts', to: 'src/routes/api.ts' },
      ]

      const program = checkLayerViolations(imports)
      const violations = await Effect.runPromise(program)

      expect(violations.length).toBe(1)
      expect(violations[0]?.rule).toBe('layer-violation')
    })
  })
})
