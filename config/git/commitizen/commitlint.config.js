// commitlint.config.js
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'header-max-length': [2, 'always', 72],
    'body-max-line-length': [2, 'always', 100],
    'subject-case': [
      2, 
      'never',
      ['upper-case', 'pascal-case', 'start-case']
    ],
    'scope-case': [2, 'always', 'kebab-case'],
    'type-enum': [
      2,
      'always',
      [
        'feat',
        'fix',
        'docs',
        'style',
        'refactor',
        'perf',
        'test',
        'build',
        'ci',
        'chore',
        'revert',
        'wip', // Work in progress
        'deps'  // Dependencies
      ]
    ],
    'scope-enum': [
      2, 
      'always', 
      [
        'git',
        'nvim',
        'zsh',
        'brew',
        'ai',
        'yazi',
        'system',
        'docs',
        'starship',
        'config',
        'karabiner',
        'hammerspoon',
        'sdk',
        'aerospace',
        'workflow',
        'tools',
        '*'  // Allow anything else for flexibility
      ]
    ],
  },
  prompt: {
    settings: {
      enableMultipleScopes: true,
      scopeEnumSeparator: ','
    },
    messages: {
      skip: '(optional)',
      max: 'maximum %d chars',
      min: 'minimum %d chars',
      emptyWarning: 'cannot be empty',
      upperLimitWarning: 'over limit',
      lowerLimitWarning: 'below limit'
    },
    questions: {
      type: {
        description: "Select the type of change you're committing:",
        enum: {
          feat: {
            description: 'A new feature',
            title: 'Features',
            emoji: '✨'
          },
          fix: {
            description: 'A bug fix',
            title: 'Bug Fixes',
            emoji: '🐛'
          },
          docs: {
            description: 'Documentation only changes',
            title: 'Documentation',
            emoji: '📝'
          },
          style: {
            description: 'Changes that do not affect code meaning (white-space, formatting, etc)',
            title: 'Styles',
            emoji: '💄'
          },
          refactor: {
            description: 'A code change that neither fixes a bug nor adds a feature',
            title: 'Code Refactoring',
            emoji: '♻️'
          },
          perf: {
            description: 'A code change that improves performance',
            title: 'Performance Improvements',
            emoji: '⚡️'
          },
          test: {
            description: 'Adding missing tests or correcting existing tests',
            title: 'Tests',
            emoji: '✅'
          },
          build: {
            description: 'Changes that affect the build system or external dependencies',
            title: 'Builds',
            emoji: '📦'
          },
          ci: {
            description: 'Changes to CI configuration files and scripts',
            title: 'Continuous Integration',
            emoji: '👷'
          },
          chore: {
            description: "Other changes that don't modify src or test files",
            title: 'Chores',
            emoji: '🔧'
          },
          revert: {
            description: 'Reverts a previous commit',
            title: 'Reverts',
            emoji: '⏪'
          },
          wip: {
            description: 'Work in progress',
            title: 'WIP',
            emoji: '🚧'
          },
          deps: {
            description: 'Dependencies updates',
            title: 'Dependencies',
            emoji: '📌'
          }
        }
      },
      scope: {
        description: 'What is the scope of this change (e.g. component or file name)'
      },
      subject: {
        description: 'Write a short, imperative tense description of the change'
      },
      body: {
        description: 'Provide a longer description of the change'
      },
      isBreaking: {
        description: 'Are there any breaking changes?'
      },
      breakingBody: {
        description: 'A BREAKING CHANGE commit requires a body. Please enter a longer description of the commit itself'
      },
      breaking: {
        description: 'Describe the breaking changes'
      },
      isIssueAffected: {
        description: 'Does this change affect any open issues?'
      },
      issuesBody: {
        description: 'If issues are closed, the commit requires a body. Please enter a longer description of the commit itself'
      },
      issues: {
        description: 'Add issue references (e.g. "fix #123", "re #123".)'
      }
    }
  }
};