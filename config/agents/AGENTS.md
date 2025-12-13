# Agent Bootloader

Senior software engineer. macOS Apple Silicon, zsh, Nix Flakes.

## PARAGON Enforcement

All code changes are enforced by PARAGON (14 guards).
Read `paragon` skill for full guard matrix.

| Layer | Mechanism |
|-------|-----------|
| Claude | PreToolUse hooks (`paragon-guard.ts`) |
| Git | pre-commit hooks (`git-hooks.nix`) |
| CI | GitHub Actions (`paragon-check.yml`) |

**Blocking guards**: bash safety, conventional commits, forbidden files/imports, any type, z.infer, no-mock, TDD, DevOps files/commands, assumption language

**Advisory guards**: flake patterns, port registry, throw detector

## Protocol

**Pull-based context** - dynamically read files, never rely on static dumps.

| Need | Action |
|------|--------|
| **PARAGON guards** | Read `config/agents/skills/paragon/SKILL.md` |
| Stack versions | Read `config/signet/src/stack/versions.ts` |
| Stack rules | Read `config/agents/rules/stack.md` |
| Pattern skills | Read `config/agents/skills/{skill}/SKILL.md` |
| Agent personas | Read `config/agents/agents/{persona}.md` |
| Lessons learned | Read `config/agents/memory/lessons.md` |

## Available Skills

### Nix Build Skills (Critical for TypeScript/Nix projects)

| Skill | Purpose |
|-------|---------|
| `nix-build-optimization` | **Critical** - Derivation splitting, Cachix, CI/CD |
| `nix-infrastructure` | Port registry, nix2container, deployment |
| `nix-flake-parts` | Modular flake composition |
| `nix-darwin-patterns` | macOS system configuration |

**Rule**: Before ANY Nix changes to TypeScript projects, read `nix-build-optimization`.

### Pattern Skills
typescript-patterns, zod-patterns, effect-ts-patterns, result-patterns,
tdd-patterns, clean-code, verification-first, hexagonal-architecture,
devops-patterns, nix-darwin-patterns, nix-flake-parts, nix-build-optimization,
typespec-patterns, hono-workers, tanstack-patterns, signet-patterns,
commit-patterns, planning-patterns, observability-patterns, refactoring-catalog,
formal-verification, semantic-codebase, repomix-patterns, livekit-agents

### MCP Reference Skills
repomix-mcp, context7-mcp

## Agent Personas

critic, synthesizer, code-reviewer, debugger, doc-writer, refactorer, test-writer,
effect-ts-expert, nix-darwin-expert

## Commands

Run `just <task>` for execution. Run `just --list` for available commands.

## Core Rules

- TypeScript types are source of truth (never z.infer)
- Result types for fallible operations (never throw)
- Biome enforced after every code change
- Ban assumption language ("should work" -> "verified via test")
- Conventional commits: type(scope): description
