---
status: accepted
date: 2026-05-11
decision-makers: [Hank Lee]
consulted: []
informed: []
---

# Codex hook layering closes the array-replace gap that breaks Claude project-scope guards

## Context and Problem Statement

Claude Code merges `settings.json` across user scope and project scope by
deep-merging — but arrays REPLACE, they do not concatenate. The single
`hooks.PreToolUse` array declared in `~/src/told/.claude/settings.json`
therefore wholesale replaces the user-scope array set up by the dotfiles
harness, silently disabling the three guards that protect Told from
package-lock writes, secret leaks, and lefthook bypasses (Guards 3, 32, 33
in `config/quality/src/hooks/lib/guards/procedural.ts`). Until a Claude-side
merge fix lands, Told's CC sessions enforce a narrower bash reimplementation
in `.claude/hooks/`, while the SSOT TypeScript guards never fire.

Codex CLI (v0.130+, `[features].codex_hooks = true`) explicitly does the
opposite: when more than one hook source exists, it loads ALL matching hooks
and higher-precedence config layers do NOT replace lower-precedence hooks
([reference][codex-hooks]). Is the Codex side a usable superset we can lean
on while the Claude merge problem is open?

## Decision Drivers

- **Honest acceptance criteria** — when Told docs claim a guard runs, it must
  run. The Claude-side gap is documented but easy to forget; we want the
  Codex side closed in a way that survives future config edits.
- **No SSOT duplication** — `procedural.ts` is the single source for Guards
  1–57. The Codex closure must not require a parallel guard implementation.
- **Minimal Told-side footprint** — Told's `.codex/config.toml` should add
  ONE marker hook plus its README so the layering pattern is exercised in
  production config, not just asserted in theory.
- **Regression detectability** — a smoke test must be able to assert the
  dotfiles user-scope hook fires from inside Told without spinning up a real
  Codex session.

## Considered Options

- **Option A — Document the Codex behaviour, no code change.** Cheapest. But
  the empirical premise was wrong (see Consequences); without the SSOT fix
  Guards 3 and 32 silently approve `apply_patch` even with full Codex
  layering.
- **Option B — Fix the SSOT dispatch + add a Told marker hook + smoke test.**
  Chosen. Extends `procedural.ts` to dispatch the Write/Edit guard set on
  `toolName === 'apply_patch'` (matching the codex adapter's projection),
  adds a small marker hook in Told to exercise project-scope layering, and a
  bash smoke test that asserts the contract.
- **Option C — Rewrite the Codex adapter to remap `tool_name` from
  `apply_patch` to `Edit`.** Smaller dotfiles diff but contradicts the
  adapter's documented invariant (see `lib/hook-input-codex.ts:43`,
  "`apply_patch` keeps its name") and would silently break any future guard
  that legitimately wants to branch on `apply_patch`.

## Decision Outcome

Chosen option: **Option B**, because it closes the empirical gap end-to-end
(SSOT + project config + automated regression test) without violating
adapter invariants and with a footprint of roughly twenty SSOT lines plus
five Told-side files.

### Consequences

- Good, because Guards 3 (forbidden files) and 32 (secrets detection) now
  fire on every Codex `apply_patch` originating in any repo, not just Told.
- Good, because the Told-side smoke test (`./.codex/hooks/codex-hook-layering.test.sh`)
  asserts the layering contract is intact independent of any live Codex
  invocation, so future config edits that accidentally break the user-scope
  hook will be caught.
- Good, because the marker hook (`.codex/hooks/told-marker.sh`) provides a
  visible signal (`told.codex.layered` on stderr) that both layers are
  loading, making any silent regression detectable on the first Codex Bash.
- Bad, because the Claude-side gap remains open — Told now has a per-harness
  asymmetry that needs explicit documentation in `CLAUDE.md` Known Gaps to
  prevent operator confusion.
- Bad, because the `apply_patch` dispatch extension changes how Codex
  `apply_patch` events are evaluated globally; any consumer of
  `procedural.ts` that previously assumed `apply_patch` was a no-op for
  Write/Edit guards needs to be re-evaluated (none today, but worth noting).

