---
description: Save session context for teleport or resume
allowed-tools: Bash, Write
---

# Context Checkpoint

## When to Use
- Before `--teleport` to web
- Before long break
- Context approaching limit (~150k tokens)
- Before risky refactoring

## Create Checkpoint

Save to `~/.claude/checkpoints/YYYY-MM-DD-HHMM.md`:
```markdown
# Session Checkpoint: [ISO timestamp]

## Original Goal
[What we set out to accomplish]

## Accomplished
- [x] Completed item 1
- [ ] Remaining item

## Files Changed
| File | Change |
|------|--------|
| path/to/file.ts | Description |

## Key Decisions
1. **Decision**: [What]
   **Rationale**: [Why]

## Critical Context
[Anything a fresh session MUST know]

## Resume Prompt
\`\`\`
Continue work on [goal]. Last session:
- Completed: [items]
- Remaining: [items]
Start by reviewing [file/area].
\`\`\`
```

## Setup
```bash
mkdir -p ~/.claude/checkpoints
```
