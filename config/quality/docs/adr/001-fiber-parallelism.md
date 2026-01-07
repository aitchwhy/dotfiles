---
status: accepted
date: 2026-01-07
decision-makers: [hank]
consulted: []
informed: []
---

# Use Effect Fiber Parallelism for Guard Execution

## Context and Problem Statement

Guards enforce code quality before Claude Code writes files. How should multiple guards execute to maximize performance while collecting all violations?

## Decision Drivers

* Guards should execute as fast as possible
* Users need to see ALL violations, not just the first one
* Effect-TS is the standard for typed async operations
* Bun runtime supports efficient fiber scheduling

## Considered Options

* Sequential execution
* Race-to-first-block with `Effect.raceAll`
* Fiber parallelism with `Effect.all({ concurrency: 'unbounded' })`
* Worker threads

## Decision Outcome

Chosen option: "Fiber parallelism with Effect.all", because it provides true concurrency while collecting all results.

### Consequences

* Good, because ~4x faster than sequential execution
* Good, because all violations visible in single output
* Good, because clean separation (each guard is self-contained Effect)
* Bad, because order of errors is non-deterministic
* Bad, because slightly more memory (all fibers allocated upfront)

## Validation

```typescript
// Must use unbounded concurrency
Effect.all(checks, { concurrency: 'unbounded' })

// Must collect all results, not race
const errors = results.filter(r => r.blocked)
```

## More Information

* [Effect Concurrency Docs](https://effect.website/docs/concurrency)
* Related: [ADR-002](002-all-errors-collection.md)
