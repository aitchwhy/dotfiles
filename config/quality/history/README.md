# History System

Persistent memory across Claude Code sessions.

## Directory Structure

```
history/
├── sessions/       # Session summaries (auto-generated)
├── decisions/      # ADRs (manual + extracted)
├── research/       # Research notes (manual + extracted)
└── README.md       # This file
```

## Purpose

The history system captures institutional knowledge that would otherwise be lost between sessions:

1. **Sessions** - What was accomplished, files changed, commits made
2. **Decisions** - Why architectural choices were made (ADRs)
3. **Research** - Investigation findings for future reference

## Integration

Session data is extracted by `session-stop.sh` and stored in `~/.claude-metrics/evolution.db`.
The files in this directory provide human-readable indexes.

## Related

- `config/quality/memory/lessons.md` - Pattern learnings
- `config/quality/memory/lessons.sql` - Structured lesson data
- `~/.claude-metrics/evolution.db` - Runtime metrics database
