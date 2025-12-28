import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const effectResilienceSkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('effect-resilience'),
    description: 'Effect-TS patterns for retry, timeout, polling, and XState integration.',
    allowedTools: ['Read', 'Write', 'Edit', 'Grep', 'Glob'],
    tokenBudget: 400,
  },
  sections: [
    {
      heading: 'Overview',
      content: `# Effect Resilience Patterns

Retry, timeout, and polling using Effect primitives.`,
    },
    {
      heading: 'Effect.retry + Schedule',
      content: `\`\`\`typescript
import { Effect, Schedule } from 'effect';

// Exponential backoff with jitter
const policy = Schedule.exponential('100 millis').pipe(
  Schedule.jittered,
  Schedule.compose(Schedule.recurs(5))
);

const resilient = Effect.retry(fetchData, policy);
\`\`\``,
    },
    {
      heading: 'Effect.timeout',
      content: `\`\`\`typescript
// Timeout with typed error
const withTimeout = Effect.timeout(fetchData, '30 seconds');
// Returns Effect<A, E | TimeoutException, R>
\`\`\``,
    },
    {
      heading: 'Effect.repeat (Polling)',
      content: `\`\`\`typescript
// Poll every 5 seconds until condition
const poll = Effect.repeat(
  checkStatus,
  Schedule.spaced('5 seconds').pipe(
    Schedule.whileOutput((status) => status !== 'complete')
  )
);
\`\`\``,
    },
    {
      heading: 'XState v5 Integration',
      content: `Use \`fromPromise\` to wrap Effect programs:

\`\`\`typescript
import { fromPromise } from 'xstate';
import { Effect } from 'effect';

const fetchActor = fromPromise(async ({ input }: { input: { id: string } }) => {
  return Effect.runPromise(
    fetchUser(input.id).pipe(
      Effect.retry(Schedule.exponential('100 millis').pipe(Schedule.recurs(3))),
      Effect.timeout('30 seconds'),
      Effect.provide(HttpClientLive)
    )
  );
});
\`\`\``,
    },
    {
      heading: 'Anti-patterns',
      content: `\`\`\`typescript
// BAD - manual retry loop
let retries = 3;
while (retries > 0) { ... }

// BAD - setTimeout polling
setInterval(() => checkStatus(), 5000);

// GOOD - Effect primitives
Effect.retry(op, Schedule.exponential('100 millis'));
Effect.repeat(op, Schedule.spaced('5 seconds'));
\`\`\``,
    },
  ],
}
