# Stack Constraints

> **Version Authority**: `config/signet/src/stack/versions.ts` is the SSOT.
> Run `just sig-doctor` to check alignment.
> Import: `import { STACK } from '@/stack'`

## Signet MCP Tools

Use these MCP tools for stack compliance:

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `mcp__signet__sig-stack` | Check/fix versions, forbidden deps | After modifying package.json |
| `mcp__signet__sig-guard` | Pre-write AST validation | Before writing TypeScript files |
| `mcp__signet__sig-migrate` | Project drift detection | At session start for new projects |
| `mcp__signet__sig-verify` | Full 5-tier verification | Before commits or when requested |

### sig-stack
```
mcp__signet__sig-stack(path: ".", fix: true)
```
- Checks forbidden deps (lodash, express, prisma, etc.)
- Checks version drift against STACK.npm
- With `fix: true`, auto-corrects versions in package.json

### sig-guard
```
mcp__signet__sig-guard(content: "...", filePath: "src/foo.ts")
```
- Runs AST-grep rules: no-any, no-zod-infer, no-mock, no-throw, no-should-work, no-console, no-legacy-tools
- Returns violations with line numbers
- Use BEFORE writing files to catch violations early

### sig-migrate
```
mcp__signet__sig-migrate(path: ".", fix: true)
```
- Detects missing CLAUDE.md, forbidden files, version drift
- With `fix: true`, creates CLAUDE.md symlink, removes forbidden files

## Runtime

- **Bun**: 1.3+
- **Node**: 25+ (current, not LTS)
- **UV**: 0.5+ (Python)

## TypeScript

- strict mode, Zod v4, Biome 2.3+
- TypeScript type is ALWAYS source of truth
- NEVER use `z.infer<>` - define type explicitly first
- Schemas MUST use `satisfies z.ZodType<T>`
- No `any` - use `unknown` + type guards

## Effects

- Effect-TS 3.x (typed errors, dependencies, retries)
- Return `Effect.fail()` for expected failures, never throw

## Logging

All logging MUST use Effect-TS. Console methods are blocked by Guard 26.

```typescript
// BAD - blocked by PARAGON Guard 26
console.log('Processing');
console.error('Failed:', error);

// GOOD - Effect-TS logging
yield* Effect.log('Processing');
yield* Effect.logError('Failed', { error });
yield* Effect.logWarning('Deprecated API');
yield* Effect.logDebug('Verbose info');

// Logger layers for different contexts
Effect.provide(Logger.pretty);        // CLI tools
Effect.provide(Logger.json);          // Services/APIs
Effect.provide(HookLoggerLive);       // Claude Code hooks
```

**Blocked**: `console.log`, `console.error`, `console.warn`, `console.debug`, `console.info`, `pino`

## Frontend

- React 19, TanStack Router, XState 5, Tailwind v4

## Backend

- Effect Platform HTTP (@effect/platform), Drizzle ORM, Effect-TS services

## APIs

- TypeSpec -> OpenAPI -> codegen pipeline

## Infrastructure

- Nix Flakes + nix-darwin
- Pulumi (GCP, TypeScript-native IaC)

## Core Principles

### Environment Parity

```
localhost === CI === production
```

Achieved via: Nix Flakes (hermetic), Process Compose (orchestration), Cloud Build (identical images).

### Type Safety Hierarchy

```
TypeScript Type (source of truth) -> Zod Schema (runtime validation via satisfies)
```

### Error Handling

```typescript
// NEVER: throw for expected failures
if (!user) throw new Error("Not found");

// ALWAYS: typed errors with Effect-TS or Result types
return Effect.fail(new UserNotFoundError({ id }));
```

### Result Type Pattern

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

## Architecture

### Hexagonal (Ports & Adapters)

