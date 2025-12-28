// commitlint.config.js - SSOT for conventional commits
// Consume: ln -sf ~/dotfiles/config/quality/commitlint.config.js commitlint.config.js

/** @type {import('@commitlint/types').UserConfig} */
export default {
  rules: {
    // Type is required
    'type-empty': [2, 'never'],
    // Subject is required
    'subject-empty': [2, 'never'],
    // Allowed commit types
    'type-enum': [2, 'always', ['feat', 'fix', 'refactor', 'test', 'docs', 'chore', 'perf', 'ci']],
    // Scope must be lowercase
    'scope-case': [2, 'always', 'lower-case'],
    // No period at end of subject
    'subject-full-stop': [2, 'never', '.'],
    // Allow any case in subject (we don't enforce sentence case)
    'subject-case': [0],
    // Body must have blank line before it
    'body-leading-blank': [2, 'always'],
    // Footer must have blank line before it
    'footer-leading-blank': [2, 'always'],
    // Header max length
    'header-max-length': [2, 'always', 100],
  },
}
