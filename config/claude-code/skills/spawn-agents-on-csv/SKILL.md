---
name: spawn-agents-on-csv
description: >
  Bulk target fan-out from a CSV manifest. Each row spawns one named target
  (subagent TOML or skill SKILL.md) with a prompt + working dir, captures
  output to /tmp/spawn-<label>.{jsonl,stderr,txt}, and appends a result row
  to the summary table. Drives the CC-91 Section A reviewer matrix + Section
  B skill matrix.
argument-hint: "<csv-path> [--summary <out.md>] [--concurrency <N>] [--dry-run]"
allowed-tools: Bash, Read, Glob
user-invocable: true
---

# Spawn Agents On CSV

Take a CSV manifest, fan out subagents row-by-row, capture transcripts, write
a summary table. Harness-agnostic: under Claude Code, use the `Task` tool
with `subagent_type`; under Codex, shell out to `codex exec`.

## CSV format

Header row REQUIRED. Columns (case-insensitive):

| column          | required | meaning                                              |
|-----------------|----------|------------------------------------------------------|
| `target`        | yes      | Name of a subagent TOML or a skill SKILL.md, e.g. `tdd-reviewer`, `datadog` |
| `prompt`        | yes      | Self-contained instructions for the target            |
| `working_dir`   | no       | cwd for the spawn (default: repo root)               |
| `session_label` | yes      | Unique kebab-case label; used for `/tmp/spawn-<label>.{jsonl,stderr,txt}` |
| `model`         | no       | Override model (default: target's default)            |

The `target` column carries either kind of customization layer — subagent or
skill. The resolver below picks the right invocation path. (Renamed from
`agent_name` in CC-94: the CSV mixes both kinds because Section A drives
reviewer subagents and Section B drives vendor + workflow skills through this
same harness.)

Example (`section-a.csv`):

```csv
target,prompt,working_dir,session_label
tdd-reviewer,"Review tests in commit d1452e0d","/Users/hank/src/told",a-tdd-d1452e0d
backend-reviewer,"Review handlers in commit dc45703d","/Users/hank/src/told",a-backend-dc45703d
```

**Prompt cells with commas, quotes, or newlines**: quote the whole cell with
`"..."`, escape internal `"` as `""`. Don't embed shell metacharacters —
prompts are passed as a single argv element, not through `bash -c`.

## Invocation contract

User invokes:

```
/spawn-agents-on-csv <path-to-csv>           # full run
/spawn-agents-on-csv <path> --dry-run         # print plan, do not spawn
/spawn-agents-on-csv <path> --concurrency 3   # at most 3 in flight
/spawn-agents-on-csv <path> --summary out.md  # write summary to file (default stdout)
```

Steps the LLM must perform:

1. **Read + validate** the CSV. Bail with a clear error if header missing,
   if `target` or `session_label` is empty, or if labels collide.

2. **Resolve each `target` via the two-kind resolver** (see § Resolver below).
   The resolver returns either:
   - `subagent` + path to a `.toml`, or
   - `skill` + path to a `SKILL.md`, or
   - `MISSING` + a reason string listing all four searched paths verbatim.

   Skip-with-MISSING any row that doesn't resolve rather than blowing up the
   whole run.

3. **Fan out**, respecting `--concurrency` (default 1, sequential — safer
   under sandbox quotas).
   - **Claude harness** (no `$CODEX_HOME` env):
     - `kind=subagent` → call the `Task` tool with
       `subagent_type: <target>`, `prompt: <prompt>`. Write the result
       to `/tmp/spawn-<label>.txt`.
     - `kind=skill` → invoke as `/<target> <prompt>` via the harness skill
       loader; capture transcript to `/tmp/spawn-<label>.txt`.
   - **Codex harness** (`$CODEX_HOME` set): shell out via `codex exec --json`
     so the JSONL event stream lands on stdout (the legacy `-o <file>`
     invocation WITHOUT `--json` writes only the final assistant message
     and is what caused the CC-91 Section F "no streaming" false negative).
     ```bash
     cd "<working_dir>" && \
       codex exec --json --color never "<wire-prompt>" \
         > "/tmp/spawn-<label>.jsonl" \
         2> "/tmp/spawn-<label>.stderr"
     ```
     where `<wire-prompt>` is:
     - `kind=subagent` → `@<target>: <prompt>` (Codex mention triggers the
       sub-session — invocation is mention-based, not flag-based; see
       ADR-015 reconciliation #3).
     - `kind=skill`    → `/<target> <prompt>` (slash-command body invokes
       the SKILL.md instructions inline).

4. **Capture exit code, head -5 of stdout, full path to transcript**.
   Under Codex, the `head` column is the text of the last
   `turn.completed` event's assistant message (extract from the JSONL
   stream via `tail -n 200 /tmp/spawn-<label>.jsonl | jq -r ...`).

5. **Emit a summary table** (markdown), columns:
   `label | target | kind | status | exit | head | transcript-path`.
   Status is one of `PASS` (exit 0 and non-empty stdout), `EMPTY` (exit 0
   but no stdout), `FAIL` (non-zero exit), `MISSING` (target unresolved —
   skipped), `WARN` (resolved but collision — see § Resolver precedence),
   `TIMEOUT`.

6. **Print the summary** to stdout, OR write to `--summary <out.md>` if
   given.

## Resolver

For each row's `target` cell, walk the four search paths in this order and
return on the FIRST match (subject to the precedence rule below). The
resolver checks **destination** paths only (the locations the runtime
actually looks at), NOT the dotfiles SSOT sources — the dotfiles tree is
unreachable on machines without `~/dotfiles`.

| # | Kind     | Scope    | Path                                                    |
|---|----------|----------|---------------------------------------------------------|
| 1 | subagent | user     | `$CODEX_HOME/agents/<target>.toml`                      |
| 2 | subagent | project  | `<working_dir>/.codex/agents/<target>.toml`             |
| 3 | skill    | user     | `~/.agents/skills/<target>/SKILL.md`                    |
| 4 | skill    | project  | `<working_dir>/.claude/skills/<target>/SKILL.md`        |

Notes:

- **`$CODEX_HOME` fallback.** When `$CODEX_HOME` is unset (Claude harness, or
  a Codex invocation that didn't export the var), iterate both
  `~/.codex-max-1/agents/<target>.toml` and `~/.codex-max-2/agents/<target>.toml`
  and return on the first match. Both directories are populated by
  `perAccountAgentSymlinks` in `~/dotfiles/modules/home/apps/codex.nix`.
- The ticket text for CC-95 originally specified `~/.agents/agents/`
  for subagents. That path does NOT exist on disk. CC-94 corrected the
  destination to `$CODEX_HOME/agents/`.

## Resolver precedence

When the same `<target>` resolves as BOTH a subagent (paths 1 or 2) AND a
skill (paths 3 or 4):

- **Subagent wins.** Subagent TOMLs are more specific contracts — they pin
  a model, a prompt scaffold, and explicit tool permissions, and exist
  precisely to override the skill body under Codex (e.g. `architect.toml`
  overrides the `plan-ticket` skill). The TOML wins by construction.
- **Emit a WARN row** in the summary table (instead of PASS). The `head`
  column lists both resolved paths so the operator can see the collision.
  Continue the run using the subagent path; do NOT spawn twice.

## MISSING reason format

When none of the four paths match, the `head` column carries the verbatim
text below (substituting the actual `<target>` and `<working_dir>`):

```
MISSING — no match in any of:
  1. $CODEX_HOME/agents/<target>.toml (or ~/.codex-max-{1,2}/agents/<target>.toml)
  2. <working_dir>/.codex/agents/<target>.toml
  3. ~/.agents/skills/<target>/SKILL.md
  4. <working_dir>/.claude/skills/<target>/SKILL.md
```

All four paths appear so the operator can `ls` each one to confirm which
layer is missing.

## Failure handling

- One failed row never stops the run. Mark `FAIL`, continue.
- Under Codex, JSONL events land in `/tmp/spawn-<label>.jsonl` and any
  warnings/progress in `/tmp/spawn-<label>.stderr` (via `codex exec --json`
  redirection). The skill's own stdout only carries the summary table.
- `--dry-run`: print the parsed plan as a table, no spawns. Each row's
  `kind` (subagent/skill/MISSING) and resolved path are shown so the
  operator can confirm resolution before a long matrix run.

## Output convention

```
Summary: 13/15 PASS, 1 FAIL, 1 MISSING

| label                | target             | kind     | status | exit | head                                      | transcript                       |
|----------------------|--------------------|----------|--------|------|-------------------------------------------|----------------------------------|
| a-tdd-d1452e0d       | tdd-reviewer       | subagent | PASS   | 0    | "All 4 cases PASS — layering..."          | /tmp/spawn-a-tdd-d1452e0d.jsonl  |
| smoke-datadog        | datadog            | skill    | PASS   | 0    | "Resolved 4 monitors, 2 muted..."         | /tmp/spawn-smoke-datadog.jsonl   |
| a-backend-dc45703d   | backend-reviewer   | subagent | FAIL   | 1    | "ERROR: ESC unavailable"                  | /tmp/spawn-a-backend-...jsonl    |
| a-prompt-…           | prompt-reviewer    | —        | MISSING| —    | "MISSING — no match in any of: 1. $CODEX..."| —                                |
```

## Why this lives in dotfiles SSOT

The skill body symlinks into both harnesses' user-scope skills dir via
`modules/home/apps/codex.nix:userAgentsSymlinks` + the Claude `.agents`
mount. One SSOT, both harnesses see the same instructions, both Section A
and Section B matrices drive through this skill rather than ad-hoc
hand-typed `cx exec` invocations (CC-49).

## Related

- CC-91 § Section A (15 reviewer cells), § Section B (~30 skill cells)
- CC-94 — Section F YELLOW closure; introduced the two-kind resolver and
  the `--json` invocation; absorbed CC-95.
- CC-95 — original resolver-gap ticket; folded into CC-94 as Commit 1.
- ADR-015 (harness port), ADR-017 (hook layering)
- Agent SSOT: `~/dotfiles/config/claude-code/agents/*.{md,toml}` +
  project-scope `<repo>/.{claude,codex}/agents/`
- Skill SSOT: `~/dotfiles/config/claude-code/skills/<name>/SKILL.md` +
  project-scope `<repo>/.claude/skills/<name>/SKILL.md`
