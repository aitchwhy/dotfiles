---
name: project-bootstrap
description: Project creation and migration workflows for Universal Project Factory
alwaysApply: false
globs: ["**/package.json", "**/flake.nix", "**/biome.json"]
---

# Project Bootstrap

Workflows for creating new projects and migrating existing ones to STACK compliance.

## New Project Workflow

### 1. Initialize Project

```bash
# API project (Hono + Drizzle + Effect)
signet init api my-service

# UI project (React 19 + TanStack + XState)
signet init ui my-app

# Full monorepo (Bun workspaces)
signet init monorepo my-platform

# Infrastructure (Pulumi + process-compose)
signet init infra my-cloud
```

### 2. Enter Project

```bash
cd my-service
bun install
```

### 3. Start Development

```bash
# With process-compose (local infra)
process-compose up

# Or direct
bun dev
```

### 4. Verify Structure

```bash
signet verify
```

## Migration Workflow

### 1. Preview Changes

```bash
signet migrate --dry-run --verbose
```

### 2. Execute Migration

```bash
signet migrate
```

### 3. Refresh Dependencies

```bash
bun install
```

### 4. Verify Compliance

```bash
signet verify
```

## Manual Migration Steps

When `signet migrate` is unavailable:

### Phase 1: Delete Forbidden Files

```bash
rm -f package-lock.json yarn.lock pnpm-lock.yaml
rm -f Dockerfile docker-compose.yml docker-compose.yaml .dockerignore
rm -f .eslintrc* eslint.config.* .prettierrc* prettier.config.*
rm -f jest.config.* .env.local .env.development
```

### Phase 2: Remove Banned Dependencies

Edit `package.json` and remove:
- `express`, `fastify`, `koa`
- `prisma`, `@prisma/client`
- `mysql`, `mysql2`, `mongoose`
- `dotenv`, `axios`, `lodash`, `moment`
- `eslint`, `prettier`, `jest`

### Phase 3: Add Required Files

**biome.json:**
```json
{
  "$schema": "https://biomejs.dev/schemas/2.0.0/schema.json",
  "organizeImports": { "enabled": true },
  "linter": { "enabled": true, "rules": { "recommended": true } },
  "formatter": { "enabled": true, "indentStyle": "space", "indentWidth": 2 }
}
```

**flake.nix:**
```nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }: {
    devShells = nixpkgs.lib.genAttrs ["x86_64-darwin" "aarch64-darwin"] (system: {
      default = nixpkgs.legacyPackages.${system}.mkShell {
        packages = with nixpkgs.legacyPackages.${system}; [ bun biome ];
      };
    });
  };
}
```

**.envrc:**
```bash
use flake
```

### Phase 4: Regenerate Lockfile

```bash
bun install
```

## Troubleshooting

### "Forbidden import" error

Your code uses a banned package. Replace:
- `express` → `hono`
- `prisma` → `drizzle-orm`
- `axios` → native `fetch`
- `dotenv` → `.envrc` with direnv

### "z.infer<> detected" error

Define TypeScript type first, then use `satisfies`:

```typescript
// Wrong
type User = z.infer<typeof UserSchema>;

// Correct
type User = { readonly id: string; readonly name: string };
const UserSchema = z.object({
  id: z.string(),
  name: z.string()
}) satisfies z.ZodType<User>;
```

### Version drift warnings

Run:
```bash
signet migrate --dry-run
```

This shows which versions need updating to match STACK.

### Missing flake.nix

```bash
signet init library $(basename $PWD)
# Or manually create from template above
```

## Quick Reference

| Command | Purpose |
|---------|---------|
| `signet init <type> <name>` | Create new project |
| `signet migrate` | Migrate existing project |
| `signet verify` | Validate compliance |
| `signet doctor` | Check system health |
| `bun install` | Regenerate lockfile |
| `process-compose up` | Start local infra |
