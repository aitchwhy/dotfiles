# Factory Patterns Skill

Patterns for using the Universal Project Factory (FCS) to generate formally consistent software systems.

## When to Use This Skill

- Creating new projects with `fcs init`
- Adding workspaces to existing monorepos with `fcs gen`
- Understanding hexagonal architecture patterns
- Working with Effect-TS layers and ports/adapters

## Core Patterns

### 1. Hexagonal Architecture (Ports and Adapters)

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

**Key Rule**: Ports define interfaces. Adapters implement them. App uses ports only.

### 2. Effect Layer Pattern

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

### 3. ProjectSpec Schema

All generated projects follow the ProjectSpec schema:

```typescript
type ProjectSpec = {
  name: string              // kebab-case project name
  type: 'monorepo' | 'api' | 'ui' | 'library' | 'infra'
  infra: {
    runtime: 'bun' | 'node'
    database?: 'turso' | 'd1' | 'neon'
    queue?: 'temporal' | 'sqs'
  }
  observability: {
    processCompose: true    // Always required
    metrics: boolean
    debugger: 'vscode' | 'nvim-dap'
  }
}
```

### 4. Monorepo Structure

```
platform/
├── apps/                 # Deployable applications
│   ├── api/              # fcs gen api <name>
│   └── web/              # fcs gen ui <name>
├── packages/             # Shared packages
│   └── shared/           # @platform/shared
├── package.json          # Bun workspaces
├── tsconfig.json         # Project references
├── tsconfig.base.json    # Shared compiler options
├── biome.json            # Linting/formatting
└── process-compose.yaml  # Local development
```

### 5. Generator Selection

| Need | Command | What You Get |
|------|---------|--------------|
| New platform | `fcs init monorepo <name>` | Workspace + shared pkg |
| Backend API | `fcs gen api <name>` | Hexagonal Hono |
| Frontend | `fcs gen ui <name>` | React 19 + XState |
| Library | `fcs gen library <name>` | TypeScript package |
| Deployment | `fcs gen infra <name>` | Pulumi + process-compose |

## Anti-Patterns to Avoid

1. **App importing adapters directly** - Use ports
2. **Circular dependencies** - Extract shared code
3. **Mixed layer imports** - Follow layer ordering
4. **Skipping process-compose** - Always include for observability
5. **Manual project setup** - Use FCS generators

## Validation

Always run after making changes:

```bash
fcs validate     # Check structure
fcs enforce      # Check architecture
bun validate     # Typecheck + lint + test
```
