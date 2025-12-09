# Agent Instructions

Senior software engineer. macOS Apple Silicon, zsh, Nix Flakes.

## Stack

- **Runtime**: Bun 1.3+, Node 22+, UV 0.5+ (Python)
- **TypeScript**: strict mode, Zod v4, Biome 2.3+
- **Frontend**: React 19, TanStack Router/Query, Tailwind v4
- **Backend**: Hono 4.x on Cloudflare Workers, Drizzle ORM
- **Infra**: Nix Flakes + nix-darwin, GitHub Actions

## Principles

- TypeScript-first: TS types are source of truth, schemas satisfy types
- Parse don't validate: `unknown` in, typed out
- Result types for fallible operations
- No `any` - use `unknown` + type guards
- Biome enforced: format + lint after every code change
- Conventional commits: `type(scope): description`

## Verification-First

**Ban assumption language. Replace with evidence.**

| BANNED | REQUIRED |
|--------|----------|
| "should now work" | "VERIFIED via test: [output]" |
| "should fix the bug" | "VERIFIED: [test_file]:[test_name]" |
| "this fixes" | "UNVERIFIED: requires [test_name]" |

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
| `typescript-patterns` | Branded types, Result types, parse don't validate |
| `zod-patterns` | TypeScript-first Zod (never use z.infer) |
| `signet-patterns` | Hexagonal architecture, Effect Schema |
| `result-patterns` | Error handling |
| `tdd-patterns` | Red-Green-Refactor |
| `nix-darwin-patterns` | Nix flakes + home-manager |
| `hono-workers` | Cloudflare Workers APIs |
| `tanstack-patterns` | Router + Query |
| `ember-patterns` | Ember platform |
| `verification-first` | Test evidence |
| `clean-code` | Code quality, Biome enforcement |

## Pattern Quick Reference

### Result Type

```typescript
type Result<T, E = Error> =
  | { readonly ok: true; readonly data: T }
  | { readonly ok: false; readonly error: E };

const Ok = <T>(data: T): Result<T, never> => ({ ok: true, data });
const Err = <E>(error: E): Result<never, E> => ({ ok: false, error });
```

### TypeScript-First Zod

```typescript
// 1. TypeScript type is source of truth
type User = {
  readonly id: string;
  readonly email: string;
  readonly role: 'admin' | 'user' | 'guest';
};

// 2. Schema satisfies the type (NEVER use z.infer)
const userSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  role: z.enum(['admin', 'user', 'guest']),
}) satisfies z.ZodType<User>;
```

### Biome Enforcement

After writing/modifying TypeScript code, always run:
```bash
biome check --write .  # Format + lint + fix
bun typecheck          # Type check
```

## Project-Specific: Ember

- Cookie `secure` flag: dynamic for localhost
- Test credentials: phone `5550000000`, OTP `123456`
- Monorepo: apps/web, apps/api, apps/agent, packages/domain
