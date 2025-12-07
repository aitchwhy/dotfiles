---
description: Create a new TypeScript/Bun project from template
---

# New TypeScript/Bun Project

Create a project using the December 2025 TypeScript/Bun template.

## Template Location

```
~/dotfiles/config/templates/typescript-bun/
```

## What's Included

- `tsconfig.json` - Strict TypeScript with Bun types
- `biome.json` - Linting + formatting (noExplicitAny enforced)
- `package.json` - Bun scripts and dependencies
- `flake.nix` - Nix development shell
- `src/lib/result.ts` - Result type implementation
- `src/schemas/example.ts` - Zod schema examples with branded types
- Test files for both modules

## Usage Steps

1. **Copy template to target location**:
   ```bash
   cp -r ~/dotfiles/config/templates/typescript-bun ~/src/PROJECT_NAME
   cd ~/src/PROJECT_NAME
   ```

2. **Replace placeholders**:
   ```bash
   sed -i '' 's/PROJECT_NAME/actual-name/g' package.json src/index.ts flake.nix
   ```

3. **Initialize**:
   ```bash
   git init
   bun install
   direnv allow  # If using Nix
   ```

4. **Verify**:
   ```bash
   bun validate  # typecheck + lint + test
   ```

## Optional: Adding Features

### Hono Backend
```bash
bun add hono @hono/zod-validator
```

### Drizzle ORM
```bash
bun add drizzle-orm
bun add -d drizzle-kit
```

### React + TanStack
```bash
bun add react react-dom @tanstack/react-router @tanstack/react-query
bun add -d @types/react @types/react-dom
```

## Conventions

- Schema-first: Zod schemas are source of truth
- Result types: Use `Ok`/`Err`, don't throw for expected failures
- Branded types: `UserId` not `string`
- TDD: Write tests first
