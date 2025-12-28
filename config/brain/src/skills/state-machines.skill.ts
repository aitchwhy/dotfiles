/**
 * State Machines Skill
 *
 * XState v5 patterns for complex UI state.
 */

import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const stateMachinesSkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('state-machines'),
    description: 'XState v5 for explicit state management in React',
    allowedTools: ['Read', 'Write', 'Edit', 'Grep'],
    tokenBudget: 400,
  },
  sections: [
    {
      heading: 'When to Use State Machines',
      content: `
Use XState when state has:
- Multiple discrete states (idle, loading, error, success)
- Complex transitions (can only go loading→success, not idle→success)
- Side effects tied to state changes
- UI that depends heavily on state

DON'T use for simple boolean flags or lists.
`,
    },
    {
      heading: 'Define Machine',
      content: `
\`\`\`typescript
import { setup, assign } from "xstate";

const orderMachine = setup({
  types: {
    context: {} as { orderId: string; error?: string },
    events: {} as
      | { type: "SUBMIT" }
      | { type: "SUCCESS"; orderId: string }
      | { type: "FAILURE"; error: string },
  },
}).createMachine({
  id: "order",
  initial: "idle",
  states: {
    idle: { on: { SUBMIT: "submitting" } },
    submitting: {
      invoke: { src: "submitOrder", onDone: "success", onError: "failure" },
    },
    success: { type: "final" },
    failure: { on: { SUBMIT: "submitting" } },
  },
});
\`\`\`
`,
    },
    {
      heading: 'React Integration',
      content: `
\`\`\`typescript
import { useMachine } from "@xstate/react";

function OrderForm() {
  const [state, send] = useMachine(orderMachine);

  if (state.matches("submitting")) return <Spinner />;
  if (state.matches("success")) return <Success orderId={state.context.orderId} />;
  if (state.matches("failure")) return <Error message={state.context.error} />;

  return <Button onClick={() => send({ type: "SUBMIT" })}>Order</Button>;
}
\`\`\`
`,
    },
    {
      heading: 'Actors for Complex Flows',
      content: `
\`\`\`typescript
const parentMachine = setup({
  actors: { orderMachine },
}).createMachine({
  invoke: {
    id: "order",
    src: "orderMachine",
    onDone: "complete",
  },
});
\`\`\`

Actors allow composing machines for multi-step workflows.
`,
    },
  ],
}
