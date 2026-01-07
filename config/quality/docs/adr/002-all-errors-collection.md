---
status: accepted
date: 2026-01-07
decision-makers: [hank]
consulted: []
informed: []
---

# Collect All Guard Errors, Not Fail-Fast

## Context and Problem Statement

When multiple guards fail, should the hook stop at the first violation (fail-fast) or collect and display all violations?

## Decision Drivers

* Developer productivity: fix multiple issues per iteration
* Clear feedback: understand full scope of violations
* Faster convergence: fewer edit-check-fix cycles

## Considered Options

* Fail-fast: stop at first violation
* Collect all: run all guards, aggregate errors
* Tiered: fail-fast for blockers, collect for warnings

## Decision Outcome

Chosen option: "Collect all", because showing all violations enables fixing multiple issues per iteration.

### Consequences

* Good, because users fix multiple issues per iteration
* Good, because faster feedback loop overall
* Good, because clear count header shows scope
* Bad, because longer error output when many violations
* Bad, because user must read entire output

### Confirmation

```typescript
// AggregatedGuardResult must contain array of errors
type AggregatedGuardResult = {
  readonly errors: readonly GuardCheckResult[]
  readonly warnings: readonly string[]
}

// Output format must show count
`━━━ ${n} guard violation${n > 1 ? 's' : ''} ━━━`
```

Test: Trigger 2+ violations and verify both appear in output.

## More Information

* Implementation: `src/hooks/lib/effect-hook.ts:formatAggregatedErrors()`
* Related: [ADR-001](001-fiber-parallelism.md)
