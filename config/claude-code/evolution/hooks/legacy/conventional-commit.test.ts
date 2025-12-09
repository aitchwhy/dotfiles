/**
 * Conventional Commit Hook Tests
 */
import { describe, expect, test } from 'bun:test';

describe('Conventional Commit Hook', () => {
  // IMPORTANT: First character after `: ` must be lowercase (matches commitlint subject-case)
  const CONVENTIONAL_COMMIT_REGEX =
    /^(feat|fix|refactor|test|docs|chore|perf|ci)(\([a-z0-9-]+\))?!?:\s+[a-z]/;

  function isValidCommitMessage(message: string): boolean {
    return CONVENTIONAL_COMMIT_REGEX.test(message);
  }

  function extractCommitMessage(command: string): string | null {
    // Match -m "message" or -m 'message'
    const match = command.match(/git\s+commit\s+.*-m\s+["']([^"']+)["']/);
    return match?.[1] || null;
  }

  describe('valid commit messages', () => {
    const VALID_MESSAGES = [
      'feat(auth): add OAuth2 login',
      'fix: handle null response',
      'refactor(db): extract query builder',
      'docs: update README',
      'test(api): add integration tests',
      'chore: update dependencies',
      'perf(render): optimize list virtualization',
      'ci: add GitHub Actions workflow',
      'feat!: breaking change',
      'fix(auth)!: breaking fix',
    ];

    test.each(VALID_MESSAGES)('allows: %s', (message) => {
      expect(isValidCommitMessage(message)).toBe(true);
    });
  });

  describe('invalid commit messages', () => {
    const INVALID_MESSAGES = [
      'Updated stuff',
      'WIP',
      'fix stuff',
      'FEAT: uppercase type',
      'feat (spaced): description',
      'feat:', // no description
      'feature: wrong type',
      'Fix: capitalized type',
      // Uppercase first letter after colon (violates subject-case)
      'feat: Add uppercase first letter',
      'fix(api): Handle null response',
      'feat(web): Add TalkMachine for voice recording',
      'refactor: Refactored the code',
      'docs: Update README',
      'chore: Update dependencies',
    ];

    test.each(INVALID_MESSAGES)('blocks: %s', (message) => {
      expect(isValidCommitMessage(message)).toBe(false);
    });
  });

  describe('command parsing', () => {
    test('extracts message from -m flag with double quotes', () => {
      const cmd = 'git commit -m "feat: add feature"';
      expect(extractCommitMessage(cmd)).toBe('feat: add feature');
    });

    test('extracts message from -m flag with single quotes', () => {
      const cmd = "git commit -m 'fix: bug fix'";
      expect(extractCommitMessage(cmd)).toBe('fix: bug fix');
    });

    test('extracts message with other flags', () => {
      const cmd = 'git commit -a -m "chore: update deps"';
      expect(extractCommitMessage(cmd)).toBe('chore: update deps');
    });

    test('returns null for no -m flag', () => {
      const cmd = 'git commit'; // Will open editor
      expect(extractCommitMessage(cmd)).toBeNull();
    });

    test('returns null for non-commit commands', () => {
      const cmd = 'git status';
      expect(extractCommitMessage(cmd)).toBeNull();
    });
  });

  describe('non-commit commands', () => {
    const NON_COMMIT_COMMANDS = ['git status', 'git push', 'git pull', 'git log', 'git diff'];

    test.each(NON_COMMIT_COMMANDS)('allows: %s', (cmd) => {
      const message = extractCommitMessage(cmd);
      expect(message).toBeNull();
    });
  });
});
