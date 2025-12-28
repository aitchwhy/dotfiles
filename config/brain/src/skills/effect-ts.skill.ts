/**
 * Effect-TS Skill
 *
 * Core patterns for typed effects, errors, and dependencies.
 */

import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const effectTsSkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('effect-ts'),
    description: 'Effect-TS patterns for typed effects, errors, and dependencies',
    allowedTools: ['Read', 'Write', 'Edit', 'Grep'],
    tokenBudget: 500,
  },
  sections: [
    {
      heading: 'Core Concept: Effect<A, E, R>',
      content: `
Effect<Success, Error, Requirements>
       ↓        ↓           ↓
    "Returns" "Can fail"  "Needs these services"

The type parameters tell you everything:
- A: What you get on success
- E: What errors can occur (typed!)
- R: What services are required
`,
    },
    {
      heading: 'Generator Syntax (Preferred)',
      content: `
\`\`\`typescript
import { Effect } from "effect";

const program = Effect.gen(function* () {
  const config = yield* getConfig();
  const db = yield* connectDatabase(config.dbUrl);
  const users = yield* db.query("SELECT * FROM users");
  return users;
});
// Type: Effect<User[], ConfigError | DbError, ConfigService>
\`\`\`
`,
    },
    {
      heading: 'Service Pattern',
      content: `
\`\`\`typescript
import { Context, Effect, Layer } from "effect";

// 1. Define port with Context.Tag
class HttpClient extends Context.Tag("HttpClient")<
  HttpClient,
  { readonly get: (url: string) => Effect.Effect<Response, HttpError> }
>() {}

// 2. Use in effects (tracked in R)
const fetchUsers = Effect.gen(function* () {
  const http = yield* HttpClient;
  return yield* http.get("/api/users");
});
// Type: Effect<Response, HttpError, HttpClient>

// 3. Provide layer
const HttpClientLive = Layer.succeed(HttpClient, { get: ... });
const program = fetchUsers.pipe(Effect.provide(HttpClientLive));
\`\`\`
`,
    },
    {
      heading: 'Typed Errors',
      content: `
\`\`\`typescript
import { Data, Effect } from "effect";

class UserNotFoundError extends Data.TaggedError("UserNotFoundError")<{
  readonly userId: string;
}> {}

const getUser = (id: string) => Effect.gen(function* () {
  const user = yield* findUser(id);
  if (!user) return yield* Effect.fail(new UserNotFoundError({ userId: id }));
  return user;
});

// Catch by tag
getUser("123").pipe(
  Effect.catchTag("UserNotFoundError", (e) => Effect.succeed(guestUser))
);
\`\`\`
`,
    },
    {
      heading: 'Anti-Patterns (BANNED)',
      content: `
- **throw** → Use Effect.fail(error)
- **try/catch** → Use Effect.tryPromise or Effect.gen
- **Promise** → Use Effect
- **console.log** → Use Effect.log
- **new Date()** → Use Clock service
`,
    },
  ],
}
