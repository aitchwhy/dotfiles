---
name: paragon
description: PARAGON Enforcement System v2.2 - 27 guards for Clean Code, SOLID, and evidence-based development.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
token-budget: 800
version: 2.2.0
---

# PARAGON Enforcement System v2.2

> **P**rotocol for **A**utomated **R**ules, **A**nalysis, **G**uards, **O**bservance, and **N**orms
>
> "The only way to go fast is to go well." — Uncle Bob

PARAGON is the unified enforcement layer ensuring all code changes comply with:
- Uncle Bob's Clean Code principles
- SOLID design principles
- Stack-specific conventions
- Evidence-based development

## Enforcement Layers

| Layer | Mechanism | Trigger |
|-------|-----------|---------|
| Claude | PreToolUse hooks (`paragon-guard.ts`) | Every Write/Edit/Bash |
| Git | pre-commit hooks (`git-hooks.nix`) | Every commit |
| CI | GitHub Actions (`paragon-check.yml`) | Every PR/push |

## Guard Matrix (27 Guards)

### Tier 1: Original Guards (1-14)

| # | Guard | Trigger | Blocks |
|---|-------|---------|--------|
| 1 | Bash Safety | Bash | `rm -rf /`, `rm -rf ~` |
| 2 | Conventional Commits | Bash(git commit) | Non-conventional messages |
| 3 | Forbidden Files | Write | package-lock, eslint, prettier, jest, prisma, Docker |
| 4 | Forbidden Imports | Write/Edit TS | express, fastify, prisma, zod/v3, GCP OTEL, dd-trace |
| 5 | Any Type | Write/Edit TS | `: any`, `as any`, `<any>` |
| 6 | z.infer | Write/Edit TS | `z.infer<>`, `z.input<>`, `z.output<>` |
| 7 | No-Mock | Write/Edit TS | jest.mock, vi.mock, Mock*Live (Layer.succeed ALLOWED) |
| 8 | TDD | Write source | Source files without corresponding test |
| 9 | DevOps Files | Write | Dockerfile, docker-compose.yml |
| 10 | DevOps Commands | Bash | docker-compose, docker build, npm run dev |
| 13 | Assumption Language | Write/Edit TS | "should work", "probably", "I think" |
| 14 | Throw Detector | Write/Edit TS | `throw` for expected errors |

### Tier 1: Advisory Guards

