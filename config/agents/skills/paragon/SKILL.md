---
name: paragon
description: PARAGON Enforcement System - 14 guards for code quality, stack compliance, and evidence-based development.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# PARAGON Enforcement System

> **P**rotocol for **A**utomated **R**ules, **A**nalysis, **G**uards, **O**bservance, and **N**orms

PARAGON is the unified enforcement layer ensuring all code changes comply with engineering standards.

## Enforcement Layers

| Layer | Mechanism | Trigger |
|-------|-----------|---------|
| Claude | PreToolUse hooks (`paragon-guard.ts`) | Every Write/Edit/Bash |
| Git | pre-commit hooks (`git-hooks.nix`) | Every commit |
| CI | GitHub Actions (`paragon-check.yml`) | Every PR/push |

## Guard Matrix (14 Guards)

### Blocking Guards (12)

| # | Guard | Trigger | Blocks |
|---|-------|---------|--------|
| 1 | Bash Safety | Bash | `rm -rf /`, `rm -rf ~` |
| 2 | Conventional Commits | Bash(git commit) | Non-conventional messages |
| 3 | Forbidden Files | Write | package-lock.json, eslint, prettier, jest, prisma, Docker |
| 4 | Forbidden Imports | Write/Edit TS | express, fastify, prisma, zod/v3, GCP OTEL, dd-trace |
| 5 | Any Type | Write/Edit TS | `: any`, `as any`, `<any>` |
| 6 | z.infer | Write/Edit TS | `z.infer<>`, `z.input<>`, `z.output<>` |
| 7 | No-Mock | Write/Edit TS | jest.mock, vi.mock, Mock*Live, Fake*, Stub* |
| 8 | TDD | Write source | Source files without corresponding test |
| 9 | DevOps Files | Write | Dockerfile, docker-compose.yml, .dockerignore |
| 10 | DevOps Commands | Bash | docker-compose up, docker build, npm run dev |
| 13 | Assumption Language | Write/Edit TS | "should work", "probably", "I think", "might" |
| 14 | Throw Detector | Write/Edit TS | `throw` for expected errors (invariants allowed) |

### Advisory Guards (2)

| # | Guard | Trigger | Warns |
|---|-------|---------|-------|
| 11 | Flake Patterns | Write flake.nix | Missing flake-parts, forAllSystems |
| 12 | Port Registry | Write modules/*.nix | Undeclared ports |

## Verification-First Philosophy

Every claim must be backed by evidence:

| BANNED | REQUIRED |
|--------|----------|
| "should now work" | "VERIFIED via test: [assertion passed]" |
| "this should fix" | "UNVERIFIED: requires [test_name]" |
| "probably works" | "confirmed by running: [command]" |
| "I think this" | Evidence-based statements only |
| "might fix" | "UNVERIFIED: requires [specific test]" |

## Blocked Files (Guard 3)

| Pattern | Alternative |
|---------|-------------|
| `package-lock.json` | `bun install` (bun.lock) |
| `yarn.lock` | `bun install` |
| `.eslintrc*` | `biome.json` |
| `.prettierrc*` | `biome.json` |
| `jest.config.*` | `bun test` |
| `prisma/schema.prisma` | `drizzle.config.ts` |
| `Dockerfile*` | `nix2container` |
| `docker-compose.*` | `process-compose.yaml` |

## Blocked Commands (Guard 10)

| Command | Alternative |
|---------|-------------|
| `docker-compose up` | `process-compose up` |
| `docker build` | `nix build .#<name>Image` |
| `npm run dev` | `process-compose up` or `just dev` |
| `bun run dev` | `process-compose up` or `just dev` |

## Implementation Files

| File | Purpose |
|------|---------|
| `config/agents/hooks/paragon-guard.ts` | PreToolUse enforcement |
| `flake/hooks.nix` | git-hooks.nix pre-commit config |
| `.github/workflows/paragon-check.yml` | CI enforcement |
| `scripts/verify-paragon.sh` | Manual verification |

## Bypasses

```bash
# TDD bypass (temporary - delete after)
touch .tdd-skip
```

## Related Skills

| Skill | Relationship |
|-------|--------------|
| `verification-first` | Evidence language patterns |
| `tdd-patterns` | Red-Green-Refactor workflow |
| `result-patterns` | Error handling without throw |
| `typescript-patterns` | Type-first development |
| `zod-patterns` | satisfies pattern (never z.infer) |
| `devops-patterns` | Nix-first DevOps philosophy |
| `hexagonal-architecture` | No-mock testing patterns |

## Quick Reference

```bash
# Verify PARAGON compliance
just verify-paragon

# Enter dev shell with hooks
nix develop

# Run pre-commit manually
just lint-staged
```
