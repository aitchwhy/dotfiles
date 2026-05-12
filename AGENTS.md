# Dotfiles — AGENTS.md

Nix-managed macOS configuration for a senior engineer building Told (voice memory platform). This file is the canonical instruction set for **Codex CLI** sessions in this repo. See `CLAUDE.md` for the Claude Code equivalent — both harnesses now share skills, hooks, and the `ref` MCP server.

> Phase B shipped 2026-05-10; CC-91 Phase 1 (2026-05-11) extended the Codex hook surface to `Stop` (session-end batch polish), `UserPromptSubmit` (placeholder for content-policy guards), and `PermissionRequest` (re-uses `pre-tool-use.ts` so Guards 3/32/33 close on approval-required actions). Manual quality only needed if you bypass `cx` (see "Quality" below).

## Quick Commands

```bash
just switch        # Rebuild darwin + home-manager
just check         # Validate flake
just health        # Verify system state
just -g cx [acct]  # Multi-account Codex picker (codex-max-1 today)
just -g cc [acct]  # Multi-account Claude Code picker
```

## Architecture

```
flake.nix                          # Entry point
├── modules/darwin/                # macOS system (dock, keyboard, services)
├── modules/home/apps/
│   ├── claude.nix                # Claude SSOT (Code + Desktop, MCP, plugins)
│   ├── codex.nix                 # Codex SSOT (cx picker, codexAccountDefs)
│   └── agents-launcher.nix       # Owns ~/.config/just/justfile (cc + cx)
├── config/quality/                # Cross-harness quality system (Claude + Codex)
│   ├── src/hooks/                # Pre/Post/Stop/SessionStart hook scripts (bun + Effect-TS)
│   ├── src/hooks/lib/hook-input-codex.ts  # Codex → Claude stdin adapter
│   ├── src/generators/claude/    # settings.json generator
│   ├── src/generators/codex/     # config.toml generator
│   ├── src/stack/versions.ts     # Version SSOT
│   └── generated/                # Output (DO NOT EDIT)
├── config/claude-code/skills/     # SKILL.md sources (linear, commit, plan-ticket, ...)
├── config/claude/commands/        # Claude Code slash commands
└── hosts/                         # Machine-specific config
```

## Codex Multi-Account

`cx <account>` sets `CODEX_HOME=$HOME/.codex-<name>` and execs `codex`, fully isolating `auth.json` / `config.toml` / history / sessions.

| Account | Email | Purpose |
|---------|-------|---------|
| `codex-max-1` | hank.lee.qed@gmail.com | Primary daily-driver |
| `codex-max-2` | hank@told.one | Secondary (parallelism, separate quota) |

Add accounts via `codexAccountDefs` in `modules/home/apps/codex.nix`; activation hooks deploy `config.toml`, the AGENTS.md symlink, and the subagent farm automatically.

`REF_API_KEY` is fetched from AWS Secrets Manager (`told/vendor/ref/api-key`) with a fallback to `~/.config/mcp/ref-api-key` for offline / SSO-expired use (CC-45).

## Sandbox + Approvals (Codex)

Per-repo `.codex/config.toml` overrides global defaults. Conservative defaults:

| Repo | sandbox_mode | approval_policy | network_access |
|------|--------------|-----------------|----------------|
| `~/dotfiles` | `workspace-write` | `on-request` | `false` |
| `~/src/told` | `workspace-write` | `on-request` | `false` (devshells flip per-profile) |

Avoid `danger-full-access` + `never` even for routine work. Profile-scoped escalations only.

## Runtime Convention

