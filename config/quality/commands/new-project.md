---
description: Create a new TypeScript/Bun project from template
---

# New TypeScript/Bun Project

Create a TypeScript project with Effect-TS stack.

## Quick Start

```bash
# Initialize a standalone project
just new-ts-project my-project
cd ~/src/my-project
```

## Stack

| Layer | Technology |
|-------|------------|
| Runtime | Bun + Node.js (via Nix) |
| HTTP | @effect/platform HttpApiBuilder |
| Validation | Effect Schema |
| Database | Drizzle ORM + postgres.js |
| Testing | Vitest |
| Linting | Biome |

## Project Structure

```
my-project/
├── src/
│   ├── domain/       # Pure business logic
│   ├── ports/        # Service interfaces
│   ├── adapters/     # Infrastructure implementations
│   └── lib/          # Shared utilities
├── flake.nix         # Nix flake
├── package.json
├── tsconfig.json
└── vitest.config.ts
```

## Conventions

- TypeScript-first: TS types are source of truth
- Effect Schema for validation (not Zod)
- Result types: Use Effect.fail, don't throw
- Branded types: `UserId` not `string`
- TDD: Write tests first

## Verification

```bash
# Check PARAGON compliance
just verify-paragon

# Type check + lint + test
bun validate
```

## Version Authority

All projects use versions from the SSOT:
`config/quality/src/stack/versions.ts`
