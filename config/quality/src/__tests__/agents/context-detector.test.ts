/**
 * Context Detector Tests
 *
 * Tests for automatic agent/skill activation based on context.
 */
import { describe, expect, it } from 'bun:test';
import {
  detectAgents,
  detectContext,
  detectSkills,
  parseGitStatus,
} from '../../agents/context-detector';

describe('Context Detector', () => {
  describe('detectContext', () => {
    it('returns empty results for empty context', () => {
      const result = detectContext({});

      expect(result.agents).toEqual([]);
      expect(result.skills).toEqual(['verification-first']); // always active
    });

    it('activates debugger agent on error patterns', () => {
      const result = detectContext({
        recentOutput: 'Error: Something went wrong\nStack trace...',
      });

      expect(result.agents).toContain('debugger');
    });

    it('activates fixer agent on test failures', () => {
      const result = detectContext({
        recentOutput: 'FAIL  src/auth.test.ts\n3 failing tests',
      });

      expect(result.agents).toContain('fixer');
    });

    it('activates feature agent on implement keywords', () => {
      const result = detectContext({
        prompt: 'Please implement a new login feature',
      });

      expect(result.agents).toContain('feature');
    });

    it('activates code-reviewer on git changes', () => {
      const result = detectContext({
        gitState: {
          hasStagedChanges: true,
          hasUnstagedChanges: false,
          hasMergeConflict: false,
          hasRebaseInProgress: false,
        },
      });

      expect(result.agents).toContain('code-reviewer');
    });

    it('activates tdd-patterns on test files', () => {
      const result = detectContext({
        activeFiles: ['src/auth.test.ts', 'src/user.test.ts'],
      });

      expect(result.skills).toContain('tdd-patterns');
    });

    it('activates commit-patterns on staged changes with commit keyword', () => {
      const result = detectContext({
        prompt: 'commit these changes',
        gitState: {
          hasStagedChanges: true,
          hasUnstagedChanges: false,
          hasMergeConflict: false,
          hasRebaseInProgress: false,
        },
      });

      expect(result.skills).toContain('commit-patterns');
    });

    it('activates planning-patterns for complex tasks', () => {
      const result = detectContext({
        prompt: 'How should I refactor this authentication system?',
      });

      expect(result.skills).toContain('planning-patterns');
    });

    it('activates typescript-patterns for TS files', () => {
      const result = detectContext({
        activeFiles: ['src/services/auth.ts'],
      });

      expect(result.skills).toContain('typescript-patterns');
    });

    it('activates nix-darwin-patterns for Nix files', () => {
      const result = detectContext({
        activeFiles: ['modules/home/default.nix'],
      });

      expect(result.skills).toContain('nix-darwin-patterns');
    });

    it('activates multiple agents/skills for complex contexts', () => {
      const result = detectContext({
        prompt: 'implement error handling',
        activeFiles: ['src/services/api.ts'],
        recentOutput: 'Error: Network timeout',
        gitState: {
          hasStagedChanges: false,
          hasUnstagedChanges: true,
          hasMergeConflict: false,
          hasRebaseInProgress: false,
        },
      });

      // Should activate multiple based on different signals
      expect(result.agents.length).toBeGreaterThan(0);
      expect(result.skills.length).toBeGreaterThan(0);
    });

    it('always includes verification-first skill', () => {
      const result = detectContext({});

      expect(result.skills).toContain('verification-first');
    });
  });

  describe('detectAgents', () => {
    it('returns only agents', () => {
      const agents = detectAgents({
        recentOutput: 'Error: test failed',
      });

      expect(agents).toContain('debugger');
      expect(agents).not.toContain('verification-first');
    });
  });

  describe('detectSkills', () => {
    it('returns only skills', () => {
      const skills = detectSkills({
        activeFiles: ['src/auth.test.ts'],
      });

      expect(skills).toContain('tdd-patterns');
      expect(skills).toContain('verification-first');
      expect(skills).not.toContain('debugger');
    });
  });

  describe('parseGitStatus', () => {
    it('detects staged changes', () => {
      const status = parseGitStatus('M  src/file.ts\nA  src/new.ts');

      expect(status.hasStagedChanges).toBe(true);
      expect(status.hasUnstagedChanges).toBe(false);
    });

    it('detects unstaged changes', () => {
      const status = parseGitStatus(' M src/file.ts\n?? src/untracked.ts');

      expect(status.hasStagedChanges).toBe(false);
      expect(status.hasUnstagedChanges).toBe(true);
    });

    it('detects merge conflicts', () => {
      const status = parseGitStatus('UU src/conflicted.ts');

      expect(status.hasMergeConflict).toBe(true);
    });

    it('detects rebase in progress', () => {
      const status = parseGitStatus('interactive rebase in progress; onto abc123\nM  src/file.ts');

      expect(status.hasRebaseInProgress).toBe(true);
    });

    it('handles mixed status', () => {
      const status = parseGitStatus('M  src/staged.ts\n M src/unstaged.ts\n?? new.ts');

      expect(status.hasStagedChanges).toBe(true);
      expect(status.hasUnstagedChanges).toBe(true);
    });
  });
});

describe('Trigger Registry', () => {
  it('has unique rule IDs', () => {
    const { TRIGGER_REGISTRY } = require('../../agents/trigger-registry');
    const ids = TRIGGER_REGISTRY.map((r: { id: string }) => r.id);
    const uniqueIds = [...new Set(ids)];

    expect(ids.length).toBe(uniqueIds.length);
  });

  it('has valid priorities', () => {
    const { TRIGGER_REGISTRY } = require('../../agents/trigger-registry');

    for (const rule of TRIGGER_REGISTRY) {
      expect(rule.priority).toBeGreaterThanOrEqual(0);
      expect(rule.priority).toBeLessThanOrEqual(100);
    }
  });

  it('getRulesByPriority returns sorted rules', () => {
    const { getRulesByPriority } = require('../../agents/trigger-registry');
    const rules = getRulesByPriority();

    for (let i = 1; i < rules.length; i++) {
      expect(rules[i - 1].priority).toBeGreaterThanOrEqual(rules[i].priority);
    }
  });

  it('getRulesByTargetType filters correctly', () => {
    const { getRulesByTargetType } = require('../../agents/trigger-registry');

    const agentRules = getRulesByTargetType('agent');
    const skillRules = getRulesByTargetType('skill');

    expect(agentRules.every((r: { target: { type: string } }) => r.target.type === 'agent')).toBe(
      true
    );
    expect(skillRules.every((r: { target: { type: string } }) => r.target.type === 'skill')).toBe(
      true
    );
  });
});
