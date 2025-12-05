# System Metrics Dashboard

Display current system health and calibration metrics.

## Instructions

1. **Read Calibration Data**
   - Load `~/.claude/metrics/baseline.json`
   - Load `~/.claude/metrics/predictions.jsonl` (if exists)
   - Calculate rolling Brier score from last 100 predictions

2. **Read Task Outcomes**
   - Load `~/.claude/metrics/task-outcomes.jsonl` (if exists)
   - Calculate success rate by task type
   - Identify trends (improving/declining)

3. **Check MCP Health**
   - Query memory graph for entity count
   - Check each MCP server responsiveness
   - Report any degraded servers

4. **Read Safety Status**
   - Load safety violation count from baseline
   - Calculate streak (days since last violation)

## Output Format

```
┌─────────────────────────────────────────────────────────────┐
│                    SYSTEM METRICS v4.0                      │
├─────────────────────────────────────────────────────────────┤
│ CALIBRATION                                                 │
│   Brier Score:        [X.XX] (target <0.15)                 │
│   Confidence Mult:    [X.XX]                                │
│   Predictions:        [N] tracked                           │
│   Trend:              [↑ improving | → stable | ↓ declining]│
├─────────────────────────────────────────────────────────────┤
│ TASK OUTCOMES                                               │
│   Overall Success:    [XX%] ([N] tasks)                     │
│   /tdd success:       [XX%]                                 │
│   /validate success:  [XX%]                                 │
│   /review success:    [XX%]                                 │
├─────────────────────────────────────────────────────────────┤
│ SAFETY                                                      │
│   Violations:         [N] total                             │
│   Streak:             [N] days clean                        │
│   Last Check:         [timestamp]                           │
├─────────────────────────────────────────────────────────────┤
│ MCP SERVERS                                                 │
│   memory:             [healthy|degraded|unavailable]        │
│   filesystem:         [healthy|degraded|unavailable]        │
│   github:             [healthy|degraded|unavailable]        │
│   sequential-thinking:[healthy|degraded|unavailable]        │
│   context7:           [healthy|degraded|unavailable]        │
├─────────────────────────────────────────────────────────────┤
│ EVOLUTION                                                   │
│   Memory Entries:     [N] entities, [N] relations           │
│   Improvements:       [N] logged                            │
│   Last Evolution:     [timestamp]                           │
└─────────────────────────────────────────────────────────────┘
```

## Data Sources

| Metric | Source File |
|--------|-------------|
| Brier Score | `~/.claude/metrics/predictions.jsonl` |
| Confidence Multiplier | `~/.claude/metrics/baseline.json` |
| Task Success | `~/.claude/metrics/task-outcomes.jsonl` |
| Safety Streak | `~/.claude/metrics/baseline.json` |
| MCP Health | Live query to each server |
| Memory Entries | MCP memory server query |
| Improvements | `~/.claude/improvements.jsonl` |

## Notes

- If metric files don't exist, report "No data yet"
- Brier score requires minimum 10 predictions to calculate
- MCP health check has 5s timeout per server
- Run `/calibrate` to update confidence multiplier
