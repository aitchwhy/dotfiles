# Dotfiles

Nix-managed macOS configuration for senior engineer building Told (voice memory platform).

## Quick Commands

```bash
just switch        # Rebuild darwin + home-manager
just check         # Validate flake
just health        # Verify system state

cd config/quality
bun run generate   # Regenerate Claude artifacts
bun run typecheck  # Check types
bun run test       # Run tests
```

## Architecture

```
flake.nix                    # Entry point
├── modules/darwin/          # macOS system (dock, keyboard, services)
├── modules/home/            # User config (shell, apps, tools)
│   └── apps/mcp.nix        # MCP server SSOT (Claude Desktop + Code)
├── config/quality/          # Claude Code hooks, skills, agents
│   ├── docs/               # Guards architecture & ADRs
│   ├── src/skills/         # Auto-loaded context (34 skills)
│   ├── src/personas/       # Subagents (@agent-name)
│   ├── src/hooks/          # Pre/Post tool enforcement (40 guards)
│   ├── src/memories/       # Engineering patterns
│   ├── src/stack/          # versions.ts SSOT
│   └── generated/          # Output (DO NOT EDIT)
└── hosts/                   # Machine-specific config
```

## Rules

- All Claude config via Nix (never edit ~/.claude/ manually)
- Skills/agents generated from TypeScript SSOT
- AST-grep rules enforce patterns at write-time
- Told is the primary project (Effect-TS, Expo SDK 54, LiveKit)

## Stack (Jan 2026)

| Category | Tools |
|----------|-------|
| Runtime | Node 25, pnpm 10, TypeScript 5.9 |
| Types | tsgo (native preview) for compilation |
| Lint | oxlint (645+ rules, type-aware) |
| Format | biome (format only, no lint) |
| Backend | Effect-TS 3.19, HttpApi, Schema, Layer |
| Frontend | React 19.1, XState 5.25, TanStack Router |
| Mobile | Expo SDK 54, React Native 0.81, NativeWind |
| Voice | LiveKit 2.16, @livekit/agents |
| Infra | Pulumi 3.214, AWS ECS, CloudFront |

## MCP Servers (6 total)

| Server | Purpose |
|--------|---------|
| ref | SOTA docs (60-95% fewer tokens) |
| exa | Code context search |
| github | GitHub API |
| playwright | Browser automation |
| ast-grep | AST-based search |
| repomix | Codebase packing |

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

## Key Files

- `modules/home/apps/mcp.nix` - MCP SSOT for Desktop + Code
- `config/quality/src/stack/versions.ts` - Version SSOT
- `config/quality/src/skills/` - Claude skills
- `config/quality/src/hooks/` - Pre/post tool hooks
- `config/quality/docs/ARCHITECTURE.md` - Guards architecture
- `config/quality/docs/adr/` - Architecture Decision Records
