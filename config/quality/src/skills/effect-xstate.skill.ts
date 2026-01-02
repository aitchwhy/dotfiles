/**
 * Effect-XState Integration Skill
 *
 * Patterns for integrating Effect-TS with XState v5 state machines.
 * Guards 52-55: Effect-XState bridge patterns.
 */

import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const effectXstateSkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('effect-xstate'),
    description: 'Effect-TS + XState v5 integration patterns',
    allowedTools: ['Read', 'Write', 'Edit', 'Grep'],
    tokenBudget: 500,
  },
  sections: [
    {
      heading: 'BANNED Patterns (Guards 52-55)',
      content: `
## Guard 52: No Effect.runPromise().then/.catch

\`\`\`typescript
// BAD - loses typed errors
Effect.runPromise(myEffect)
  .then(result => send({ type: "SUCCESS", data: result }))
  .catch(err => send({ type: "ERROR", error: String(err) }))

// GOOD - preserves typed errors
const exit = await Effect.runPromiseExit(myEffect)
if (Exit.isSuccess(exit)) {
  send({ type: "SUCCESS", data: exit.value })
} else {
  send({ type: "ERROR", cause: exit.cause })
}
\`\`\`

## Guard 53: No useRef for Machine-Owned State

\`\`\`typescript
// BAD - split-brain state, XState can't track
const tokenRef = useRef<string | null>(null)
const [state, send] = useMachine(authMachine)

// GOOD - state in machine context
const authMachine = setup({
  types: { context: {} as { token: string | null } }
}).createMachine({
  context: { token: null },
  // token updated via assign() actions
})
\`\`\`

## Guard 54: No useEffect + Effect.runPromise

\`\`\`typescript
// BAD - bypasses XState's invoke system
useEffect(() => {
  Effect.runPromise(fetchUser(userId))
    .then(user => send({ type: "USER_LOADED", user }))
}, [userId])

// GOOD - use XState invoke with fromPromise
const fetchUserActor = fromPromise<User, { userId: string }>(
  async ({ input }) => {
    const exit = await Effect.runPromiseExit(fetchUser(input.userId))
    if (Exit.isFailure(exit)) throw exit.cause
    return exit.value
  }
)

// In machine:
invoke: {
  src: 'fetchUser',
  input: ({ context }) => ({ userId: context.userId }),
  onDone: { actions: assign({ user: ({ event }) => event.output }) },
  onError: { actions: assign({ error: ({ event }) => event.error }) },
}
\`\`\`

## Guard 55: No String(err) Error Conversion

\`\`\`typescript
// BAD - loses typed error information
.catch(err => setError(String(err)))
.catch(err => setError(err.message))

// GOOD - preserve Effect Cause types
if (Exit.isFailure(exit)) {
  const cause = exit.cause  // Cause<MyTypedError>
  // Can pattern match on cause type
}
\`\`\`
`,
    },
    {
      heading: 'Required Pattern: Effect-to-XState Bridge',
      content: `
## Actor Definition Pattern

\`\`\`typescript
import { fromPromise } from "xstate"
import { Effect, Exit } from "effect"

// Define typed actor that bridges Effect to XState
const myActor = fromPromise<OutputType, InputType>(async ({ input }) => {
  const exit = await Effect.runPromiseExit(myEffect(input))

  if (Exit.isFailure(exit)) {
    // Throw cause to trigger onError
    throw exit.cause
  }

  return exit.value
})
\`\`\`

## Machine Definition

\`\`\`typescript
const machine = setup({
  types: {
    context: {} as {
      result: OutputType | null
      error: Cause.Cause<MyError> | null
    },
    events: {} as { type: "FETCH" } | { type: "RETRY" },
  },
  actors: { myActor },
}).createMachine({
  id: "data-fetcher",
  initial: "idle",
  context: { result: null, error: null },
  states: {
    idle: {
      on: { FETCH: "loading" },
    },
    loading: {
      invoke: {
        src: "myActor",
        input: ({ context }) => ({ /* input from context */ }),
        onDone: {
          target: "success",
          actions: assign({ result: ({ event }) => event.output }),
        },
        onError: {
          target: "failure",
          actions: assign({ error: ({ event }) => event.error }),
        },
      },
    },
    success: { type: "final" },
    failure: {
      on: { RETRY: "loading" },
    },
  },
})
\`\`\`
`,
    },
    {
      heading: 'Why This Pattern',
      content: `
1. **Typed Errors Preserved**: Exit.isFailure gives you Cause<E>, not unknown
2. **XState Controls Flow**: All async through invoke, not imperative useEffect
3. **Single Source of Truth**: Context is the only state, no refs
4. **Serializable**: Machine state can be persisted/hydrated
5. **Testable**: Can mock actors without mocking frameworks
`,
    },
  ],
}
