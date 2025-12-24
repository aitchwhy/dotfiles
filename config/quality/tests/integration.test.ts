/**
 * Integration Tests
 *
 * End-to-end tests for the quality system.
 */

import { describe, expect, it } from 'vitest';
import { ALL_PERSONAS } from '../src/personas';
import { ALL_RULES } from '../src/rules';
import { ALL_SKILLS } from '../src/skills';

describe('Quality System Integration', () => {
  describe('counts', () => {
    it('has exactly 12 rules', () => {
      expect(ALL_RULES).toHaveLength(12);
    });

    it('has exactly 9 skills', () => {
      expect(ALL_SKILLS).toHaveLength(9);
    });

    it('has exactly 6 personas', () => {
      expect(ALL_PERSONAS).toHaveLength(6);
    });
  });

  describe('rules coverage', () => {
    it('covers all categories', () => {
      const categories = new Set(ALL_RULES.map((r) => r.category));
      expect(categories).toContain('type-safety');
      expect(categories).toContain('effect');
      expect(categories).toContain('architecture');
      expect(categories).toContain('observability');
    });

    it('has error-severity rules for critical violations', () => {
      const errors = ALL_RULES.filter((r) => r.severity === 'error');
      expect(errors.length).toBeGreaterThan(0);

      const criticalIds = ['no-any', 'no-try-catch', 'no-mock', 'no-console'];
      for (const id of criticalIds) {
        expect(errors.some((r) => r.id === id)).toBe(true);
      }
    });
  });

  describe('skills coverage', () => {
    it('has core Effect skill', () => {
      expect(ALL_SKILLS.some((s) => s.frontmatter.name === 'effect-ts')).toBe(true);
    });

    it('has testing skill', () => {
      expect(ALL_SKILLS.some((s) => s.frontmatter.name === 'testing')).toBe(true);
    });

    it('all skills have sections', () => {
      for (const skill of ALL_SKILLS) {
        expect(skill.sections.length).toBeGreaterThan(0);
      }
    });
  });

  describe('personas coverage', () => {
    it('has opus-level personas for complex tasks', () => {
      const opusPersonas = ALL_PERSONAS.filter((p) => p.model === 'opus');
      expect(opusPersonas.length).toBeGreaterThan(0);
    });

    it('all personas have system prompts', () => {
      for (const persona of ALL_PERSONAS) {
        expect(persona.systemPrompt.length).toBeGreaterThan(50);
      }
    });
  });
});
