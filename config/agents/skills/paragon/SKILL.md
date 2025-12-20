---
name: paragon
description: PARAGON Enforcement System v3.5 - 49 guards for Clean Code, SOLID, configuration centralization, stack compliance, parse-at-boundary, and evidence-based development.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
token-budget: 500
version: 3.5.0
references:
  - references/guards-detail.md: "Detailed guard explanations (Tiers 3-8)"
  - references/bypasses.md: "Bypass mechanisms and refactoring catalog"
---

# PARAGON Enforcement System v3.5

> **P**rotocol for **A**utomated **R**ules, **A**nalysis, **G**uards, **O**bservance, and **N**orms
>
> "The only way to go fast is to go well." — Uncle Bob

## Enforcement Layers

| Layer | Mechanism | Trigger |
|-------|-----------|---------|
| Claude | PreToolUse hooks (`paragon-guard.ts`) | Every Write/Edit/Bash |
| Git | pre-commit hooks (`git-hooks.nix`) | Every commit |
| CI | GitHub Actions (`paragon-check.yml`) | Every PR/push |

## Guard Matrix Summary (49 Guards)

### Tier 1: Original Guards (1-14) - BLOCKING

| # | Guard | Blocks |
|---|-------|--------|
| 1 | Bash Safety | `rm -rf /`, `rm -rf ~` |
| 2 | Conventional Commits | Non-conventional messages |
| 3 | Forbidden Files | package-lock, bun.lock, eslint, jest, .env |
| 4 | Forbidden Imports | express, prisma, zod/v3, dd-trace |
| 5 | Any Type | `: any`, `as any`, `<any>` |
| 6 | z.infer | `z.infer<>`, `z.input<>`, `z.output<>` |
| 7 | No-Mock | jest.mock, vi.mock |
| 8 | TDD | Source without test |
| 9 | DevOps Files | process-compose.yaml, .env |
| 10 | DevOps Commands | bun run/test/install |
| 13 | Assumption Language | "should work", "probably" |
| 14 | Throw Detector | `throw` for expected errors |

### Tier 2: Clean Code (15-17)

| # | Guard | Blocks |
|---|-------|--------|
| 15 | No Comments | Unnecessary inline comments |
| 16 | Meaningful Names | Cryptic abbrevs, Hungarian notation |
| 17 | No Commented-Out Code | Dead code in comments |

### Quick Reference (Tiers 3-8)

See `references/guards-detail.md` for full details on:
- Tier 3: Extended Clean Code (18-25)
- Tier 4: Tooling Guards (26-27)
- Tier 5: Configuration Guards (28-30)
- Tier 6: Stack Compliance (31)
- Tier 7: Parse-at-Boundary (32-39)
- Tier 8: Parse Don't Validate (40-49)

## Verification-First Philosophy

| BANNED | REQUIRED |
|--------|----------|
| "should work" | "VERIFIED via test: [assertion]" |
| "this should fix" | "UNVERIFIED: requires [test]" |
| "probably works" | "confirmed by running: [cmd]" |
| "I think" | Evidence-based statements |

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

## Quick Commands

```bash
# Verify PARAGON compliance
just verify-paragon

# Run pre-commit manually
just lint-staged

# Run ast-grep validation
sg scan --rule config/agents/rules/paragon-combined.yaml .

# Skip specific guard (emergency)
touch .paragon-skip-31
```

## Related Skills

| Skill | Relationship |
|-------|--------------|
| `typescript-patterns` | Type-first, Result types |
| `effect-ts-patterns` | Typed errors, Layer DI |
| `tdd-patterns` | Red-Green-Refactor |
| `hexagonal-architecture` | No-mock testing |
| `parse-boundary-patterns` | Guards 32-39 patterns |
