# XState Machine Examples

## Auth Flow Machine

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

## Recording Session Machine

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
    saved: { type: 'final' },
    error: {
      on: {
        RETRY: 'connecting',
        DISCARD: 'idle',
      },
    },
  },
});
```

## Multi-Step Form Machine

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
    success: { type: 'final' },
  },
});
```
