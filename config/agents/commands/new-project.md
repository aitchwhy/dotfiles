---
description: Create a new TypeScript/Bun project from template
---

# New TypeScript/Bun Project

Create a project using Signet, the Single Source of Truth for project generation.

## Quick Start

```bash
# Initialize a standalone library/service
signet init library my-project
cd ~/src/my-project

# Or initialize a monorepo platform
signet init monorepo my-platform
```

## Project Types

| Type | Use Case |
|------|----------|
| `library` | Standalone TypeScript package |
| `api` | Hexagonal Hono backend (Ports/Adapters, Effect Layers) |
| `ui` | React 19 frontend (XState, TanStack Router) |
| `monorepo` | Multi-package workspace (Bun workspaces) |
| `infra` | Infrastructure (Pulumi, process-compose) |

## Adding to Existing Projects

```bash
cd my-platform
signet gen api voice-service
signet gen ui web-app
```

## Verification

```bash
signet validate       # Check project structure
signet enforce --fix  # Run architecture enforcers
bun validate          # typecheck + lint + test
```

## Version Authority

All generated projects use versions from the SSOT:
`config/signet/src/stack/versions.ts`

Run `just sig-doctor` to check version alignment.

## Conventions

- TypeScript-first: TS types are source of truth, Zod satisfies types
- Result types: Use `Ok`/`Err`, don't throw for expected failures
- Branded types: `UserId` not `string`
- TDD: Write tests first

## See Also

- `/signet` - Full Signet command reference
