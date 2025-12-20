---
name: state-machine-patterns
description: XState v5 patterns for finite state machines, actors, and React integration.
allowed-tools: Read, Write, Edit
token-budget: 600
references:
  - references/machines.md: "Auth, recording, and form machine examples"
  - references/actors.md: "Promise, callback actors and testing"
  - references/react.md: "React hooks and provider patterns"
---

# State Machine Patterns (XState v5)

> Read specific reference files based on your task.

## When to Use State Machines

| Scenario | Use State Machine? |
|----------|-------------------|
| Simple boolean toggle | No - `useState` |
| Form with basic validation | Maybe - if multi-step |
| Auth flow (login/logout/refresh) | Yes |
| Recording/upload pipeline | Yes |
| Multi-step wizard | Yes |
| Complex modal with transitions | Yes |
| Simple data fetching | No - TanStack Query |
| Data with retries/cancellation | Consider |

## Core Pattern: setup + createMachine

Always use `setup()` for type-safe machines:

```typescript
import { setup, assign, createActor } from 'xstate';

// 1. Define types explicitly
type Context = {
  data: Data | null;
  error: string | null;
  retries: number;
};

type Events =
  | { type: 'FETCH' }
  | { type: 'SUCCESS'; data: Data }
  | { type: 'FAILURE'; error: string }
  | { type: 'RETRY' };

// 2. Setup with typed implementations
const machine = setup({
  types: {
    context: {} as Context,
    events: {} as Events,
  },
  actions: {
    setData: assign({
      data: ({ event }) => (event as { type: 'SUCCESS'; data: Data }).data,
      error: null,
    }),
    setError: assign({
      error: ({ event }) => (event as { type: 'FAILURE'; error: string }).error,
    }),
    incrementRetries: assign({
      retries: ({ context }) => context.retries + 1,
    }),
  },
  guards: {
    hasRetriesLeft: ({ context }) => context.retries < 3,
  },
}).createMachine({
  id: 'dataFetcher',
  initial: 'idle',
  context: { data: null, error: null, retries: 0 },

  states: {
    idle: {
      on: { FETCH: 'loading' },
    },
    loading: {
      on: {
        SUCCESS: { target: 'success', actions: 'setData' },
        FAILURE: [
          { guard: 'hasRetriesLeft', target: 'retrying', actions: 'setError' },
          { target: 'error', actions: 'setError' },
        ],
      },
    },
    retrying: {
      after: {
        1000: { target: 'loading', actions: 'incrementRetries' },
      },
    },
    success: {
      on: { FETCH: 'loading' },
    },
    error: {
      on: { RETRY: { target: 'loading', actions: assign({ retries: 0 }) } },
    },
  },
});
```

## Quick Reference

| Operation | Code |
|-----------|------|
| Create actor | `const actor = createActor(machine)` |
| Start actor | `actor.start()` |
| Send event | `actor.send({ type: 'EVENT', data })` |
| Get state | `actor.getSnapshot()` |
| Check state | `state.matches('loading')` |
| Get context | `state.context.data` |
| Subscribe | `actor.subscribe(callback)` |
| Stop actor | `actor.stop()` |

## When to Read Reference Files

| Task | Read |
|------|------|
| Auth, recording, form examples | `references/machines.md` |
| Promise/callback actors, testing | `references/actors.md` |
| React hooks, providers | `references/react.md` |

## Visualization

XState machines can be visualized at https://stately.ai/viz
