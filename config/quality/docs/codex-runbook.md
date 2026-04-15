# Codex CLI Runbook

Operational guide for using OpenAI Codex CLI alongside Claude Code in the dotfiles-managed environment.

**Decision**: ADR-014 — Codex CLI is a fallback provider, not a primary workflow replacement.

## Prerequisites

- Node 22+ (Node 25 installed via Nix)
- OpenAI account: ChatGPT Plus/Pro/Business/Edu/Enterprise OR API key
- Dotfiles rebuilt: `just switch` (installs Codex via activation hook)

## Installation

Codex CLI is installed automatically by the `setupCodexCli` activation hook in `modules/home/packages/common.nix`.

```bash
# Verify installation
codex --version

# Manual install/upgrade (if activation hook hasn't run)
npm i -g @openai/codex@latest
```

## Authentication

Two auth methods:

### ChatGPT Account (Recommended)

```bash
codex          # First run triggers browser-based OAuth login
# OR
codex auth login
```

Login credentials stored locally. No API key needed.

### API Key

```bash
export OPENAI_API_KEY="sk-..."
codex
```

Or set in config:

```toml
# ~/.codex/config.toml
[auth]
cli_auth_credentials_store = "keychain"  # macOS Keychain
```

## MCP Configuration

The `ref` MCP server (primary documentation tool) works with Codex:

```bash
# Add ref server (same server used by Claude Code)
codex mcp add ref --type http --url "https://ref.tools/mcp"

# Verify
codex mcp list

# Remove if needed
codex mcp remove ref
```

## AGENTS.md

Codex reads `AGENTS.md` at the repo root (analogous to `CLAUDE.md`). Both managed repos have an `AGENTS.md`:

| Repo | File | Status |
|------|------|--------|
| `~/dotfiles` | `AGENTS.md` | Mirrors critical rules from CLAUDE.md |
| `~/src/told` | `AGENTS.md` | Codex-compatible subset of told's CLAUDE.md |

Each AGENTS.md includes:
- Architecture overview and directory structure
- Stack versions and key files
- Code rules (absolute rules, imports, git workflow)
- Manual quality verification commands

**Not included** (Claude Code specific): hooks, skills/commands, agents, domain rules, plugins, MCP JSON config.

**Drift governance:** See `config/quality/docs/drift-governance.md` for the sync process and trigger checklist. Run `config/quality/scripts/check-agents-drift.sh` to detect structural drift.

Discovery chain: `~/.codex/AGENTS.override.md` > `~/.codex/AGENTS.md` > project root walk. 32 KiB limit.

## Approval Modes

| Mode | Behavior | Use When |
|------|----------|----------|
| Auto (default) | Workspace-scoped writes auto-approved | Normal development |
| Read-only | Consultative, no writes | Code review, exploration |
| Full Access | Unrestricted | Trusted automation |

```bash
codex --approval-mode read-only   # Start in read-only
codex --approval-mode full-auto   # Start in full access
```

## Switching Workflow

### When to use Codex

- Claude Code is down (provider outage)
- Rate-limited on all Claude accounts
- Task needs OpenAI model capabilities (e.g., specific model strengths)
- Quick exploration where quality hooks aren't needed

### When to stay on Claude Code

- Any task requiring quality guards (format, lint, typecheck enforcement)
- Workflow commands needed (`/commit`, `/linear`, `/plan-ticket`)
- MCP servers already configured and working
- Multi-account switching via `just -g cc`

### Switching procedure

```bash
# Claude Code (primary)
cc                    # Or: just -g cc

# Codex (fallback)
codex                 # In any project directory

# Both can run independently in separate terminals
```

## Compatibility Matrix

| Feature | Claude Code | Codex CLI | Status |
|---------|------------|-----------|--------|
| Installation | Nix package | npm global (activation hook) | Working |
| Config format | JSON (settings.json) | TOML (config.toml) | Separate configs |
| Instruction file | CLAUDE.md | AGENTS.md | Both present |
| PreToolUse hooks | 6 quality guards | None | **Not portable** |
| PostToolUse hooks | Yes | None | **Not portable** |
| Skills (/commit etc.) | 12+ skills | None | **Not portable** |
| Commands | 6+ commands | None | **Not portable** |
| MCP servers | Auto-configured via Nix | Manual `codex mcp add` | Manual setup |
| Multi-account | 5 accounts via justfile | Single account | Manual switch |
| Permissions | Fine-grained allow/deny | 3 approval modes | Less granular |
| Plugins | caveman (1) | None | **Not portable** |

## Known Limitations

1. **No quality hooks**: Format, lint, typecheck enforcement does not run in Codex sessions. Code quality must be verified manually after Codex sessions.
2. **No skills/commands**: `/commit`, `/linear`, `/plan-ticket` etc. are Claude Code specific. Use git CLI directly.
3. **No multi-account launcher**: `just -g cc` picker is Claude Code only. Run `codex` directly.
4. **Less granular permissions**: 3 approval modes vs Claude Code's per-tool allow/deny lists.
5. **Manual MCP setup**: MCP servers must be added manually via `codex mcp add` (not auto-configured).
6. **No plugin ecosystem**: Caveman mode and other plugins unavailable.

## Troubleshooting

```bash
# Codex not found after just switch
npm i -g @openai/codex@latest    # Manual install

# Auth issues
codex auth logout && codex auth login

# MCP server not connecting
codex mcp list                    # Verify config
codex mcp remove ref && codex mcp add ref --type http --url "..."

# Version check
codex --version
node --version                    # Must be 22+
```
