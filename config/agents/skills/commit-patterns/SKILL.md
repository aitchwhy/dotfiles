---
name: commit-patterns
description: Conventional commit patterns for Nix and TypeScript projects. Automatic message composition based on staged changes.
allowed-tools: Bash, Read, Grep
---

## Conventional Commit Format

```
type(scope): description

[optional body]

[optional footer]
```

### Commit Types

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(auth): add OAuth2 login` |
| `fix` | Bug fix | `fix(api): handle null response` |
| `refactor` | Code change (no fix/feat) | `refactor(db): extract query builder` |
| `test` | Adding/updating tests | `test(user): add login tests` |
| `docs` | Documentation only | `docs(readme): update install steps` |
| `chore` | Build/dependencies | `chore(deps): update Effect to 3.20` |
| `ci` | CI/CD changes | `ci(github): add type check action` |
| `style` | Formatting (no logic) | `style: format with Biome` |
| `perf` | Performance improvement | `perf(query): add database index` |

### Scopes by Project Type

#### Nix Projects
- `darwin`, `home`, `flake`, `modules`, `packages`
- `homebrew`, `kanata`, `ghostty`, `zellij`, `nvim`

#### TypeScript Projects
- `api`, `web`, `cli`, `domain`, `infra`
- `auth`, `db`, `cache`, `queue`, `email`

### Rules

1. **Imperative mood**: "add" not "added" or "adds"
2. **No period** at end of subject line
3. **Max 72 characters** for subject line
4. **Scope is optional** but recommended
5. **Body**: Explain *why*, not *what* (code shows what)
6. **Footer**: Reference issues with `Closes #123`

## Pre-Commit Checklist

```bash
# 1. Check staged changes
git diff --cached --stat

# 2. Run validation
bun typecheck && bun lint && bun test

# 3. Review diff for secrets
git diff --cached | grep -E "(password|secret|token|key)" && echo "WARNING: Possible secret detected"
```

## Commit Message Examples

### Feature Addition
```
feat(auth): add OAuth2 Google login

Implement Google OAuth2 flow using passport.js.
Tokens stored in HttpOnly cookies for security.

Closes #42
```

### Bug Fix
```
fix(api): handle null user in profile endpoint

Previously threw 500 when user was deleted but session remained.
Now returns 401 and clears the session.
```

### Refactoring
```
refactor(db): extract connection pool to separate module

No behavior change. Improves testability by allowing
pool injection in tests.
```

### Nix Configuration
```
feat(darwin): add Kanata keyboard remapping

Configure home-row mods with tap-hold-release-keys.
CapsLock = Esc (tap) / Hyper (hold).
```

## Breaking Changes

For breaking changes, add `!` after type/scope and explain in footer:

```
feat(api)!: change auth endpoint response format

BREAKING CHANGE: /api/auth now returns { user, token }
instead of { data: { user, token } }. Update client
code to use new structure.
```

## Multi-Part Commits

For large changes, split into atomic commits:

1. `refactor(x): extract interface` (preparation)
2. `feat(x): add new implementation` (feature)
3. `test(x): add integration tests` (verification)
4. `docs(x): update API documentation` (docs)

## Git Commands

```bash
# Stage specific files
git add path/to/file.ts

# Stage hunks interactively
git add -p

# Commit with message
git commit -m "type(scope): description"

# Amend last commit (local only!)
git commit --amend

# Verify commit
git log -1 --oneline
```
