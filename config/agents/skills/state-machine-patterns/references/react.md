# XState React Integration

## useMachine Hook

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

## useActor for Global Actors

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

## useSelector for Derived State

```typescript
import { useSelector } from '@xstate/react';

function UserStatus() {
  const isLoggedIn = useSelector(globalActor, (state) => state.matches('authenticated'));
  const userName = useSelector(globalActor, (state) => state.context.user?.name);

  return isLoggedIn ? <span>Hello, {userName}</span> : <LoginButton />;
}
```

## State Machine Provider Pattern

```typescript
import { createActorContext } from '@xstate/react';

const AuthMachineContext = createActorContext(authMachine);

function App() {
  return (
    <AuthMachineContext.Provider>
      <AuthenticatedApp />
    </AuthMachineContext.Provider>
  );
}

function UserProfile() {
  const [state, send] = AuthMachineContext.useActor();
  const isAuthenticated = AuthMachineContext.useSelector(
    (state) => state.matches('authenticated')
  );

  if (!isAuthenticated) return <Redirect to="/login" />;

  return <Profile user={state.context.user} />;
}
```

## Anti-Patterns

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
