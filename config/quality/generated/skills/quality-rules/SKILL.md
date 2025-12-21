---
name: quality-rules
description: All 12 active quality rules with examples and fixes
allowed-tools: Read, Grep
token-budget: 500
---

# quality-rules

## Type Safety Rules

| Rule | Severity | Fix |
|------|----------|-----|
| no-any | error | Use `unknown` + type guards |
| no-zod | error | Use Effect Schema, TS type as SSOT |
| require-branded-id | warning | `type UserId = string & Brand.Brand<"UserId">` |

## Effect Rules

| Rule | Severity | Fix |
|------|----------|-----|
| no-try-catch | error | Use `Effect.tryPromise` or `Effect.gen` |
| require-effect-gen | warning | Use `Effect.gen(function* () { ... })` |
| require-tagged-error | error | Use `Data.TaggedError("Name")<{}>` |
| no-throw | error | Return `Effect.fail(error)` |
| no-process-env | error | Use Config service with Layer |

## Architecture Rules

| Rule | Severity | Fix |
|------|----------|-----|
| no-mock | error | Use Layer substitution |
| port-requires-adapter | warning | Create Live + Test layers |
| no-forbidden-import | error | See stack/forbidden.ts |

## Observability Rules

| Rule | Severity | Fix |
|------|----------|-----|
| no-console | error | Use `Effect.log`, `Effect.logError` |

## Rule Enforcement

Rules are enforced at multiple layers:

1. **Pre-tool-use hook**: Blocks writes with violations
2. **Pre-commit hook**: Runs AST-grep before commit
3. **CI pipeline**: Fails PRs with violations

To see all rules: `config/quality/src/rules/`
