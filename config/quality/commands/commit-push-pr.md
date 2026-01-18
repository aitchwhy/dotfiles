---
description: Commit, push, and create PR with verification
allowed-tools: Bash
---

# Commit -> Push -> PR

## Pre-flight
```bash
pnpm typecheck && pnpm lint && pnpm test --run
git status --porcelain
git diff --cached --stat
```

## Commit
```bash
git add -A
git commit -m "type(scope): description"
```

### Commit Types
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code restructure
- `chore`: Maintenance
- `docs`: Documentation
- `test`: Test only
- `perf`: Performance

## Push & PR
```bash
git push -u origin HEAD
gh pr create --fill
```

Or with explicit body:
```bash
gh pr create \
  --title "type(scope): description" \
  --body "## Summary
<what and why>

## Testing
- [x] typecheck
- [x] lint
- [x] test"
```

Print PR URL when complete.
