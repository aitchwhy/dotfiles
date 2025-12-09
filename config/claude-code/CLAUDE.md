# Claude Code

Senior software engineer. macOS Apple Silicon, zsh, Nix Flakes.

## Stack

- **Runtime**: Bun 1.3+, Node 22+, UV 0.5+ (Python)
- **TypeScript**: strict mode, Zod v4, Biome 2.3+
- **Frontend**: React 19, TanStack Router/Query, Tailwind v4
- **Backend**: Hono 4.x on Cloudflare Workers, Drizzle ORM
- **Infra**: Nix Flakes + nix-darwin, GitHub Actions

## Principles

- Schema-first: Zod/Pydantic are source of truth
- Parse don't validate: `unknown` in, typed out
- Result types for fallible operations
- No `any` - use `unknown` + type guards
- Conventional commits: `type(scope): description`

## Commands

| Command | Purpose |
|---------|---------|
| `/tdd` | Test-driven development |
| `/validate` | typecheck + lint + test |
| `/commit` | Conventional commit |
| `/pr` | Pull request creation |
| `/fix` | Bug fixing |
| `/debug` | Hypothesis-driven debugging |

## Skills

| Skill | Purpose |
|-------|---------|
| `typescript-patterns` | Branded types, Result types |
| `zod-patterns` | Schema-first development |
| `result-patterns` | Error handling |
| `tdd-patterns` | Red-Green-Refactor |
| `nix-darwin-patterns` | Nix flakes + home-manager |
| `hono-workers` | Cloudflare Workers APIs |
| `tanstack-patterns` | Router + Query |
| `ember-patterns` | Ember platform |
| `verification-first` | Test evidence |
| `clean-code` | Code quality |
