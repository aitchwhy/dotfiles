---
name: spawn-agents-on-csv
description: >
  Bulk subagent fan-out from a CSV manifest. Each row spawns one named
  subagent (reviewer, architect, etc.) with a prompt + working dir, captures
  output to /tmp/spawn-<label>.txt, and appends a result row to the summary
  table. Drives the CC-91 Section A reviewer matrix + Section B skill matrix.
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
| `agent_name`    | yes      | Reviewer/architect name, e.g. `tdd-reviewer`         |
| `prompt`        | yes      | Self-contained instructions for the subagent         |
| `working_dir`   | no       | cwd for the spawn (default: repo root)               |
| `session_label` | yes      | Unique kebab-case label; used for `/tmp/spawn-<label>.txt` |
| `model`         | no       | Override model (default: agent's TOML default)       |

Example (`section-a.csv`):

```csv
agent_name,prompt,working_dir,session_label
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
   if `agent_name` or `session_label` is empty, or if labels collide.

2. **Verify each `agent_name` exists**. Under Claude, check
   `~/dotfiles/config/claude-code/agents/<name>.md` OR
   `<repo>/.claude/agents/<name>.md`. Under Codex, check
   `~/.agents/agents/<name>.toml` OR `<repo>/.codex/agents/<name>.toml`.
   Skip-with-FAIL any unknown agent rather than blowing up the whole run.

3. **Fan out**, respecting `--concurrency` (default 1, sequential — safer
   under sandbox quotas).
   - **Claude harness** (no `$CODEX_HOME` env): call the `Task` tool with
     `subagent_type: <agent_name>`, `prompt: <prompt>`, then write the
     result to `/tmp/spawn-<label>.txt`.
   - **Codex harness** (`$CODEX_HOME` set): shell out:
     ```bash
     cd "<working_dir>" && \
       codex exec --color never -o "/tmp/spawn-<label>.txt" "<prompt>"
     ```
     If the row carries `--agent` semantics for Codex, prefix the prompt
     with `@<agent_name>: ` so Codex's `/agents` mention triggers the
     sub-session. (Codex agent invocation is mention-based, not flag-based
     — see ADR-015 reconciliation #3.)

4. **Capture exit code, head -5 of stdout, full path to transcript**.

5. **Emit a summary table** (markdown), columns:
   `label | agent | status | exit | head | transcript-path`.
   Status is one of `PASS` (exit 0 and non-empty stdout), `EMPTY` (exit 0
   but no stdout), `FAIL` (non-zero exit), `MISSING` (unknown agent —
   skipped), `TIMEOUT`.

6. **Print the summary** to stdout, OR write to `--summary <out.md>` if
   given.

## Failure handling

- One failed row never stops the run. Mark `FAIL`, continue.
- TTY noise from `cx`/`codex` exec goes to the transcript file via `-o`;
  the skill's own stdout only carries the summary table.
- `--dry-run`: print the parsed plan as a table, no spawns. Useful before a
  long matrix.

## Output convention

```
Summary: 13/15 PASS, 1 FAIL, 1 MISSING

| label                | agent              | status | exit | head                              | transcript                  |
|----------------------|--------------------|--------|------|-----------------------------------|-----------------------------|
| a-tdd-d1452e0d       | tdd-reviewer       | PASS   | 0    | "All 4 cases PASS — layering..."  | /tmp/spawn-a-tdd-d1452e0d.txt |
| a-backend-dc45703d   | backend-reviewer   | FAIL   | 1    | "ERROR: ESC unavailable"          | /tmp/spawn-a-backend-...txt |
| a-prompt-…           | prompt-reviewer    | MISSING| —    | "No TOML at .codex/agents/..."    | —                            |
```

## Why this lives in dotfiles SSOT

The skill body symlinks into both harnesses' user-scope skills dir via
`modules/home/apps/codex.nix:userAgentsSymlinks` + the Claude `.agents`
mount. One SSOT, both harnesses see the same instructions, both Section A
and Section B matrices drive through this skill rather than ad-hoc
hand-typed `cx exec` invocations (CC-49).

## Related

- CC-91 § Section A (15 reviewer cells), § Section B (~30 skill cells)
- ADR-015 (harness port), ADR-017 (hook layering)
- Agent SSOT: `~/dotfiles/config/claude-code/agents/*.{md,toml}` +
  project-scope `<repo>/.{claude,codex}/agents/`
