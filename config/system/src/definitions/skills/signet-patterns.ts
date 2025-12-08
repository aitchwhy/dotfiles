/**
 * Factory Patterns Skill Definition
 *
 * Universal Project Factory (FCS) patterns.
 * Migrated from: config/claude-code/skills/factory-patterns/SKILL.md
 */
import type { SystemSkill } from '@/schema'

export const factoryPatternsSkill: SystemSkill = {
  name: 'factory-patterns' as SystemSkill['name'],
  description:
    'Patterns for using the Universal Project Factory (FCS) to generate formally consistent software systems with hexagonal architecture.',
  allowedTools: ['Read', 'Write', 'Edit', 'Bash'] as SystemSkill['allowedTools'],

  sections: [
    {
      title: 'When to Use This Skill',
      content: `- Creating new projects with \`fcs init\`
- Adding workspaces to existing monorepos with \`fcs gen\`
- Understanding hexagonal architecture patterns
- Working with Effect-TS layers and ports/adapters`,
    },
    {
      title: 'Hexagonal Architecture (Ports and Adapters)',
      patterns: [
        {
          title: 'Directory Structure',
          annotation: 'do',
          language: 'text',
          code: `src/
├── ports/           # Interfaces (what the app needs)
│   └── database.ts  # Context.Tag<Database, DatabaseService>
├── adapters/        # Implementations (how it's provided)
│   ├── turso.ts     # Layer.succeed(Database, TursoService)
│   └── d1.ts        # Layer.succeed(Database, D1Service)
├── app/             # Business logic (depends on ports only)
│   └── service.ts   # Uses Database port, not adapters
└── routes/          # Entry points (wires everything)
    └── api.ts       # Provides adapters as layers`,
        },
      ],
    },
    {
      title: 'Effect Layer Pattern',
      patterns: [
        {
          title: 'Port and Adapter',
          annotation: 'do',
          language: 'typescript',
          code: `// Port (Interface)
export class Database extends Context.Tag('Database')<
  Database,
  DatabaseService
>() {}

// Adapter (Implementation)
const makeService = (client: LibsqlClient): DatabaseService => ({
  query: (sql) => Effect.tryPromise(() => client.execute(sql)),
})

export const TursoLive = (url: string, token: string) =>
  Layer.succeed(Database, makeService(createClient({ url, authToken: token })))

// Usage - inject adapter at composition root
const program = myBusinessLogic.pipe(
  Effect.provide(TursoLive(process.env.DATABASE_URL, process.env.DATABASE_TOKEN))
)`,
        },
      ],
    },
    {
      title: 'Generator Selection',
      content: `| Need | Command | What You Get |
|------|---------|--------------|
| New platform | \`fcs init monorepo <name>\` | Workspace + shared pkg |
| Backend API | \`fcs gen api <name>\` | Hexagonal Hono |
| Frontend | \`fcs gen ui <name>\` | React 19 + XState |
| Library | \`fcs gen library <name>\` | TypeScript package |
| Deployment | \`fcs gen infra <name>\` | Pulumi + process-compose |`,
    },
    {
      title: 'Anti-Patterns to Avoid',
      content: `1. **App importing adapters directly** - Use ports
2. **Circular dependencies** - Extract shared code
3. **Mixed layer imports** - Follow layer ordering
4. **Skipping process-compose** - Always include for observability
5. **Manual project setup** - Use FCS generators`,
    },
    {
      title: 'Validation',
      patterns: [
        {
          title: 'Always Validate',
          annotation: 'info',
          language: 'bash',
          code: `fcs validate     # Check structure
fcs enforce      # Check architecture
bun validate     # Typecheck + lint + test`,
        },
      ],
    },
  ],
}
