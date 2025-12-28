/**
 * Memory System Tests
 *
 * Validates the 22 canonical memories are correctly defined
 * and maintain structural integrity.
 */
import { Schema } from 'effect'
import { describe, expect, it } from 'vitest'
import { getMemoriesByCategory, getMemory, MEMORIES, MEMORY_COUNTS } from './index'
import { MemorySchema } from './schemas'

describe('Memory System', () => {
  describe('counts', () => {
    it('has exactly 35 memories', () => {
      expect(MEMORIES).toHaveLength(35)
      expect(MEMORY_COUNTS.total).toBe(35)
    })

    it('has correct category distribution', () => {
      expect(MEMORY_COUNTS.principle).toBe(7)
      expect(MEMORY_COUNTS.constraint).toBe(9)
      expect(MEMORY_COUNTS.pattern).toBe(16)
      expect(MEMORY_COUNTS.gotcha).toBe(0)
      expect(MEMORY_COUNTS.standard).toBe(3)
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
    it('getMemoriesByCategory returns correct counts', () => {
      expect(getMemoriesByCategory('principle')).toHaveLength(7)
      expect(getMemoriesByCategory('constraint')).toHaveLength(9)
      expect(getMemoriesByCategory('pattern')).toHaveLength(16)
      expect(getMemoriesByCategory('gotcha')).toHaveLength(0)
      expect(getMemoriesByCategory('standard')).toHaveLength(3)
    })

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