- **bun**: scripts, MCP servers, tooling wrappers, config/quality hooks, pkgs/*.nix CLI wrappers.
- **pnpm + Node.js**: application code (~/src/told), devshells, production.

## Rules

- All Claude/Codex config via Nix (never edit `~/.claude/`, `~/.codex/`, `~/.codex-max-N/` manually — they are symlinks/generated).
- Told is the primary project (Effect-TS, Expo SDK 54, LiveKit).
- Run `just check` before committing Nix changes; commits without it are rejected by Guard 57.
- Format with biome, lint with oxlint, typecheck with tsgo for TypeScript files.
- All file paths in `cc-status` / `cx-status` output are JSON — parse with `jq`, not regex.

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

## Skills, Hooks, Agents (Codex paths)

Per [Codex skills docs](https://developers.openai.com/codex/skills) and Phase B port:

| Concern | Source of truth | Codex discovery path |
|---------|-----------------|----------------------|
| Skills | `config/claude-code/skills/*/SKILL.md` (currently: `caveman`, `commit`, `datadog`, `grill-me`, `linear`, `plan-ticket`, `spawn-agents-on-csv`) | `~/.agents/skills/` (per-user) + `<repo>/.agents/skills/` (project) |
| Hooks | `config/quality/src/hooks/*.ts` (Effect-TS, bun) | invoked via `[[hooks.<Event>]]` in `~/.codex-<acct>/config.toml` |
| Sub-agents | `config/claude-code/agents/*.md` | `$CODEX_HOME/agents/<name>.toml` (per-account user scope) + `$CWD/.codex/agents/<name>.toml` (project scope). Standalone TOML files, not `[profiles.<name>]`. |
| Slash commands | `config/claude/commands/*.md` | Codex built-ins only; user extensions go through skills |
| MCP servers | `modules/home/apps/claude.nix` (cliAllJson) | `[mcp_servers.<name>]` in `~/.codex-<acct>/config.toml` |

Phase B wires the symlinks + activation hooks so Codex reads from the dotfiles sources.

## Quality (manual fallback)

Hooks fire automatically in both Claude Code and Codex (via `cx`). If you invoke `codex` directly without `cx` and miss the hook wiring, run manually before commits:

```bash
# TypeScript
bunx biome format --write .       # Format
bunx oxlint .                     # Lint
bunx tsc --noEmit                 # Typecheck (or tsgo when stable)

# Nix
nixfmt .                          # Format
statix check .                    # Lint
deadnix .                         # Dead-code scan
just check                        # Flake validation (required before commit)
```

## Key Files

- `modules/home/apps/claude.nix` — Claude SSOT
- `modules/home/apps/codex.nix` — Codex SSOT
- `modules/home/apps/agents-launcher.nix` — `~/.config/just/justfile` owner
- `config/quality/src/stack/versions.ts` — Version SSOT
- `config/quality/docs/ARCHITECTURE.md` — Guards architecture
- `config/quality/docs/adr/015-codex-harness-port.md` — dual-harness architecture (supersedes ADR-014)
- `config/quality/docs/drift-governance.md` — AGENTS.md ↔ CLAUDE.md sync process

## Known Gaps

- **Told guard-layering (closed under Codex)**: Project-scope `~/src/told/.codex/config.toml` adds a narrow `^Bash$` marker hook that runs alongside (not replacing) the dotfiles user-scope `^(apply_patch|Bash|Grep)$` hook. With CC-50 + CC-91 Phase 1, Guards 3 (forbidden files), 32 (secrets), 33 (hook bypass) fire on Codex `apply_patch` and `Bash` from inside Told. Regression smoke: `~/src/told/.codex/hooks/codex-hook-layering.test.sh` (4/4 PASS post-deploy). Drift smoke: `~/src/told/.codex/hooks/check-agents-drift.sh`. The mirror under Claude Code remains open — see `CLAUDE.md` "Known Gaps".

## Cross-References

- `CLAUDE.md` — Claude Code instruction set (full hooks/skills/agents/MCP details).
- Linear project: [Codex Harness Parity](https://linear.app/toldone/project/codex-harness-parity-23a9f66f278c) (CC team).
- CC-60 Phase B doc: the locked source-of-truth for Phase B execution.
- CC-91: Phase 1 (Stop/UserPromptSubmit/PermissionRequest wiring + agent-drift smoke + bun unblock) shipped 2026-05-11; Phases 2-3 (matrix sweep + capstone + verdict) tracked open.
