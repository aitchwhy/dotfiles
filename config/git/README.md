# Git Configuration

A comprehensive Git configuration with Conventional Commits support, AI-assisted commit messages, and workflow optimizations for modern development practices.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Conventional Commits Workflow](#conventional-commits-workflow)
- [Commands & Aliases](#commands--aliases)
- [AI Integration](#ai-integration)
- [File Structure](#file-structure)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)

## Features

- **Conventional Commits** with fuzzy filtering and auto-completion
- **Commitlint** validation for enforcing commit message standards
- **Husky** hooks for pre-commit and commit-message validation
- **AI-assisted** commit message generation using Claude
- **Fuzzy commands** for interactive staging and committing
- **Optimized Git defaults** for modern development workflows

## Installation

The Git configuration is installed automatically as part of the dotfiles setup:

```bash
cd ~/dotfiles
./scripts/setup.sh
```

To initialize just the Git configuration with Conventional Commits support:

```bash
# Install dependencies
cd ~/dotfiles/config/git/commitizen
npm install

# Set up git hooks
node scripts/setup-hooks.js

# Source the git aliases
source ~/dotfiles/config/zsh/git-aliases.zsh
```

## Conventional Commits Workflow

### What are Conventional Commits?

Conventional Commits is a specification for adding human and machine-readable meaning to commit messages. It provides a simple set of rules for creating an explicit commit history, making it easier to automate releases and changelogs.

### Basic Format

```
<type>(<optional scope>): <description>

<optional body>

<optional footer>
```

Example:
```
feat(auth): add OAuth2 authentication

Implement OAuth2 authentication for Google and GitHub providers.
Includes token refresh and profile fetching capabilities.

Fixes #123
```

### Workflow Diagram

```
┌─────────────────┐         ┌───────────────┐           ┌───────────────┐
│                 │         │               │           │               │
│  Code Changes   │──────►  │ Stage Changes │──────►    │    Commit     │
│                 │         │  (git add or  │           │  (git-cz or   │
└─────────────────┘         │     gfa)      │           │    gcz)       │
                            └───────────────┘           └───────┬───────┘
                                                                │
                                                                ▼
┌─────────────────┐         ┌───────────────┐           ┌───────────────┐
│                 │         │               │           │               │
│      Push       │◄────────│  Passes       │◄──────────│ Commitlint    │
│                 │    Yes   │  Validation?  │     No    │   Checks     │
└─────────────────┘         │               │──────────►│   Message     │
                            └───────────────┘           └───────────────┘
```

### Quick Start

1. Make your code changes
2. Stage files with either:
   ```bash
   git add .               # Stage all changes
   gfa                     # Fuzzy-select files to stage
   ```

3. Commit using Commitizen:
   ```bash
   gcz                     # Launch interactive commit wizard
   # Or
   git-cz                  # Same as above
   ```

4. The interactive prompt will help you create a properly formatted commit message with:
   - Type (feat, fix, docs, etc.)
   - Scope (optional component name)
   - Short description
   - Longer description (optional)
   - Breaking changes (optional)
   - Issue references (optional)

## Commands & Aliases

### Git Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `cz` | `!f() { npx --no-install commitizen; }; f` | Launch commitizen |
| `czf` | `!f() { npx --no-install -- commitizen; }; f` | Launch commitizen (force) |
| `fzcommit` | `!f() { git status --short \| fzf --multi --preview 'git diff --color {2}' \| ... }; f` | Fuzzy add and commit |
| `fzadd` | `!f() { git status --short \| fzf --multi --preview 'git diff --color {2}' \| ... }; f` | Fuzzy add files |
| `ai-commit` | `!f() { just ai commit-msg; }; f` | AI-generated commit message |

### Shell Aliases

| Alias | Description |
|-------|-------------|
| `git-cz` or `gcz` | Launch commitizen |
| `gczf` | Launch commitizen (skip hooks) |
| `gfa` | Fuzzy-add files |
| `gfc` | Fuzzy-add and commit |
| `gaic` | AI-assisted commit message |
| `gll` | Enhanced log view |
| `glc` | Complete log view with all branches |
| `gco` | Fuzzy checkout branch |
| `gbr` | List and checkout branch |
| `gclint` | Run commitlint on last commit |

### Helper Functions

| Function | Description |
|----------|-------------|
| `git-setup-conv` | Initialize conventional commits setup |
| `git-conv-help` | Show quick reference guide |

## AI Integration

This configuration integrates with Claude AI to generate meaningful commit messages based on your changes:

```bash
# Stage your changes
git add .

# Generate AI-assisted commit message
gaic
# or
git ai-commit
```

The AI will:
1. Analyze your staged changes
2. Identify the type of changes (feature, fix, docs, etc.)
3. Generate a conventional commit message
4. Present the message for your approval

## File Structure

```
config/git/
├── gitconfig             # Main Git configuration
├── gitmessage            # Commit message template
├── gitignore             # Global gitignore rules
├── commitizen/           # Conventional commits setup
│   ├── package.json      # Dependencies
│   ├── commitlint.config.js  # Commit validation rules
│   ├── .czrc             # Commitizen configuration
│   └── scripts/          # Setup scripts
└── README.md             # This documentation
```

## Customization

### Commit Types

To add or modify commit types, edit the following files:

1. **`commitlint.config.js`**: Update the `type-enum` array
   ```js
   'type-enum': [
     2,
     'always',
     [
       'feat',
       'fix',
       // Add your custom type here
     ]
   ]
   ```

2. **`.czrc`**: Add to the `types` object
   ```json
   "types": {
     "custom": {
       "description": "Custom type description",
       "title": "Custom Title",
       "emoji": "🔧"
     }
   }
   ```

### Commit Scopes

To customize the allowed scopes, edit the `scope-enum` array in `commitlint.config.js`.

## Troubleshooting

### Common Issues

1. **Commitizen not found**
   ```bash
   cd ~/dotfiles/config/git/commitizen
   npm install
   ```

2. **Git hooks not running**
   ```bash
   node ~/dotfiles/config/git/commitizen/scripts/setup-hooks.js
   ```

3. **Bypass validation for WIP commits**
   ```bash
   git commit --no-verify -m "wip: temporary commit"
   # or
   gczf
   ```

For detailed information about using conventional commits, see [CONVENTIONAL_COMMITS.md](../../docs/CONVENTIONAL_COMMITS.md).