### Confirmation

Verification path:

1. From inside `~/src/told`, pipe Codex-shape `PreToolUse` payloads for
   `apply_patch` (forbidden-file + secret cases) and `Bash` (hook-bypass
   case) into `bun "$HOME/dotfiles/config/quality/src/hooks/pre-tool-use.ts"`.
   All three must return `{"decision":"block",...}` with the matching guard
   tag in the reason string.
2. Run `bash ~/src/told/.codex/hooks/codex-hook-layering.test.sh` — must
   print four `PASS` lines.
3. Open a Codex session in Told, run a benign `Bash` (e.g. `pnpm typecheck`).
   The dotfiles status message `Pre-tool guards` must appear AND the marker
   hook must emit `told.codex.layered` to stderr in the Codex log.
4. In the same Codex session, attempt `git commit --no-verify -m test`.
   Codex must deny with the Guard 33 reason.

Acceptance test artifact lives at:
`~/src/told/.codex/hooks/codex-hook-layering.test.sh`.

## Pros and Cons of the Options

### Option A — document only

- Good, because zero code change.
- Bad, because the documented claim ("Codex layered hooks close Guards 3 +
  32") was empirically false until the SSOT was fixed — preflight verification
  showed `apply_patch` payloads with `package-lock.json` returning
  `{"decision":"approve"}`. Documentation that lies about enforcement is
  worse than acknowledging the gap.

### Option B — SSOT fix + marker + smoke test

- Good, because Guard 3 + Guard 32 actually fire on `apply_patch` now.
- Good, because the smoke test is hermetic — no Codex session required, no
  LLM tokens spent, runs in roughly one second.
- Good, because the marker hook is a positive signal: silence on the
  `told.codex.layered` line during a Codex Bash means the dotfiles config is
  broken.
- Neutral, because the dispatch change is three lines and trivially
  reversible.
- Bad, because it bundles a real SSOT change with a documentation /
  observability change. Reviewers must read both halves.

### Option C — adapter remap

- Good, because all Codex tool calls would surface as Claude shapes, simpler
  mental model.
- Bad, because it contradicts the adapter's stated invariant
  (`lib/hook-input-codex.ts:43`) and erases the `apply_patch` distinction
  that some guards may legitimately want in the future (e.g. patch-body
  parsers, multi-file change checks).

## More Information

### Empirical evidence captured during this work

Verification commands run from inside `/Users/hank/src/told` against the
pre-fix `procedural.ts`:

| Input | Expected | Got (pre-fix) | Got (post-fix) |
|-------|----------|---------------|----------------|
| Claude `Write` `package-lock.json` | block | block | block |
| Codex `apply_patch` adding `package-lock.json` | block | **approve** | block |
| Claude `Write` content with Stripe live key | block | block | block |
| Codex `apply_patch` adding content with Stripe live key | block | **approve** | block |
| Claude/Codex `Bash` `git commit --no-verify` | block | block | block |
| Claude/Codex `Bash` `pnpm test` (control) | approve | approve | approve |

The two pre-fix `approve` rows are the regression this ADR closes.

### Codex documentation references

- [codex-hooks]: https://developers.openai.com/codex/hooks#where-codex-looks-for-hooks
- https://developers.openai.com/codex/config-advanced#hooks-experimental
- https://developers.openai.com/codex/llms-full.txt#project-config-files-codex-config-toml

### Related ADRs

- [ADR-007](007-hook-architecture.md) — original PreToolUse architecture.
- [ADR-013](013-local-first-hooks.md) — hook protocol contract.
- [ADR-015](015-codex-harness-port.md) — dual-harness port; established the
  Codex hook input adapter this ADR depends on.

### Follow-on work

The Claude-side gap is tracked separately. Until that lands, Told's
`.claude/hooks/pre-tool-use.sh` + `pre-tool-use-bash.sh` remain in place as
the narrower bash fallback. Do NOT delete them.
