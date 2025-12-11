---
name: clean-code
description: Clean code patterns for Nix and TypeScript. Explicit imports, Result types, function size limits, Biome enforcement. Apply to dotfiles and TypeScript projects.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

## Nix-Specific Patterns

### Explicit Library Imports (Never `with lib;`)

```nix
# Bad: implicit scope pollution
{ config, lib, ... }:
with lib;
{
  options.foo = mkOption { ... };
}

# Good: explicit imports, clear provenance
{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
in
{
  options.foo = mkOption { ... };
  config = mkIf config.foo.enable { ... };
}
```

### Module Structure

Standard Nix module layout: options first, then config:

```nix
{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.myModule;
in
{
  options.myModule = {
    enable = mkEnableOption "my module";
  };
  config = mkIf cfg.enable { ... };
}
```

## TypeScript Clean Code

### Function Size Limits (< 20 lines)

```typescript
// Bad: monolithic function
async function processOrder(order: Order): Promise<Result<ProcessedOrder, Error>> {
  // 50+ lines of validation, transformation, side effects
}

// Good: decomposed into single-responsibility functions
async function processOrder(order: Order): Promise<Result<ProcessedOrder, Error>> {
  const validated = validateOrder(order);
  if (!validated.ok) return validated;
  const enriched = await enrichWithCustomerData(validated.data);
  if (!enriched.ok) return enriched;
  return calculateTotals(enriched.data);
}
```

### Naming Rules

| Pattern | Bad | Good |
|---------|-----|------|
| Descriptive | `d`, `temp`, `obj` | `orderCreatedAt`, `activeUsers` |
| Indicate IO | `getUser()` | `fetchUser()` (network), `findUser()` (may return null) |
| Long scope = long name | `n` in 50 lines | `userCount` |

### Early Returns Over Nesting

```typescript
// Bad: deeply nested
function processRequest(req: Request) {
  if (req.user) {
    if (req.user.isActive) {
      if (req.user.hasPermission('write')) {
        return doWork(req);
      }
    }
  }
}

// Good: guard clauses
function processRequest(req: Request) {
  if (!req.user) return Err('Not authenticated');
  if (!req.user.isActive) return Err('User inactive');
  if (!req.user.hasPermission('write')) return Err('No permission');
  return doWork(req);
}
```

### Comments: Explain "Why", Not "What"

```typescript
// Bad: describes what (obvious from code)
// Loop through users and check if active
for (const user of users) { if (user.isActive) { ... } }

// Good: explains why
// Use in-memory filtering (list <100, already cached)
const activeUsers = users.filter(user => user.isActive);
```

### Readonly by Default

```typescript
interface User {
  readonly name: string;
  readonly roles: readonly string[];
}
```

## Biome Enforcement

### MANDATORY: Run After Every Code Change

```bash
biome check --write .  # Format + lint + auto-fix
bun typecheck          # Type check
```

### Critical Rules (NEVER Disable)

| Rule | Why |
|------|-----|
| `noExplicitAny` | Forces `unknown` + type guards |
| `noUnusedVariables` | Dead code removal |
| `noNonNullAssertion` | Forces null checks |
| `useConst` | Immutability by default |

## Code Quality Detection

Quick detection commands from Robert C. Martin's Clean Code:

```bash
# Commented code (C5)
rg "//\s*(const|let|function)" --type ts

# Magic numbers (G25)
rg "\b\d{3,}\b" --type ts | head -20

# Type safety overrides (G4)
rg "@ts-ignore|as any" --type ts

# Flag arguments (F3)
rg ":\s*boolean" --type ts | head -20

# Law of Demeter violations (G36)
rg "\.\w+\(\)\.\w+\(\)\.\w+\(" --type ts

# Too many arguments (F1)
rg "function.*\(.*,.*,.*,.*," --type ts

# Non-descriptive names (N1)
rg "\b(temp|tmp|data|obj|val|res|ret)\b\s*=" --type ts
```

## Clean Code Canonical Reference

| Category | Codes | Key Smells |
|----------|-------|------------|
| Comments | C1-C5 | Inappropriate info, obsolete, redundant, commented-out code |
| Environment | E1-E2 | Multi-step build/test |
| Functions | F1-F4 | Too many args, output args, flag args, dead functions |
| General | G1-G36 | Duplication (G5), dead code (G9), inconsistency (G11), feature envy (G14) |
| Naming | N1-N7 | Non-descriptive, non-standard, short names in long scope |
| Tests | T1-T9 | Insufficient tests, skipped trivial tests, untested boundaries |

### Key Remediation Patterns

**F1 Too Many Arguments** → Introduce Parameter Object:
```typescript
// Bad
function createUser(name: string, email: string, age: number, role: string) {}

// Good
type CreateUserParams = { readonly name: string; readonly email: string; ... };
function createUser(params: CreateUserParams) {}
```

**F2 Output Arguments** → Return modified value:
```typescript
// Bad: mutates argument
function appendFooter(report: Report) { report.footer = "..."; }

// Good: returns new value
function withFooter(report: Report): Report { return { ...report, footer: "..." }; }
```

**F3 Flag Arguments** → Split into two functions:
```typescript
// Bad
function createFile(name: string, temp: boolean) {}

// Good
function createFile(name: string) {}
function createTempFile(name: string) {}
```

**G19 Use Explanatory Variables**:
```typescript
// Bad
if (platform.toUpperCase().indexOf("MAC") > -1 && browser.toUpperCase().indexOf("IE") > -1) {}

// Good
const isMacOS = platform.toUpperCase().indexOf("MAC") > -1;
const isIE = browser.toUpperCase().indexOf("IE") > -1;
if (isMacOS && isIE) {}
```

**G28 Encapsulate Conditionals**:
```typescript
// Bad
if (timer.hasExpired() && !timer.isRecurrent()) {}

// Good
if (shouldBeDeleted(timer)) {}
```

**G31 Hidden Temporal Couplings** → Make dependencies explicit:
```typescript
// Bad: implicit order
initialize(); process(); cleanup();

// Good: explicit chain
const initialized = initialize();
const processed = process(initialized);
cleanup(processed);
```
