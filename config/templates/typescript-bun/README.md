# TypeScript/Bun Project Template

> **Version**: December 2025
> **Stack**: Bun 1.3+, TypeScript 5.9+, Biome 2.3+, Zod 4

---

## Quick Start

```bash
# Copy template to new project
cp -r ~/dotfiles/config/templates/typescript-bun ~/src/my-project
cd ~/src/my-project

# Replace placeholders
sed -i '' 's/PROJECT_NAME/my-project/g' package.json src/index.ts

# Initialize
bun install
direnv allow  # If using Nix

# Verify
bun validate
```

---

## What's Included

### Configuration Files

| File | Purpose |
|------|---------|
| `tsconfig.json` | Strict TypeScript with Bun types |
| `biome.json` | Linting + formatting (no ESLint/Prettier) |
| `package.json` | Scripts and dependencies |
| `flake.nix` | Nix development shell |
| `.gitignore` | Modern Bun/TS ignores |
| `.envrc` | direnv configuration |

### Source Files

| File | Purpose |
|------|---------|
| `src/index.ts` | Entry point |
| `src/lib/result.ts` | Result type for error handling |
| `src/schemas/example.ts` | Zod schema examples with branded types |

---

## Scripts

```bash
bun dev        # Watch mode
bun start      # Run once
bun test       # Run tests
bun typecheck  # Type check only
bun lint       # Lint only
bun lint:fix   # Lint and fix
bun format     # Format only
bun validate   # Full validation (typecheck + lint + test)
```

---

## Adding Features

### Hono Backend
```bash
bun add hono @hono/zod-validator
```

### Drizzle ORM
```bash
bun add drizzle-orm
bun add -d drizzle-kit
```

### React Frontend
```bash
bun add react react-dom @tanstack/react-router @tanstack/react-query
bun add -d @types/react @types/react-dom
```

---

## Conventions

- **Schema-first**: Define Zod schemas, derive TypeScript types
- **Result types**: Use `Ok`/`Err` for fallible operations, don't throw
- **Branded types**: Use branded IDs for type safety (`UserId`, not `string`)
- **TDD**: Write tests first, verify with evidence

---

*Template from ~/dotfiles — See STACK.md for complete version matrix*