```
+----------------------------------------+
|              Domain                     |
|   (Pure logic, no I/O, no framework)   |
+----------------------------------------+
         ^                      ^
         |                      |
+--------+--------+  +---------+---------+
|  Inbound Ports  |  |  Outbound Ports   |
|  (API contract) |  | (StoragePort etc) |
+--------+--------+  +---------+---------+
         |                      |
+--------+--------+  +---------+---------+
| Inbound Adapter |  | Outbound Adapters |
| (Effect HTTP)   |  | (GCS, PostgreSQL) |
+-----------------+  +-------------------+
```

### No-Mock Testing

**NEVER mock infrastructure.** Tests run against real services:

| Environment | Infrastructure |
|-------------|---------------|
| Local | Docker via process-compose |
| CI | GitHub Actions services |
| Staging | Real GCP (Cloud SQL, GCS) |

**Blocked**: `Mock*Live`, `jest.mock()`, `vi.mock()`, `sinon.*`
**Allowed**: `Layer.succeed()` (DI), factory functions with real adapters

## Language Barrier

**Ban assumption language. Replace with evidence.**

| BANNED | REQUIRED |
|--------|----------|
| "should work" | "verified via [test/output]" |
| "probably" | "error output shows" |
| "likely" | "confirmed by running" |
| "I think" | Evidence-based statements only |
| "might" | "UNVERIFIED: requires [test_name]" |

## Biome Enforcement

After writing/modifying TypeScript code, always run:

```bash
biome check --write .  # Format + lint + fix
bun typecheck          # Type check
```

## Modern CLI Tools (Guard 27)

Use modern Rust CLI tools exclusively. Legacy tools are blocked by PARAGON Guard 27.

| Legacy | Modern | Purpose |
|--------|--------|---------|
| `grep` | `rg` (ripgrep) | Pattern search |
| `find` | `fd` | File discovery |
| `ls` | `eza` | Directory listing |
| `du` | `dust` | Disk usage |

```bash
# BAD - blocked by Guard 27
grep -r "pattern" .
find . -name "*.ts"
ls -la
du -sh

# GOOD - Modern Rust tools
rg "pattern" .           # ripgrep: faster, .gitignore aware
fd -e ts                 # fd: simpler syntax, parallel
eza -la                  # eza: colors, git status
dust                     # dust: visual tree view

# Common patterns
rg -t ts "Effect"        # Search TypeScript files only
rg -q "pattern"          # Quiet mode (exit code only)
fd -e md --changed-within 7d  # Files modified in last 7 days
eza --oneline            # One file per line (like ls -1)
```

**Installation**: All tools provided via Nix (`pkgs.ripgrep`, `pkgs.fd`, `pkgs.eza`, `pkgs.dust`)

## Nix Build Rules

### Derivation Splitting (Mandatory)

For ANY TypeScript project with Nix builds:

1. **nodeModules derivation** - Contains ONLY `bun install`
   - Hash based on `bun.lock` only
   - Uses `__noChroot = true` for network access

2. **App derivation** - Contains ONLY `bun build`
   - Symlinks to nodeModules: `ln -s ${nodeModules}/node_modules ./`
   - No network access needed

### CI Cache Stack (Mandatory Order)

```yaml
- uses: DeterminateSystems/nix-installer-action@v14
- uses: DeterminateSystems/magic-nix-cache-action@v8  # MUST be after installer
- uses: cachix/cachix-action@v15                      # MUST be after magic-cache
```

### Prohibited Patterns

```nix
# NEVER: bun install in app derivation
api = mkDerivation {
  buildPhase = ''
    bun install  # WRONG - kills cache
    bun build
  '';
};

# ALWAYS: Split derivations
nodeModules = mkDerivation { buildPhase = "bun install"; };
api = mkDerivation {
  buildPhase = ''
    ln -s ${nodeModules}/node_modules ./
    bun build
  '';
};
```

### Version Pins

| Input | Required Version |
|-------|------------------|
| nixpkgs | `nixos-24.11` (stable) |
| nix-installer-action | `@v14` |
| magic-nix-cache-action | `@v8` |
| cachix-action | `@v15` |
