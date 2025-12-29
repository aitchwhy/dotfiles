import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const effectClockPatternsSkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('effect-clock-patterns'),
    description: 'Effect Clock for injectable, testable time. Never use new Date() directly.',
    allowedTools: ['Read', 'Write', 'Edit'],
    tokenBudget: 800,
  },
  sections: [
    {
      heading: 'Overview',
      content: `# Effect Clock Patterns`,
    },
    {
      heading: 'Why Not new Date()?',
      content: `\`\`\`typescript
// UNTESTABLE
const createdAt = new Date();
\`\`\``,
    },
    {
      heading: 'Clock Service',
      content: `\`\`\`typescript
import { Clock, Effect } from "effect";

// Helper (put in lib/clock.ts)
export const currentTimestamp = Effect.map(
  Clock.currentTimeMillis,
  (ms) => new Date(ms)
);

// Usage
const program = Effect.gen(function* () {
  const now = yield* currentTimestamp;
  yield* db.update(records).set({ updatedAt: now });
});
\`\`\``,
    },
    {
      heading: 'Testing',
      content: `\`\`\`typescript
import { TestClock, Effect } from "effect";

const test = Effect.gen(function* () {
  yield* TestClock.setTime(new Date("2024-06-15").getTime());
  const result = yield* myTimeDependentCode;
  yield* TestClock.adjust("1 hour");
});

Effect.runPromise(test.pipe(Effect.provide(TestClock.layer)));
\`\`\``,
    },
    {
      heading: 'Migration',
      content: `| Before | After |
|--------|-------|
| \`new Date()\` | \`yield* currentTimestamp\` |
| \`Date.now()\` | \`yield* Clock.currentTimeMillis\` |`,
    },
  ],
}
