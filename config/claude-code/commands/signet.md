# Signet (Code Quality & Generation Platform)

Guide me through using Signet to create formally consistent software systems.

## Available Commands

1. **Initialize a new project**:
   ```bash
   signet init <type> <name>
   ```
   Types: `monorepo`, `api`, `ui`, `library`, `infra`

2. **Generate a workspace in existing project**:
   ```bash
   signet gen <type> <name>
   ```

3. **Validate project structure**:
   ```bash
   signet validate [path]
   ```

4. **Run architecture enforcers**:
   ```bash
   signet enforce [--fix]
   ```

## Workflow

### Creating a New Platform

```bash
# Initialize monorepo
signet init monorepo ember-platform
cd ember-platform

# Add API service
signet gen api voice-service

# Add web frontend
signet gen ui web-app

# Add infrastructure
signet gen infra deployment

# Validate everything
signet validate
signet enforce
```

### Project Types

| Type | Description | Key Technologies |
|------|-------------|------------------|
| `monorepo` | Bun workspaces | Shared configs, TypeScript project refs |
| `api` | Hexagonal Hono API | Ports/Adapters, Effect Layers |
| `ui` | React 19 frontend | XState, TanStack Router |
| `library` | Standalone package | TypeScript, Biome |
| `infra` | Infrastructure | Pulumi, process-compose |

## What would you like to create?
