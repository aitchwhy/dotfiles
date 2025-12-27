/**
 * Parse Boundary Skill
 *
 * Schema.decodeUnknown at system edges.
 */

import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const parseBoundarySkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('parse-boundary'),
    description: 'Parse external data at boundaries, trust internal types',
    allowedTools: ['Read', 'Write', 'Edit', 'Grep'],
    tokenBudget: 300,
  },
  sections: [
    {
      heading: 'The Principle',
      content: `
**Parse, don't validate.**

External data (API requests, file reads, env vars) is \`unknown\`.
Parse it ONCE at the boundary into typed data.
Internal code trusts the types completely.
`,
    },
    {
      heading: 'Boundary Examples',
      content: `
\`\`\`typescript
// HTTP request boundary
const handleRequest = (req: Request) =>
  Effect.gen(function* () {
    const body = yield* Effect.tryPromise(() => req.json());
    const data = yield* Schema.decodeUnknown(CreateUserSchema)(body);
    return yield* createUser(data); // data is typed
  });

// Environment boundary
const Config = Effect.gen(function* () {
  const raw = { apiKey: process.env.API_KEY, port: process.env.PORT };
  return yield* Schema.decodeUnknown(ConfigSchema)(raw);
});

// File read boundary
const loadConfig = (path: string) =>
  Effect.gen(function* () {
    const content = yield* readFile(path);
    const json = yield* Effect.try(() => JSON.parse(content));
    return yield* Schema.decodeUnknown(ConfigSchema)(json);
  });
\`\`\`
`,
    },
    {
      heading: 'Internal Code',
      content: `
\`\`\`typescript
// Internal function - trusts types, no parsing
const createUser = (data: CreateUserData) =>
  Effect.gen(function* () {
    const repo = yield* UserRepository;
    const id = yield* generateId();
    return yield* repo.save({ ...data, id });
  });
\`\`\`

No Schema.decode inside business logic - types are trusted.
`,
    },
  ],
}
