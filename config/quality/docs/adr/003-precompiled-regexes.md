---
status: accepted
date: 2026-01-07
decision-makers: [hank]
consulted: []
informed: []
---

# Pre-compile Regex Patterns at Module Scope

## Context and Problem Statement

Procedural guards use many regex patterns for file matching, commit parsing, and command extraction. Should patterns be defined inline or pre-compiled?

## Decision Drivers

* Performance: guards run on every tool use
* Maintainability: patterns should be easy to find and update
* Type safety: patterns should be grouped semantically

## Considered Options

* Inline patterns: `/pattern/.test(str)` in each function
* Pre-compiled at module scope with semantic grouping
* External pattern file (JSON/YAML)

## Decision Outcome

Chosen option: "Pre-compiled at module scope", because it combines performance with maintainability.

### Consequences

* Good, because patterns compiled once at module load
* Good, because semantic grouping (`FILE_EXT`, `GIT_COMMIT`, `CMD_PARSE`)
* Good, because TypeScript `as const` enables type-safe access
* Good, because ~10-20% faster for pattern-heavy guards
* Bad, because patterns less visible at point of use

### Confirmation

```typescript
// Patterns must be at module scope (top of file)
const FILE_EXT = { ... } as const
const GIT_COMMIT = { ... } as const
const CMD_PARSE = { ... } as const

// NOT inside functions
function check() {
  const pattern = /.../ // WRONG
}
```

Verify: `grep -n "^const.*= {$" src/hooks/lib/guards/procedural.ts`

## More Information

* Location: `src/hooks/lib/guards/procedural.ts` lines 1-30
* Pattern groups: `FILE_EXT` (5), `GIT_COMMIT` (4), `CMD_PARSE` (2)
