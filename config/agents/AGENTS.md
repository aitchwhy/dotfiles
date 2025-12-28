# Agent Bootloader

Senior software engineer. macOS Apple Silicon, zsh, Nix Flakes.

## PARAGON Enforcement

All code changes are enforced by PARAGON (49 guards).
Read `paragon` skill for full guard matrix.

| Layer  | Mechanism                             |
| ------ | ------------------------------------- |
| Claude | PreToolUse hooks (`paragon-guard.ts`) |
| Git    | pre-commit hooks (`git-hooks.nix`)    |
| CI     | GitHub Actions (`paragon-check.yml`)  |

**Blocking guards**: bash safety, conventional commits, forbidden files/imports, any type, z.infer, no-mock, TDD, DevOps files/commands, assumption language

**Advisory guards**: flake patterns, port registry, throw detector

## Protocol

**Pull-based context** - dynamically read files, never rely on static dumps.

| Need                     | Action                                                     |
| ------------------------ | ---------------------------------------------------------- |
| **PARAGON guards**       | Read `config/brain/generated/claude/skills/paragon.md`     |
| Stack versions           | Read `config/brain/src/stack/versions.ts`                  |
| Stack rules              | Read `config/brain/docs/stack.md`                          |
| Pattern skills           | Read `config/brain/generated/claude/skills/{skill}.md`     |
| Agent personas           | Read `config/brain/generated/claude/personas/{persona}.md` |
| **Canonical memories**   | Read `config/brain/generated/claude/memories.md`           |
| **Critic-mode protocol** | Read `config/brain/generated/claude/critic-mode.md`        |

## Available Skills

### Nix Skills (Dotfiles ONLY)

| Skill                              | Purpose                                  |
| ---------------------------------- | ---------------------------------------- |
| `nix-patterns`                     | nix-darwin, Home Manager (DOTFILES ONLY) |
| `nix-configuration-centralization` | Port registry for dotfiles               |
| `secrets-management`               | sops-nix patterns                        |

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

**ALWAYS use modern alternatives** - legacy commands (`grep`, `find`, `ls`, `cat`) are discouraged.

### ripgrep (`rg`) - replaces `grep`

```bash
# Basic search (recursive by default, respects .gitignore)
rg "pattern"                    # NOT: grep -r "pattern"
rg "pattern" src/               # search in specific directory
rg -i "pattern"                 # case-insensitive
rg -w "word"                    # whole word match
rg -l "pattern"                 # list files only (like grep -l)
rg -c "pattern"                 # count matches per file
rg -A3 -B3 "pattern"            # context lines (after/before)
rg --type ts "pattern"          # filter by file type
rg -g "*.nix" "pattern"         # filter by glob
rg -F "literal.string"          # literal string (no regex)
rg --hidden "pattern"           # include hidden files
```

### fd - replaces `find`

```bash
# Basic search (recursive, respects .gitignore)
fd "pattern"                    # NOT: find . -name "*pattern*"
fd -e nix                       # by extension: find . -name "*.nix"
fd -e ts -e tsx                 # multiple extensions
fd "^config"                    # regex: names starting with "config"
fd -t f                         # files only (type: f=file, d=dir, l=symlink)
fd -t d                         # directories only
fd -H "pattern"                 # include hidden files
fd -I "pattern"                 # include gitignored files
fd -x cmd {}                    # execute command on each result
fd -X cmd                       # execute command with all results as args
fd . -e ts --exec wc -l         # count lines in all .ts files
```

### eza - replaces `ls`

```bash
# Basic listing
eza                             # NOT: ls
eza -l                          # long format with git status
eza -la                         # include hidden files
eza -lah                        # with human-readable sizes
eza -T                          # tree view
eza -T -L 2                     # tree with depth limit
eza -l --git                    # show git status column
eza -l --icons                  # with file type icons
eza --group-directories-first   # dirs first
eza -l -s modified              # sort by modified time
eza -l -s size                  # sort by size
```

### bat - replaces `cat`

```bash
# View files with syntax highlighting
bat file.ts                     # NOT: cat file.ts
bat -n file.ts                  # with line numbers only (no decorations)
bat -p file.ts                  # plain output (like cat)
bat -l nix file                 # force language syntax
bat --style=numbers file.ts     # minimal style with line numbers
bat -r 10:20 file.ts            # show only lines 10-20
```

### Key Differences from Legacy Commands

| Legacy               | Modern     | Key Syntax Difference                     |
| -------------------- | ---------- | ----------------------------------------- |
| `grep -r`            | `rg`       | Recursive by default, no `-r` needed      |
| `grep -E`            | `rg`       | Extended regex by default, no `-E` needed |
| `find . -name "*.x"` | `fd -e x`  | Extension flag, no quotes needed          |
| `find . -type f`     | `fd -t f`  | Shorter type flag                         |
| `ls -la`             | `eza -la`  | Same flags, better output                 |
| `cat file`           | `bat file` | Same syntax, adds highlighting            |
