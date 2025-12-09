---
name: signet-patterns
description: Patterns for using Signet to generate formally consistent software systems with hexagonal architecture.
allowed-tools: Read, Write, Edit, Bash
---

## When to Use This Skill

- Creating new projects with `signet init`
- Adding workspaces to existing monorepos with `signet gen`
- Understanding hexagonal architecture patterns
- Working with Effect-TS layers and ports/adapters

## Hexagonal Architecture (Ports and Adapters)

### Directory Structure

```
src/
├── ports/           # Interfaces (what the app needs)
│   └── database.ts  # Context.Tag<Database, DatabaseService>
├── adapters/        # Implementations (how it's provided)
│   ├── turso.ts     # Layer.succeed(Database, TursoService)
│   └── d1.ts        # Layer.succeed(Database, D1Service)
├── app/             # Business logic (depends on ports only)
│   └── service.ts   # Uses Database port, not adapters
└── routes/          # Entry points (wires everything)
    └── api.ts       # Provides adapters as layers
```

## Effect Layer Pattern

### Port and Adapter

```typescript
// Port (Interface)
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
)
```

## Generator Selection

| Need | Command | What You Get |
|------|---------|--------------|
| New platform | `signet init monorepo <name>` | Workspace + shared pkg |
| Backend API | `signet gen api <name>` | Hexagonal Hono |
| Frontend | `signet gen ui <name>` | React 19 + XState |
| Library | `signet gen library <name>` | TypeScript package |
| Deployment | `signet gen infra <name>` | Pulumi + process-compose |

## Anti-Patterns to Avoid

1. **App importing adapters directly** - Use ports
2. **Circular dependencies** - Extract shared code
3. **Mixed layer imports** - Follow layer ordering
4. **Skipping process-compose** - Always include for observability
5. **Manual project setup** - Use Signet generators

## Validation

### Always Validate

```bash
signet validate     # Check structure
signet enforce      # Check architecture
bun validate        # Typecheck + lint + test
```
