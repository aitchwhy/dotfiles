---
description: Cross-project SSOT validation tool
allowed-tools: Bash, Read, Grep, Glob
---

# paragon-sync

Validates Single Source of Truth (SSOT) compliance across projects.

## Usage

```bash
/paragon-sync [target-dir]
```

## Checks Performed

1. **Version Drift** - package.json versions vs dotfiles/config/quality/versions.json
2. **Forbidden Dependencies** - lodash, express, prisma, jest, etc.
3. **Forbidden Files** - package-lock.json, .eslintrc, .prettierrc, jest.config.js

## Example

```bash
# Validate current project
/paragon-sync

# Validate specific project
/paragon-sync ~/projects/my-app
```

## Implementation

```bash
bun run ~/dotfiles/config/agents/hooks/paragon-sync.ts [target-dir]
```
