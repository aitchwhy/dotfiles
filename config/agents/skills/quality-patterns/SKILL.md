---
name: quality-patterns
description: Code quality patterns combining clean code principles and verification-first development. Biome enforcement, evidence-based claims, function size limits.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
token-budget: 600
---

## Verification-First Philosophy

**Every claim about code behavior must be backed by test evidence.**

### Banned Language

| BANNED | REQUIRED |
|--------|----------|
| "should now work" | "VERIFIED via test: assertion passed" |
| "this should fix" | "VERIFIED via test: specific output" |
| "probably works" | "UNVERIFIED: requires test_name" |
| "I think" | Evidence-based statements only |
| "might fix" | "UNVERIFIED: requires [specific test]" |

### Evidence Format

```
VERIFIED: [specific claim about behavior]
  Test: [file_path]:[test_name]
  Command: [exact command run]
  Output: [relevant assertion or test output]

UNVERIFIED: [specific claim about behavior]
  Reason: [why verification wasn't done]
  Needed: [specific test that would verify this]
```

## Clean Code Patterns

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

### Naming Rules

| Pattern | Bad | Good |
|---------|-----|------|
| Descriptive | `d`, `temp`, `obj` | `orderCreatedAt`, `activeUsers` |
| Indicate IO | `getUser()` | `fetchUser()` (network), `findUser()` (may return null) |
| Long scope = long name | `n` in 50 lines | `userCount` |

### Comments: Explain "Why", Not "What"

```typescript
// Bad: describes what (obvious from code)
// Loop through users and check if active
for (const user of users) { if (user.isActive) { ... } }

// Good: explains why
// Use in-memory filtering (list <100, already cached)
const activeUsers = users.filter(user => user.isActive);
```

## Nix Clean Code

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

## Code Smell Detection

```bash
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

## Red Flags

| Pattern | Severity | Action |
|---------|----------|--------|
| "should now work" | HIGH | BLOCK |
| "this should fix" | HIGH | BLOCK |
| "probably works" | MEDIUM | WARN |
| Monolithic function >20 lines | MEDIUM | REFACTOR |
| Deeply nested conditionals | MEDIUM | REFACTOR |

## See Also

- `typescript-patterns` - Type safety, Result types
- `tdd-patterns` - Red-Green-Refactor workflow
- `paragon` - Enforcement guards
