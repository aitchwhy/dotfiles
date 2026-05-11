---
status: accepted
date: 2026-05-10
decision-makers: [Hank Lee]
consulted: []
informed: []
supersedes: 014-codex-cli-readiness.md
---

# Codex Harness Port: dual-harness, shared skills, hooks via shared scripts

## Context and Problem Statement

ADR-014 (April 2026) accepted Codex CLI as an npm-installed fallback with no quality hooks, no shared skills, and only an `AGENTS.md` stub mirroring `CLAUDE.md`. As of Codex CLI v0.130 (May 2026):

- `hooks` is a stable feature flag (`codex features list | grep hooks`).
- `apply_patch` and MCP tool calls fire `PreToolUse` / `PostToolUse` hooks (PR #18391, fixed issue #16732, shipped 2026-04-22).
- `plugins`, `multi_agent`, `personality`, `guardian_approval` are all stable.
- `CODEX_HOME` env var isolates per-account state cleanly (`auth.json`, `config.toml`, history, sessions, MCP state).
- Skills follow the `agentskills.io` open standard; user-scoped path is `~/.agents/skills/` shared across tools.

The original "Codex is a fallback, no quality enforcement, no shared skills" stance is no longer accurate. We need a coherent dual-harness architecture: bring Codex to parity with the existing Claude Code harness without duplicating skill bodies, hook scripts, or MCP configs.

## Decision Drivers

- **No skill-body duplication** — `config/claude-code/skills/*/SKILL.md` should be the single source of truth, readable by both harnesses.
- **No hook-script duplication** — `config/quality/src/hooks/*.ts` should run for both harnesses; only the stdin JSON shape differs.
- **No MCP-config drift** — the `ref` server should be declared once and consumed by both harnesses.
- **Per-account isolation** — multiple Codex accounts (Max plans) need clean isolation, mirroring Claude's `CLAUDE_CONFIG_DIR` scheme.
- **Generator-driven** — Codex `config.toml` should be generated declaratively from a Nix/TypeScript SSOT, mirroring the existing `config/quality/src/generators/claude/` setup.
- **Conservative defaults** — sandbox + approval policy defaults that prefer paranoia over convenience.

## Considered Options

- **Option A**: Standalone Codex harness, duplicating skills/hooks/MCP. Easiest to ship, highest maintenance cost.
- **Option B**: Shared skills + Codex-specific hooks via separate Nix module + generator (**chosen**).
- **Option C**: Ship a Codex marketplace plugin (`told-codex-pack`) that bundles everything. Highest leverage but blocked on `plugin_hooks` being under-development in v0.130.

## Decision Outcome

**Option B: shared skills + Codex-specific generators + a thin hook input adapter.**

### Architecture

- Skills live at `config/claude-code/skills/{linear,commit,plan-ticket,grill-me,datadog}/SKILL.md`. Codex reads them via a Nix-managed symlink at `~/.agents/skills/` (user-scoped, shared across `~/.codex-max-N/` accounts).
- Hooks live at `config/quality/src/hooks/*.ts`. A new `lib/hook-input-codex.ts` adapter projects Codex's stdin JSON into the Claude shape the existing scripts consume. The hook scripts call the adapter conditionally based on `CODEX_HOME` env presence (T10).
- A new generator at `config/quality/src/generators/codex/` emits `generated/codex/config.toml` from a `codex-definitions.ts` SSOT (parallel to `definitions.ts` for Claude).
- `modules/home/apps/codex.nix` mirrors `claude.nix`'s symlink farm to wire `~/.codex-max-N/{AGENTS.md, config.toml, agents/}` per account.
- Architect agent ports to `$CODEX_HOME/agents/architect.toml` (per-account; e.g. `~/.codex-max-1/agents/architect.toml`). Standalone TOML agent file, not `[profiles.architect]` — profiles are flagged experimental in v0.130. See "Correction (CC-87)" at the end of this ADR.
- The Caveman plugin is intentionally NOT ported as a Codex plugin. The persona is encoded in `AGENTS.md` prose / a `personality` preset; the marketplace plugin path is gated on `plugin_hooks` stabilizing (currently under-development).

### Hook event mapping

| Claude event | Codex event | Notes |
|--------------|-------------|-------|
| `PreToolUse: Write\|Edit\|Bash\|Grep` | `PreToolUse: ^(apply_patch\|Bash\|Grep)$` | Codex uses single `apply_patch` for all edits. |
| `PostToolUse: Write\|Edit\|MultiEdit` | `PostToolUse: ^apply_patch$` | Same. |
| `PostToolUse: Write(**/package.json)` | `PostToolUse: ^apply_patch$` (script-side filter) | Codex matcher is regex-on-tool_name only; file-path filtering moves into the script. |
| `PostToolUse: Bash(darwin-rebuild switch:*)` | (not portable) | Codex `Stop` is per-turn, not per-process. GC moves to `just switch` recipe or LaunchAgent. |
| `SessionStart` | `SessionStart` | Direct port. |
| (none) | `PermissionRequest, PreCompact, PostCompact` | Codex-only events, enumerated in SSOT for future use. |

Hook events Claude has that Codex does not: `Notification`, `SubagentStart/Stop`, `FileChanged`, `TaskCreated/Completed`, `PostToolBatch`, `WorktreeCreate/Remove`. Functionality that depended on these stays Claude-only.

### Sandbox + approvals defaults

- `~/dotfiles/.codex/config.toml`: `sandbox_mode = "workspace-write"`, `approval_policy = "on-request"`, `network_access = false`.
- `~/src/told/.codex/config.toml`: same, with told-specific `writable_roots`.
- Global default for ad-hoc directories: same workspace-write + on-request. Avoid `danger-full-access` + `never` even for routine work.

### Per-account isolation

`cx <account>` sets `CODEX_HOME=$HOME/.codex-<name>`. The Nix symlink farm wires each `CODEX_HOME` dir to read `AGENTS.md` and `config.toml` from dotfiles-managed sources. Phase A (CC-59) established this for `codex-max-1`; T6 (CC-66) restores `codex-max-2` and adds the symlink farm.

### Consequences

- Good: skill bodies, MCP config, and hook scripts have a single source of truth.
- Good: adding a third Codex account is a one-line addition to `codexAccountDefs`.
- Good: Phase A's `cx` picker (CC-59) keeps working unchanged; this ADR builds on top.
- Good: ADR-014's "no quality enforcement in Codex" gap closes via shared hooks.
- Bad: `unified-polish.ts` runs against `apply_patch` patches — file path extraction depends on patch parsing (`parseApplyPatchPaths` in `hook-input-codex.ts`).
- Bad: per-event regex matching is less expressive than Claude's `Write(**/package.json)` glob. File-path filtering moves into the script body.
- Bad: hooks bundled inside Codex plugins are not yet stable (`plugin_hooks = under-development` in v0.130), so the `told-codex-pack` distribution path is deferred (T13).
- Neutral: Caveman persona is replicated via AGENTS.md prose instead of a marketplace plugin.

### Confirmation

- `bun run typecheck` and `bun run generate` produce `generated/codex/config.toml` with `[mcp_servers.ref]`, `[[hooks.PreToolUse]]`, `[[hooks.PostToolUse]]`, `[[hooks.SessionStart]]` blocks.
- `just switch` symlinks `~/.codex-max-1/AGENTS.md` → `~/dotfiles/AGENTS.md` and `~/.codex-max-1/config.toml` → the generated file with `REF_API_KEY` substituted.
- `cx codex-max-1` interactive session honors `[[hooks.PostToolUse]]` on a real `apply_patch` (T12 smoke test).
- `vitest run hook-input-codex` passes — adapter projects Codex JSON to Claude shape correctly for `apply_patch`, `Bash`, MCP tools, and non-tool events.

## Pros and Cons of the Options

### Option A: Standalone Codex harness, duplicate skills/hooks/MCP

- Good, because zero risk of cross-talk between Claude and Codex.
- Bad, because every skill body update requires touching two files.
- Bad, because hook logic divergence is inevitable over time.
- Bad, because MCP configs drift.

### Option B: Shared skills + Codex-specific generator + adapter (chosen)

- Good, because single source of truth for skill bodies and hook scripts.
- Good, because the adapter is a small, well-tested module (`hook-input-codex.test.ts`).
- Good, because generator-driven config follows the established `claude/settings.generator.ts` pattern.
- Bad, because hook scripts gain a small `CODEX_HOME ?` branch (manageable).
- Bad, because matcher syntax differences require a translation table in `codex-definitions.ts`.

### Option C: Codex marketplace plugin (`told-codex-pack`)

- Good, because one `codex plugin marketplace add` brings the whole harness up.
- Good, because shareable with teammates.
- Bad, because plugin-bundled hooks are `under-development` in v0.130.
- Bad, because plugin distribution is "coming soon" per OpenAI docs.
- **Deferred to T13** as a stretch goal once `plugin_hooks` stabilizes.

## References

- Phase A commits: `bc060426`, `884fd20a`, `6d8f812b` (Codex install + `cx` picker).
- Phase B Linear project: [Codex Harness Parity](https://linear.app/toldone/project/codex-harness-parity-23a9f66f278c).
- CC-60 Phase B doc (locked source of truth for the port).
- ADR-014 (superseded by this ADR).
- ADR-007 (hook architecture; underlying pattern reused).
- Codex docs: [hooks](https://developers.openai.com/codex/hooks), [skills](https://developers.openai.com/codex/skills), [subagents](https://developers.openai.com/codex/subagents), [config-reference](https://developers.openai.com/codex/config-reference).
- PR [#18391](https://github.com/openai/codex/pull/18391) — apply_patch hook fix.

## Correction (CC-87, 2026-05-11)

Phase B's initial implementation symlinked the architect to `~/.agents/agents/architect.toml`, conflating the skills user-scope (`~/.agents/skills/`) with the subagents user-scope. Per [Codex subagents docs](https://developers.openai.com/codex/subagents#custom-agents), subagents are discovered at `$CODEX_HOME/agents/` (user) and `$CWD/.codex/agents/` (project) — there is no `~/.agents/agents/` scan path. Skills and subagents share no directory.

CC-87 moves the architect symlink farm into `$CODEX_HOME/agents/<name>.toml` per account (e.g. `~/.codex-max-1/agents/architect.toml`) and enumerates `config/claude-code/agents/*.toml` so new agents auto-deploy on `just switch`. The `~/.agents/skills` user-scope symlink is unchanged (skills *do* live there per the skills docs). Sibling told-repo work renames `~/src/told/.agents/agents/` → `~/src/told/.codex/agents/` to expose the 16 reviewer + 1 synthesizer subagents at project scope.
