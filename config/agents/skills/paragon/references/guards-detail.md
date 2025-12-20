# PARAGON Guard Details

## Tier 3: Extended Clean Code (18-25)

| # | Guard | Category | Blocks |
|---|-------|----------|--------|
| 18 | Function Arguments | Ch. 3 | >3 positional parameters |
| 19 | Law of Demeter | Ch. 6 | Method chains `a.b().c().d()` |
| 20 | Function Size | Ch. 3 | Functions >20 lines |
| 21 | Cyclomatic Complexity | Ch. 3 | >10 branches per function |
| 22 | Switch on Type | Ch. 3 | `switch(x.type)` anti-pattern |
| 23 | Null Returns | Ch. 7 | `return null;` |
| 24 | Interface Segregation | SOLID | Interfaces >7 members |
| 25 | Deep Nesting | Ch. 3 | >3 indent levels |

## Tier 4: Tooling Guards (26-27)

| # | Guard | Trigger | Blocks |
|---|-------|---------|--------|
| 26 | No Console | Write/Edit TS | `console.log`, `console.error`, `console.warn` |
| 27 | Modern CLI Tools | Bash/Write | `grep`, `find`, `ls`, `du` |

**Guard 26 Rationale**: Use Effect-TS logging:
```typescript
// BAD - blocked
console.log('Processing', data);

// GOOD - Effect-TS logging
yield* Effect.log('Processing', data);
```

**Guard 27 Rationale**: Use modern Rust CLI tools:
```bash
# BAD - blocked
grep -r "pattern" .

# GOOD - Modern tools
rg "pattern" .       # ripgrep
```

## Tier 5: Configuration Guards (28-30)

| # | Guard | Trigger | Blocks |
|---|-------|---------|--------|
| 28 | No Hardcoded Ports | Write .nix | Port numbers outside lib/config/ |
| 29 | No Split-Brain Config | sig-config | Same value in 2+ .nix files |
| 30 | Config Reference Required | Write .nix | localhost URLs outside lib/config/ |

**Guard 28 Example**:
```nix
# BAD - blocked
services.foo.port = 3000;

# GOOD - use lib/config reference
let cfg = import ../../../lib/config { inherit lib; }; in
services.foo.port = cfg.ports.development.api;
```

## Tier 6: Stack Compliance (31)

**Guard 31 Rationale**: Enforce stack standards:
```json
// BAD - blocked (forbidden deps)
{
  "dependencies": {
    "lodash": "^4.17.0",    // Use native methods or Effect
    "express": "^4.18.0",   // Use @effect/platform HttpApiBuilder
    "prisma": "^5.0.0"      // Use Drizzle instead
  }
}
```

## Tier 7: Parse-at-Boundary Guards (32-39)

| # | Guard | Trigger | Blocks |
|---|-------|---------|--------|
| 32 | Optional Chaining in Non-Boundary | Write/Edit TS | `x?.y` in domain code |
| 33 | Nullish Coalescing in Non-Boundary | Write/Edit TS | `x ?? y` in domain code |
| 34 | Null Check Then Assert | Write/Edit TS | `if (x === null) ... x!` |
| 35 | Type Assertions | Write/Edit TS | `x as Type` (warning only) |
| 36 | Non-Null Assert Without Narrowing | Write/Edit TS | `x!` without type guard |
| 37 | Nullable Union in Context | Write/Edit TS | `string \| null` in Context types |
| 38 | Truthiness Check | Write/Edit TS | `if (value)` implicit checks |
| 39 | Undefined Check in Domain | Write/Edit TS | `=== undefined` in domain code |

**Boundary files** (where optional chaining IS allowed):
- `*/api/*.ts` - API route handlers
- `*/lib/*-client.ts` - API clients
- `*.schema.ts` - Schema definitions
- `*.test.ts`, `*.spec.ts` - Test files

## Tier 8: Parse Don't Validate Guards (40-48)

| # | Guard | Severity | Blocks |
|---|-------|----------|--------|
| 40 | Type Assertion | error | `as Type`, `as { ... }` |
| 41 | Null Propagation | error | `?? null` (spreads null virus) |
| 42 | Uncontrolled Date | error | `new Date()`, `Date.now()` |
| 43 | Try/Catch in Domain | error | `try/catch` outside boundary |
| 44 | Raw Fetch | error | `fetch()` (use Effect HttpClient) |
| 45 | Nullable Union | warning | `T \| null` in type definitions |
| 46 | Undefined Union | warning | `T \| undefined` in type definitions |
| 47 | pg Driver | error | `from 'pg'` (use postgres.js) |
| 48 | Non-Null Assertion | error | `x!`, `foo.bar!` |
| 49 | No Jest | error | `jest.*`, `from 'jest'` |
