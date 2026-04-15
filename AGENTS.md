# Dotfiles

Nix-managed macOS configuration for senior engineer building Told (voice memory platform).

> This file mirrors critical rules from CLAUDE.md for Codex CLI sessions.
> Quality hooks, skills, and commands are Claude Code specific and not available here.

## Quick Commands

```bash
just switch        # Rebuild darwin + home-manager
just check         # Validate flake
just health        # Verify system state
```

## Architecture

```
flake.nix                    # Entry point
├── modules/darwin/          # macOS system (dock, keyboard, services)
├── modules/home/            # User config (shell, apps, tools)
│   └── apps/claude.nix     # Claude SSOT (MCP, plugins, marketplaces)
├── config/quality/          # Claude Code hooks + settings generator
│   ├── docs/               # Guards architecture & ADRs
│   ├── src/hooks/          # Pre/Post tool enforcement (Claude Code only)
│   ├── src/stack/          # versions.ts SSOT
│   ├── src/generators/     # settings.json generator
│   └── generated/          # Output (DO NOT EDIT)
├── config/claude/commands/  # Slash commands (Claude Code only)
├── config/claude-code/      # Skills + agents (Claude Code only)
└── hosts/                   # Machine-specific config
```

## Runtime Convention

- **bun**: scripts, MCP servers, tooling wrappers, config/quality hooks, pkgs/*.nix CLI wrappers
- **pnpm + Node.js**: application code (~/src/told), devshells, production

## Rules

- All Claude/Codex config via Nix (never edit ~/.claude/ or ~/.codex/ manually)
- Told is the primary project (Effect-TS, Expo SDK 54, LiveKit)
- Run `just check` before committing Nix changes
- Format with biome, lint with oxlint, typecheck with tsgo for TypeScript files

## Stack (Mar 2026)

| Category | Tools |
|----------|-------|
| Runtime | Node 25, pnpm 10, TypeScript 5.9 |
| Types | tsgo (native preview) for compilation |
| Lint | oxlint (690+ rules, type-aware) |
| Format | biome (format only, no lint) |
| Backend | Effect-TS 3.19, HttpApi, Schema, Layer |
| Frontend | React 19.2, XState 5.25, TanStack Router |
| Mobile | Expo SDK 54, React Native 0.81, NativeWind |
| Voice | LiveKit 2.16, @livekit/agents |
| Infra | Pulumi 3.217, AWS ECS, CloudFront |

## Key Files

- `modules/home/apps/claude.nix` - Claude SSOT (MCP, plugins, marketplaces)
- `config/quality/src/stack/versions.ts` - Version SSOT
- `config/quality/docs/ARCHITECTURE.md` - Guards architecture
- `config/quality/docs/adr/` - Architecture Decision Records

## Quality (Manual in Codex Sessions)

Claude Code enforces quality via PreToolUse/PostToolUse hooks. Codex has no hook equivalent. Manually verify before committing:

```bash
# TypeScript
bunx biome format --write .     # Format
bunx oxlint .                   # Lint

# Nix
nixfmt .                        # Format
statix check .                  # Lint
deadnix .                       # Dead code
just check                      # Flake validation
```
