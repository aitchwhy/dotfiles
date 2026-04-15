---
status: accepted
date: 2026-04-15
decision-makers: [Hank Lee]
consulted: []
informed: []
---

# Codex CLI readiness: install path, auth model, and compatibility assessment

## Context and Problem Statement

OpenAI's Codex CLI is a viable fallback coding agent when Claude Code is unavailable (provider outage, rate limits). Before integrating it into the dotfiles workflow, we need to assess operational readiness: install status, auth path, and compatibility with existing quality infrastructure. How should we install and configure Codex CLI alongside Claude Code without disrupting existing workflows?

## Decision Drivers

* Provider redundancy — avoid single-provider lock-in for AI coding assistance
* Minimal disruption — existing Claude Code quality guards, hooks, and skills must continue working
* Nix-managed — installation should be declarative and reproducible
* Low maintenance — assessment phase, not full integration

## Considered Options

* Option A: Homebrew formula
* Option B: npm global install via home-manager activation hook
* Option C: Custom Nix derivation in pkgs/

## Decision Outcome

Chosen option: "Option B — npm global install via activation hook", because Codex CLI is not in nixpkgs or Homebrew core, npm is the canonical install path, and an activation hook follows the established `setupUvTools` pattern in `common.nix`. Can be promoted to a proper Nix derivation later if Codex becomes a daily driver.

### Consequences

* Good, because installation is declarative and idempotent via home-manager activation
* Good, because Node 25 already meets Codex's Node 22+ requirement
* Good, because Codex sessions can use MCP servers (ref) via `codex mcp add`
* Bad, because Codex sessions run without quality guards (no hook equivalent exists)
* Bad, because Claude Code skills/commands (`/commit`, `/linear`, `/plan-ticket`) have no Codex equivalent
* Neutral, because AGENTS.md can mirror critical CLAUDE.md rules but not enforce them

### Confirmation

* `codex --version` returns a version after `just switch`
* `AGENTS.md` exists at repo root and is picked up by Codex sessions
* Runbook at `config/quality/docs/codex-runbook.md` covers install, auth, MCP, and switching
* Claude Code workflows remain unaffected (`cc`, `just -g cc`, hooks, skills all work)

## Pros and Cons of the Options

### Option A: Homebrew formula

* Good, because Homebrew is already used for many CLI tools
* Bad, because `@openai/codex` is not in Homebrew core (would need a tap or manual formula)
* Bad, because Homebrew node dependency management is less predictable

### Option B: npm global install via activation hook

* Good, because npm is the canonical install path (`npm i -g @openai/codex`)
* Good, because follows established `setupUvTools` pattern in `common.nix`
* Good, because idempotent — only installs/upgrades when version differs
* Neutral, because npm global installs are outside Nix's dependency graph

### Option C: Custom Nix derivation

* Good, because fully Nix-managed with reproducible builds
* Bad, because Codex CLI has complex npm dependencies that are hard to package
* Bad, because overkill for an assessment phase — high effort, low immediate value

## More Information

### Compatibility Matrix

| Feature | Claude Code | Codex CLI | Gap |
|---------|------------|-----------|-----|
| Config format | JSON | TOML | Medium — cannot share config |
| Instruction files | CLAUDE.md | AGENTS.md | Low — content adaptable |
| Hooks (PreToolUse etc.) | Yes (6 hooks) | No equivalent | **High** |
| Skills/Commands | Yes (12+) | No equivalent | **High** |
| MCP support | Yes (JSON) | Yes (TOML) | Low — same servers |
| Multi-account | CLAUDE_CONFIG_DIR | CODEX_HOME | Low |
| Permissions | Fine-grained allow/deny | 3 approval modes | Medium |
| Nix integration | Deep | None | **High** |

3 high-severity gaps mean Codex is suitable as a **fallback provider only**, not a primary workflow replacement.

Related: [Codex CLI docs](https://developers.openai.com/codex/cli), [Codex config reference](https://developers.openai.com/codex/config-reference)
