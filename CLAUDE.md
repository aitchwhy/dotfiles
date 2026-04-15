# Dotfiles

Nix-managed macOS configuration for senior engineer building Told (voice memory platform).

## Quick Commands

```bash
just switch        # Rebuild darwin + home-manager
just check         # Validate flake
just health        # Verify system state

cd config/quality
bun run generate   # Regenerate settings.json
bun run typecheck  # Check types
```

## Workflow Commands (Claude Code)

| Command | Description |
|---------|-------------|
| /switch | Rebuild Nix system configuration |
| /generate | Regenerate settings.json from SSOT |
| /commit | Git add, commit, and push |
| /linear | Manage Linear tickets (get, transition, comment) |
| /plan-ticket | Plan + implement a Linear ticket |

## Architecture

```
flake.nix                    # Entry point
├── modules/darwin/          # macOS system (dock, keyboard, services)
├── modules/home/            # User config (shell, apps, tools)
│   └── apps/claude.nix     # Claude SSOT (MCP, plugins, marketplaces)
├── config/quality/          # Claude Code hooks + settings generator
│   ├── docs/               # Guards architecture & ADRs
│   ├── src/hooks/          # Pre/Post tool enforcement
│   ├── src/stack/          # versions.ts SSOT
│   ├── src/generators/     # settings.json generator
│   └── generated/          # Output (DO NOT EDIT)
├── config/claude/commands/  # Slash commands (add-app, clean-claude, commit)
├── config/claude-code/      # Skills (/linear, /plan-ticket) + agents (architect)
└── hosts/                   # Machine-specific config
```

## Runtime Convention

- **bun**: scripts, MCP servers, tooling wrappers, config/quality hooks, pkgs/*.nix CLI wrappers
- **pnpm + Node.js**: application code (~/src/told), devshells, production

## Rules

- All Claude config via Nix (never edit ~/.claude/ manually)
- Hooks enforce quality at tool-use time (format, lint, typecheck)
- AST-grep rules delegated to project-level sgconfig.yml
- Told is the primary project (Effect-TS, Expo SDK 54, LiveKit)

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

## MCP Servers

| Server | Level | Purpose |
|--------|-------|---------|
| ref | user | SOTA docs (60-95% fewer tokens) |

## Vendor Skills (GraphQL API, no MCP)

| Skill | Purpose |
|-------|---------|
| /linear | Linear ticket management (get, transition, comment) via GraphQL API |

## Plugins (MINIMAL - 0)

None.

## Network & API Tools (Minimal)

| Tool | Purpose |
|------|---------|
| speedtest | Internet speed (Ookla) |
| trippy | Network path (mtr+traceroute+ping) |
| rustscan | Port scanning |
| bandwhich | Bandwidth by process |
| termshark | Packet inspection |
| xh | HTTP client (Rust) |
| Proxyman | HTTP proxy (GUI) |
| yaak | API collections (GUI) |

See [ADR-009](config/quality/docs/adr/009-network-api-toolkit.md) for full details.

## Sub-Configuration Docs

| Path | Domain |
|------|--------|
| `config/hazel/CLAUDE.md` | Hazel file automation rules & scripts |

## Known Gaps

- **Told guard gap**: When working in ~/src/told, Told's PreToolUse replaces dotfiles' PreToolUse via deep merge with array replacement. Guards 3 (forbidden files), 32 (secrets detection), 33 (hook bypass prevention) do NOT run in Told. Tracked in Linear.

## Codex Cross-Reference

`AGENTS.md` at repo root is the Codex-compatible instruction file — a subset of this file excluding hooks, skills, agents, and MCP config. See `config/quality/docs/drift-governance.md` for the sync process.

## Key Files

- `modules/home/apps/claude.nix` - Claude SSOT (MCP, plugins, marketplaces)
- `config/quality/src/stack/versions.ts` - Version SSOT
- `config/quality/src/hooks/` - Pre/post tool hooks
- `config/quality/src/generators/claude/settings.generator.ts` - Settings generator
- `config/quality/docs/ARCHITECTURE.md` - Guards architecture
- `config/quality/docs/adr/` - Architecture Decision Records
