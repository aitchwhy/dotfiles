# AGENTS.md Drift Governance

Process for keeping AGENTS.md files in sync with their corresponding CLAUDE.md files across repos.

**Scope:** `~/dotfiles` and `~/src/told` — both maintain separate AGENTS.md (Codex) and CLAUDE.md (Claude Code) files.

**Design:** Two-copy, no symlinks. AGENTS.md is intentionally smaller (Codex-compatible subset). Content drift is expected; structural drift is not.

## Trigger Checklist

Update AGENTS.md when any of these change in CLAUDE.md:

| Trigger | Example |
|---------|---------|
| Stack version changes | versions.ts, pnpm-workspace.yaml catalog |
| Repo structure changes | New apps, packages, or top-level dirs |
| Git workflow changes | Branch naming, PR format, commit conventions |
| Absolute rules changes | AST-grep rules added/removed/modified |
| Import convention changes | Barrel export rules, extension rules |
| Deployment pipeline changes | New stages, rollback procedures |
| CLI command changes | New commands, renamed commands |
| Key files changes | New critical files, removed files |

## Ownership

Hank (sole engineer). Updates both files when triggers fire.

## Cadence

- **On-demand:** When trigger events occur during normal development
- **Monthly spot-check:** Calendar reminder to run drift check script
- **Pre-release:** Before major infrastructure or architecture changes

## Drift Check Script

Run `config/quality/scripts/check-agents-drift.sh` to detect structural drift:

```bash
bash config/quality/scripts/check-agents-drift.sh
```

The script checks:
1. Both repos have AGENTS.md files present
2. Section headers in AGENTS.md have corresponding CLAUDE.md sections
3. Stack version numbers match between AGENTS.md and CLAUDE.md (per repo)
4. File sizes are under 32 KiB (Codex discovery chain limit)

**Not checked** (intentionally different): line-by-line content, Claude-only sections absent from AGENTS.md, section ordering.

## Recovery

If drift is detected:
1. Read the current CLAUDE.md for the affected repo
2. Update AGENTS.md to reflect current state
3. Commit with message: `docs(agents): sync AGENTS.md with CLAUDE.md`
4. Re-run drift check to confirm resolution
