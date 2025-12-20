# XState Invoked Actors (Services)

## Promise Actor

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

## Callback Actor (Subscriptions)

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

## Observable Actor

```typescript
import { fromObservable } from 'xstate';
import { interval } from 'rxjs';
import { map } from 'rxjs/operators';

const machine = setup({
  actors: {
    ticker: fromObservable(() =>
      interval(1000).pipe(
        map((count) => ({ type: 'TICK', count }))
      )
    ),
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

## Effect-TS Integration

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
