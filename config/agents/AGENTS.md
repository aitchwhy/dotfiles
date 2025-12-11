# Agent Bootloader

Senior software engineer. macOS Apple Silicon, zsh, Nix Flakes.

## Protocol

**Pull-based context** - dynamically read files, never rely on static dumps.

| Need | Action |
|------|--------|
| Stack versions | Read `config/signet/src/stack/versions.ts` |
| Stack rules | Read `config/agents/rules/stack.md` |
| Pattern skills | Read `config/agents/skills/{skill}/SKILL.md` |
| Agent personas | Read `config/agents/agents/{persona}.md` |
| Lessons learned | Read `config/agents/memory/lessons.md` |

## Available Skills

typescript-patterns, zod-patterns, effect-ts-patterns, result-patterns,
tdd-patterns, clean-code, verification-first, hexagonal-architecture,
devops-patterns, nix-darwin-patterns, nix-flake-parts, typespec-patterns,
hono-workers, tanstack-patterns, signet-patterns, commit-patterns,
planning-patterns, observability-patterns, refactoring-catalog,
formal-verification, semantic-codebase, repomix-patterns, livekit-agents

## Agent Personas

critic, synthesizer, code-reviewer, debugger, doc-writer, refactorer, test-writer

## Commands

Run `just <task>` for execution. Run `just --list` for available commands.

## Core Rules

- TypeScript types are source of truth (never z.infer)
- Result types for fallible operations (never throw)
- Biome enforced after every code change
- Ban assumption language ("should work" -> "verified via test")
- Conventional commits: type(scope): description
