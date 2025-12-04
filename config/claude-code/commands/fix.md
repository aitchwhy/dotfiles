---
description: Structured bug fixing with minimal changes
allowed-tools: Read, Write, Bash, Grep, Glob
---

# Bug Fix Protocol

Follow this structured approach to fix: $ARGUMENTS

## 1. Understand

- What is the expected behavior?
- What is the actual behavior?
- What are the reproduction steps?

## 2. Investigate

- Search for related code: `rg "$ARGUMENTS" --type ts --type tsx`
- Check recent changes: `git log --oneline -20`
- Look for similar patterns in codebase

## 3. Plan

- Identify the root cause (not symptoms)
- Propose the minimal fix
- Consider side effects

## 4. Implement

- Make the smallest change that fixes the issue
- Follow existing code patterns
- Add type safety if missing

## 5. Validate

- Run `/validate` to ensure no regressions
- Test the specific fix manually if needed

## 6. Commit

- Use conventional commit: `fix(scope): description`
- Reference issue number if applicable
