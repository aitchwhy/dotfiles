---
status: accepted
date: 2026-01-17
---

# ADR-012: Boris Cherny Workflow Patterns

## Context

Boris Cherny (Claude Code creator) shared workflow patterns for effective Claude Code usage.

## Decision

### Adopted

- `/verify-loop` - Autonomous verification until green
- `/commit-push-pr` - Streamlined PR workflow
- `/context-checkpoint` - Session continuity for teleport/resume
- `ralph-wiggum` plugin - Long-running autonomous tasks

### Not Adopted

- GitHub Action (@claude) - Current hooks sufficient
- Session hook auto-checkpoint - Documented in planning-patterns skill instead

## Consequences

- Commands now accessible via symlink (`.claude/commands` -> `config/quality/commands`)
- Single SSOT for commands in `config/quality/commands/`
- Autonomous verification available via `/verify-loop`
- Context management patterns documented in planning-patterns skill

## Verification

```bash
ls -la ~/.claude/commands/
```
