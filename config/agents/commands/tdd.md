---
description: Test-driven development cycle
allowed-tools: Read, Write, Bash
---

# TDD Cycle: $ARGUMENTS

## RED Phase

1. Write a failing test that describes desired behavior
2. Run test to confirm it fails
3. Failure message should be clear

```bash
bun test --watch
```

## GREEN Phase

1. Write minimum code to pass the test
2. Don't optimize yet
3. Keep it simple

## REFACTOR Phase

1. Clean up while tests stay green
2. Extract common patterns
3. Improve naming
4. Remove duplication

## Loop

Repeat RED -> GREEN -> REFACTOR for each behavior.

## Guidelines

- One assertion per test (usually)
- Test behavior, not implementation
- Use descriptive test names
- Arrange -> Act -> Assert pattern
