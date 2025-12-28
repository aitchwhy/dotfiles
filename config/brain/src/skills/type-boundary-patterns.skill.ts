import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const typeBoundaryPatternsSkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('type-boundary-patterns'),
    description:
      'Vendor type boundaries ($Infer, third-party APIs). Parse at boundary, never assert.',
    allowedTools: ['Read', 'Write', 'Edit'],
    tokenBudget: 1500,
  },
  sections: [
    {
      heading: 'Overview',
      content: `# Type Boundary Patterns`,
    },
    {
      heading: 'The Problem',
      content: `Vendors like BetterAuth provide \`$Infer\` types:

\`\`\`typescript
type Session = typeof auth.$Infer.Session;
\`\`\`

This gives compile-time shape. Runtime data is still UNTRUSTED until parsed.`,
    },
    {
      heading: 'The Lie',
      content: `\`\`\`typescript
// DANGEROUS
const session = await auth.api.getSession({ headers });
return session as AuthSession; // LIES TO COMPILER
\`\`\``,
    },
    {
      heading: 'The Solution',
      content: `\`\`\`typescript
import { Schema, Effect } from "effect";

// 1. Define Schema matching expected shape
// CRITICAL: Use DateFromSelf for vendor Date objects, Date for ISO strings
const AuthSessionSchema = Schema.Struct({
  session: Schema.Struct({
    id: Schema.String,
    userId: Schema.String,
    token: Schema.String,
    expiresAt: Schema.DateFromSelf, // Vendor returns Date, not string
  }),
  user: Schema.Struct({
    id: Schema.String,
    email: Schema.String,
    phoneNumber: Schema.optional(Schema.String),
  }),
});

// 2. Derive type FROM schema
type AuthSession = typeof AuthSessionSchema.Type;

// 3. Parse at boundary
const getSession = (header: string | undefined) =>
  Effect.gen(function* () {
    const raw = yield* betterAuthGetSession(header);
    if (!raw) return null;

    return yield* Schema.decodeUnknown(AuthSessionSchema)(raw).pipe(
      Effect.mapError((e) => new AuthError({ code: 'INTERNAL', message: String(e) }))
    );
  });
\`\`\``,
    },
    {
      heading: 'Schema.Date vs Schema.DateFromSelf',
      content: `| Schema Type | Input | Output | Use When |
|-------------|-------|--------|----------|
| \`Schema.Date\` | ISO string | Date object | API returns "2024-01-01T00:00:00Z" |
| \`Schema.DateFromSelf\` | Date object | Date object | Vendor returns actual Date |

BetterAuth, Drizzle ORM, and most Node libraries return actual Date objects.
Use \`Schema.DateFromSelf\` for these.`,
    },
    {
      heading: 'Key Principle',
      content: `| Source | Compile-Time | Runtime Safety |
|--------|--------------|----------------|
| \`$Infer\` | Yes | No |
| \`as Type\` | Yes (lie) | No |
| \`Schema.decodeUnknown\` | Yes | Yes |`,
    },
  ],
}
