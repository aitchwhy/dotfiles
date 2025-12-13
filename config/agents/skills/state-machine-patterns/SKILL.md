---
name: state-machine-patterns
description: XState v5 patterns for finite state machines, actors, and React integration.
allowed-tools: Read, Write, Edit
token-budget: 2000
---

# State Machine Patterns (XState v5)

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

## React Integration

### useMachine Hook

```typescript
import { useMachine } from '@xstate/react';

function DataComponent() {
  const [state, send] = useMachine(machine);

  return (
    <div>
      {state.matches('loading') && <Spinner />}
      {state.matches('error') && (
        <ErrorBanner
          message={state.context.error}
          onRetry={() => send({ type: 'RETRY' })}
        />
      )}
      {state.matches('success') && <DataView data={state.context.data} />}

      <button
        onClick={() => send({ type: 'FETCH' })}
        disabled={state.matches('loading')}
      >
        {state.matches('loading') ? 'Loading...' : 'Fetch'}
      </button>
    </div>
  );
}
```

### useActor for Global Actors

```typescript
import { createActor } from 'xstate';
import { useActor } from '@xstate/react';

// Create actor outside component (singleton)
const globalActor = createActor(machine);
globalActor.start();

function Component() {
  const [state, send] = useActor(globalActor);
  // ...
}
```

## Common Machine Patterns

### Auth Flow Machine

```typescript
type AuthContext = {
  user: User | null;
  error: string | null;
};

type AuthEvents =
  | { type: 'LOGIN'; credentials: Credentials }
  | { type: 'LOGOUT' }
  | { type: 'REFRESH' }
  | { type: 'SESSION_EXPIRED' };

const authMachine = setup({
  types: {
    context: {} as AuthContext,
    events: {} as AuthEvents,
  },
}).createMachine({
  id: 'auth',
  initial: 'unauthenticated',
  context: { user: null, error: null },

  states: {
    unauthenticated: {
      on: { LOGIN: 'authenticating' },
    },
    authenticating: {
      invoke: {
        src: 'loginService',
        onDone: { target: 'authenticated', actions: 'setUser' },
        onError: { target: 'unauthenticated', actions: 'setError' },
      },
    },
    authenticated: {
      on: {
        LOGOUT: { target: 'unauthenticated', actions: 'clearUser' },
        SESSION_EXPIRED: 'refreshing',
      },
    },
    refreshing: {
      invoke: {
        src: 'refreshService',
        onDone: 'authenticated',
        onError: { target: 'unauthenticated', actions: 'clearUser' },
      },
    },
  },
});
```

### Recording Session Machine

```typescript
type RecordingContext = {
  sessionId: string | null;
  audioUrl: string | null;
  duration: number;
  error: string | null;
};

type RecordingEvents =
  | { type: 'START' }
  | { type: 'STOP' }
  | { type: 'PAUSE' }
  | { type: 'RESUME' }
  | { type: 'DISCARD' }
  | { type: 'SAVE' }
  | { type: 'TICK' };

const recordingMachine = setup({
  types: {
    context: {} as RecordingContext,
    events: {} as RecordingEvents,
  },
}).createMachine({
  id: 'recording',
  initial: 'idle',
  context: { sessionId: null, audioUrl: null, duration: 0, error: null },

  states: {
    idle: {
      entry: assign({ duration: 0, audioUrl: null }),
      on: { START: 'connecting' },
    },
    connecting: {
      invoke: {
        src: 'connectService',
        onDone: { target: 'recording', actions: 'setSessionId' },
        onError: { target: 'error', actions: 'setError' },
      },
    },
    recording: {
      invoke: { src: 'timerService' },
      on: {
        TICK: { actions: assign({ duration: ({ context }) => context.duration + 1 }) },
        PAUSE: 'paused',
        STOP: 'processing',
        DISCARD: 'idle',
      },
    },
    paused: {
      on: {
        RESUME: 'recording',
        STOP: 'processing',
        DISCARD: 'idle',
      },
    },
    processing: {
      invoke: {
        src: 'uploadService',
        onDone: { target: 'complete', actions: 'setAudioUrl' },
        onError: { target: 'error', actions: 'setError' },
      },
    },
    complete: {
      on: {
        SAVE: 'saving',
        DISCARD: 'idle',
      },
    },
    saving: {
      invoke: {
        src: 'saveService',
        onDone: 'saved',
        onError: { target: 'error', actions: 'setError' },
      },
    },
    saved: {
      type: 'final',
    },
    error: {
      on: {
        RETRY: 'connecting',
        DISCARD: 'idle',
      },
    },
  },
});
```

### Multi-Step Form Machine

