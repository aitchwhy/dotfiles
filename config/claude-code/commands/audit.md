# Self-Audit Protocol

Run a comprehensive self-audit against all v4.0 criteria:

## Instructions

1. **Memory Health Check**
   - Count current memory entries
   - Identify stale entries (>30 days unused)
   - Check for contradictions

2. **Tool Efficiency Analysis**
   - List active MCP servers
   - Measure token usage per server
   - Identify unused tools

3. **Accuracy Calibration**
   - Calculate rolling Brier score from recent predictions
   - Compare stated confidence vs actual outcomes
   - Flag systematic biases

4. **Safety Posture Verification**
   - Run all safety invariants
   - Check for drift indicators
   - Verify permission minimization

5. **Evolution Status**
   - Count learnings per scope (task/file/project/stack/global)
   - Identify pending propagations
   - Check research sync status

## Output Format

Produce a scorecard:
```
┌─────────────────────────────────────────┐
│           ULTRATHINK v4.0 AUDIT         │
├─────────────────────────────────────────┤
│ Memory Health:       [X/10]             │
│ Tool Efficiency:     [X/10]             │
│ Accuracy:            [X/10]             │
│ Safety:              [X/10]             │
│ Evolution:           [X/10]             │
├─────────────────────────────────────────┤
│ TOTAL SCORE:         [XX/50]            │
│ GRADE:               [A/B/C/D/F]        │
└─────────────────────────────────────────┘
```

Then provide specific recommendations for improvement.
