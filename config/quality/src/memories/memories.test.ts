/**
 * Memory System Tests
 *
 * Validates memory definitions and structural integrity.
 * Uses SSOT pattern - validates internal consistency, not magic numbers.
 */
import { Schema } from 'effect'
import { describe, expect, it } from 'vitest'
import { getMemoriesByCategory, getMemory, MEMORIES, MEMORY_COUNTS } from './index'
import { MemorySchema } from './schemas'

describe('Memory System', () => {
  describe('counts - SSOT validation', () => {
    it('memories array matches MEMORY_COUNTS.total', () => {
      expect(MEMORIES).toHaveLength(MEMORY_COUNTS.total)
      expect(MEMORIES.length).toBeGreaterThan(0)
    })

    it('category counts sum to total', () => {
      const sum =
        MEMORY_COUNTS.principle +
        MEMORY_COUNTS.constraint +
        MEMORY_COUNTS.pattern +
        MEMORY_COUNTS.gotcha +
        MEMORY_COUNTS.standard
      expect(sum).toBe(MEMORY_COUNTS.total)
    })

    it('each category count matches actual memories', () => {
      expect(getMemoriesByCategory('principle')).toHaveLength(MEMORY_COUNTS.principle)
      expect(getMemoriesByCategory('constraint')).toHaveLength(MEMORY_COUNTS.constraint)
      expect(getMemoriesByCategory('pattern')).toHaveLength(MEMORY_COUNTS.pattern)
      expect(getMemoriesByCategory('gotcha')).toHaveLength(MEMORY_COUNTS.gotcha)
      expect(getMemoriesByCategory('standard')).toHaveLength(MEMORY_COUNTS.standard)
    })
  })

  describe('schema validation', () => {
    it('all memories pass schema validation', () => {
      const decode = Schema.decodeUnknownSync(MemorySchema)
      for (const memory of MEMORIES) {
        expect(() => decode(memory)).not.toThrow()
      }
    })

    it('all memory IDs are unique', () => {
      const ids = MEMORIES.map((m) => m.id)
      const uniqueIds = new Set(ids)
      expect(uniqueIds.size).toBe(ids.length)
    })

    it('all memory IDs match kebab-case pattern', () => {
      const pattern = /^[a-z0-9-]+$/
      for (const memory of MEMORIES) {
        expect(memory.id).toMatch(pattern)
      }
    })
  })

  describe('content quality', () => {
    it('all memories have non-empty content', () => {
      for (const memory of MEMORIES) {
        expect(memory.content.length).toBeGreaterThan(50)
      }
    })

    it('all memories have titles under 80 chars', () => {
      for (const memory of MEMORIES) {
        expect(memory.title.length).toBeLessThanOrEqual(80)
      }
    })

    it('all memories have content under 500 chars', () => {
      for (const memory of MEMORIES) {
        expect(memory.content.length).toBeLessThanOrEqual(500)
      }
    })
  })

  describe('required memories exist', () => {
    const requiredIds = [
      'parse-dont-validate',
      'domain-purity',
      'layer-architecture',
      'effect-platform-only',
      'xstate-patterns',
      'testing-strategy',
      'directory-structure',
    ]

    it.each(requiredIds)('has required memory: %s', (id) => {
      expect(getMemory(id)).toBeDefined()
    })
  })

  describe('helper functions', () => {
    it('getMemory returns undefined for unknown ID', () => {
      expect(getMemory('nonexistent-memory')).toBeUndefined()
    })

    it('getMemory returns correct memory for valid ID', () => {
      const memory = getMemory('parse-dont-validate')
      expect(memory).toBeDefined()
      expect(memory?.category).toBe('principle')
    })
  })
})
