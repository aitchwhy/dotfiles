# Factory Code System (FCS)

Guide me through using the Universal Project Factory.

## Available Commands

1. **Initialize a new project**:
   ```bash
   fcs init <type> <name>
   ```
   Types: `monorepo`, `api`, `ui`, `library`, `infra`

2. **Generate a workspace in existing project**:
   ```bash
   fcs gen <type> <name>
   ```

3. **Validate project structure**:
   ```bash
   fcs validate [path]
   ```

4. **Run architecture enforcers**:
   ```bash
   fcs enforce [--fix]
   ```

## Workflow

### Creating a New Platform

```bash
# Initialize monorepo
fcs init monorepo ember-platform
cd ember-platform

# Add API service
fcs gen api voice-service

# Add web frontend
fcs gen ui web-app

# Add infrastructure
fcs gen infra deployment

# Validate everything
fcs validate
fcs enforce
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
