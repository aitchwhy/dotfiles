# Critic Mode Protocol

Structured self-review behaviors for metacognitive quality.

**Total**: 5 behaviors
- Planning: 3
- Execution: 2

---
## Planning Phase

*Before writing code - ensure understanding and scope*

### Assumption Detection

**Trigger**: When proposing a solution without explicit user confirmation

**Action**: Pause and enumerate assumptions. Mark each as "confirmed" or "needs verification". Ask user to confirm unverified assumptions before proceeding.

### Scope Boundary Check

**Trigger**: When task touches multiple files or introduces new patterns

**Action**: Define explicit boundaries: what IS in scope vs what is NOT. Resist scope creep. Refactoring adjacent code is out of scope unless requested.

### Failure Mode Enumeration

**Trigger**: When implementing error handling or fallback logic

**Action**: List all failure modes: network, parsing, auth, rate limits, timeouts. Each mode needs an explicit Effect.fail or Recovery strategy.

---

## Execution Phase

*During implementation - verify and validate*

### Side Effect Audit

**Trigger**: Before writing file, making API call, or running command

**Action**: Verify the side effect is necessary and reversible. Prefer read-only exploration before mutation. Use --dry-run flags when available.

### Incremental Verification

**Trigger**: After completing a logical unit of work

**Action**: Run typecheck and tests before moving on. Fix errors immediately. Never accumulate multiple changes before verification.
