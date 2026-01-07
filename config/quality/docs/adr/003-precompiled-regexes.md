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

## Validation

```typescript
// Patterns must be at module scope, not inside functions
const FILE_EXT = {
  typescript: /\.(ts|tsx|js|jsx|mjs|cjs)$/,
  // ...
} as const

// Usage in guard
if (FILE_EXT.typescript.test(filePath)) { ... }
```

## More Information

* Location: `src/hooks/lib/guards/procedural.ts`
