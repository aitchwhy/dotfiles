/**
 * Hexagonal Architecture Skill
 *
 * Ports (Context.Tag) and Adapters (Layer) for testable code.
 */

import type { SkillDefinition } from '../schemas';
import { SkillName } from '../schemas';

export const hexagonalSkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('hexagonal'),
    description: 'Ports & Adapters with Effect Context.Tag and Layer',
    allowedTools: ['Read', 'Write', 'Edit', 'Grep'],
    tokenBudget: 400,
  },
  sections: [
    {
      heading: 'Core Concept',
      content: `
Hexagonal Architecture isolates business logic from infrastructure:

- **Port** = Context.Tag (interface definition)
- **Adapter** = Layer (implementation)
- Live adapters for production, Test adapters for tests
`,
    },
    {
      heading: 'Define a Port',
      content: `
\`\`\`typescript
import { Context, Effect } from "effect";

class UserRepository extends Context.Tag("UserRepository")<
  UserRepository,
  {
    readonly findById: (id: UserId) => Effect.Effect<User, UserNotFoundError>;
    readonly save: (user: User) => Effect.Effect<void, DatabaseError>;
  }
>() {}
\`\`\`
`,
    },
    {
      heading: 'Create Adapters',
      content: `
\`\`\`typescript
import { Layer } from "effect";

// Live adapter - real database
const UserRepositoryLive = Layer.effect(UserRepository,
  Effect.gen(function* () {
    const db = yield* Database;
    return {
      findById: (id) => db.query("SELECT * FROM users WHERE id = ?", [id]),
      save: (user) => db.execute("INSERT INTO users ...", [user]),
    };
  })
);

// Test adapter - in-memory
const UserRepositoryTest = Layer.succeed(UserRepository, {
  findById: () => Effect.succeed(testUser),
  save: () => Effect.succeed(undefined),
});
\`\`\`
`,
    },
    {
      heading: 'Testing Without Mocks',
      content: `
\`\`\`typescript
describe("createUser", () => {
  it("saves user", async () => {
    const TestLayer = Layer.mergeAll(UserRepositoryTest, ClockTest);

    const result = await Effect.runPromise(
      createUser({ name: "Test" }).pipe(Effect.provide(TestLayer))
    );

    expect(result.name).toBe("Test");
  });
});
\`\`\`

No mocks needed - swap layers for different behaviors.
`,
    },
  ],
};
