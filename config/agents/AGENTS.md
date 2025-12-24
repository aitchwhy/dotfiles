# Agent Bootloader

Senior software engineer. macOS Apple Silicon, zsh, Nix Flakes.

## PARAGON Enforcement

All code changes are enforced by PARAGON (49 guards).
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
| Stack versions | Read `config/quality/src/stack/versions.ts` |
| Stack rules | Read `config/quality/docs/stack.md` |
| Pattern skills | Read `config/agents/skills/{skill}/SKILL.md` |
| Agent personas | Read `config/agents/agents/{persona}.md` |
| **Canonical memories** | Read `config/quality/generated/memories.md` |
| **Critic-mode protocol** | Read `config/quality/generated/critic-mode.md` |

## Available Skills

### Nix Skills (Dotfiles ONLY)

| Skill | Purpose |
|-------|---------|
| `nix-patterns` | nix-darwin, Home Manager (DOTFILES ONLY) |
| `nix-configuration-centralization` | Port registry for dotfiles |
| `secrets-management` | sops-nix patterns |

**DELETED**: `nix-infrastructure`, `nix-build-optimization` (use `devops-patterns` for Docker)

**Scope**: Nix is ONLY for dotfiles management. Development uses Docker Compose.

### Core Pattern Skills
typescript-patterns, effect-ts-patterns, quality-patterns,
hexagonal-architecture, formal-verification, tdd-patterns, parse-boundary-patterns

### Effect-TS Skills
effect-resilience, api-contract

### Nix Skills (Dotfiles Only)
nix-patterns, nix-configuration-centralization, secrets-management

### Framework Skills
state-machine-patterns, observability-patterns

### DevOps/Workflow Skills
devops-patterns, gha-oidc-patterns, planning-patterns, typespec-patterns, pulumi-esc

### Reference Skills
repomix, context7-mcp

### Specialized Skills
livekit-agents, refactoring-catalog, semantic-codebase

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

## CLI Tool Preferences

**Always use modern alternatives** instead of legacy commands:

| Instead of | Use | Reason |
|------------|-----|--------|
| `grep` | `rg` (ripgrep) | Faster, respects .gitignore, better defaults |
| `find` | `fd` | Simpler syntax, faster, respects .gitignore |
| `ls` | `eza` | Better formatting, git integration, colors |
| `cat` | `bat` | Syntax highlighting, line numbers |

Examples:
- `rg "pattern"` not `grep -r "pattern"`
- `fd "*.nix"` not `find . -name "*.nix"`
- `eza -la` not `ls -la`
- `bat file.ts` not `cat file.ts`
