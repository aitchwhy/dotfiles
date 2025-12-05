# CLAUDE CODE v5.0
# Minimal Effective Configuration

> **Managed via**: `~/dotfiles` with Nix + home-manager symlinks
> **Version**: 5.0.0 | December 2025

---

## IDENTITY

Senior software engineer building Ember, a voice memory platform for families.
Environment: macOS Apple Silicon (M4), zsh, Nix Flakes + Home Manager.
Tools: Cursor, Claude Code, Ghostty, Hammerspoon, Yazi, Zellij.

**Thinking Activation**:
- "think" → 4K reasoning tokens
- "think hard" / "megathink" → 10K reasoning tokens
- "ultrathink" → 32K reasoning tokens (maximum depth)

Default: Ultrathink for non-trivial tasks.

---

## CORE PRINCIPLES

### Parse Don't Validate
- Zod schema → TypeScript type (never reverse)
- Validate at boundaries, trust internally
- `unknown` in, typed out
- No `any`, no type assertions without validation

### Make Illegal States Unrepresentable
- Discriminated unions for state machines
- Branded types for identifiers (`UserId`, not `string`)
- Result types for fallible operations
- Never `null | undefined` without purpose

### Schema-First Development
- Zod (TS) and Pydantic (Python) are source of truth
- Types, API contracts, database interfaces derive from schemas

### MDAP Principles
- **Extreme Decomposition**: Break complex tasks into minimal subtasks
- **Error Correction at Every Step**: Validate after each change
- **Red-Flagging**: Pause when something feels wrong

---

## TECH STACK (Frozen Dec 2025)

### Runtime
- Bun v1.3+ (runtime, test runner, package manager)
- Node v22+ LTS (fallback)
- UV v0.5+ (Python, never pip)

### TypeScript
- TypeScript v5.9+ strict mode
- Zod v4 (schema-first validation)
- Biome v2.3+ (lint + format, NOT ESLint/Prettier)

### Frontend
- React 19 with TanStack Router + Query
- Tailwind CSS v4
- shadcn/ui components

### Backend
- HonoJS 4.x on Cloudflare Workers
- Drizzle ORM 0.44+ with D1/Turso/Neon
- Result type pattern for all handlers

### Python
- Python 3.13+ with UV
- Pydantic v2 for validation
- Ruff for lint/format

### Infrastructure
- Nix Flakes + Home Manager + nix-darwin
- Cloudflare Workers/Pages
- GitHub Actions CI/CD

---

## TYPESCRIPT STANDARDS

### Zero `any` Policy
Use `unknown` + type guards. Branded types for all identifiers:

```typescript
declare const __brand: unique symbol;
type Brand<T, B extends string> = T & { readonly [__brand]: B };

type UserId = Brand<string, 'UserId'>;
type OrderId = Brand<string, 'OrderId'>;
```

### Result Types
Never throw for expected failures:

```typescript
type Result<T, E = Error> =
  | { readonly ok: true; readonly data: T }
  | { readonly ok: false; readonly error: E };

const Ok = <T>(data: T): Result<T, never> => ({ ok: true, data });
const Err = <E>(error: E): Result<never, E> => ({ ok: false, error });
```

---

## TESTING (TDD)

Red-Green-Refactor cycle:

1. **Red**: Write failing test for expected behavior
2. **Green**: Write minimal code to pass
3. **Refactor**: Improve while green

Hierarchy: E2E (few) → Integration (moderate) → Unit (many)

```typescript
import { describe, test, expect } from 'bun:test';
describe('Feature', () => {
  test('success path', () => { /* ... */ });
  test('error path', () => { /* ... */ });
});
```

---

## QUALITY GATES

### Every Code Change MUST:
1. Pass `tsc --noEmit` (zero type errors)
2. Pass `bunx biome check` (zero lint errors)
3. Include tests for new functionality
4. Use conventional commits

### Every New File MUST:
1. Have explicit types (no inferred `any`)
2. Export schemas before types
3. Use Result types for fallible functions

---

## GIT

Conventional commits: `type(scope): description`
Types: feat, fix, refactor, test, docs, chore, perf, ci
Atomic commits. Never commit broken code. Rebase over merge.

---

## NAMING & STYLE

- Semantic: `userId` not `id`, `rowIdx` not `i`
- Magic numbers as expressions: `60 * 60` not `3600`
- Comments explain "why" not "what"
- No commented-out code—delete it
- All data readonly by default

---

## RED FLAGS (Pause and Verify)

- Changing more than 3 files for a "simple" change
- Type assertions without adjacent validation
- `any` appearing anywhere
- Missing error handling on async operations
- Tests that seem to pass but don't verify behavior

---

## ANTI-PATTERNS

| Bad | Good |
|-----|------|
| ESLint/Prettier | Biome |
| npm/yarn | Bun |
| Express | Hono |
| pip | UV |
| `any` | `unknown` + type guards |
| `null` | `undefined` |
| Magic numbers | Named expressions |
| Commented-out code | Delete it |

---

## SHELL & CLI

Modern tools: eza (ls), bat (cat), rg (grep), fd (find), delta (diff).
History: Atuin. Prompt: Starship. Files: Yazi. Multiplexer: Zellij.
Nix for packages. Homebrew only for GUI apps and casks.

---

## COMMANDS

| Command | Purpose |
|---------|---------|
| `/tdd` | Test-driven development cycle |
| `/validate` | Run typecheck + lint + test |
| `/commit` | Conventional commit helper |
| `/pr` | Pull request creation |
| `/fix` | Structured bug fixing |
| `/debug` | Hypothesis-driven debugging |
| `/feature` | Spec-first TDD implementation |
| `/plan` | Implementation planning |
| `/review` | Quick code review |
| `/nix-search` | Search Nix packages |
| `/nix-rebuild` | Rebuild darwin config |
| `/sync` | Sync dev environment |

---

*v5.0.0 - Consolidated from v4.0 ULTRATHINK system. Aspirational features removed.*
