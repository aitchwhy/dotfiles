---
description: Spec-first TDD feature implementation
allowed-tools: Read, Write, Bash, Grep, Glob
---

# Feature Implementation: $ARGUMENTS

## 1. Specification

- Define the feature requirements clearly
- Identify acceptance criteria
- List edge cases

## 2. Schema First

- Define Zod schemas for new data structures
- Update shared types in packages/domain if needed
- Ensure types are exported

## 3. Test First (TDD)

- Write failing E2E test for happy path
- Write unit tests for core logic
- Tests should be red initially

## 4. Implement

- Implement minimum code to pass tests
- Follow existing patterns in codebase
- Use Result types for error handling

## 5. Refactor

- Clean up while tests stay green
- Extract reusable utilities
- Improve naming and documentation

## 6. Validate

- Run `/validate` for full check
- Ensure no type errors
- Confirm all tests pass

## 7. Commit

- Use: `feat(scope): description`
- Keep commits atomic
