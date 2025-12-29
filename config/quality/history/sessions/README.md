# Session History

This directory stores session summaries extracted by `session-stop.sh`.

## Format

Each session is stored as `YYYY-MM-DD-HH-MM-{hash}.md`:

```markdown
# Session: {project} @ {timestamp}

## Summary
Brief description of what was accomplished.

## Files Changed
- path/to/file1.ts
- path/to/file2.nix

## Commits
- abc1234: feat: added feature
- def5678: fix: resolved bug

## Learnings
- [pattern] Discovered new pattern
- [gotcha] Encountered issue with X

## Duration
45 minutes
```

## Retention

Sessions older than 90 days are archived to `~/.claude-history/archive/`.

## Querying

```bash
# List recent sessions
ls -lt config/quality/history/sessions/ | head -10

# Search sessions for a topic
grep -r "pattern" config/quality/history/sessions/
```
