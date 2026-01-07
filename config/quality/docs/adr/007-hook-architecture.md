---
status: accepted
date: 2025-12-28
decision-makers: [hank]
consulted: []
informed: []
---

# Hook-Based Quality Enforcement Architecture

## Context and Problem Statement

How should quality rules be enforced when Claude Code writes files or executes commands?

## Decision Drivers

* Enforcement must happen before changes reach disk
* Must support multiple guard categories
* Must integrate with Claude Code's hook protocol
* Must be fast (runs on every tool use)

## Considered Options

* Post-commit hooks (too late)
* CI checks (too late)
* Pre-tool-use hooks (preventive)
* File watchers (reactive)

## Decision Outcome

Chosen option: "Pre-tool-use hooks", because they block violations before disk writes.

### Consequences

* Good, because violations never reach disk
* Good, because immediate feedback in Claude Code
* Good, because supports Write, Edit, and Bash tools
* Bad, because hook errors can block all operations
* Bad, because requires Claude Code hook support

## Validation

```typescript
// Hook input structure
type PreToolUseInput = {
  hook_event_name: 'PreToolUse'
  tool_name: 'Write' | 'Edit' | 'Bash' | ...
  tool_input: {
    file_path?: string
    content?: string
    command?: string
  }
}

// Hook output structure
type HookDecision =
  | { decision: 'approve' }
  | { decision: 'block', reason: string }
```

## More Information

* Entry point: `src/hooks/pre-tool-use.ts`
* Protocol: `src/hooks/lib/effect-hook.ts`
* Related: [ADR-001](001-fiber-parallelism.md)
