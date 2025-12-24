/**
 * API Contract Skill
 *
 * HttpApiBuilder for typed HTTP endpoints.
 */

import type { SkillDefinition } from '../schemas';
import { SkillName } from '../schemas';

export const apiContractSkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('api-contract'),
    description: 'Typed HTTP APIs with @effect/platform HttpApiBuilder',
    allowedTools: ['Read', 'Write', 'Edit', 'Grep'],
    tokenBudget: 450,
  },
  sections: [
    {
      heading: 'Why HttpApiBuilder',
      content: `
- Type-safe request/response schemas
- Automatic client generation
- Built-in error handling
- OpenAPI spec generation
- NO framework lock-in (no Hono, Express)
`,
    },
    {
      heading: 'Define API Contract',
      content: `
\`\`\`typescript
import { HttpApi, HttpApiEndpoint, HttpApiGroup } from "@effect/platform";
import { Schema } from "effect";

const UserSchema = Schema.Struct({
  id: Schema.String,
  name: Schema.String,
  email: Schema.String,
});

class UsersApi extends HttpApiGroup.make("users")
  .add(
    HttpApiEndpoint.get("getUser", "/users/:id")
      .setPath(Schema.Struct({ id: Schema.String }))
      .addSuccess(UserSchema)
  )
  .add(
    HttpApiEndpoint.post("createUser", "/users")
      .setPayload(Schema.Struct({ name: Schema.String, email: Schema.String }))
      .addSuccess(UserSchema)
  ) {}

class MyApi extends HttpApi.empty.add(UsersApi) {}
\`\`\`
`,
    },
    {
      heading: 'Implement Handlers',
      content: `
\`\`\`typescript
import { HttpApiBuilder } from "@effect/platform";

const UsersApiLive = HttpApiBuilder.group(MyApi, "users", (handlers) =>
  handlers
    .handle("getUser", ({ path }) =>
      Effect.gen(function* () {
        const repo = yield* UserRepository;
        return yield* repo.findById(path.id);
      })
    )
    .handle("createUser", ({ payload }) =>
      Effect.gen(function* () {
        const repo = yield* UserRepository;
        return yield* repo.create(payload);
      })
    )
);
\`\`\`
`,
    },
    {
      heading: 'Generate Client',
      content: `
\`\`\`typescript
import { HttpApiClient } from "@effect/platform";

// Type-safe client from API definition
const client = HttpApiClient.make(MyApi, {
  baseUrl: "https://api.example.com",
});

// Usage
const user = yield* client.users.getUser({ path: { id: "123" } });
\`\`\`
`,
    },
  ],
};
