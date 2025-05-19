# Modern Conventional Commits Workflow (2025)

This document provides a comprehensive guide to using the conventional commits workflow in your projects. This implementation includes fuzzy filtering, commitlint validation, and AI-assisted commit messages.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Tools and Integrations](#tools-and-integrations)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

The Conventional Commits workflow implemented in this dotfiles repository provides:

- **Commitizen integration** with fuzzy filtering using `cz-git`
- **Commitlint validation** for enforcing conventional commit format
- **Husky hooks** for running pre-commit and commit-msg validations
- **AI-assisted commit messages** using Claude to analyze changes and generate commits
- **Fuzzy git commands** for interactive staging and committing
- **Shell aliases** for streamlined workflow

## Installation

All configuration is already set up in your dotfiles. The main setup script automatically configures the conventional commits workflow.

If you need to manually initialize or reinitialize the tooling:

```bash
# Initialize conventional commits tooling
cd ~/dotfiles/config/git/commitizen
npm install

# Run the setup script
node scripts/setup-hooks.js
```

Alternatively, use the helper function:

```bash
# Run the helper function from anywhere
git-setup-conv
```

This will:
1. Install required dependencies (commitizen, cz-git, commitlint, husky)
2. Set up git hooks for commit validation
3. Configure git to use the hooks

To source the shell aliases immediately:

```bash
source ~/dotfiles/config/zsh/git-aliases.zsh
```

## Usage

### Basic Workflow

```bash
# 1. Make changes to your code
# 2. Stage files using fuzzy add
gfa
# 3. Commit using commitizen with fuzzy filtering
gcz
# 4. Push your changes
git push
```

### Available Commands

| Command | Description |
|---------|-------------|
| `git-cz` or `gcz` | Interactive commitizen prompt with fuzzy filtering |
| `gczf` | Commitizen without hook validation (for WIP commits) |
| `gfa` | Fuzzy-find and stage files for commit |
| `gfc` | Fuzzy-find, stage, and commit in one command |
| `gaic` | Generate commit message using AI |
| `gclint` | Run commitlint on last commit |
| `git-setup-conv` | Re-initialize conventional commits setup |
| `git-conv-help` | Show quick reference for conventional commits |

### AI-Assisted Commits

The `gaic` command will:
1. Analyze your staged changes
2. Generate a conventional commit message that describes the changes
3. Offer to use the generated message or modify it

```bash
# Stage changes first
git add .
# Use AI to generate commit message
gaic
```

## Configuration

The conventional commits setup uses the following configuration files:

- **`~/dotfiles/config/git/commitizen/.czrc`**: Commitizen configuration
- **`~/dotfiles/config/git/commitizen/commitlint.config.js`**: Commitlint rules
- **`~/dotfiles/config/git/gitconfig`**: Git aliases and core settings
- **`~/dotfiles/config/git/gitmessage`**: Commit message template
- **`~/dotfiles/config/zsh/git-aliases.zsh`**: Shell aliases and functions

### Customizing Commit Types

The default configuration includes standard conventional commit types plus a few custom ones:

- Standard: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
- Custom: `wip` (work in progress), `deps` (dependency updates)

To add custom types, edit the following files:
- `commitlint.config.js`: Add to the `type-enum` rule
- `.czrc`: Add to the `types` object

### Customizing Commit Scopes

Allowed scopes are defined in the `commitlint.config.js` file under the `scope-enum` rule.

## Tools and Integrations

This setup integrates the following tools:

- **[Commitizen](https://github.com/commitizen/cz-cli)**: Interactive commit message wizard
- **[cz-git](https://github.com/Zhengqbbb/cz-git)**: Commitizen adapter with fuzzy filtering
- **[Commitlint](https://github.com/conventional-changelog/commitlint)**: Validate commit messages
- **[Husky](https://github.com/typicode/husky)**: Git hooks to validate commits
- **[Claude AI](https://claude.ai)**: AI-assisted commit message generation

## Best Practices

- **Use scopes consistently**: Choose meaningful scopes that map to areas of your codebase
- **Keep the subject line concise**: Aim for 50 characters or less
- **Use imperative mood**: Write "add feature" not "added feature"
- **Include a body for complex changes**: Explain why the change was made
- **Reference issues in footer**: Use "Fixes #123" or "Related to #456"
- **Mark breaking changes**: Use `!` suffix or `BREAKING CHANGE:` in the body

## Troubleshooting

### Commitizen not found

If you get `command not found: commitizen` or similar errors:

```bash
# Reinstall dependencies
cd ~/dotfiles/config/git/commitizen
npm install

# Make sure global node_modules bin is in your PATH
export PATH="$PATH:$(npm config get prefix)/bin"
```

### Commit validation failing

If your commits are being rejected:

```bash
# Check the commitlint rules
cat ~/dotfiles/config/git/commitizen/commitlint.config.js

# Test a commit message manually
echo "feat: my change" | npx --no-install commitlint

# Bypass validation for temporary commits
git commit --no-verify -m "WIP: temporary commit"
# Or use the alias
gczf
```

### Husky hooks not running

If hooks aren't executing:

```bash
# Check hooks path setting
git config --get core.hooksPath

# Run setup script again
cd ~/dotfiles/config/git/commitizen
node scripts/setup-hooks.js
```