| # | Guard | Trigger | Warns |
|---|-------|---------|-------|
| 11 | Flake Patterns | Write flake.nix | Missing flake-parts, forAllSystems |
| 12 | Port Registry | Write modules/*.nix | Undeclared ports |

### Tier 2: Clean Code Guards (15-17) - Uncle Bob

| # | Guard | Chapter | Blocks |
|---|-------|---------|--------|
| 15 | No Comments | Ch. 4 | Unnecessary inline comments |
| 16 | Meaningful Names | Ch. 2 | Cryptic abbrevs, Hungarian notation |
| 17 | No Commented-Out Code | Ch. 4 | Dead code in comments |

### Tier 3: Extended Clean Code (18-25) - Uncle Bob + SOLID

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

### Tier 4: Tooling Guards (26-27)

| # | Guard | Trigger | Blocks |
|---|-------|---------|--------|
| 26 | No Console | Write/Edit TS | `console.log`, `console.error`, `console.warn`, `console.debug`, `console.info` |
| 27 | Modern CLI Tools | Bash/Write | `grep`, `find`, `ls`, `du` (use rg, fd, eza, dust) |

**Guard 26 Rationale**: Use Effect-TS logging for structured, typed logging:
```typescript
// BAD - blocked
console.log('Processing', data);
console.error('Failed:', error);

// GOOD - Effect-TS logging
yield* Effect.log('Processing', data);
yield* Effect.logError('Failed', error);
```

**Guard 27 Rationale**: Use modern Rust CLI tools for speed, safety, and readability:
```bash
# BAD - blocked
grep -r "pattern" .
find . -name "*.ts"
ls -la
du -sh

# GOOD - Modern tools
rg "pattern" .       # ripgrep
fd -e ts            # fd
eza -la             # eza
dust                # dust
```

## Infinite Loop Prevention

Guards 18-26 include protection against refactoring loops:

| Mechanism | Description |
|-----------|-------------|
| Per-file cooldown | 30s between checks on same file |
| Max iterations | 3 guard-triggered edits per file |
| Guard groups | Related guards skip if sibling fired |
| Bypass files | `.paragon-skip`, `.paragon-skip-{N}` |
| Refactoring marker | `.paragon-refactoring` for sessions |

Guard groups:
- **naming**: 14, 16, 18 (names & args)
- **structure**: 20, 21, 25 (size, complexity, nesting)
- **patterns**: 19, 22, 23 (demeter, switch, null)
- **comments**: 15, 17 (comments & dead code)

## Bypasses

```bash
# Skip ALL guards (emergency only)
touch .paragon-skip

# Skip specific guard
touch .paragon-skip-20  # Skip function size guard

# Refactoring session (logs but doesn't block)
touch .paragon-refactoring

# TDD bypass (temporary)
touch .tdd-skip
```

## Verification-First Philosophy

| BANNED | REQUIRED |
|--------|----------|
| "should work" | "VERIFIED via test: [assertion]" |
| "this should fix" | "UNVERIFIED: requires [test]" |
| "probably works" | "confirmed by running: [cmd]" |
| "I think" | Evidence-based statements |
| "might fix" | "UNVERIFIED: requires [test]" |

## Clean Code Principles Enforced

| Principle | Guard(s) |
|-----------|----------|
| Functions should be small | 20, 21 |
| Few arguments | 18 |
| Meaningful names | 16 |
| Don't comment bad code | 15, 17 |
| Law of Demeter | 19 |
| No null returns | 23 |
| Guard clauses over nesting | 25 |
| Polymorphism over switch | 22 |

## SOLID Principles Enforced

| Principle | Guard(s) |
|-----------|----------|
| Interface Segregation | 24 |
| Dependency Inversion | 7 (Layer.succeed ALLOWED) |

## Implementation Files

| File | Purpose |
|------|---------|
| `config/agents/hooks/paragon-guard.ts` | PreToolUse enforcement (27 guards) |
| `config/agents/rules/ast-grep/no-legacy-tools.yml` | Guard 27 AST-grep rule |
| `flake/hooks.nix` | git-hooks.nix pre-commit |
| `.github/workflows/paragon-check.yml` | CI enforcement |
| `scripts/verify-paragon.sh` | Manual verification |

## Related Skills

| Skill | Relationship |
|-------|--------------|
| `typescript-patterns` | Type-first, Result types |
| `effect-ts-patterns` | Typed errors, Layer DI |
| `tdd-patterns` | Red-Green-Refactor |
| `hexagonal-architecture` | No-mock testing |
| `quality-patterns` | Additional code quality |

## Fowler Refactoring Catalog Integration

PARAGON cleanup maps code smells to [Fowler's Refactoring Catalog](https://refactoring.com/catalog/).

### Code Smell → Refactoring Mapping

| Code Smell | Category | Refactoring |
|------------|----------|-------------|
| Long Method | Bloaters | ExtractFunction |
| Long Parameter List | Bloaters | IntroduceParameterObject |
| Primitive Obsession | Bloaters | ReplacePrimitiveWithObject |
| Data Clumps | Bloaters | ExtractClass |
| Switch Statements | OO-Abusers | ReplaceConditionalWithPolymorphism |
| Temporary Field | OO-Abusers | ExtractClass |
| Feature Envy | Couplers | MoveFunction |
| Message Chains | Couplers | HideDelegate |
| Comments | Dispensables | ExtractFunction, RenameVariable |
| Dead Code | Dispensables | RemoveDeadCode |
| Duplicate Code | Dispensables | ExtractFunction |
| Deep Nesting | Change-Preventers | ReplaceNestedConditionalWithGuardClauses |

### Core Refactorings (Most Used)

1. **Extract Function** - Any code fragment with semantic meaning
2. **Replace Nested Conditional with Guard Clauses** - Deep nesting → early returns
3. **Introduce Parameter Object** - >3 parameters → single object
4. **Replace Conditional with Polymorphism** - switch on type → handler map
5. **Replace Loop with Pipeline** - for loops → filter/map/reduce

### Cleanup Hook

The `paragon-cleanup.ts` hook runs automatically:
- **PostToolUse**: Incremental analysis on changed files
- **Stop**: Full codebase analysis at session end

```bash
# Run cleanup manually
just agents paragon-clean

# View cleanup statistics
just agents paragon-stats
```

## Quick Reference

```bash
# Verify PARAGON compliance
just verify-paragon

# Run pre-commit manually
just lint-staged

# Check specific guard
./scripts/verify-paragon.sh

# Run cleanup manually
just agents paragon-clean

# View cleanup metrics
just agents paragon-stats
```
