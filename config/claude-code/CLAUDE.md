# Hank's Development System

## Identity

Senior software engineer building Ember, a voice memory platform for families.
Environment: macOS Apple Silicon (M4), zsh, Nix Flakes + Home Manager.
Primary tools: Cursor, Claude Code, Ghostty, Hammerspoon, Yazi, Zellij.

## Philosophy

Schema-driven development. Zod (TS) and Pydantic (Python) are the source of truth.
Types, API contracts, and database interfaces derive from schemas—never the reverse.

Core principles:
- Parse don't validate (validate at boundaries, trust internally)
- Make illegal states unrepresentable at the type level
- Result types for fallible operations: `{ ok: true; data: T } | { ok: false; error: E }`
- Composition over inheritance
- Smallest surgical change that solves the problem
- Measure before and after

## TypeScript Standards

TypeScript 5.9+ strict mode. Zero `any`—use `unknown` + type guards.
Branded types: `type UserId = string & { readonly __brand: 'UserId' }`.
All data readonly. Use `undefined` not `null` for absent values.
Use `satisfies z.ZodType<T>` over `z.infer<typeof schema>`.
Biome 2.3+ for lint/format (NOT ESLint/Prettier).

## Python Standards

Python 3.13+ with UV (never pip). Pydantic v2 for validation, Ruff for lint/format.
Type hints everywhere. Pattern matching with `match`. `str | None` not `Optional[str]`.

## Naming & Style

Semantic: `userId` not `id`, `rowIdx` not `i`, `isEnabled` not `flag`.
Magic numbers as expressions: `60 * 60` not `3600`.
Comments explain "why" not "what". No commented-out code.

## Testing (Canon TDD)

1. Write failing E2E test (happy path)
2. Minimal unit tests for core logic
3. Implement until green
4. Refactor while green

Tools: Playwright (E2E), Bun test (TS), pytest (Python).

## Git

Conventional commits: `type(scope): description`.
Types: feat, fix, refactor, test, docs, chore, ci.
Atomic commits. Never commit broken code. Rebase over merge.

## Tech Stack (Frozen Dec 2025)

- Runtime: Bun 1.3.x, Python 3.13.x/UV 0.5.x
- TypeScript: 5.9+ strict, Zod 4.x
- Frontend: React 19.x, TanStack Router/Query, Tailwind 4.x
- API: HonoJS 4.x, Drizzle 0.44+, Cloudflare Workers
- Voice: livekit-agents 1.3+, Deepgram STT, Cartesia TTS
- Database: Postgres via Neon or Supabase
- Format: Biome 2.3+ (NOT ESLint/Prettier)
- Monorepo: apps/ for applications, packages/ for shared code, Bun workspaces

## Anti-Patterns (Never Use)

- ESLint/Prettier -> Biome
- npm/yarn -> Bun
- Express -> Hono
- pip -> UV
- `any` -> `unknown` + type guards
- `null` -> `undefined`
- Magic numbers -> Named expressions
- Commented-out code -> Delete it

## Shell & CLI

Modern tools: eza (ls), bat (cat), rg (grep), fd (find), delta (diff).
History: Atuin. Prompt: Starship. Files: Yazi. Multiplexer: Zellij.
Nix for packages. Homebrew only for GUI apps and casks.

## Validation Gate

Before marking complete: `bun run typecheck && bun run lint && bun test` must pass.