```typescript
type FormContext = {
  step1Data: Step1Data | null;
  step2Data: Step2Data | null;
  step3Data: Step3Data | null;
};

type FormEvents =
  | { type: 'NEXT'; data: unknown }
  | { type: 'BACK' }
  | { type: 'SUBMIT' };

const formMachine = setup({
  types: {
    context: {} as FormContext,
    events: {} as FormEvents,
  },
}).createMachine({
  id: 'multiStepForm',
  initial: 'step1',
  context: { step1Data: null, step2Data: null, step3Data: null },

  states: {
    step1: {
      on: {
        NEXT: {
          target: 'step2',
          actions: assign({ step1Data: ({ event }) => event.data as Step1Data }),
        },
      },
    },
    step2: {
      on: {
        NEXT: {
          target: 'step3',
          actions: assign({ step2Data: ({ event }) => event.data as Step2Data }),
        },
        BACK: 'step1',
      },
    },
    step3: {
      on: {
        NEXT: {
          target: 'submitting',
          actions: assign({ step3Data: ({ event }) => event.data as Step3Data }),
        },
        BACK: 'step2',
      },
    },
    submitting: {
      invoke: {
        src: 'submitService',
        onDone: 'success',
        onError: 'step3',
      },
    },
    success: {
      type: 'final',
    },
  },
});
```

## Invoked Actors (Services)

### Promise Actor

```typescript
import { fromPromise } from 'xstate';

const machine = setup({
  actors: {
    fetchUser: fromPromise(async ({ input }: { input: { userId: string } }) => {
      const response = await fetch(`/api/users/${input.userId}`);
      if (!response.ok) throw new Error('Failed to fetch');
      return response.json();
    }),
  },
}).createMachine({
  // ...
  states: {
    loading: {
      invoke: {
        src: 'fetchUser',
        input: ({ context }) => ({ userId: context.userId }),
        onDone: { target: 'success', actions: assign({ user: ({ event }) => event.output }) },
        onError: { target: 'error' },
      },
    },
  },
});
```

### Callback Actor (Subscriptions)

```typescript
import { fromCallback } from 'xstate';

const machine = setup({
  actors: {
    timerService: fromCallback(({ sendBack }) => {
      const interval = setInterval(() => {
        sendBack({ type: 'TICK' });
      }, 1000);

      return () => clearInterval(interval);
    }),
  },
}).createMachine({
  // ...
});
```

## Testing State Machines

```typescript
import { createActor } from 'xstate';
import { describe, it, expect } from 'bun:test';

describe('authMachine', () => {
  it('transitions from unauthenticated to authenticating on LOGIN', () => {
    const actor = createActor(authMachine);
    actor.start();

    expect(actor.getSnapshot().value).toBe('unauthenticated');

    actor.send({ type: 'LOGIN', credentials: { email: 'test@example.com', password: 'secret' } });

    expect(actor.getSnapshot().value).toBe('authenticating');
  });

  it('stores user in context on successful auth', async () => {
    const actor = createActor(authMachine);
    actor.start();

    actor.send({ type: 'LOGIN', credentials: mockCredentials });

    // Wait for async transition
    await new Promise(resolve => {
      actor.subscribe(state => {
        if (state.matches('authenticated')) resolve(undefined);
      });
    });

    expect(actor.getSnapshot().context.user).toBeDefined();
  });
});
```

## Visualization

XState machines can be visualized at https://stately.ai/viz

Import your machine definition to:
- See state graph
- Simulate transitions
- Export diagrams

## Anti-Patterns

### Avoid

```typescript
// DON'T: Inline complex logic
on: {
  SUBMIT: {
    target: 'submitting',
    actions: ({ context }) => {
      // Complex validation logic here
      // This should be in a guard or separate action
    }
  }
}

// DON'T: Use string events without types
actor.send('SUBMIT'); // No type safety

// DON'T: Mutate context directly
actions: assign({
  items: ({ context }) => {
    context.items.push(newItem); // Mutation!
    return context.items;
  }
})
```

### Prefer

```typescript
// DO: Use typed events
actor.send({ type: 'SUBMIT', data: formData });

// DO: Return new values from assign
actions: assign({
  items: ({ context }) => [...context.items, newItem]
})

// DO: Use guards for validation
guards: {
  isValidForm: ({ context }) => validateForm(context.formData).ok
},
states: {
  form: {
    on: {
      SUBMIT: { guard: 'isValidForm', target: 'submitting' }
    }
  }
}
```

## Integration with Effect-TS

For server-side state machines with typed errors:

```typescript
import { Effect } from 'effect';
import { createActor } from 'xstate';

const runMachineEffect = <T>(
  machine: AnyMachine,
  finalState: string
): Effect.Effect<T, MachineError> =>
  Effect.async((resume) => {
    const actor = createActor(machine);

    actor.subscribe((state) => {
      if (state.matches(finalState)) {
        resume(Effect.succeed(state.context as T));
      }
      if (state.matches('error')) {
        resume(Effect.fail(new MachineError(state.context.error)));
      }
    });

    actor.start();

    return Effect.sync(() => actor.stop());
  });
```
