# Agent Instructions

Senior software engineer. macOS Apple Silicon, zsh, Nix Flakes.

> **Version Authority**: `config/signet/src/stack/versions.ts` is the single source of truth.
> Run `just sig-doctor` to check version alignment.
> Import: `import { STACK } from '@/stack'`

## Context Protocol

This repository uses **pull-based context** - dynamically discover information rather than relying on pre-packaged XML dumps.

**Do NOT read `repomix-output.xml`.** Instead, use filesystem MCP tools to build your mental map:

| Tool | Purpose |
|------|---------|
| `ls`, `find` | Discover directory structure |
| `grep`, `rg` | Search file contents |
| `Read` | Read specific files |
| `Glob` | Pattern-match file paths |

### Context Generation

Run `just gen-context` to generate editor-specific rule files:

| Target | File | Generated From |
|--------|------|----------------|
| Cursor | `.cursorrules` | AGENT.md + SKILL.md files |
| Claude CLI | `~/.claude/CLAUDE.md` | Symlinked |

## Language Barrier

**Ban assumption language. Replace with evidence.**

| BANNED | REQUIRED |
|--------|----------|
| "should work" | "verified via [test/output]" |
| "probably" | "error output shows" |
| "likely" | "confirmed by running" |
| "I think" | Evidence-based statements only |
| "might" | "UNVERIFIED: requires [test_name]" |

## Stack

- **Runtime**: Bun 1.3+, Node 25+ (current, not LTS), UV 0.5+ (Python)
- **TypeScript**: strict mode, Zod v4, Biome 2.3+
- **Effects**: Effect-TS 3.x (typed errors, dependencies, retries)
- **Frontend**: React 19, TanStack Router, XState 5, Tailwind v4
- **Backend**: Hono 4.x, Drizzle ORM, Effect-TS services
- **APIs**: TypeSpec → OpenAPI → codegen
- **Infra**: Nix Flakes + nix-darwin, Terranix → OpenTofu, Pulumi (GCP)

## Core Principles

### Environment Parity
```
localhost === CI === production
```
Achieved via: Nix Flakes (hermetic), Process Compose (orchestration), Cloud Build (identical images).

### Type Safety Hierarchy
```
TypeScript Type (source of truth) → Zod Schema (runtime validation via satisfies)
```
- **TypeScript type is ALWAYS the source of truth**
- **NEVER use `z.infer<>`** — define the type explicitly first
- Zod schemas MUST use `satisfies` to ensure conformance
- No `any` — use `unknown` + type guards

### Error Handling Philosophy
```typescript
// ❌ NEVER: throw for expected failures
if (!user) throw new Error("Not found");

// ✅ ALWAYS: typed errors with Effect-TS or Result types
return Effect.fail(new UserNotFoundError({ id }));
```

### Maximum Rigor Through Paradigms

| Paradigm | Tool | What It Eliminates |
|----------|------|-------------------|
| Algebraic Effects | Effect-TS | Untyped errors, hidden dependencies |
| Finite State Machines | XState | Impossible states, state explosion |
| TypeScript-First Validation | Zod + `satisfies` | Type drift |

### Hexagonal Architecture (Ports & Adapters)

```
┌────────────────────────────────────────┐
│              Domain                     │
│   (Pure logic, no I/O, no framework)   │
└────────────────────────────────────────┘
         ▲                      ▲
         │                      │
┌────────┴────────┐  ┌─────────┴─────────┐
│  Inbound Ports  │  │  Outbound Ports   │
│  (API contract) │  │ (StoragePort etc) │
└────────┬────────┘  └─────────┬─────────┘
         │                      │
┌────────┴────────┐  ┌─────────┴─────────┐
│ Inbound Adapter │  │ Outbound Adapters │
│ (Hono handlers) │  │ (GCS, PostgreSQL) │
└─────────────────┘  └───────────────────┘
```

### No-Mock Testing Policy

**NEVER mock infrastructure.** Tests run against real services:

| Environment | Infrastructure |
|-------------|---------------|
| Local | Docker via process-compose |
| CI | GitHub Actions services |
| Staging | Real GCP (Cloud SQL, GCS) |

**Blocked**: `Mock*Live`, `jest.mock()`, `vi.mock()`, `sinon.*`
**Allowed**: `Layer.succeed()` (DI), factory functions with real adapters

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

## 5-Tier Quality System

This system achieves >85% first-attempt correctness through layered verification.

| Tier | Component | Purpose |
|------|-----------|---------|
| 1 | Pattern Knowledge | refactoring-catalog, distributed-systems-patterns, code-smells |
| 2 | Formal Verification | formal-verification skill, contracts, property-based tests |
| 3 | Execution Feedback | test-during-generation hook, iterative-repair |
| 4 | Multi-Agent Review | critic, synthesizer agents, /debate command |
| 5 | Codebase Context | semantic-codebase skill, ast-grep integration |

### Mandatory Workflow

1. **Before writing**: Check relevant pattern skills
2. **During writing**: Hooks verify types and tests
3. **After writing**: Run `/debate` for multi-agent review
4. **Before commit**: Run `just verify-all` - all 5 tiers must pass

## Commands

| Command | Purpose |
|---------|---------|
| `/tdd` | Test-driven development |
| `/validate` | typecheck + lint + test |
| `/debate` | Multi-agent code review |
| `/commit` | Conventional commit |
| `/pr` | Pull request creation |
| `/fix` | Bug fixing |
| `/debug` | Hypothesis-driven debugging |

## Skills

### Core Patterns
| Skill | Purpose |
|-------|---------|
| `typescript-patterns` | Branded types, Result types, parse don't validate |
| `zod-patterns` | TypeScript-first Zod (never use z.infer), Zod v4 features |
| `effect-ts-patterns` | Effect<A,E,R>, Layers, Services, typed errors |
| `result-patterns` | Error handling |

### Quality System (5-Tier)
| Skill | Purpose |
|-------|---------|
| `refactoring-catalog` | Fowler's 61 refactoring patterns |
| `distributed-systems-patterns` | Consensus, replication, versioning |
| `code-smells` | Clean Code heuristics as detection rules |
| `formal-verification` | Contracts, preconditions, property-based testing |
| `semantic-codebase` | Codebase navigation and context building |
| `verification-first` | Test evidence over assumption |
| `clean-code` | Code quality, Biome enforcement |

### Architecture
| Skill | Purpose |
|-------|---------|
| `hexagonal-architecture` | No-mock testing, service containers, ports/adapters |
| `signet-patterns` | Hexagonal code generation, Effect Schema |
| `signet-generator-patterns` | Extend Signet with new generators |
| `tdd-patterns` | Red-Green-Refactor |

### Infrastructure
| Skill | Purpose |
|-------|---------|
| `nix-darwin-patterns` | Nix flakes + home-manager |
| `nix-flake-parts` | Modular flakes with flake-parts |
| `terranix-patterns` | Nix → Terraform → OpenTofu |

### Web/API
| Skill | Purpose |
|-------|---------|
| `typespec-patterns` | API-first, OpenAPI codegen |
| `hono-workers` | Cloudflare Workers APIs |
| `tanstack-patterns` | Router + Query |
| `ember-patterns` | Ember platform |

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
