---
description: Conventional commit helper
allowed-tools: Bash, Read
---

# Commit Helper

## 1. Pre-flight

```bash
git status
git diff --cached --stat
```

## 2. Validate

- Run `/validate` to ensure clean state
- Confirm all changes are intentional

## 3. Compose Message

Based on staged changes, suggest a commit message:

Format: `type(scope): description`

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code change that neither fixes nor adds
- `test`: Adding/updating tests
- `docs`: Documentation only
- `chore`: Build process, dependencies
- `ci`: CI/CD changes

**Rules:**
- Imperative mood ("add" not "added")
- No period at end
- Max 72 characters
- Scope is optional but helpful

## 4. Execute

```bash
git commit -m "type(scope): description"
```

## 5. Verify

```bash
git log -1 --oneline
```
