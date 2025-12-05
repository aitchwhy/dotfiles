# Confidence Calibration

Calculate rolling Brier score and adjust confidence multiplier.

## Instructions

1. **Load Prediction History**
   - Read `~/.claude/metrics/predictions.jsonl`
   - Use last 100 predictions (or all if fewer)
   - Require minimum 10 predictions to calculate

2. **Calculate Brier Score**
   ```
   Brier Score = mean((predicted_probability - actual_outcome)²)

   Where:
   - predicted_probability = stated confidence (0-1)
   - actual_outcome = 1 if correct, 0 if incorrect

   Example: 10 predictions at 80% confidence, 8 correct
   BS = (8 × (0.8-1)² + 2 × (0.8-0)²) / 10
   BS = (8 × 0.04 + 2 × 0.64) / 10
   BS = (0.32 + 1.28) / 10 = 0.16
   ```

3. **Assess Calibration Quality**
   - BS < 0.10: Excellent (well-calibrated)
   - BS 0.10-0.15: Good (target range)
   - BS 0.15-0.25: Fair (needs adjustment)
   - BS > 0.25: Poor (significantly miscalibrated)

4. **Adjust Confidence Multiplier**
   ```
   If overconfident (outcomes < stated confidence):
     new_multiplier = old_multiplier × 0.95

   If underconfident (outcomes > stated confidence):
     new_multiplier = old_multiplier × 1.02

   If well-calibrated (within 5%):
     keep current multiplier
   ```

5. **Update Baseline**
   - Write new Brier score to `~/.claude/metrics/baseline.json`
   - Write new confidence multiplier
   - Log calibration event to improvements.jsonl

## Output Format

```
┌─────────────────────────────────────────────────────────────┐
│                 CALIBRATION REPORT                          │
├─────────────────────────────────────────────────────────────┤
│ Predictions Analyzed: [N]                                   │
│ Time Period:          [start] to [end]                      │
├─────────────────────────────────────────────────────────────┤
│ BRIER SCORE                                                 │
│   Current:            [X.XXX]                               │
│   Previous:           [X.XXX]                               │
│   Change:             [↑X.XX | ↓X.XX | →stable]             │
│   Quality:            [Excellent|Good|Fair|Poor]            │
├─────────────────────────────────────────────────────────────┤
│ CALIBRATION ANALYSIS                                        │
│   Stated avg conf:    [XX%]                                 │
│   Actual success:     [XX%]                                 │
│   Drift:              [+X% overconfident | -X% under | OK]  │
├─────────────────────────────────────────────────────────────┤
│ CONFIDENCE MULTIPLIER                                       │
│   Previous:           [X.XX]                                │
│   New:                [X.XX]                                │
│   Adjustment:         [none | -5% | +2%]                    │
├─────────────────────────────────────────────────────────────┤
│ BREAKDOWN BY TASK TYPE                                      │
│   feature:   [XX%] stated → [XX%] actual (n=[N])            │
│   bugfix:    [XX%] stated → [XX%] actual (n=[N])            │
│   refactor:  [XX%] stated → [XX%] actual (n=[N])            │
│   other:     [XX%] stated → [XX%] actual (n=[N])            │
└─────────────────────────────────────────────────────────────┘

Recommendation: [Use current multiplier | Reduce stated confidence |
                 Can increase confidence | Need more data]
```

## Prediction Record Schema

Each prediction in `predictions.jsonl`:
```json
{
  "id": "pred-uuid",
  "timestamp": "2025-12-04T19:00:00Z",
  "taskId": "task-uuid",
  "taskType": "feature|bugfix|refactor|research|other",
  "description": "Brief description of prediction",
  "statedConfidence": 0.85,
  "actualOutcome": true,
  "outcomeRecordedAt": "2025-12-04T19:30:00Z",
  "notes": "Optional context"
}
```

## Usage

Run `/calibrate` after completing a batch of tasks to:
1. Record outcomes for pending predictions
2. Calculate updated Brier score
3. Adjust confidence multiplier if needed

For best results, record predictions BEFORE starting work and outcomes AFTER verification.
