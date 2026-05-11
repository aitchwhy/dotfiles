# Dotfiles

Nix-managed macOS configuration for senior engineer building Told (voice memory platform).

## Quick Commands

```bash
just switch        # Rebuild darwin + home-manager
just check         # Validate flake
just health        # Verify system state
just disk-audit    # Read-only host disk inventory (run quarterly)

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

## Codex (dual-harness, May 2026)

After Phase B, this repo also drives a Codex CLI harness in parallel. Both harnesses share skills, hooks, and the `ref` MCP server. See `AGENTS.md` for the canonical Codex-side instruction set, ADR-015 for the architecture, and `config/quality/docs/drift-governance.md` for divergence rules.

| Concern | Claude Code | Codex |
|---------|-------------|-------|
| CLI launch | `cc [account]` (alias of `just -g cc`) | `cx [account]` (alias of `just -g cx`) |
| Account isolation | `CLAUDE_CONFIG_DIR=$HOME/.claude-max-N` | `CODEX_HOME=$HOME/.codex-max-N` |
| SSOT module | `modules/home/apps/claude.nix` | `modules/home/apps/codex.nix` |
| Generated config | `config/quality/generated/claude/settings.json` | `config/quality/generated/codex/config.toml` |
| Skills discovery | `~/.claude/skills` (symlinked per CLAUDE_CONFIG_DIR) | `~/.agents/skills` (per-user, shared) |
| Hook event count | ~30 | 8 (PreToolUse, PostToolUse, PermissionRequest, SessionStart, UserPromptSubmit, Stop, PreCompact, PostCompact) |
| Hook script entry | `config/quality/src/hooks/*.ts` (Effect-TS, bun) | same scripts — `lib/hook-input-codex.ts` adapter projects Codex stdin to Claude shape inside `parseInput` |
| Subagents | Markdown agents in `config/claude-code/agents/*.md` | Standalone TOML at `$CODEX_HOME/agents/<name>.toml` (per-account user scope) + `$CWD/.codex/agents/<name>.toml` (project scope); architect ported in Phase B |
| Sandbox model | Permissions allow/deny in settings.json | `sandbox_mode` + `approval_policy` in config.toml; per-project overrides in `.codex/config.toml` |

## Key Files

- `modules/home/apps/claude.nix` - Claude SSOT (MCP, plugins, marketplaces)
- `modules/home/apps/codex.nix` - Codex SSOT (cx picker + symlink farm + config deploy)
- `config/quality/src/stack/versions.ts` - Version SSOT
- `config/quality/src/hooks/` - Pre/post tool hooks (cross-harness)
- `config/quality/src/hooks/codex-definitions.ts` - Codex hook event SSOT
- `config/quality/src/hooks/lib/hook-input-codex.ts` - Codex → Claude stdin adapter
- `config/quality/src/generators/claude/settings.generator.ts` - Claude settings generator
- `config/quality/src/generators/codex/config-toml.generator.ts` - Codex config.toml generator
- `config/quality/docs/ARCHITECTURE.md` - Guards architecture
- `config/quality/docs/adr/` - Architecture Decision Records (ADR-015 = dual-harness)
- `config/quality/docs/drift-governance.md` - AGENTS.md ↔ CLAUDE.md sync + Codex divergence table
