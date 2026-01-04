# Dotfiles

Declarative system configuration for macOS via Nix Flakes.

## Quick Start

```bash
# One command to rule them all
darwin-rebuild switch --flake ~/dotfiles
```

This single command:
1. Rebuilds nix-darwin system configuration
2. Applies Home Manager user configuration
3. Generates Quality System artifacts (skills, personas, memories)
4. Symlinks Claude Code/Desktop config
5. Validates all checks pass

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Nix Flakes                                    │
│  flake.nix → flake/                                                     │
│  ├── darwin.nix      (macOS system config)                             │
│  ├── home.nix        (user environment)                                │
│  └── checks.nix      (CI validation)                                   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                         darwin-rebuild switch
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        Quality System                                   │
│  config/quality/src/                                                    │
│  ├── memories/     (17 engineering patterns)                           │
│  ├── critic-mode/  (5 metacognitive behaviors)                         │
│  ├── skills/       (9 domain skills)                                   │
│  ├── personas/     (6 AI personas)                                     │
│  ├── rules/        (12 AST-based rules)                                │
│  ├── stack/        (frozen versions SSOT)                              │
│  └── hooks/        (PARAGON enforcement)                               │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                           bun run generate
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        Generated Output                                 │
│  config/quality/generated/                                              │
│  ├── memories.md       (canonical engineering knowledge)               │
│  ├── critic-mode.md    (self-review protocol)                          │
│  ├── settings.json     (Claude Code settings)                          │
│  ├── skills/           (SKILL.md files)                                │
│  └── personas/         (persona.md files)                              │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                          Home Manager symlinks
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         Runtime Config                                  │
│  ~/.claude/                                                             │
│  ├── settings.json → generated/settings.json                           │
│  ├── skills/       → generated/skills/                                 │
│  └── agents/       → generated/personas/                               │
│                                                                         │
│  ~/.config/claude/mcp-servers.json  (12 MCP servers)                   │
└─────────────────────────────────────────────────────────────────────────┘
```

## Quality System

The Quality System is a TypeScript-based code quality framework that generates Claude Code configuration from a single source of truth.

### Components

| Component | Count | Description |
|-----------|-------|-------------|
| Memories | 17 | Engineering patterns (principles, constraints, patterns, gotchas) |
| Critic Behaviors | 5 | Metacognitive protocols (3 planning, 2 execution) |
| Skills | 9 | Domain expertise (Effect-TS, testing, observability, etc.) |
| Personas | 6 | AI agent configurations (effect-architect, debugger, etc.) |
| Rules | 12 | AST-based code validation (no-any, no-try-catch, etc.) |

### PARAGON Guards

49 quality guards enforced at multiple layers:

| Layer | Mechanism |
|-------|-----------|
| Claude | PreToolUse hooks (`paragon-guard.ts`) |
| Git | pre-commit hooks (`git-hooks.nix`) |
| CI | GitHub Actions (`paragon-check.yml`) |

**Blocking guards**: bash safety, conventional commits, forbidden files/imports, any type, z.infer, no-mock, TDD, DevOps files/commands, assumption language

## MCP Servers

6 Model Context Protocol servers configured (optimized Jan 2026):

| Server | Purpose |
|--------|---------|
| ref | SOTA documentation search (60-95% fewer tokens) |
| exa | Code context search across repos |
| github | GitHub API integration |
| playwright | Browser automation |
| ast-grep | AST-based code search |
| repomix | Codebase packaging for AI |

## Development

```bash
# Run Quality System tests
cd config/quality && bun test

# Regenerate artifacts
cd config/quality && bun run generate

# Full validation
cd config/quality && bun run validate

# Check Nix flake
nix flake check

# Rebuild system
darwin-rebuild switch --flake ~/dotfiles
```

## Directory Structure

```
~/dotfiles/
├── flake.nix              # Nix flake entry point
├── flake/                  # Flake modules
│   ├── darwin.nix         # macOS system config
│   ├── home.nix           # User environment
│   └── checks.nix         # CI validation
├── modules/               # Nix modules
│   ├── darwin/            # nix-darwin modules
│   └── home/              # Home Manager modules
├── config/                # Configuration sources
│   ├── quality/           # Quality System (TypeScript)
│   └── agents/            # Claude Code agent configs
└── .github/workflows/     # CI workflows
```

## Conventions

- **TypeScript types are SSOT**: Define Effect Schema first, derive types via `Schema.Type`
- **Result types for errors**: Never throw, use `Effect<A, E, R>` or `Either<A, E>`
- **Parse at boundaries**: `Schema.decodeUnknown` at entry points, trust types internally
- **Single source of truth**: versions.ts for deps, ports.nix for ports
- **Conventional commits**: `type(scope): description`
